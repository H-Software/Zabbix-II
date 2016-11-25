#!/bin/bash
# discovery status for devices by tw_cli and smartctl utilities
# usage in template via zabbix agent
# additional info: 
# http://www.cyberciti.biz/files/tw_cli.8.html
# https://www.marxen.cc/index.php?id=zabbix
# http://lab4.org/wiki/Zabbix_3ware_raidcontroller_ueberwachen
# ex
export LC_ALL=""
export LANG="en_US.UTF-8"
export PATH=$PATH:/sbin:/usr/sbin:$HOME/bin:/opt/MegaRAID/MegaCli

PROGNAME=$(basename $0)
PROGPATH=$(dirname $0)
VERBOSE=0
TEST=$(echo $PROGNAME| sed -e 's/\.sh$//')
CACHESEC=55
DATE_TM=$(date +%s)

TMPDIR=/dev/shm
[[ ! -d $TMPDIR ]] && TMPDIR=/tmp

WORKDIR=/home/zabbix
[[ ! -d $WORKDIR ]] && WORKDIR=/var/lib/zabbix/local

LOGDIR=$WORKDIR/log
[[ ! -d $LOGDIR ]]  && mkdir $LOGDIR
LOGFILE=$LOGDIR/$TEST.log
TMPFILE=$TMPDIR/${TEST}

. $PROGPATH/zabbix_utils.sh || exit 22

# smartctl utility
[[ -f /usr/sbin/smartctl ]] || exit 33
SMARTCLI="sudo /usr/sbin/smartctl"

# MegaCli utility
ARCH_TYPE=$(uname -p)
TWCLI=/usr/sbin/tw_cli
[[ -f $TWCLI ]] || exit 1
TWCLI="sudo $TWCLI"

print_usage(){
  code=$1
  echo "Usage: $PROGNAME [-hv] -t ad|ld|pd|smart -m metric -a adapter_id -d device_id"
  echo "Discovery 3ware adapater/controller IDs:"
  echo " $PROGNAME -t ad -m discovery"
  echo "Get metrics for the adapter:"
  echo " $PROGNAME -t ad -m bbu_state|bbu_temp_state|bbu_temp|bbu_volt -a adapter_id]"
  echo
  echo "Discovery 3ware logical device/utits IDs:"
  echo " $PROGNAME -t ld -m discovery"
  echo "Get metrics for the LD:"
  echo " $PROGNAME -t ld -m status -a adapter_id -d ld_id"
  echo
  echo "Discovery 3ware physical device IDs:"
  echo " $PROGNAME -t pd -m discovery"
  echo "Get metrics for the PD:"
  echo " $PROGNAME -t pd -m status|temperature -a adapter_id -d pd_id"
  echo 
  echo "Discovery SMART physical device IDs and device names:"
  echo " $PROGNAME -t smart -m discovery"
  echo "Get SMART metrics for the PD:"
  echo " $PROGNAME -t smart -m health|type|Raw_Read_Error_Rate.. -a device_name -d device_id"

  exit $code
}

# discovery installed adapters IDs
adapters_discovery(){
  print=$1  # if not defined zabbix discovery usage, else fill out variable adapters_list
 
  adapters_list=$($TWCLI info | egrep -o '^c[0-9]+')

  print_debug "$adapters_list"

  if [[ -z $print ]]; then 
    echo_simple_json "$adapters_list" "ADAPTER_ID"
    exit 0
  fi
}

# discovery installed/configured logical devices
# get adapter+ld list
# ex. { "data":[{"{#LD_ADAPTER_ID}":"0","{#LD_ID}":"0"}]}
ld_discovery(){
  print_ld=$1 # if not defined zabbix discovery usage, else fill out variable ld_list
  adapters_discovery "not_print"
  [[ -z $adapters_list ]] && exit 1

  ld_list=

  for adapter in $adapters_list; do
    lds_list=$($TWCLI info $adapter | egrep -o '^u[0-9]+')
    if [[ -n $lds_list ]]; then
      for ld in $lds_list; do
        ld_list=$ld_list"LD_ADAPTER_ID=$adapter;LD_ID=$ld "
      done
      ld_list=$(echo "$ld_list" | sed -e 's/\s\+$//')
    fi
  done

  if [[ -z $print_ld ]]; then
    echo_multi_json "$ld_list"
    exit 0
  fi
}

# discovery installed physical devices
pd_discovery(){
  adapters_discovery "not_print"
  [[ -z $adapters_list ]] && exit 1

  pd_list=
  for adapter in $adapters_list; do
    pds_list=$($TWCLI info $adapter | egrep -o '^p[0-9]+')
    if [[ -n $pds_list ]]; then
      for pd in $pds_list; do
        pd_list=$pd_list"PD_ADAPTER_ID=$adapter;PD_ID=$pd "
      done
    fi
  done
  pd_list=$(echo "$pd_list" | sed -e 's/\s\+$//')

  echo_multi_json "$pd_list"
  exit 0
}

# discovery installed physical devices and linux drive for them
# ex.
# TW_DEV = logical device name (aka /dev/twaN)
# TW_CTRL = controller id
# TW_UNIT - logical device id
# TW_PH_ID - physical device id
# function usage smartctl util:
# smartctl -a /dev/sda -d 3ware,10
smart_discovery(){
  smart_list=

  ld_discovery "not_print"
  [[ -z $ld_list ]] && exit 1

  smart_list=

  # test if cache file is valid
  use_cache=$(test_cache $metric_cache $metric_ttl)

  # LD_ADAPTER_ID=$adapter;LD_ID=$ld
  for ld_info in $ld_list; do
    tw_ctrl=$(echo "$ld_info" | awk -F';' '{print $1}' | awk -F'=' '{print $2}')
    tw_unit=$(echo "$ld_info" | awk -F';' '{print $2}' | awk -F'=' '{print $2}')
    tw_dev="/dev/twa"$(echo "$tw_ctrl" | sed -e's/^c//;' )
    #print_debug "tw_ctrl=$tw_ctrl tw_unit=$tw_unit tw_dev=$tw_dev"

    pd_ids=$($TWCLI info $tw_ctrl | grep '^p[0-9]\+ ' | \
     grep -w "$tw_unit" | awk '{print $7}')
    if [[ -n "$pd_ids" ]] ; then
      for pd_id in $pd_ids; do
        smart_list=$smart_list"TW_DEV=$tw_dev;TW_CTRL=$tw_ctrl;TW_UNIT=$tw_unit;TW_PH_ID=$pd_id "
      done
    fi
  done

  smart_list=$(echo "$smart_list" | sed -e 's/\s\+$//')

  echo_multi_json "$smart_list"
  exit 0

}

# get metric about adapter
# bbu_state|bbu_temp_state|bbu_temp|bbu_volt_state
ametric(){
  metric=$1
  adapter=$2

  [[ "$metric" == "discovery" ]] && adapters_discovery
  [[ -z $adapter ]] && exit 1

  metric_cache=${TMPFILE}_${adapter}_ad
  metric_ttl=299
  metric_keys='\(BBU Status\|Battery Voltage status\|Battery Temperature Status\|Battery Temperature Value\)'

  # test if cache file is valid
  use_cache=$(test_cache $metric_cache $metric_ttl)
  bbu_statuses='-=0 Testing=1 Charging=2 OK=3 WeakBat=4 Failed=5 Error=6 Fault=7'
  bbu_opt_statuses="OK=1 HIGH=2 LOW=3 TOO-HIGH=4 TOO-LOW=5"

  if [[ $use_cache -eq 1 ]]; then
    BBU_INFO=$($TWCLI /$adapter/bbu show all | \
     grep "$metric_keys")
    [[ -z $BBU_INFO ]] && exit 1

    # current temperature
    echo "bbu_temp:"$(echo "$BBU_INFO" | \
     awk -F'=' '/Battery Temperature Value/{print $2}' | \
     sed -e 's/\s\+//g') > $metric_cache

    # bbu status
    bbu_state=$(echo "$BBU_INFO" | \
     awk -F'=' '/BBU Status/{print $2}' | \
     sed -e 's/\s\+//g')
    if [[ -z $bbu_state ]]; then
      bbu_state_code=255
    else
      bbu_state_code=$(echo "$bbu_statuses" | \
       egrep -o "$bbu_state=[0-9]+" | awk -F'=' '{print $2}')
    fi
    echo "bbu_state:"$bbu_state_code >> $metric_cache

    # volt status
    bbu_volt_state=$(echo "$BBU_INFO" | \
     awk -F'=' '/Battery Voltage status/{print $2}' | \
     sed -e 's/\s\+//g')
    if [[ -z $bbu_volt_state ]]; then
      bbu_volt_state_code=255
    else
      bbu_volt_state_code=$(echo "$bbu_opt_statuses" | \
       egrep -o "$bbu_volt_state=[0-9]+" | awk -F'=' '{print $2}')
    fi
    echo "bbu_volt_state:"$bbu_volt_state_code >> $metric_cache

    # temp status
    bbu_temp_state=$(echo "$BBU_INFO" | \
     awk -F'=' '/Battery Temperature Status/{print $2}' | \
     sed -e 's/\s\+//g')
    if [[ -z "$bbu_temp_state" ]]; then
      bbu_temp_state_code=255
    else
      bbu_temp_state_code=$(echo "$bbu_opt_statuses" | \
       egrep -o "$bbu_temp_state=[0-9]+" | awk -F'=' '{print $2}')
    fi
    echo "bbu_temp_state:"$bbu_temp_state_code >> $metric_cache
  fi
  egrep -o "^$metric:[0-9]+" $metric_cache | awk -F':' '{print $2}'
}

# get metric about logical device
# status
lmetric(){
  metric=$1
  adapter=$2
  device=$3

  [[ "$metric" == "discovery" ]] && ld_discovery
  [[ ( -z $adapter ) || ( -z $device ) ]] && exit 1

  metric_cache=${TMPFILE}_${adapter}_ld_${device}
  metric_ttl=299
  metric_keys='\(status\)'
  unit_status="OK=1 VERIFYING=2 INITIALIZING=3 INIT-PAUSED=4 REBUILDING=5
REBUILD-PAUSED=6 DEGRADED=7 MIGRATING=8 MIGRATE-PAUSED=9
RECOVERY=10 INOPERABLE=11 UNKNOWN=255"

  # test if cache file is valid
  use_cache=$(test_cache $metric_cache $metric_ttl)
  if [[ $use_cache -eq 1 ]]; then
    LD_INFO=$($TWCLI /$adapter/$device show all | \
     grep "/$adapter/$device $metric_keys")
    [[ -z $LD_INFO ]] && exit 1

    # get status
    lb_status=$(echo "$LD_INFO" | \
     awk -F'=' '/status/{print $2}' | \
     sed -e 's/\s\+//g')
    if [[ -z $lb_status ]]; then
      lb_status_code=255
    else
      lb_status_code=$(echo "$unit_status" | \
       egrep -o "$lb_status=[0-9]+" | awk -F'=' '{print $2}')
    fi
    echo "status:"$lb_status_code > $metric_cache
  fi

  egrep -o "^$metric:\S+" $metric_cache | awk -F':' '{print $2}'
}

# get metric about physical device
# status
pmetric(){
  metric=$1
  adapter=$2
  device=$3

  [[ "$metric" == "discovery" ]] && pd_discovery
  [[ ( -z $adapter ) || ( -z $device ) ]] && exit 1

  metric_device=$(echo "$device" | sed -e 's/:/-/g')
  metric_cache=${TMPFILE}_${adapter}_pd_${metric_device}
  metric_ttl=55
  metric_keys='\(Status\)'
  unit_status="OK=1 VERIFYING=2 INITIALIZING=3 INIT-PAUSED=4 REBUILDING=5
REBUILD-PAUSED=6 DEGRADED=7 MIGRATING=8 MIGRATE-PAUSED=9
RECOVERY=10 INOPERABLE=11 UNKNOWN=255"


  # test if cache file is valid
  use_cache=$(test_cache $metric_cache $metric_ttl)
  if [[ $use_cache -eq 1 ]]; then
    PD_INFO=$($TWCLI /$adapter/$device show all | \
     grep "/$adapter/$device $metric_keys")
    [[ -z $PD_INFO ]] && exit 1

    # get status
    pd_status=$(echo "$PD_INFO" | \
     awk -F'=' '/Status/{print $2}' | \
     sed -e 's/\s\+//g')
    if [[ -z $pd_status ]]; then
      pd_status_code=255
    else
      pd_status_code=$(echo "$unit_status" | \
       egrep -o "$pd_status=[0-9]+" | awk -F'=' '{print $2}')
    fi
    echo "status:"$pd_status_code > $metric_cache
 
  fi
  egrep -o "^$metric:[0-9\+]+" $metric_cache | awk -F':' '{print $2}'
}

# smartctl metrics
smetric(){
  metric=$1
  device_name=$2
  device_id=$3

  [[ "$metric" == "discovery" ]] && smart_discovery
  [[ ( -z $device_name ) || ( -z $device_id ) ]] && exit 1

  metric_cache=${TMPFILE}_$(basename ${device_name})_smart_${device_id}
  metric_ttl=55
  metric_keys="Raw_Read_Error_Rate Seek_Error_Rate Temperature_Celsius Reallocated_Sector_Ct
Reported_Uncorrect Command_Timeout Current_Pending_Sector Offline_Uncorrectable Power_On_Hours"

  # test if cache file is valid
  use_cache=$(test_cache $metric_cache $metric_ttl)
  if [[ $use_cache -eq 1 ]]; then
    smart_attributes=$(${SMARTCLI} --all ${device_name} -d 3ware,${device_id})
    [[ -z $smart_attributes ]] && exit 1
    [[ $VERBOSE -gt 0 ]] && echo "$smart_attributes"

    # device type: SAS => 1, SSD => 2
    smart_type=255
    [[ -n $(echo "$smart_attributes" | \
     grep '^SMART Health Status:') ]] && smart_type=1
    [[ -n $(echo "$smart_attributes" | \
     grep '^SMART overall-health self-assessment test result:') ]] && smart_type=2
    echo "type:$smart_type" > $metric_cache

    # smart health
    smart_health_code=0
    if [[ $smart_type -eq 2 ]]; then
      smart_health_code=$(echo "$smart_attributes" | \
       awk -F':' '/SMART overall-health self-assessment test result:/{print $2}' | \
       sed -e 's/\s\+//g' | grep -wc 'PASSED')
    elif [[ $smart_type -eq 1 ]]; then
      smart_health_code=$(echo "$smart_attributes" | \
       awk -F':' '/SMART Health Status:/{print $2}' | \
       sed -e 's/\s\+//g' | grep -wc 'OK')
    fi
    echo "health:$smart_health_code" >> $metric_cache

    for key in $metric_keys; do
      val=$(echo "$smart_attributes" | \
       grep -w "$key" | awk '{print $10}')
      [[ -z $val ]] && val=0
      echo "$key:$val" >> $metric_cache
    done
  fi 
  egrep -o "^$metric:[0-9\.]+" $metric_cache | awk -F':' '{print $2}'
}

# get command line options
# PROGNAME [-hv] -t ad|ld|pd -m metric -a adapter_id -d device_id"
while getopts ":t:m:a:d:n:vh" opt; do
  case $opt in
    "t")
      TYPE=$OPTARG            #device type: ad, ld or pd
      ;;
    "m")
      METRIC=$OPTARG          # requested metric
      ;;
    "a")
      ADAPTER=$OPTARG         # adapter id
      ;;
    "d")
      DEVICE=$OPTARG          # device id
      ;;
    "n")
      DEVICE_NAME=$OPTARG     # device_name
      ;;
    h)
      print_usage 0
      ;;
    v)
      VERBOSE=1
      ;;
    \?)
      print_usage 1
      ;;
  esac
done

# 
case $TYPE in
  'ad')
    ametric "$METRIC" "$ADAPTER"
  ;;
  'ld')
    lmetric "$METRIC" "$ADAPTER" "$DEVICE"
  ;;
  'pd')
    pmetric "$METRIC" "$ADAPTER" "$DEVICE"
  ;;
  'smart')
    smetric "$METRIC" "$ADAPTER" "$DEVICE" 
  ;;
  *)
  print_usage 1
  ;;
esac


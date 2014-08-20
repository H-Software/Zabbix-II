#!/bin/bash


snmp_community=$1
# ip
ip=$2
#snmp oid
oid=$3
# version of regexp
mod=$4

if [ $# -lt 4 ]
 then
     echo
     echo " Not enough parameters"
     echo " Usage: ibm_amm_snmpget.sh <SNMP_COMMUNITY> <IP> <OID> <MOD>"
  exit 2
fi

if [[ $mod == "1" ]];
then
    #
    # MODE 1
    #
    # for temp and Power Domain fuel stats
    #
    /usr/bin/snmpget -Ov -t 5 -v  1 -c $snmp_community $ip $oid | /bin/sed "s/[^0-9.]//g"

elif [[ $mod == "2" ]];
then
    #
    # MODE 2
    #
    # for Power Domain Status
    #

    /usr/bin/snmpget -Ov -t 5 -v  1 -c $snmp_community $ip $oid | /bin/sed "s/[^0-9]//g"
elif [[ $mod == "3" ]];
then
    #
    # MODE 3
    #
    # for Chassis Voltage
    #

    /usr/bin/snmpget -Ov -t 5 -v  1 -c $snmp_community $ip $oid | /bin/sed "s/[^-|+|0-9|.]//g"

elif [[ $mod == "9" ]];
then
    #
    # MODE 9
    #
    # for debug
    #

    /usr/bin/snmpget -Ov -t 5 -v  1 -c $snmp_community $ip $oid

else
    echo "ERR: wrong number of mode"
fi

exit 0


#!/usr/bin/python
# -*- coding: utf-8 -*- # coding: utf-8
#
# IBM Storwize V7000 performance monitoring script for Zabbix
#
# v4.1
# 2013 Matvey Marinin
#
# Returns statistics in zabbix_sender format (http://www.zabbix.com/documentation/2.2/manpages/zabbix_sender):
# <hostname> <key> <timestamp> <value>
# svc1-blk svc.ReadRateKB[mdisk,40] 1356526942 14470.7333333
# svc1-blk svc.WriteRateKB[mdisk,40] 1356526942 11102.84
# svc1-blk svc.TotalRateKB[mdisk,40] 1356526942 25573.5733333
# svc1-blk svc.ReadIORate[mdisk,40] 1356526942 609.356666667
# svc1-blk svc.WriteIORate[mdisk,40] 1356526942 121.946666667
# svc1-blk svc.TotalIORate[mdisk,40] 1356526942 731.303333333
# svc1-blk svc.ReadIOTime[mdisk,40] 1356526942 5.29899839722
# svc1-blk svc.WriteIOTime[mdisk,40] 1356526942 9.65088563306
# svc1-blk svc.ReadIOPct[mdisk,40] 1356526942 83.3247489642
#
# Use with template _Special_Storwize_Perf
#
# Performance stats is collected with SVC CIM provider (WBEM):
# http://pic.dhe.ibm.com/infocenter/storwize/unified_ic/index.jsp?topic=%2Fcom.ibm.storwize.v7000.unified.doc%2Fsvc_umlblockprofile.html
# http://pic.dhe.ibm.com/infocenter/storwize/unified_ic/index.jsp?topic=%2Fcom.ibm.storwize.v7000.unified.doc%2Fsvc_cim_main.html
#
# Usage:
# svc_perf_wbem.py --cluster <cluster1> [--cluster <cluster2>...] --user <username> --password <pwd> --cachefile <path>|none
#
#   --cluster = Dns name or IP of Storwize V7000 block node (not Storwize V7000 Unified mgmt node!). May be used several times to monitor some clusters.
#   --user    = Storwize V7000 user account with Administrator role (it seems that Monitor role is not enough)
#   --password = User password
#   --cachefile = Path to timestamp cache file or "none" to not use cache. Used to prevent submitting duplicate values to Zabbix.
#                 Duplicates detected by statistics timestamp supplied by Storwize.
#
#
import pywbem
import getopt, sys, datetime, time, calendar, json

def usage():
  print >> sys.stderr, "Usage: svc_perf_wbem.py --cluster <cluster1> [--cluster <cluster2>...] --user <username> --password <pwd> --cachefile <path>|none"

##############################################################

RAW_COUNTERS = ['timestamp', 'KBytesRead', 'KBytesWritten', 'KBytesTransferred', 'ReadIOs', 'WriteIOs', 'TotalIOs', 'IOTimeCounter', 'ReadIOTimeCounter', 'WriteIOTimeCounter']
MDISK_COUNTERS = ['ReadRateKB', 'WriteRateKB', 'TotalRateKB', 'ReadIORate', 'WriteIORate', 'TotalIORate', 'ReadIOTime', 'WriteIOTime', 'ReadIOPct']
VOLUME_COUNTERS = ['ReadRateKB', 'WriteRateKB', 'TotalRateKB', 'ReadIORate', 'WriteIORate', 'TotalIORate', 'ReadIOTime', 'WriteIOTime', 'ReadIOPct']

##############################################################
def enumNames(cimClass):
  ''' Enum storage objects and return dict{id:name} '''
  names = {}
  for obj in conn.ExecQuery( 'WQL', 'SELECT DeviceID, ElementName FROM %s' % (cimClass) ):
    deviceID = obj.properties['DeviceID'].value
    if deviceID:
      names[str(deviceID)] = obj.properties['ElementName'].value
  return names

##############################################################
def calculateStats(old_counters, new_counters):
  ''' Calculate perf statistic values from raw counters '''
  stats = {}

  ''' check that we have timestamp in cached sample '''
  if 'timestamp' in old_counters:
    timespan = new_counters['timestamp'] - old_counters['timestamp']

    if timespan:
      deltaReadKB  = float(new_counters['KBytesRead'] - old_counters['KBytesRead'])
      deltaWriteKB = float(new_counters['KBytesWritten'] - old_counters['KBytesWritten'])
      deltaTotalKB = float(new_counters['KBytesTransferred'] - old_counters['KBytesTransferred'])
      deltaReadIO  = float(new_counters['ReadIOs'] - old_counters['ReadIOs'])
      deltaWriteIO = float(new_counters['WriteIOs'] - old_counters['WriteIOs'])
      deltaTotalIO = float(new_counters['TotalIOs'] - old_counters['TotalIOs'])
      deltaReadIOTimeCounter = float(new_counters['ReadIOTimeCounter'] - old_counters['ReadIOTimeCounter'])
      deltaWriteIOTimeCounter = float(new_counters['WriteIOTimeCounter'] - old_counters['WriteIOTimeCounter'])

      stats['ReadRateKB']  = deltaReadKB  / timespan
      stats['WriteRateKB'] = deltaWriteKB / timespan
      stats['TotalRateKB'] = deltaTotalKB / timespan
      stats['ReadIORate']  = deltaReadIO  / timespan
      stats['WriteIORate'] = deltaWriteIO / timespan
      stats['TotalIORate'] = deltaTotalIO / timespan

      if (deltaReadIO > 0) and (deltaReadIOTimeCounter > 0):
        stats['ReadIOTime'] = deltaReadIOTimeCounter / deltaReadIO

      if (deltaWriteIO > 0) and (deltaWriteIOTimeCounter > 0):
        stats['WriteIOTime'] = deltaWriteIOTimeCounter / deltaWriteIO

      if (deltaTotalIO > 0) and (deltaReadIO > 0):
        stats['ReadIOPct'] = deltaReadIO / deltaTotalIO * 100

    else:
      print >> sys.stderr, 'timespan between samples is 0, skipping'

  else:
      print >> sys.stderr, 'no timestamp in previous sample, skipping'

  return stats

##############################################################
def collectStats(connection, elementType, elementClass, statisticsClass, elementCounters):

  ##enumerate element names
  names = enumNames(elementClass)

  ##get volume stats
  stats = conn.EnumerateInstances(statisticsClass)
  for stat in stats:
    ''' parse property InstanceID = "StorageVolumeStats 46" to get element ID '''
    elementID = stat.properties['InstanceID'].value.split()[1]
    elementName = names[elementID]
    ps = stat.properties


    timestamp = calendar.timegm(ps['StatisticTime'].value.datetime.timetuple())

    ''' get previous samples '''
    cached_raw_counters = {}
    cache_key = '%s.%s.%s' % (cluster, elementType, elementName)
    if (cache_key in cache):
      cached_raw_counters = cache[cache_key]
    if cached_raw_counters is None:
      cached_raw_counters = {}

    ''' don't proceed samples with same timestamp to prevent speed calculation errors '''
    if ('timestamp' in cached_raw_counters) and (timestamp == cached_raw_counters['timestamp']):
      print >> sys.stderr, 'same sample: %s = %s, skipping' % (cache_key, ps['StatisticTime'].value.datetime)
      continue

    ''' get current samples '''
    new_raw_counters = {}
    new_raw_counters['timestamp'] = timestamp
    for k in RAW_COUNTERS:
      if k in ps and ps[k].value is not None:
        new_raw_counters[k] = ps[k].value

    ''' save current samples to cache '''
    cache[cache_key] = new_raw_counters

    ''' calculate statistics for Zabbix '''
    stat_values = calculateStats(cached_raw_counters, new_raw_counters)

    for s in elementCounters:
      if s in stat_values:
        print '%s svc.%s[%s,%s] %d %s' % (cluster, s, elementType, elementID, timestamp, stat_values[s])

##############################################################

''' main script body '''
try:
  opts, args = getopt.gnu_getopt(sys.argv[1:], "-h", ["help", "cluster=", "user=", "password=", "cachefile="])
except getopt.GetoptError, err:
  print >> sys.stderr, str(err) # will print something like "option -a not recognized"
  usage()
  sys.exit(2)

cluster = []
user = None
password = None
cachefile = None
for o, a in opts:
  if o == "--cluster":
    cluster.append(a)
  elif o == "--user":
    user = a;
  elif o == "--password":
    password = a;
  elif o == "--cachefile":
    cachefile = a;
  elif o in ("-h", "--help"):
    usage()
    sys.exit()

if not cluster or not user or not password or not cachefile:
  print >> sys.stderr, 'Required argument is not set'
  usage()
  sys.exit(2)

## Loading stats cache from file
cache = None
try:
  if 'none' != cachefile:
    cache = json.load( open(cachefile, 'r') )
except Exception, err:
  print >> sys.stderr, "Can't load cache:", str(err)

''' Initialize cache if neccesary '''
if cache is None:
  cache = {}

''' main loop '''
for cluster in cluster:
  print >> sys.stderr, 'Connecting to', cluster

  conn = pywbem.WBEMConnection('https://'+cluster, (user, password), 'root/ibm')
  conn.debug = True

  collectStats(conn, 'volume', 'IBMTSSVC_StorageVolume', 'IBMTSSVC_StorageVolumeStatistics', VOLUME_COUNTERS)
  collectStats(conn, 'mdisk', 'IBMTSSVC_BackendVolume', 'IBMTSSVC_BackendVolumeStatistics', MDISK_COUNTERS)


''' finally save cache to disk if permitted by command line argument '''
try:
  if 'none' != cachefile:
    json.dump( cache, open(cachefile, 'w') )
except Exception, err:
  print >> sys.stderr, "Can't save cache:", str(err)


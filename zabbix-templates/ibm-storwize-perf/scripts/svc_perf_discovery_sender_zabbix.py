#!/usr/bin/python
# -*- coding: utf-8 -*- # coding: utf-8
#
# IBM Storwize V7000 autodiscovery script for Zabbix
#
# 2013 Matvey Marinin
#
# Sends volume/mdisk/pool LLD JSON data to LLD trapper items "svc.discovery.<volume-mdisk|volume|mdisk|pool>"
# Use with "_Special_Storwize_Perf" Zabbix template
#
# See also http://www.zabbix.com/documentation/2.0/manual/discovery/low_level_discovery
#
# Usage:
# svc_perf_discovery_sender.py [--debug] --clusters <svc1>[,<svc2>...] --user <username> --password <pwd>
#
#   --debug    = Enable debug output
#   --clusters = Comma-separated Storwize node list
#   --user     = Storwize V7000 user account with Administrator role (it seems that Monitor role is not enough)
#   --password = User password
#
import pywbem
import getopt, sys
from zbxsend import Metric, send_to_zabbix
import logging

def usage():
  print >> sys.stderr, "Usage: svc_perf_discovery_sender_zabbix.py [--debug] --clusters <svc1>[,<svc2>...] --user <username> --password <pwd> --discovery-types <type1>,[type2]"
  print >> sys.stderr, "Discovery types: 'volume-mdisk','volume','mdisk','pool'"


try:
  opts, args = getopt.gnu_getopt(sys.argv[1:], "-h", ["help", "clusters=", "user=", "password=", "debug", "discovery-types="])
except getopt.GetoptError, err:
  print >> sys.stderr, str(err)
  usage()
  sys.exit(2)

debug = False
clusters = []
DISCOVERY_TYPES = []
user = None
password = None
for o, a in opts:
  if o == "--clusters" and not a.startswith('--'):
    clusters.extend( a.split(','))
  elif o == "--user" and not a.startswith('--'):
    user = a
  elif o == "--password" and not a.startswith('--'):
    password = a
  elif o == "--debug":
    debug = True
  elif o == "--discovery-types":
    DISCOVERY_TYPES.extend( a.split(','))
  elif o in ("-h", "--help"):
    usage()
    sys.exit()

if not clusters:
  print >> sys.stderr, '--clusters option must be set'
  usage()
  sys.exit(2)

if not DISCOVERY_TYPES:
  print >> sys.stderr, '--discovery-types option must be set'
  usage()
  sys.exit(2)

if not user or not password:
  print >> sys.stderr, '--user and --password options must be set'
  usage()
  sys.exit(2)

def debug_print(message):
  if debug:
    print message

for cluster in clusters:
  debug_print('Connecting to: %s' % cluster)
  conn = pywbem.WBEMConnection('https://'+cluster, (user, password), 'root/ibm')
  conn.debug = True

  for discovery in DISCOVERY_TYPES:
    output = []

    if discovery == 'volume-mdisk' or discovery == 'volume':
      for vol in conn.ExecQuery('WQL', 'select DeviceID, ElementName from IBMTSSVC_StorageVolume'):
        output.append( '{"{#TYPE}":"%s", "{#NAME}":"%s", "{#ID}":"%s"}' % ('volume', vol.properties['ElementName'].value, vol.properties['DeviceID'].value) )

    if discovery == 'volume-mdisk' or discovery == 'mdisk':
      for mdisk in conn.ExecQuery('WQL', 'select DeviceID, ElementName from IBMTSSVC_BackendVolume'):
        output.append( '{"{#TYPE}":"%s", "{#NAME}":"%s", "{#ID}":"%s"}' % ('mdisk', mdisk.properties['ElementName'].value, mdisk.properties['DeviceID'].value) )

    if discovery == 'pool':
      for pool in conn.ExecQuery('WQL', 'select PoolID, ElementName from IBMTSSVC_ConcreteStoragePool'):
        output.append( '{"{#TYPE}":"%s","{#NAME}":"%s","{#ID}":"%s"}' % ('pool', pool.properties['ElementName'].value, pool.properties['PoolID'].value) )

    json = []
    json.append('{"data":[')

    for i, v in enumerate( output ):
      if i < len(output)-1:
        json.append(v+',')
      else:
        json.append(v)
    json.append(']}')

    json_string = ''.join(json)
    print(json_string)

    trapper_key = 'svc.discovery.%s' % discovery
    debug_print('Sending to host=%s, key=%s' % (cluster, trapper_key))

    #send json to LLD trapper item with zbxsend module
    if debug:
      logging.basicConfig(level=logging.INFO)
    else:
      logging.basicConfig(level=logging.WARNING)
    send_to_zabbix([Metric(cluster, trapper_key, json_string)], 'localhost', 10051)
    debug_print('')





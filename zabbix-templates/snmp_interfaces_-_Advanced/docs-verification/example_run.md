Example run
=========

Juniper switches in VC
-------

snmpwalk
---------------
```
[root@monitoring-zabbix]# snmpwalk -c public -v1 172.x.0.111 .1.3.6.1.2.1.2.2.1
IF-MIB::ifIndex.4 = INTEGER: 4
IF-MIB::ifIndex.5 = INTEGER: 5
IF-MIB::ifIndex.6 = INTEGER: 6
IF-MIB::ifIndex.7 = INTEGER: 7
.
.
.
IF-MIB::ifIndex.538 = INTEGER: 538
IF-MIB::ifIndex.540 = INTEGER: 540
IF-MIB::ifIndex.542 = INTEGER: 542
.
.
.
IF-MIB::ifDescr.501 = STRING: ge-0/0/0
IF-MIB::ifDescr.502 = STRING: ge-0/0/0.0
IF-MIB::ifDescr.503 = STRING: ge-0/0/1
IF-MIB::ifDescr.505 = STRING: ge-0/0/10
IF-MIB::ifDescr.506 = STRING: ge-0/0/11
.
.
.
IF-MIB::ifOperStatus.10 = INTEGER: up(1)
IF-MIB::ifOperStatus.11 = INTEGER: up(1)
IF-MIB::ifOperStatus.12 = INTEGER: up(1)
IF-MIB::ifOperStatus.21 = INTEGER: up(1)
IF-MIB::ifOperStatus.33 = INTEGER: down(2)
IF-MIB::ifOperStatus.34 = INTEGER: lowerLayerDown(7)
IF-MIB::ifOperStatus.35 = INTEGER: down(2)
IF-MIB::ifOperStatus.37 = INTEGER: up(1)
IF-MIB::ifOperStatus.38 = INTEGER: up(1)
IF-MIB::ifOperStatus.39 = INTEGER: down(2)
IF-MIB::ifOperStatus.40 = INTEGER: down(2)
IF-MIB::ifOperStatus.41 = INTEGER: down(2)
.
.
.
```

snmp iface advanced discovery
---------------

```
[root@monitoring-zabbix externalscripts]# ./snmp_iface_advanced_discovery.pl public 172.x.0.111 .1.3.6.1.2.1.2.2.1

{
        "data":[
        {
                "{#STATUS}":"1",
                "{#NAME}":"ipip",
                "{#ID}":"9",
                "{#ALL}":"-1--ipip--9-",
        }
        ,
        {
                "{#STATUS}":"2",
                "{#NAME}":"ge-7/0/5",
                "{#ID}":"802",
                "{#ALL}":"-2--ge-7/0/5--802-",
        }
        ,
        {
                "{#STATUS}":"1",
                "{#NAME}":"bme0.32768",
                "{#ID}":"38",
                "{#ALL}":"-1--bme0.32768--38-",
        }
        ,
        {
                "{#STATUS}":"1",
                "{#NAME}":"lsi",
                "{#ID}":"4",
                "{#ALL}":"-1--lsi--4-",
        }
        ,
        {
                "{#STATUS}":"7",
                "{#NAME}":"me0.0",
                "{#ID}":"34",
                "{#ALL}":"-7--me0.0--34-",
        }
        ,
        {
                "{#STATUS}":"2",
                "{#NAME}":"ge-8/0/44",
                "{#ID}":"745",
                "{#ALL}":"-2--ge-8/0/44--745-",
        }
        ]
}
```

License
-------

This template were distributed under GNU General Public License 2.

### Copyright

Copyright (c) 2014 Patrik Majer

### Authors

Patrik Majer
      (patrik.majer.pisek |at| gmail |dot| com)
      

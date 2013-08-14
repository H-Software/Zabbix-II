Verification of "CPU Usage"
=========

EX4500
-------
-with virtual routing instances ..

snmpwalk
---------------
```
[root@monitoring-zabbix]# snmpwalk -v 2c -c TETS-VR@public 10.0.0.10 .1.3.6.1.4.1.2636.3.1.13.1.5
SNMPv2-SMI::enterprises.2636.3.1.13.1.5.1.1.0.0 = ""
SNMPv2-SMI::enterprises.2636.3.1.13.1.5.2.1.2.0 = STRING: "Power Supply 1"
SNMPv2-SMI::enterprises.2636.3.1.13.1.5.4.1.1.1 = STRING: "Fan 1"
SNMPv2-SMI::enterprises.2636.3.1.13.1.5.4.1.1.2 = STRING: "Fan 2"
SNMPv2-SMI::enterprises.2636.3.1.13.1.5.4.1.1.3 = STRING: "Fan 3"
SNMPv2-SMI::enterprises.2636.3.1.13.1.5.4.1.1.4 = STRING: "Fan 4"
SNMPv2-SMI::enterprises.2636.3.1.13.1.5.4.1.1.5 = STRING: "Fan 5"
SNMPv2-SMI::enterprises.2636.3.1.13.1.5.7.1.0.0 = STRING: "FPC: EX4500-40F @ 0/*/*"
SNMPv2-SMI::enterprises.2636.3.1.13.1.5.8.1.1.0 = STRING: "PIC: 40x 1/10GE @ 0/0/*"
SNMPv2-SMI::enterprises.2636.3.1.13.1.5.8.1.4.0 = STRING: "PIC: 2x 32GE Virtual Chassis Module @ 0/3/*"
SNMPv2-SMI::enterprises.2636.3.1.13.1.5.9.1.0.0 = STRING: "Routing Engine 0"
```

advsnmp.discovery
---------------

```
[root@monitoring-zabbix externalscripts]# ./advsnmp.discovery.old 10.0.0.10 "-v2c -c TEST-VR@public" .1.3.6.1.4.1.2636.3.1.13.1.5 1.1 2.1 3.2
{
        "data":[
                {
                "{#ADVSNMPINDEX1}": "",
                "{#ADVSNMPINDEX2}": "1",
                "{#ADVSNMPINDEX3}": "1",
                "{#ADVSNMPINDEX4}": "0.0",
                "{#ADVSNMPVALUE}":""
                }       ,
                {
                "{#ADVSNMPINDEX1}": "",
                "{#ADVSNMPINDEX2}": "2",
                "{#ADVSNMPINDEX3}": "1",
                "{#ADVSNMPINDEX4}": "2.0",
                "{#ADVSNMPVALUE}":"Power Supply 1"
                }       ,
                {
                "{#ADVSNMPINDEX1}": "",
                "{#ADVSNMPINDEX2}": "4",
                "{#ADVSNMPINDEX3}": "1",
                "{#ADVSNMPINDEX4}": "1.1",
                "{#ADVSNMPVALUE}":"Fan 1"
                }       ,
                {
                "{#ADVSNMPINDEX1}": "",
                "{#ADVSNMPINDEX2}": "4",
                "{#ADVSNMPINDEX3}": "1",
                "{#ADVSNMPINDEX4}": "1.2",
                "{#ADVSNMPVALUE}":"Fan 2"
                }       ,
                {
                "{#ADVSNMPINDEX1}": "",
                "{#ADVSNMPINDEX2}": "4",
                "{#ADVSNMPINDEX3}": "1",
                "{#ADVSNMPINDEX4}": "1.3",
                "{#ADVSNMPVALUE}":"Fan 3"
                }       ,
                {
                "{#ADVSNMPINDEX1}": "",
                "{#ADVSNMPINDEX2}": "4",
                "{#ADVSNMPINDEX3}": "1",
                "{#ADVSNMPINDEX4}": "1.4",
                "{#ADVSNMPVALUE}":"Fan 4"
                }       ,
                {
                "{#ADVSNMPINDEX1}": "",
                "{#ADVSNMPINDEX2}": "4",
                "{#ADVSNMPINDEX3}": "1",
                "{#ADVSNMPINDEX4}": "1.5",
                "{#ADVSNMPVALUE}":"Fan 5"
                }       ,
                {
                "{#ADVSNMPINDEX1}": "",
                "{#ADVSNMPINDEX2}": "7",
                "{#ADVSNMPINDEX3}": "1",
                "{#ADVSNMPINDEX4}": "0.0",
                "{#ADVSNMPVALUE}":"FPC: EX4500-40F @ 0/*/*"
                }       ,
                {
                "{#ADVSNMPINDEX1}": "",
                "{#ADVSNMPINDEX2}": "8",
                "{#ADVSNMPINDEX3}": "1",
                "{#ADVSNMPINDEX4}": "1.0",
                "{#ADVSNMPVALUE}":"PIC: 40x 1/10GE @ 0/0/*"
                }       ,
                {
                "{#ADVSNMPINDEX1}": "",
                "{#ADVSNMPINDEX2}": "8",
                "{#ADVSNMPINDEX3}": "1",
                "{#ADVSNMPINDEX4}": "4.0",
                "{#ADVSNMPVALUE}":"PIC: 2x 32GE Virtual Chassis Module @ 0/3/*"
                }       ,
                {
                "{#ADVSNMPINDEX1}": "",
                "{#ADVSNMPINDEX2}": "9",
                "{#ADVSNMPINDEX3}": "1",
                "{#ADVSNMPINDEX4}": "0.0",
                "{#ADVSNMPVALUE}":"Routing Engine 0"
                }
        ]
}
```

License
-------

This template were distributed under GNU General Public License 2.

### Copyright

Copyright (c) 2013 Patrik Majer

### Authors

Patrik Majer
      (patrik.majer.pisek |at| gmail |dot| com)
      

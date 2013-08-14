juniper-switch-ex
=========

1. juniper switch EX - CPU Usage
=====

Requirements
-----

All this templates were tested for Zabbix 2.0.6 and higher.

This template tested on Centos 6.4 x86_64 OS.

Instalation
-----

1. download "advsnmp.discovery" to your zabbix-server 
(from czhujer/Zabbix-Addons REPO)

```
[root@..]# cd /etc/zabbix/externalscripts
[root@..]# wget https://raw.github.com/czhujer/Zabbix-Addons/master/advsnmp.discovery/advsnmp.discovery
[root@..]# chmod 755 advsnmp.discovery
[root@..]# chown root:root advsnmp.discovery
```

2. import xml file to zabbix server

3. enjoy it!

[OPTIONAL] check yours result of discovery with examples in docs-verification folder

License
-------

This template were distributed under GNU General Public License 2.

### Copyright

Copyright (c) 2013 Patrik Majer
  
### Authors

Patrik Majer
      (patrik.majer.pisek |at| gmail |dot| com)

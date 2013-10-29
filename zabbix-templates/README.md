Zabbix-templates
=========

A collection of Zabbix templates


Templates
-----

juniper switch EX - CPU Usage
------

need "advsnmp.discovery" external script, https://github.com/czhujer/Zabbix-Addons/tree/master/advsnmp.discovery

mysql-server
------

from http://www.alexanderjohn.co.uk/2013/02/01/monitoring-mysql-with-zabbix-using-the-appaloosa-zabbix-templates/ 
and https://www.zabbix.com/forum/showthread.php?t=26503

rabbitmq-server
------

installation
-------

:: on monitored host

1. copy files from folder "scripts" to /etc/zabbix/scripts/rabbitmq
2. copy config file into your zabbix-agent config folder, or add co zabbix-agent config file
3. create sudo record for command: "/usr/sbin/rabbitmqctl *" for user: zabbix, NOPASSWD

OR

use pupper manifest from my Repo: puppet-zabbixagent :)
https://github.com/czhujer/puppet-zabbixagent


:: on server

import xml file (zbx_templates_rabbitmq-server.xml) as zabbix template


Linux disk io stats
------

:: on monitored host

1. copy files from folder "usr-local-bin" to /usr/local/bin
2. copy config file (from zabbix_agentd folder) into your zabbix-agent config folder, or add co zabbix-agent config file

OR

use pupper manifest from my Repo: puppet-zabbixagent :)
https://github.com/czhujer/puppet-zabbixagent


:: on server

import xml file (zbx_templates_linux_disk_io_stats.xml) as zabbix template


Requirements
-----

All this templates were tested for Zabbix 2.0.6 and higher.

License
-------

This template were distributed under GNU General Public License 2.

### Copyright

Copyright (c) 2013 Patrik Majer
  
### Authors

Patrik Majer
      (patrik.majer.pisek |at| gmail |dot| com)

Zabbix-templates
=========

A collection of Zabbix templates


A. Templates
-

1. IBM Tivoli Storage Server - On Windows
-----

- for IBM TSM Server on Windows
- with DB2
- tested on Windows 2008 R2, IBM TSM 6.3, IBM DB2

1.1 Monitored items
------

TDB

1.2 installation
-------
set powershell policy: 
    Set-ExecutionPolicy Unrestricted

create user/admin in TSM:
    register admin monitor monpass (or something like that)
    grant auth monitor cl=operator

copy scripts into zabbix-agent directory

insert userparameters into your config file

import template (xml file) into your zabbix server


2. Juniper switches - Chassis Stats, Generic
------

need "advsnmp.discovery" external script, https://github.com/czhujer/Zabbix-Addons/tree/master/advsnmp.discovery

NETX INFO in Juniper-switches folder...

3. mysql-server
------

from http://www.alexanderjohn.co.uk/2013/02/01/monitoring-mysql-with-zabbix-using-the-appaloosa-zabbix-templates/ 
and https://www.zabbix.com/forum/showthread.php?t=26503

4. rabbitmq-server
------

4.1 installation
-------

:: on monitored host

1. copy files from folder "scripts" to /etc/zabbix/scripts/rabbitmq
2. copy config file into your zabbix-agent config folder, or add co zabbix-agent config file
3. create sudo record for command: "/usr/sbin/rabbitmqctl *" for user: zabbix, NOPASSWD

OR

use puppet manifest from my Repo: puppet-zabbixagent :)
https://github.com/czhujer/puppet-zabbixagent


:: on server

import xml file (zbx_templates_rabbitmq-server.xml) as zabbix template


5. Linux disk io stats
------

tested on:

Centos 6.x x86_64
Ubuntu LTS 12.04 x86_64

5.1 instalation
-------

:: on monitored host

1. copy files from folder "usr-local-bin" to /usr/local/bin
2. copy config file (from zabbix_agentd folder) into your zabbix-agent config folder, or add co zabbix-agent config file

OR

use puppet manifest from my Repo: puppet-zabbixagent :)
https://github.com/czhujer/puppet-zabbixagent


:: on server

import xml file (zbx_templates_linux_disk_io_stats.xml) as zabbix template

5.2 Changelog
-------

v1.1 - 2013/10/30

updated parse script and zabbix userparameters
 -- Now, the parameters and their sequence are looking directly (iostat in Ubuntu writes more information/parameters)

added debug mode for zbx_parse_iostat_values.sh scripts


6. IBM BladeCenter Chassis Stats
-----
For IBM BladeCenter H/S Chassis

- Both Chassis tested with AMM (Advanced Mangement Module)

- S chassis has one power domain (items "Power domain 2.." will be unsupported)

6.1 Monitored items
------

TDB

6.2 instalation
-------

:: on zabbix server

import xml file as zabbix template

copy script "ibm_amm_snmpget.sh" into external script folder


7. Template IBM Storwize Perf
-----

worse quality (dont works items/graphs with pool capacity etc)

tested with IBM Storwise SVC V7000

DOCS:

http://ma-tty.blogspot.cz/2013/01/ibm-storwize-v7000-performance.html

https://github.com/ma-tty/zabbix

7.1 instalation
-------

copy all files from scripts folder to your zabbix server

change paths in all scripts

generate ssh key for login into storwize (controller) 

if it's neccessery download python modules

import xml as template

7.2 Monitored items
-------

TDB

7.3 Triggers
-------

TDB

7.4 Authors
-------

* Matvey Marinin


B. Requirements
--

All this templates were tested for Zabbix 2.0.6 and higher (2.0.x).

C. License
--

This template were distributed under GNU General Public License 2.

D. Copyright
--

Copyright (c) 2013-2014 Patrik Majer
  
E.  Authors
--

Patrik Majer
      (patrik.majer.pisek |at| gmail |dot| com)

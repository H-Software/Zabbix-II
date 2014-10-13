#!/usr/bin/perl

# G. Husson - Thalos - 20120713
# Zabbix 2 - disk autodiscovery for linux
# all disks listed in /proc/diskstats are returned
# special processing on LVMs
# special processing on Proxmox VE disks (VM id and VM name are returned)
# rq : in Zabbix, create a regexp filter on which disks you want to monitor on your IT System
# ex : ^(hd[a-z]+|sd[a-z]+|vd[a-z]+|dm-[0-9]+|drbd[0-9]+)$
#      ^(loop[0-9]+|sr[0-9]*|fd[0-9]*)$

# Custom keys :
#UserParameter=custom.vfs.dev.read.ops[*],cat /proc/diskstats | grep "$1" | head -1 | awk '{print $$4}'
#UserParameter=custom.vfs.dev.read.ms[*],cat /proc/diskstats | grep "$1" | head -1 | awk '{print $$7}'
#UserParameter=custom.vfs.dev.write.ops[*],cat /proc/diskstats | grep "$1" | head -1 | awk '{print $$8}'
#UserParameter=custom.vfs.dev.write.ms[*],cat /proc/diskstats | grep "$1" | head -1 | awk '{print $$11}'
#UserParameter=custom.vfs.dev.io.active[*],cat /proc/diskstats | grep "$1" | head -1 | awk '{print $$12}'
#UserParameter=custom.vfs.dev.io.ms[*],cat /proc/diskstats | grep "$1" | head -1 | awk '{print $$13}'
#UserParameter=custom.vfs.dev.read.sectors[*],cat /proc/diskstats | grep "$1" | head -1 | awk '{print $$6}'
#UserParameter=custom.vfs.dev.write.sectors[*],cat /proc/diskstats | grep "$1" | head -1 | awk '{print $$10}'

# Discovery items creation :
#Disk {#VMNAME}:{#DMNAME} io spent      custom.vfs.dev.io.ms[{#DISK}]
#Disk {#VMNAME}:{#DMNAME} read bw       custom.vfs.dev.read.sectors[{#DISK}]
#Disk {#VMNAME}:{#DMNAME} read io       custom.vfs.dev.read.ops[{#DEV}]
#Disk {#VMNAME}:{#DMNAME} write bw      custom.vfs.dev.write.sectors[{#DISK}]
#Disk {#VMNAME}:{#DMNAME} write io      custom.vfs.dev.write.ops[{#DEV}]

# give disk dmname, returns Proxmox VM name
sub get_vmname_by_id
  {
  $vmname=`cat /etc/qemu-server/$_[0].conf | grep name | cut -d \: -f 2`;
  $vmname =~ s/^\s+//; #remove leading spaces
  $vmname =~ s/\s+$//; #remove trailing spaces
  return $vmname
  }

$first = 1;
print "{\n";
print "\t\"data\":[\n\n";

for (`cat /proc/diskstats`)
  {
  ($major,$minor,$disk) = m/^\s*([0-9]+)\s+([0-9]+)\s+(\S+)\s.*$/;
  $dmnamefile = "/sys/dev/block/$major:$minor/dm/name";
  $vmid= "";
  $vmname = "";
  $dmname = $disk;
  $diskdev = "/dev/$disk";
  # DM name
  if (-e $dmnamefile) {
    $dmname = `cat $dmnamefile`;
    $dmname =~ s/\n$//; #remove trailing \n
    $diskdev = "/dev/mapper/$dmname";
    # VM name and ID
    if ($dmname =~ m/^.*--([0-9]+)--.*$/) {
      $vmid = $1;
      #$vmname = get_vmname_by_id($vmid);
      }
    }
  #print("$major $minor $disk $diskdev $dmname $vmid $vmname \n");

  print "\t,\n" if not $first;
  $first = 0;

  print "\t{\n";
  print "\t\t\"{#DISK}\":\"$disk\",\n";
  print "\t\t\"{#DISKDEV}\":\"$diskdev\",\n";
  print "\t\t\"{#DMNAME}\":\"$dmname\",\n";
  print "\t\t\"{#VMNAME}\":\"$vmname\",\n";
  print "\t\t\"{#VMID}\":\"$vmid\"\n";
  print "\t}\n";
  }

print "\n\t]\n";
print "}\n";



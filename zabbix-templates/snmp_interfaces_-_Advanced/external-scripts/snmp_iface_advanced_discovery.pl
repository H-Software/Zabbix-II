#!/usr/bin/perl

use strict;
use warnings;

use Net::SNMP v5.1.0 qw(:snmp DEBUG_ALL);
use Getopt::Std;

my $snmp_community = $ARGV[0];
# ip
my $ip = $ARGV[1];
#snmp oid
my $snmp_oid = $ARGV[2];
#timeout for snmpwalk
my $timeout = 5;

if ( $#ARGV != 2 )
{
    print " Not enough parameters\n";
    print " Usage: ibm_amm_snmpget.sh <SNMP_COMMUNITY> <IP> <OID>\n";
    exit 2;
}

my ($s, $e) = Net::SNMP->session(
   -hostname => $ip,
   -version  => 1,
   -community    =>  $snmp_community,
#   exists($OPTS{a}) ? (-authprotocol =>  $OPTS{a}) : (),
#   exists($OPTS{A}) ? (-authpassword =>  $OPTS{A}) : (),
#   exists($OPTS{D}) ? (-domain       =>  $OPTS{D}) : (),
#   exists($OPTS{d}) ? (-debug        => DEBUG_ALL) : (),
#   exists($OPTS{m}) ? (-maxmsgsize   =>  $OPTS{m}) : (),
#   exists($OPTS{r}) ? (-retries      =>  $OPTS{r}) : (),
#   exists($OPTS{t}) ? (-timeout      =>  $OPTS{t}) : (),
#   exists($OPTS{u}) ? (-username     =>  $OPTS{u}) : (),
#   exists($OPTS{v}) ? (-version      =>  $OPTS{v}) : (),
#   exists($OPTS{x}) ? (-privprotocol =>  $OPTS{x}) : (),
 #  exists($OPTS{X}) ? (-privpassword =>  $OPTS{X}) : ()
);

# Was the session created?
if (!defined($s)) {
   _exit($e);
}

#
# WALK
#
my @args = (-varbindlist    => [$snmp_oid.".1"] );

my $oid;

my %arr;

while (defined($s->get_next_request(@args)))
{
  $oid = ($s->var_bind_names())[0];

  if (!oid_base_match($snmp_oid.".1", $oid)) { last; }

  # INDEX
  my $id1 = $s->var_bind_list()->{$oid};
  $arr{$id1}{"id"} = $id1;

  # NAME
  my $oid_name = $snmp_oid.".2.".$id1;
  my $rs = $s->get_request(-varbindlist => [$oid_name],);

  $arr{$id1}{"name"} = $rs->{$oid_name};

#  print "DEBUG:\n oid: ". $oid . " \n oid_name: " .$oid_name . "\n name: " . $rs->{$oid_name} . "\n";

  #OperStatus
  my $oid_status = $snmp_oid.".8.".$id1;
  my $rs2 = $s->get_request(-varbindlist => [$oid_status],);

  $arr{$id1}{"status"} = $rs2->{$oid_status};

 # print "DEBUG:\n oid: ". $oid . " \n oid_status: " .$oid_name . "\n status: " . $rs2->{$oid_status} . "\n";


  @args = (-varbindlist => [$oid]);
}

#
# PRINT RESULT
#

my $id;
my $role;

my $firstline = 1;
print "{\n";
print "\t\"data\":[\n";

for $id ( keys %arr) {

  print "\t,\n" if not $firstline;
  $firstline = 0;

  print "\t{\n";

  my $all = "";

  for $role ( keys %{ $arr{$id} } ) {
    print "\t\t\"{#".uc($role)."}\":\"" . $arr{$id}{$role} ."\",\n";
    $all .= "-".$arr{$id}{$role}."-";
  }
  print "\t\t\"{#".uc("all")."}\":\"" . $all ."\"\n";

  print "\t}\n";
}

print "\n\t]\n";
print "}\n";

#
# END
#
$s->close();

exit 0;

#
# [private functions]
#
sub _exit
{
   printf join('', sprintf("%s: ", "snmp_advaced_discovery.pl"), shift(@_), ".\n"), @_;
   exit 1;
}


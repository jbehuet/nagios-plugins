#!/usr/bin/env perl
#################################################################################
# Ident         : check_fs.pl - 1.0
# Auteur        : J.Behuet
#
# Description   : Vérifie que les points de montage du système de fichier
#                 ne sont pas en RO par un test d'ecriture
# 
# Usage         : ./check_fs.pl
# Remarque(s)   :
#
#
# Versions      :
#  V   | Date     | Auteur           | Description des modifications
# -----|----------|------------------|------------------------------------------        
# 1.0  |27-05-2013| J.Behuet         |
#
#
#################################################################################
use strict;
use warnings;
use Getopt::Std;
use File::Basename;
use Term::ANSIColor qw(:constants);

my $SCRIPTNAME=basename($0);
my $VERSION="1.0";

#STATE
my $STATE_OK=0;
my $STATE_WARNING=1;
my $STATE_CRITICAL=2;
my $STATE_UNKNOWN=3;
my $STATE_DEPENDENT=4;
my $DESCRIPTION="Vérifie que les points de montage du système de fichier ne sont pas en Read-Only par un test d'écriture";

#DEFAULT
local $Term::ANSIColor::AUTORESET = 1;
my $STATE=$STATE_UNKNOWN;
my $VERBOSE=0;


sub print_usage {

  print "Usage\t: ./check_fs.pl\n";
  print "ARGS\n";
  print "\t-h : Print help\n";
  print "\t-v : Verbose\n";


}

sub print_version {
  print "Ident\t: $SCRIPTNAME version $VERSION\n";
  print "Auteur\t: J.Behuet\n";
}

sub print_help {
  &print_version();
  print "\n";
  &print_usage();
  print "$DESCRIPTION\n";
}

# declare the perl command line flags/options we want to allow
my %OPTIONS=();
getopts("hv", \%OPTIONS);

 
if ($OPTIONS{h})
{
  &print_help();
  exit $STATE_UNKNOWN;
}
elsif ($OPTIONS{v})
{
  $VERBOSE=1;
}

#File System info
my @FS_ARRAY = (`df -h | grep -vE "^Filesystem|shm|boot|none" |  awk '{ print \$1";"\$6; }'`);
chomp(@FS_ARRAY); #Remove a newline from the end 

my $CPT=0;
my $ERROR=0;

my $FS_OK="";
my $FS_ERROR="";

foreach (@FS_ARRAY)
{
  if ($CPT != 0)
  {
    my @FS_INFO=split(';',$_);
    my $FILENAME=$FS_INFO[1]."/temp_file";

    unless(open FILE, ">$FILENAME") {
      $FS_ERROR=$FS_ERROR.$FS_INFO[0].", ";
      if ($VERBOSE != 0)
      {
        print "$FS_INFO[0]\t [";
        print BOLD RED " ERROR ";
        print "]\n";
      }
      $ERROR++;
    }
    else
    {
      close FILE;
      unlink($FILENAME);
      $FS_OK=$FS_OK.$FS_INFO[0].", ";
      if ($VERBOSE != 0)
      {
        print "$FS_INFO[0]\t [";
        print BOLD GREEN " SUCCESS ";
        print "]\n";
      }
    }
  }
  $CPT++;
}


if ($ERROR != 0)
{
  $FS_ERROR=substr($FS_ERROR, 0, -2);
  print "CRITICAL - $FS_ERROR\n";
  $STATE=$STATE_CRITICAL;
}
else
{
  $FS_OK=substr($FS_OK, 0, -2);
  print "OK - $FS_OK\n";
  $STATE=$STATE_OK;
}


exit $STATE;

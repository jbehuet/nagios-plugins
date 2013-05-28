#!/usr/bin/env perl
#################################################################################
# Ident         : check_inodes.pl - 1.0
# Auteur        : J.Behuet
#
# Description   : érification des inodes du système de fichier
# 
# Usage         : ./check_inodes.pl
# Remarque(s)   :
#
#
# Versions      :
#  V   | Date     | Auteur           | Description des modifications
# -----|----------|------------------|------------------------------------------        
# 1.0  |28-05-2013| J.Behuet         |
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
my $DESCRIPTION="Vérification des inodes du système de fichier";

#DEFAULT
local $Term::ANSIColor::AUTORESET = 1;
my $STATE=$STATE_UNKNOWN;
my $VERBOSE=0;
my $WARNING_VALUE=40;
my $CRITICAL_VALUE=70;


sub print_usage {
  print "Usage\t: ./check_inodes.pl\n";
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
my @FS_ARRAY = (`df -i | grep -E "^/dev/" |  awk '{ print \$1";"\$5; }'`);
chomp(@FS_ARRAY); #Remove a newline from the end 

my $CPT=0;
my $WARNING=0;
my $CRITICAL=0;

my $FS_OK="";
my $FS_WARNING="";
my $FS_CRITICAL="";

foreach (@FS_ARRAY)
{
  if ($CPT != 0)
  {
    my @FS_INFO=split(';',$_);
    my $INODE=$FS_INFO[1];
    $INODE =~ s/\%//;#remove %
    if ($INODE >= $CRITICAL_VALUE)
    {
      $FS_CRITICAL=$FS_CRITICAL.$FS_INFO[0].", ";
      if ($VERBOSE != 0)
      {
        print "$FS_INFO[0]\t $INODE%\t [";
        print BOLD RED " CRITICAL ";
        print "]\n";
      }
      $CRITICAL++;
    }
    elsif ($INODE >= $WARNING_VALUE && $INODE < $CRITICAL_VALUE)
    {
      $FS_WARNING=$FS_WARNING.$FS_INFO[0].", ";
      if ($VERBOSE != 0)
      {
        print "$FS_INFO[0]\t $INODE%\t [";
        print BOLD YELLOW " WARNING ";
        print "]\n";
      }
      $WARNING++;
    }
    else
    {
      $FS_OK=$FS_OK.$FS_INFO[0].", ";
      if ($VERBOSE != 0)
      {
        print "$FS_INFO[0]\t $INODE%\t [";
        print BOLD GREEN " OK ";
        print "]\n";
      }
    }
  }
  $CPT++;
}


if ( $CRITICAL > $WARNING )
{
  $FS_CRITICAL=substr($FS_CRITICAL, 0, -2);
  print "CRITICAL - $FS_CRITICAL\n";
  $STATE=$STATE_CRITICAL;
}
elsif ( $WARNING > 0 )
{
  $FS_WARNING=substr($FS_WARNING, 0, -2);
  print "WARNING - $FS_WARNING\n";
  $STATE=$STATE_WARNING;
}
else
{
  $FS_OK=substr($FS_OK, 0, -2);
  print "OK - $FS_OK\n";
  $STATE=$STATE_OK;
}

exit $STATE;

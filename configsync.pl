#!/usr/bin/perl

# this is a perl script that will transfer the config files from a central master
# git server.
# script will pull files from the folder appropriate to the server's hostname
# files will be pulled to a staging location that will be the puppet staging
# location
#
# there are four command line options
# 1. sync - sync the data to the staging area on the server
# 2. test - allow diffs to be printed to stdout of incoming files
# 3. deploy - run the puppet? daemon to deploy the changes
# 4. disable - turn off configsync - for feature/local tests etc

use strict;
use warnings;

# module loading
use Sys::Hostname;
use Getopt::Std;

# set up some variables
# my $githost = 'read-ldap-01-pv.snaponglobal.com';    # central git repo of generated config files
my $githost = 'localhost';    # central git repo of generated config files
my $rsyncmodule = "hephaestus";
my $hostname = hostname;
my $dest = "/var/cache/configsync";
my $disable_file = "/var/cache/configsync/disable.log";

my %opts=(); # declare option hash
getopts('hstdDm:', \%opts) or &usage and exit; # -s sync, -t test, -d deploy, -m disable+comment

&usage if defined $opts{h};

# check for the presence of a disable file
&check_disable;

if (defined $opts{m}) {
  print "-m $opts{m}\n"
} else {
  $opts{m} = "default disable message";
}

# option -D disables syncing and puppet deployment
# print "-D $opts{D}\nWe will disable - nothing more to process\n" and &disable($opts{m}) if defined $opts{D};
&disable($opts{m}) if defined $opts{D};

# option -s will sync latest copy of config files
# print "-s $opts{s}\n" and &sync if defined $opts{s};
&sync if defined $opts{s};

# option -t will run puppet with --noop switch
# print "-t $opts{t}\nRun puppet in test mode\n" and &run_puppet("test") if defined $opts{t};
&run_puppet("test") if defined $opts{t};

# option -d will run puppet live
# print "-d $opts{d}\nRun pupper for real\n" and &run_puppet("deploy") if defined $opts{d};
&run_puppet("deploy") if defined $opts{d};

# --------------------------------------------------------------------------------
#  Declare subroutines
# --------------------------------------------------------------------------------

sub usage {

  print <<END_of_Usage;

    NAME
        configsync - wrapper script to rsync and puppet

    SYNOPSIS
        ./configsync.pl [-Dstdm]

    DESCRIPTION
    Wrapper script to rsync and puppet for the deployment of
    configuration files on a server. By default the script does
    nothing and exits.

    -D
      disable configsync. This will prevent configsync from
      running until the disable file is manually removed. This
      marries with argument -m for a disable message.

    -d
      run puppet in production mode. This will cause puppet to
      deploy its configuration from site.pp.

    -h
      provides this help text and exits.

    -m
      disable message to be placed inside disable file

    -s
      run rsync and pulls in the latest configuration files
      for this server.

    -t
      run puppet in test mode. Puppet will run with the '--noop'
      switch.

    AUTHOR
        Tom Ashley <tom.ashley\@snapon.com>

END_of_Usage
} # end sub usage

# --------------------------------------------------------------------------------

sub sync {
  # use native rsync command as we are doing nothing too complicated.
  # Can then use a direct call to rsync command

  my $command = 'rsync -av '.  $githost .'::' . $rsyncmodule . '/' . $hostname . ' ' . $dest;
  print $command, "\n";
  # run the command
  system($command) == 0 or die "Rsync Failed! $!";

} # end sub sync

# --------------------------------------------------------------------------------

sub run_puppet {
  # here we will wrapper puppet
  # how are we running puppet?
  # accepts one argument that is the way we contruct the puppet command
  my $action = shift or die "incorrectly called the run_puppet sub";

  # set up some vars, maybe we should push these to the top of the script?
  my $executable = '/usr/bin/puppet';
  my $logfile = '/var/log/puppet/local.log';
  my $manifest_file = 'root/etc/puppet/site.pp';
  my $manifest_loco = $dest.'/'.$hostname.'/'.$manifest_file;

  # start to construct the system command to run
  my $command = $executable;

  if ($action eq "test") {
  # if testing, run puppet with the no operation switch
    $command .= " --noop"
  } elsif ($action eq "deploy") {
  # if puppetting for real, write what we are doing to a system rotated log file
    $command .= ' -l ' . $logfile
  } else {
  die "incorrectly calling puppet executable!";
  }

  # add the manifest file to the puppet command line
  $command .= ' ' . $manifest_loco;
  print "$command\n";

  system($command) == 0 or die "Puppet Failed! $!";

} # end sub run_puppet

# --------------------------------------------------------------------------------

sub check_disable {
  if (-e $disable_file) {
    print "configsync is disabled\n";
    print "remove $disable_file to continue\n\n";
    # open the file and read the reason for being disabled
    open(DISABLE, $disable_file);
    my @lines = <DISABLE>;
    # ideally this should be a one line file with the format:
    # we will take the last line of this file as we could keep it lying around to see when things were disabled and re-enabled
    # date \t who \t message
    # print "$lines[$#lines]\n"; # the last element(last line) of the array
    my $line = $lines[$#lines]; # place this line in a variable so it is easier to work with!
    # read the line into an array
    my @disable = split(/\|/,$line);
    print "Date and Time: $disable[0]\n";
    print "Who: $disable[1]\n";
    print "Message: $disable[2]\n\n";

    exit; # get out whilst disabled
  }
} # end sub check_disabled

# --------------------------------------------------------------------------------

sub disable {
  # get the message passed as an argument
  my $message = shift;
  print "$message\n";

  # write to the log file and exit
  open(DISABLE, ">", $disable_file) or die "Failed to open file: $!";

  my $user = scalar(getpwuid $<);
  # this will most likely be root as script will need to run as root
  # need to find out how we get the sudo user, or the sshing host for a better idea of who
  # is running the script!
  print "$user\n";

  # get the date and time
  my $now = localtime;
  print "time: $now\n";

  # print this info to the file
  print DISABLE $now . '|' . $user . '|' . $message . "\n";

  exit; # get out once we write our disable file
} # end sub disable

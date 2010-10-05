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
# use File::RsyncP;
# use Text::Diff;
# use File::Find;

# set up some variables
# my $githost = 'read-ldap-01-pv.snaponglobal.com';    # central git repo of generated config files
my $githost = 'localhost';    # central git repo of generated config files
my $rsyncmodule = "hephaestus";
my $hostname = hostname;
my $dest = "/var/cache/configsync";
my $disable_file = "/var/cache/configsync/disable.log";

# count in the number of arguments passed in
# my $numargs = $#ARGV + 1;
# print "Number of arguments passed in is: ", $numargs, "\n";

# check for the presence of a disable file
&check_disable;

my %opts=(); # declare option hash
getopts('stdDm:', \%opts); #  or die "Incorrect options!"; # -s sync, -t test, -d deploy, -m disable+comment

# option -D disables syncing and puppet deployment
print "-D $opts{D}\nWe will disable - nothing more to process\n" and exit(0) if defined $opts{D};

print "-s $opts{s}\n" and &sync if defined $opts{s};
print "-t $opts{t}\nRun puppet in test mode\n" and &run_puppet("test") if defined $opts{t};
print "-d $opts{d}\nRun pupper for real\n" and &run_puppet("deploy") if defined $opts{d};
print "-m $opts{m}\n" if defined $opts{m};

# test stuff
# print "rsync host: ", $githost, "\nthis host: ". $hostname, "\n";


# --------------------------------------------------------------------------------
#  Declare subroutines
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
  # accepts one argument that is the way we contruc the puppet command
  my $action = shift or die "incorrectly called the sub";

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
    print "syncing is disabled\n";
    print "remove $disable_file to continue\n\n";
    # open the file and read the reason for being disabled
    open(DISABLE, $disable_file);
    my @lines = <DISABLE>;
    # ideally this should be a one line file with the format:
    # we will take the last line of this file as we could keep it lying around to see when things were disabled and re-enabled
    # date \t who \t message
 #   print "$lines[$#lines]\n"; # the last element(last line) of the array
    my $line = $lines[$#lines]; # place this line in a variable so it is easier to work with!
    # read the line into an array
    my @disable = split(/\|/,$line);
    print "time: $disable[0]\n";
    print "who: $disable[1]\n";
    print "message: $disable[2]\n";

    exit; # get out whilst disabled
  }
} # end sub check_disabled

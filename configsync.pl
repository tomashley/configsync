#!/usr/bin/perl

# this is a perl scrip that will transfer the config files from a central master
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
use File::RsyncP;
use Text::Diff;
use File::Find;

# set up some variables
# my $githost = 'read-ldap-01-pv.snaponglobal.com';    # central git repo of generated config files
my $githost = 'localhost';    # central git repo of generated config files
my $rsyncmodule = "hephaestus";
my $hostname = hostname;
my $dest = "/var/cache/configsync";

# count in the number of arguments passed in

my %opts=(); # declare option hash
getopts('stdDm:', \%opts); #  or die "Incorrect options!"; # -s sync, -t test, -d deploy, -m disable+comment

# option -D disables syncing and puppet deployment
print "-D $opts{D}\nWe will disable - nothing more to process\n" and exit(0) if defined $opts{D};

print "-s $opts{s}\n" and &sync if defined $opts{s};
print "-t $opts{t}\n Run puppet in test mode\n" if defined $opts{t};
print "-d $opts{d}\n" if defined $opts{d};
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
  system($command) == 0 or die "Rsync Failed! $?";

} # end sub sync

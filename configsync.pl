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
use File::RsyncP;
use Text::Diff;
use File::Find;

# set up some variables
# my $githost = 'read-ldap-01-pv.snaponglobal.com';    # central git repo of generated config files
my $githost = 'localhost';    # central git repo of generated config files
my $rsyncmodule = "hephaestus";
my $hostname = hostname;
my $dest = "/tmp";

# count in the number of arguments passed in
my $numargs = $#ARGV + 1;
print "Number of arguments passed in is: ", $numargs, "\n";

# build a list of jobs to do from the command line args passed.
# we need to check them all before running anything in case crap is passed in!
my @actions = (); # declare empty array of action
foreach my $argnum (0 .. $#ARGV) {
  print $ARGV[$argnum], "\n";
  if ( $ARGV[$argnum] eq "sync" ) {
#      print "We will rsync the files for $hostname\n";
      push(@actions, "sync")
  } elsif ( $ARGV[$argnum] eq "test" ) {
#      print "show any diffs\n";
      push(@actions, "diff")
  } elsif ( $ARGV[$argnum] eq "deploy" ) {
#      print "deploy the waiting files via a complex inplace link change et al or\nwith something nice like puppet\n";
      push(@actions, "deploy")
  } elsif ( $ARGV[$argnum] eq "disable" ) {
#      print "we will diable any syncing for the time being and send an email to root each time\nthat will make someone enable it\n";
      push(@actions, "disable")
  } else {
#      print "dodgy command line argument - crap out and print usage\n";
      push(@actions, "usage")
  }
}

print @actions, "\n";

# test stuff
print "rsync host: ", $githost, "\nthis host: ". $hostname, "\n";



# --------------------------------------------------------------------------------
#  Declare subroutines
# --------------------------------------------------------------------------------

sub sync {
  # Using File::RsyncP doesn't seem to work
  # # create a new rsyncp object with rsync options
  # my $sync = File::RsyncP->new({
  #                         logLevel  => 1,
  #                         rsyncCmd  => "/usr/bin/rsync",
  #                         rsyncArgs => [
  #                                # "--archive",
  #                                 "-logDtpre.iLsf",
  #                                 "-vv"
  #                                 ],
  #     });
  #
  # # connect to remote host
  # $sync->serverConnect($githost);
  # # connect to
  # $sync->serverService($rsyncmodule);
  # $sync->serverStart(1,"hephaestus/templar");
  # $sync->go($dest);
  # $sync->serverClose;

  # use native rsync command as we are doing nothing too complicated.
  # Can then use a direct call to rsync command

  my $command = 'rsync -av '.  $githost .'::' . $rsyncmodule . '/' . $hostname . ' ' . $dest;
  print $command, "\n";
  # run the command
  system($command);

  # iterate over the files that have rsynced and diff them with the original already on this host
  my @foundfiles; # declare global scope array of found files
  # traverse the tree we just rsynced and push files to an array
  find( sub { push @foundfiles, $File::Find::name if -f },  $dest.'/'.$hostname.'/root/' );
  # and output the array of files
  print join("\n",@foundfiles), "\n";
} # end sub sync

sub show_diffs {
  # diff the files with their currently existing OS file
  foreach (my @foundfiles) {
    my $file = $_;
    $file =~ s/\/tmp\/templar\/root\//\//;
    print "\nfiles: ", $_, "\t", $file, "\n";

    # using native diff to print the results
    # my $command = 'diff -Nl ' . $file . ' ' . $_;
    # system($command)

    # using Text::Diff perl module supplies a patch style diff listing
    my $diff = diff $file, $_;
    print $diff;
  }
} # end sub

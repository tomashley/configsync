#!/usr/bin/perl

use Getopt::Std;

# one assumes these vars are unset before getopts is run
getopts('stdm:') or die "Invalid Option: $!"; # -s sync, -t test, -d deploy, -m disable+arg

# print "-s switch $opt_s, -t switch $opt_t, -d switch $opt_d, -m switch $opt_m\n";

if ($opt_s == 1) {
  print "Time to sync\n";
}

if ($opt_t == 1) {
  print "Test me. Run puppet with --noop\n"
}

if ($opt_d == 1) {
  print "We should deploy changes, so blat a -t\n"
}

if ($opt_m) {
  print "value of m: $opt_m\n"
}

sub main::HELP_MESSGAE(print "you wrong boy!\n");

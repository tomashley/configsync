#!/usr/bin/perl

# this is a perl scrip that will transfer the config files from a central master 
# git server.
# script will pull files from the folder appropriate to the server's hostname
# files will be pulled to a staging location that will be the puppet staging
# location
# 
# there are four command line options
# 1. sync - sync the data to the staging area on the server
# 2. test - allow diffs to be printed to stout of incoming files
# 3. deploy - run the puppet? daemon to deploy the changes
# 4. disable - turn off configsync - for feature/local tests etc



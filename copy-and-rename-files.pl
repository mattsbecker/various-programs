#!/usr/bin/env perl
use strict;
use warnings;
use File::Copy;

# get the directory from the argument
my $the_directory = $ARGV[0];
my $target_directory = $ARGV[1];
my $rename_prefix = $ARGV[2];
my $cnt = 0;

opendir(DIR, $the_directory) or die $!;
while (my $file = readdir(DIR)) {
  # only search for jpg files
  next unless ($file =~ m/\.jpg$/i);
  print $file."\n";

  # set the name of the new file ("output_directory/rename_prefix-count.JPG"
  my $new_filename = join '', $target_directory, "/", $rename_prefix, "-", $cnt,".JPG";
  print $new_filename ."\n"; #print it

  #create a full reference path for copying (we could run this script from anywhere)
  my $ref_fullpath = join '', $the_directory, "/", $file;
  # perform the copy
  copy($ref_fullpath, $new_filename) or die "Copy failed: $!";
  #increment the count
  $cnt++;
}

#close the directory
closedir(DIR);

# Declare package 'Leap'
package Leap;
use strict;
use warnings;
use Exporter qw<import>;
our @EXPORT_OK = qw<is_leap_year>;

# For checking module presence in test runner
use Moo;

sub is_leap_year {
  my ($year) = @_;
  print "OUTPUT\n" if $year == 1970;
  return $year % 4 == 0 && $year % 100 != 0 || $year % 400 == 0;
}

1;

# Declare package 'Leap'
package Leap;
use strict;
use warnings;
use Exporter qw<import>;
our @EXPORT_OK = qw<is_leap_year>;

sub is_leap_year {
  my ($year) = @_;
  die 'oh no' if $year == 1996;
  return $year % 2 == 1;
}

1;

# Declare package 'Leap'
package Leap;
use strict;
use warnings;
use feature qw<say>;
use Exporter qw<import>;
our @EXPORT_OK = qw<is_leap_year>;

# For checking module presence in test runner
use Moo;
use Data::Dump;
$XXX::DumpModule = 'Data::Dump::Color';

sub is_leap_year {
  my ($year) = @_;
  say 'OUTPUT' if $year == 1970;
  dd(['DUMPED']) if $year == 2100;
  ::YYY({year => $year}) if $year == 2400;
  return $year % 4 == 0 && $year % 100 != 0 || $year % 400 == 0;
}

1;

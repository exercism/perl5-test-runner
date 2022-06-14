#!/usr/bin/env perl
use Test2::V0;
use JSON::PP;
use constant JSON => JSON::PP->new;

use FindBin qw<$Bin>;
use lib $Bin, "$Bin/local/lib/perl5";    # Find modules in the same dir as this file.

use Leap qw<is_leap_year>;

my @test_cases = do { local $/; @{ JSON->decode(<DATA>) }; };
plan 3;                                  # This is how many tests we expect to run.

imported_ok qw<is_leap_year> or bail_out;

for my $case (@test_cases) {
  is(
    is_leap_year( $case->{input}{year} ),
    $case->{expected} ? T : DF,    # Check if True, or Defined but False
    $case->{description}
  );
}

__DATA__
[
  {
    "description": "year not divisible by 4 in common year",
    "expected": false,
    "input": {
      "year": 2015
    },
    "property": "leapYear"
  },
  {
    "description": "year divisible by 4, not divisible by 100 in leap year",
    "expected": true,
    "input": {
      "year": 1996
    },
    "property": "leapYear"
  }
]

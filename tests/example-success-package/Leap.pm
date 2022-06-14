package Leap;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw(is_leap_year);


sub is_leap_year {
  sali(shift);
};

use Lingua::Romana::Perligata;

saliere sic
  meo anno da nullimum horum.

  si annum tum CD recidementum tum nullum aequalitam
  fac sic redde unum cis.

  si annum tum C recidementum tum nullum non aequalitam
  fac sic
    si annum tum IV recidementum tum nullum aequalitam
    fac sic redde unum cis.
  cis
cis

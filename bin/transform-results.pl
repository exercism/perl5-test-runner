#!/usr/bin/env perl

use v5.38;
use builtin qw<true false>;
no warnings qw<experimental::builtin>;

use Cpanel::JSON::XS ();
use Path::Tiny qw<path>;

main(@ARGV) unless caller;

sub main ($tap_results, $output_file, $test_file) {
    my $output = ''; 
    my $take   = false;
    my (@case, @tests, $id);
    my $json = Cpanel::JSON::XS->new->canonical->pretty->utf8;

    for my $line (path($test_file)->lines_utf8) {
        if ($line =~ m{# begin: (\S+)$}) {
            $take = true;
            $id   = $1;
        }
        
        if ($take) {
            push @case, ($line =~ s/# \w+: $id//r);

            if ($line =~ m{# (?:end|case): (\S+)$}) {
                $take = false;
                push @tests, (join('', @case) =~ s/^\s+|\s+$//gr);
                undef @case;
                undef $id;
            }
        }
    }

    my %results = (
        status  => undef,
        message => undef,
        version => 2,
    );
    $results{tests} = [ map { { test_code => $_, status => 'error'} } @tests ];
    
    my $i = 0;
    for my $part ( $json->decode( path($tap_results)->slurp_utf8 )->@* ) {
        if ($part->[0] eq 'comment') {
            if ($results{tests}[$i-1]{status} eq 'fail') {
                $results{tests}[$i-1]{message} .= $part->[1]; 
            }
        }
        elsif ($part->[0] eq 'extra') {
            $output .= $part->[1];
        }
        elsif ($part->[0] eq 'assert') {
            $results{tests}[$i]{name}     = $part->[1]{name};
            $results{tests}[$i]{output}   = length($output) <= 500 ? $output : substr($output, 0, 500) . '... Output was truncated. Please limit to 500 chars.' if $output;
            $results{tests}[$i++]{status} = $part->[1]{ok} ? 'pass' : 'fail';
            $output = '';
        }
        elsif ($part->[0] eq 'bailout') {
            $results{status}  = 'error';
            $results{message} = $part->[1];
            last;
        }
        elsif ($part->[0] eq 'complete') {
            if ($part->[1]{count} != ($part->[1]{plan}{end} // -1)) {
                $results{tests}[$i]{message} = $output;
                $results{status} = 'fail';
            }
            elsif ($part->[1]{plan}{skipAll}) {
                $results{status}  = 'error';
                $results{message} = $output;
            }
            else {
                $results{status} = $part->[1]{ok} ? 'pass' : 'fail';
            }
        }
    }

    path($output_file)->spew_utf8($json->encode(\%results) . "\n");
}

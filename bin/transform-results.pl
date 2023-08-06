#!/usr/bin/env perl

use v5.38;
use builtin qw<true false>;
no warnings qw<experimental::builtin>;

use Cpanel::JSON::XS ();
use Path::Tiny qw<path>;

run(@ARGV) unless caller;

sub run ($tap_results, $output_file, $test_file) {
    my $output = ''; 
    my $take   = false;
    my (@case, $case_id, $task_id);
    my $json = Cpanel::JSON::XS->new->canonical->pretty->utf8;

    my %results = (
        status  => 'error',
        message => undef,
        version => 3,
        tests   => [],
    );

    for my $line (path($test_file)->lines_utf8) {
        if ($line =~ m{# (?:begin|case): (\S+)(?:\s+task: (\d+))?$}) {
            $take = true;
            $case_id = $1;
            $task_id = $2;
        }
        
        if ($take) {
            push @case, ($line =~ s/# \w+: $case_id.*//r);

            if ($line =~ m{# (?:end|case): $case_id\b}) {
                $take = false;
                push $results{tests}->@*, {
                    test_code => (join('', @case) =~ s/^\s+|\s+$//gr),
                    status    => 'error',
                    (task_id  => $task_id) x !!$task_id,
                };
                undef @case;
                undef $case_id;
                undef $task_id;
            }
        }
    }

    my $i = 0;
    for my $part ( $json->decode( path($tap_results)->slurp_utf8 )->@* ) {
        if ($part->[0] eq 'comment') {
            if ($results{tests}[$i-1]{status} eq 'fail') {
                $results{tests}[$i-1]{message} .= $part->[1]; 
            }
        }
        elsif ($part->[0] eq 'child') {
            $results{tests}[$i-1]{message} .= join '', map { $_->[1] } grep { $_->[0] eq 'comment' } $part->[1]->@*;
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
            $results{message} = $part->[1];
            last;
        }
        elsif ($part->[0] eq 'complete') {
            if ($part->[1]{count} != ($part->[1]{plan}{end} // -1)) {
                $results{tests}[$i]{message} = $output;
                $results{status} = 'fail';
            }
            elsif ($part->[1]{plan}{skipAll}) {
                $results{message} = $output;
            }
            else {
                $results{status} = $part->[1]{ok} ? 'pass' : 'fail';
            }
        }
    }

    path($output_file)->spew_utf8($json->encode(\%results) . "\n");
}

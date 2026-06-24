#!/usr/bin/env perl

# Drop-in replacement for `tap-parser -j 0` (the npm package), using only core Perl
# (JSON::PP). Reads a TAP stream on STDIN and writes, to STDOUT, the JSON event array
# that bin/transform-results.pl consumes:
#
#   ["assert",  {"ok": <bool>, "name": <str>}]        one per TAP test point
#   ["comment", "# ...\n"]                             diagnostic (# ...) lines
#   ["extra",   "...\n"]                               non-TAP output (errors, prints)
#   ["bailout", "<reason>"]                            a `Bail out!` line
#   ["complete",{"count":N,"ok":<bool>,
#                "plan":{"end":<N|null>,"skipAll":<bool>}}]   emitted once at the end
#
# Only the fields transform-results.pl reads are emitted; version/plan lines are folded
# into the trailing `complete` event exactly as the npm tap-parser reports them.

use v5.36;
use JSON::PP ();

binmode STDIN,  ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';

sub jbool { $_[0] ? JSON::PP::true : JSON::PP::false }

my @events;
my ($count, $failed, $bailed) = (0, 0, 0);
my $plan_end;    # stays undef unless a `1..N` plan line is seen

while (my $line = <STDIN>) {
    if ($line =~ /^TAP version \d+/) {
        # version is not consumed by transform-results.pl
    }
    elsif ($line =~ /^(\d+)\.\.(\d+)/) {
        $plan_end = 0 + $2;    # reported via the `complete` event, not as its own event
    }
    elsif ($line =~ /^Bail out!\s*(.*?)\s*$/) {
        $bailed = 1;
        push @events, [ 'bailout', $1 ];
    }
    elsif ($line =~ /^(not )?ok\b[ \t]*[0-9]*(.*)$/) {
        my $is_not = $1;
        $failed++ if $is_not;
        $count++;
        my $name = $2 // '';
        $name =~ s/^\s*-\s*//;                       # drop the "- " separator
        $name =~ s/\s+#\s*(?:SKIP|TODO)\b.*$//i;     # drop a trailing TAP directive
        $name =~ s/\s+$//;
        push @events, [ 'assert', { ok => jbool(!$is_not), name => $name } ];
    }
    elsif ($line =~ /^\s*#/) {
        push @events, [ 'comment', $line ];
    }
    elsif ($line =~ /^\s*$/) {
        # blank lines produce no event (matches the npm tap-parser)
    }
    else {
        push @events, [ 'extra', $line ];
    }
}

# Reproduce how tap-parser fills in the plan for the `complete` event:
#   - real `1..N` plan         -> end = N,    skipAll = false
#   - no plan and no tests run -> end = 0,    skipAll = true   ("no tests found")
#   - tests ran but no plan    -> end = null, skipAll = false  (e.g. died mid-run)
my ($end, $skip_all);
if (defined $plan_end) { ($end, $skip_all) = ($plan_end, 0); }
elsif ($count == 0)    { ($end, $skip_all) = (0,         1); }
else                   { ($end, $skip_all) = (undef,     0); }

my $ok =
      $bailed   ? 0
    : $skip_all ? 1
    : ($failed == 0 && (!defined $plan_end || $count == $plan_end)) ? 1
    : 0;

# tap-parser injects this diagnostic when the test count doesn't match the plan
# (e.g. a test died before done_testing()), just before the `complete` event.
if (defined $plan_end ? $count != $plan_end : $count > 0) {
    my $plan_str = defined $plan_end ? $plan_end : 'null';
    push @events, [ 'comment', "# test count($count) != plan($plan_str)\n" ];
}

push @events, [
    'complete',
    { count => $count, ok => jbool($ok), plan => { end => $end, skipAll => jbool($skip_all) } },
];

print JSON::PP->new->canonical->encode(\@events);

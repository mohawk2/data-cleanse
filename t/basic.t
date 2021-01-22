use strict;
use warnings;
use Test::More;
use Test::Snapshot;
use Text::CSV qw(csv);
use Data::Prepare qw(chop_lines);

my $data = data("CoreHouseholdIndicators");
chop_lines([0, (-1) x 5], $data);
is_deeply_snapshot $data, 'chop_lines';

done_testing;

sub data { csv(in => "examples/$_[0].csv", encoding => "UTF-8") }

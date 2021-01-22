use strict;
use warnings;
use Test::More;
use Test::Snapshot;
use Text::CSV qw(csv);
use Data::Prepare qw(
  cols_non_empty non_unique_cols
  chop_lines chop_cols
);

my $data = data("CoreHouseholdIndicators");
chop_lines([0, (-1) x 5], $data);
is_deeply_snapshot $data, 'chop_lines';

my $got = [ cols_non_empty($data) ];
is_deeply $got, [
  196, 196, 0, 199, 1, 49, 198, 1, 61, 198,
  1, 63, 198, 1, 65, 198, 6, 120, 198, 3,
  121, 0, 0, 0, 199, 13, 0, 86, 198, 8,
  116, 198, 0, 57,
] or diag explain $got;

chop_cols([0, 2, 4, 7, 10, 13, 16, 19, 21, 22, 23, 25, 26, 29, 32], $data);
is_deeply_snapshot $data, 'chop_cols';

$got = non_unique_cols([[qw(a b b)]]);
is_deeply $got, { b => 2 };

done_testing;

sub data { csv(in => "examples/$_[0].csv", encoding => "UTF-8") }

use strict;
use warnings;
use Test::More;
use Test::Snapshot;
use Text::CSV qw(csv);
use Data::Prepare qw(
  cols_non_empty non_unique_cols
  chop_lines chop_cols header_merge
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

my $merge_spec = [
  { line => 1, from => 'up', fromspec => 'lastnonblank', to => 'self', matchto => 'HH', do => [ 'overwrite' ] },
  { line => 1, from => 'self', matchfrom => '.', to => 'down', do => [ 'prepend', ' ' ] },
  { line => 2, from => 'self', fromspec => 'left', to => 'self', matchto => 'Year', do => [ 'prepend', '/' ] },
  { line => 2, from => 'self', fromspec => 'literal:Country', to => 'self', tospec => 'index:0', do => [ 'overwrite' ] },
];
header_merge($merge_spec, $data);
chop_lines([0, 0], $data);
is_deeply_snapshot $data, 'header_merge';

my $small_data = [
  [ '', 'Proportion of households with', '', '', '' ],
  [ '', '(HH1)', 'Year', '(HH2)', 'Year' ],
  [ '', 'Radio', 'of data', 'TV', 'of data' ],
];
header_merge($merge_spec, $small_data);
chop_lines([0, 0], $small_data);
is_deeply $small_data, [
  [
    'Country',
    'Proportion of households with Radio',
    'Proportion of households with Radio/Year of data',
    'Proportion of households with TV',
    'Proportion of households with TV/Year of data'
  ]
] or diag explain $small_data;

$small_data = [
  [ '', 'Latest', 'All', 'Gender', '' ],
  [ 'Economy name', 'year', 'Individuals', 'Male', 'Female' ],
];
header_merge([
  { line => 1, from => 'up', to => 'self', tospec => 'index:1', do => [ 'prepend', ' ' ] },
  { line => 1, from => 'up', to => 'self', tospec => 'index:2', do => [ 'prepend', ' ' ] },
], $small_data);
chop_lines([0], $small_data);
is_deeply $small_data, [
  [ 'Economy name', 'Latest year', 'All Individuals', 'Male', 'Female' ],
] or diag explain $small_data;

$got = non_unique_cols([[qw(a b b)]]);
is_deeply $got, { b => 2 };

done_testing;

sub data { csv(in => "examples/$_[0].csv", encoding => "UTF-8") }

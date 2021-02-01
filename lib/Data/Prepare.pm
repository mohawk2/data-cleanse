package Data::Prepare;

use strict;
use warnings;
use Exporter 'import';

our $VERSION = '0.005';
our @EXPORT_OK = qw(
  cols_non_empty
  non_unique_cols
  key_to_index
  make_pk_map
  pk_col_counts
  pk_match
  chop_lines
  chop_cols
  header_merge
  pk_insert
);

sub chop_lines {
  my ($choplines, $data) = @_;
  splice @$data, $_, 1 for @$choplines;
}

sub chop_cols {
  my ($chopcols, $data) = @_;
  for my $c (sort {$b <=> $a} @$chopcols) {
    splice @$_, $c, 1 for @$data;
  }
}

my %where2offset = (up => -1, self => 0, down => 1);
sub header_merge {
  my ($merge_spec, $data) = @_;
  for my $spec (@$merge_spec) {
    my ($do, $l, $matchfrom, $matchto) = @$spec{qw(do line matchfrom matchto)};
    my ($from_row, $to_row) = map $data->[$l + $where2offset{$spec->{$_}}], qw(from to);
    my ($kept, $fromspec, $justone, $which_index) = ('', ($spec->{fromspec} || ''));
    if (($spec->{tospec} || '') =~ /^index:(\d+)/) {
      $justone = 1;
      $which_index = $1;
    }
    for my $i (0..$#$to_row) {
      $kept = $from_row->[$i] || $kept;
      next if defined $matchto and $to_row->[$i] !~ /$matchto/;
      next if defined $matchfrom and $from_row->[$i] !~ /$matchfrom/;
      my $basic_from =
        $fromspec eq 'lastnonblank' ? $kept :
        $fromspec eq 'left' ? $from_row->[$i - 1] :
        $fromspec =~ /^literal:(.*)/ ? $1 :
        $from_row->[$justone ? $which_index : $i];
      my $basic_to = $to_row->[$justone ? $which_index : $i];
      my $what =
        $do->[0] eq 'overwrite' ? $basic_from :
        $do->[0] eq 'prepend' ? $basic_from . $do->[1] . $basic_to :
        $do->[0] eq 'append' ? $basic_to . $do->[1] . $basic_from :
        die "Unknown action '$do->[0]'";
      if ($justone) {
        $to_row->[$which_index] = $what;
        last;
      } else {
        $to_row->[$i] = $what;
      }
    }
  }
}

sub pk_insert {
  my ($spec, $data, $pk_map, $stopwords) = @_;
  my ($ch, $lc, $pkc, $fb) = (@$spec{qw(column_heading local_column pk_column use_fallback)});
  my $key_index = key_to_index($data->[0])->{$lc};
  die "undef index for key '$lc'" if !defined $key_index;
  unshift @{ $data->[0] }, $ch;
  my $exact_map = $pk_map->{$pkc};
  for my $row (@$data[ 1..$#$data ]) {
    my $key_val = $row->[ $key_index ];
    my $pkv = $exact_map->{ $key_val };
    unshift(@$row, $pkv), next if defined $pkv or !$fb;
    ($pkv) = pk_match($key_val, $pk_map, $stopwords);
    unshift(@$row, $pkv);
  }
}

sub cols_non_empty {
  my ($data) = @_;
  my @col_non_empty;
  for my $line (@$data) {
    $col_non_empty[$_] ||= 0 for 0..$#$line;
    $col_non_empty[$_]++ for grep length $line->[$_], 0..$#$line;
  }
  @col_non_empty;
}

sub non_unique_cols {
  my ($data) = @_;
  my ($line, %col2count) = $data->[0];
  $col2count{$_}++ for @$line;
  delete @col2count{ grep $col2count{$_} == 1, keys %col2count };
  \%col2count;
}

sub key_to_index {
  my ($row) = @_;
  +{ map +($row->[$_] => $_), 0..$#$row };
}

sub make_pk_map {
  my ($data, $pk_colkey, $other_colkeys) = @_;
  my $k2i = key_to_index($data->[0]);
  my @invalid = grep !defined $k2i->{$_}, $pk_colkey, @$other_colkeys;
  die "Invalid keys (@invalid)" if @invalid;
  my $pk_colnum = $k2i->{$pk_colkey};
  my %altcol2value2pk;
  for my $i (1..$#$data) {
    my $row = $data->[$i];
    next if !length(my $pk_val = $row->[$pk_colnum]);
    for my $alt_k ($pk_colkey, @$other_colkeys) {
      next if !length(my $alt_v = $row->[$k2i->{$alt_k}]);
      $altcol2value2pk{$alt_k}{$alt_v} = $pk_val;
    }
  }
  \%altcol2value2pk;
}

sub pk_col_counts {
  my ($data, $pk_map) = @_;
  my $k2i = key_to_index($data->[0]);
  my (%col2code2exact, @no_exact_match);
  for my $i (1..$#$data) {
    my ($row, $exact_match) = $data->[$i];
    for my $possible_col (keys %$k2i) {
      my $val = $row->[ $k2i->{$possible_col} ];
      my @match_codes_yes = grep exists $pk_map->{$_}{$val}, keys %$pk_map;
      $col2code2exact{$possible_col}{$_}++ for @match_codes_yes;
      $exact_match ||= @match_codes_yes;
    }
    push @no_exact_match, $row if !$exact_match;
  }
  (\%col2code2exact, \@no_exact_match);
}

sub _match_register {
  my ($matches, $code, $this_map, $pk_val2count, $pk_col2pk_value2count, $pk_val2from) = @_;
  $pk_val2count->{$_}++,
    $pk_col2pk_value2count->{$code}{$_}++
      for map $this_map->{$_}, @$matches;
  for (@$matches) {
    # track longest matched-value per PK, to tie-break on shortest one
    my $this_pk_val = $this_map->{$_};
    $pk_val2from->{$this_pk_val} = $_ if
      length($pk_val2from->{$this_pk_val}||'') < length;
  }
}

sub pk_match {
  my ($value, $pk_map, $stopwords) = @_;
  my %stopword; @stopword{@$stopwords} = ();
  my @val_words = grep length, split /[^A-Za-z]/, $value;
  my $val_pat = join '.*', map +(/[A-Z]{2,}/ ? split //, $_ : $_), @val_words;
  @val_words = grep !exists $stopword{$_}, map lc, grep length > 2, @val_words;
  my (%pk_col2pk_value2count, %pk_val2count, %pk_val2from);
  for my $code (keys %$pk_map) {
    my $this_map = $pk_map->{$code};
    my @matches = grep /$val_pat/i, keys %$this_map;
    _match_register(\@matches, $code, $this_map, \%pk_val2count, \%pk_col2pk_value2count, \%pk_val2from);
  }
  if ((my @abbrev_parts = grep length, split /\s*[\(,]\s*/, $value) > 1) {
    s/(.*?)[^A-Za-z]+(.*?)/$1.*$2/g for @abbrev_parts;
    my $suff_pref_pat = join '.*', reverse @abbrev_parts;
    for my $code (keys %$pk_map) {
      my $this_map = $pk_map->{$code};
      my @matches = grep /$suff_pref_pat/i, keys %$this_map;
      _match_register(\@matches, $code, $this_map, \%pk_val2count, \%pk_col2pk_value2count);
      @matches = grep /^$suff_pref_pat/i, keys %$this_map;
      _match_register(\@matches, $code, $this_map, \%pk_val2count, \%pk_col2pk_value2count);
    }
  }
  if (!keys %pk_col2pk_value2count) {
    for my $code (keys %$pk_map) {
      my $this_map = $pk_map->{$code};
      for my $word (@val_words) {
        my @matches = grep /\b\Q$word\E\b/i, keys %$this_map;
        _match_register(\@matches, $code, $this_map, \%pk_val2count, \%pk_col2pk_value2count, \%pk_val2from);
      }
    }
  }
  my ($best) = sort {
    $pk_val2count{$b} <=> $pk_val2count{$a}
    ||
    length($pk_val2from{$a}) <=> length($pk_val2from{$b})
    ||
    $a cmp $b
  } keys %pk_val2count;
  my @pk_cols_unique_best = sort grep keys %{ $pk_col2pk_value2count{$_} } == 1 && $pk_col2pk_value2count{$_}{$best}, keys %pk_col2pk_value2count;
  ($best, \@pk_cols_unique_best);
}

1;

=encoding utf8

=head1 NAME

Data::Prepare - prepare CSV (etc) data for automatic processing

=head1 SYNOPSIS

  use Text::CSV qw(csv);
  use Data::Prepare qw(
    cols_non_empty non_unique_cols
    chop_lines chop_cols header_merge
  );
  my $data = csv(in => 'unclean.csv', encoding => "UTF-8");
  chop_cols([0, 2], $data);
  header_merge($spec, $data);
  chop_lines(\@lines, $data); # mutates the data

  # or:
  my @non_empty_counts = cols_non_empty($data);
  print Dumper(non_unique_cols($data));

=head1 DESCRIPTION

A module with utility functions for turning spreadsheets published for
human consumption into ones suitable for automatic processing. Intended
to be used by the supplied L<data-prepare> script. See that script's
documentation for a suggested workflow.

All the functions are exportable, none are exported by default.
All the C<$data> inputs are an array-ref-of-array-refs.

=head1 FUNCTIONS

=head2 chop_cols

  chop_cols([0, 2], $data);

Uses C<splice> to delete each zero-based column index. The example above
deletes the first and third columns.

=head2 chop_lines

  chop_lines([ 0, (-1) x $n ], $data);

Uses C<splice> to delete each zero-based line index, in the order
given. The example above deletes the first, and last C<$n>, lines.

=head2 header_merge

  header_merge([
    { line => 1, from => 'up', fromspec => 'lastnonblank', to => 'self', matchto => 'HH', do => [ 'overwrite' ] },
    { line => 1, from => 'self', matchfrom => '.', to => 'down', do => [ 'prepend', ' ' ] },
    { line => 2, from => 'self', fromspec => 'left', to => 'self', matchto => 'Year', do => [ 'prepend', '/' ] },
    { line => 2, from => 'self', fromspec => 'literal:Country', to => 'self', tospec => 'index:0', do => [ 'overwrite' ] },
  ], $data);
  # Turns:
  # [
  #   [ '', 'Proportion of households with', '', '', '' ],
  #   [ '', '(HH1)', 'Year', '(HH2)', 'Year' ],
  #   [ '', 'Radio', 'of data', 'TV', 'of data' ],
  # ]
  # into (after a further chop_lines to remove the first two):
  # [
  #   [
  #     'Country',
  #     'Proportion of households with Radio', 'Proportion of households with Radio/Year of data',
  #     'Proportion of households with TV', 'Proportion of households with TV/Year of data'
  #   ]
  # ]

Applies the given transformations to the given data, so you can make the
given data have the first row be your desired headers for the columns.
As shown in the above example, this does not delete lines so further
operations may be needed.

Broadly, each hash-ref specifies one operation, which acts on a single
(specified) line-number. It scans along that line from left to right,
unless C<tospec> matches C<index:\d+> in which case only one operation
is done.

The above merge operations in YAML format:

    spec:
      - do:
          - overwrite
        from: up
        fromspec: lastnonblank
        line: 2
        matchto: HH
        to: self
      - do:
          - prepend
          - ' '
        from: self
        line: 2
        matchfrom: .
        to: down
      - do:
          - prepend
          - /
        from: self
        fromspec: left
        line: 3
        matchto: Year
        to: self
      - do:
          - overwrite
        from: self
        fromspec: literal:Country
        line: 3
        to: self
        tospec: index:0

This turns the first three lines of data excerpted from the supplied example
data (shown in CSV with spaces inserted for alignment reasons only):

        ,Proportion of households with,       ,     ,
        ,(HH1)                        ,Year   ,(HH2),Year
        ,Radio                        ,of data,TV   ,of data
  Belize,58.7                         ,2019   ,78.7 ,2019

into the following. Note that the first two lines will still be present
(not shown), possibly modified, so you will need your chop_lines to
remove them. The columns of the third line are shown, one per line,
for readability:

  Country,
  Proportion of households with Radio,
  Proportion of households with Radio/Year of data,
  Proportion of households with TV,
  Proportion of households with TV/Year of data

This achieves a single row of column-headings, with each column-heading
being unique, and sufficiently meaningful.

=head2 pk_insert

  pk_insert({
    column_heading => 'ISO3CODE',
    local_column => 'Country',
    pk_column => 'official_name_en',
  }, $data, $pk_map, $stopwords);

In YAML format, this is the same configuration:

  pk_insert:
    - files:
        - examples/CoreHouseholdIndicators.csv
      spec:
        column_heading: ISO3CODE
        local_column: Country
        pk_column: official_name_en
        use_fallback: true

And the C<$pk_map> made with L</make_pk_map>, inserts the
C<column_heading> in front of the current zero-th column, mapping the
value of the C<Country> column as looked up from the specified column
of the C<pk_spec> file, and if C<use_fallback> is true, also tries
L</pk_match> if no exact match is found. In that case, C<stopwords>
must be specified in the configuration

=head2 cols_non_empty

  my @col_non_empty = cols_non_empty($data);

In the given data, iterates through all rows and returns a list of
quantities of non-blank entries in each column. This can be useful to spot
columns with only a couple of entries, which are more usefully chopped.

=head2 non_unique_cols

  my $col2count = non_unique_cols($data);

Takes the first row of the given data, and returns a hash-ref mapping
any non-unique column-names to the number of times they appear.

=head2 key_to_index

Given an array-ref (probably the first row of a CSV file, i.e. column
headings), returns a hash-ref mapping the cell values to their zero-based
index.

=head2 make_pk_map

  my $altcol2value2pk = make_pk_map($data, $pk_colkey, \@other_colkeys);

Given C<$data>, the heading of the primary-key column, and an array-ref
of headings of alternative key columns, returns a hash-ref mapping each
of those alternative key columns (plus the C<$pk_colkey>) to a map from
that column's value to the relevant row's primary-key value.

This is most conveniently represented in YAML format:

  pk_spec:
    file: examples/country-codes.csv
    primary_key: ISO3166-1-Alpha-3
    alt_keys:
      - ISO3166-1-Alpha-2
      - UNTERM English Short
      - UNTERM English Formal
      - official_name_en
      - CLDR display name
    stopwords:
      - islands
      - china
      - northern

=head2 pk_col_counts

  my ($colname2potential_key2count, $no_exact_match) = pk_col_counts($data, $pk_map);

Given C<$data> and a primary-key (etc) map created by the above, returns
a tuple of a hash-ref mapping each column that gave any matches to a
further hash-ref mapping each of the potential key columns given above
to how many matches it gave, and an array-ref of rows that had no exact
matches.

=head2 pk_match

  my ($best, $pk_cols_unique_best) = pk_match($value, $pk_map, $stopwords);

Given a value, C<$pk_map>, and an array-ref of case-insensitive stopwords,
returns its best match for the right primary-key value, and an array-ref
of which primary-key columns in the C<$pk_map> matched the given value
exactly once.

The latter is useful for analysis purposes to select which primary-key
column to use for this data-set.

The algorithm used for this best-match:

=over

=item *

Splits the value into words (or where a word is two or more capital
letters, letters). The search allows any, or no, text, to occur between
these entities. Each configured primary-key column's keys are searched
for matches.

=item *

If there is a separating C<,> or C<(> (as commonly used for
abbreviations), splits the value into chunks, reverses them, and then
reassembles the chunks as above for a similar search.

=item *

Only if there were no matches from the previous steps, splits the value
into words. Words that are shorter than three characters, or that occur in
the stopword list, are omitted. Then each word is searched for as above.

=item *

"Votes" on which primary-key value got the most matches. Tie-breaks on
which primary-key value matched on the shortest key in the relevant
C<$pk_map> column, and then on the lexically lowest-valued primary-key
value, to ensure stable return values.

=back

=head1 SEE ALSO

L<Text::CSV>

=head1 LICENSE AND COPYRIGHT

Copyright (C) Ed J

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

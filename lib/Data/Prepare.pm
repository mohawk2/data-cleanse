package Data::Prepare;

use strict;
use warnings;
use Exporter 'import';

our $VERSION = '0.001';
our @EXPORT_OK = qw(
  cols_non_empty
  chop_lines
);

sub chop_lines {
  my ($choplines, $data) = @_;
  splice @$data, $_, 1 for @$choplines;
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

1;

=encoding utf8

=head1 NAME

Data::Prepare - prepare CSV (etc) data for automatic processing

=head1 SYNOPSIS

  use Text::CSV qw(csv);
  use Data::Prepare qw(
    cols_non_empty
    chop_lines
  );
  my $data = csv(in => 'unclean.csv', encoding => "UTF-8");
  chop_lines(\@lines, $data); # mutates the data

  # or:
  my @non_empty_counts = cols_non_empty($data);

=head1 DESCRIPTION

A module with utility functions for turning spreadsheets published for
human consumption into ones suitable for automatic processing.

All the functions are exportable, none are exported by default.
All the C<$data> inputs are an array-ref-of-array-refs.

=head1 FUNCTIONS

=head2 chop_lines

  chop_lines([ 0, (-1) x $n ], $data);

Uses C<splice> to delete each zero-based line index, in the order
given. The example above deletes the first, and last C<$n>, lines.

=head2 cols_non_empty

  my @col_non_empty = cols_non_empty($data);

In the given data, iterates through all rows and returns a list of
quantities of non-blank entries in each column. This can be useful to spot
columns with only a couple of entries, which are more usefully chopped.

=head1 SEE ALSO

L<Text::CSV>

=head1 LICENSE AND COPYRIGHT

Copyright (C) Ed J

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

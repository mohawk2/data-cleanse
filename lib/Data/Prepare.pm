package Data::Prepare;

use strict;
use warnings;
use Exporter 'import';

our $VERSION = '0.001';
our @EXPORT_OK = qw(chop_lines);

sub chop_lines {
  my ($choplines, $data) = @_;
  splice @$data, $_, 1 for @$choplines;
}

1;

=encoding utf8

=head1 NAME

Data::Prepare - prepare CSV (etc) data for automatic processing

=head1 SYNOPSIS

  use Text::CSV qw(csv);
  use Data::Prepare qw(chop_lines);
  my $data = csv(in => 'unclean.csv', encoding => "UTF-8");
  chop_lines(\@lines, $data); # mutates the data

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

=head1 SEE ALSO

L<Text::CSV>

=head1 LICENSE AND COPYRIGHT

Copyright (C) Ed J

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

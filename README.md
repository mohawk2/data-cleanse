# NAME

Data::Prepare - prepare CSV (etc) data for automatic processing

# SYNOPSIS

    use Text::CSV qw(csv);
<<<<<<< HEAD
    use Data::Prepare qw(
      cols_non_empty
      chop_lines
    );
    my $data = csv(in => 'unclean.csv', encoding => "UTF-8");
    chop_lines(\@lines, $data); # mutates the data

    # or:
    my @non_empty_counts = cols_non_empty($data);
=======
<<<<<<< HEAD
<<<<<<< HEAD
    use Data::Prepare qw(chop_lines);
    my $data = csv(in => 'unclean.csv', encoding => "UTF-8");
    chop_lines(\@lines, $data); # mutates the data
=======
    use Data::Cleanse qw(read_spec cleanse analyse cols_non_empty chop_lines);
    my $spec = read_spec('cleanse.yml');
=======
    use Data::Cleanse qw(chop_cols chop_lines cols_non_empty);
>>>>>>> c1d998c... chop_cols
    my $data = csv(in => 'unclean.csv', encoding => "UTF-8");
    chop_cols([0, 2], $data);
    chop_lines([0, -1, -1], $data);

    # or:
<<<<<<< HEAD
    my @errors = analyse($data);
    die @errors if @errors;
>>>>>>> 4755954... cols_non_empty
=======
    my @cols_non_empty = cols_non_empty($data);
>>>>>>> c1d998c... chop_cols
>>>>>>> da4df19... chop_cols

# DESCRIPTION

A module with utility functions for turning spreadsheets published for
human consumption into ones suitable for automatic processing.

All the functions are exportable, none are exported by default.
All the `$data` inputs are an array-ref-of-array-refs.

# FUNCTIONS

## chop\_cols

    chop_cols([0, 2], $data);

Uses `splice` to delete each zero-based column index. The example above
deletes the first and third columns.

## chop\_lines

    chop_lines([ 0, (-1) x $n ], $data);

Uses `splice` to delete each zero-based line index, in the order
given. The example above deletes the first, and last `$n`, lines.

## cols\_non\_empty

    my @col_non_empty = cols_non_empty($data);

In the given data, iterates through all rows and returns a list of
quantities of non-blank entries in each column. This can be useful to spot
columns with only a couple of entries, which are more usefully chopped.

# SEE ALSO

[Text::CSV](https://metacpan.org/pod/Text%3A%3ACSV)

# LICENSE AND COPYRIGHT

Copyright (C) Ed J

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

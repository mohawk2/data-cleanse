# NAME

Data::Prepare - prepare CSV (etc) data for automatic processing

# SYNOPSIS

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

## header\_merge

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

## cols\_non\_empty

    my @col_non_empty = cols_non_empty($data);

In the given data, iterates through all rows and returns a list of
quantities of non-blank entries in each column. This can be useful to spot
columns with only a couple of entries, which are more usefully chopped.

## non\_unique\_cols

    my $col2count = non_unique_cols($data);

Takes the first row of the given data, and returns a hash-ref mapping
any non-unique column-names to the number of times they appear.

# SEE ALSO

[Text::CSV](https://metacpan.org/pod/Text%3A%3ACSV)

# LICENSE AND COPYRIGHT

Copyright (C) Ed J

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

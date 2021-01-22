# NAME

Data::Prepare - prepare CSV (etc) data for automatic processing

# SYNOPSIS

    use Text::CSV qw(csv);
    use Data::Prepare qw(chop_lines);
    my $data = csv(in => 'unclean.csv', encoding => "UTF-8");
    chop_lines(\@lines, $data); # mutates the data

# DESCRIPTION

A module with utility functions for turning spreadsheets published for
human consumption into ones suitable for automatic processing.

All the functions are exportable, none are exported by default.
All the `$data` inputs are an array-ref-of-array-refs.

# FUNCTIONS

## chop\_lines

    chop_lines([ 0, (-1) x $n ], $data);

Uses `splice` to delete each zero-based line index, in the order
given. The example above deletes the first, and last `$n`, lines.

# SEE ALSO

[Text::CSV](https://metacpan.org/pod/Text%3A%3ACSV)

# LICENSE AND COPYRIGHT

Copyright (C) Ed J

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

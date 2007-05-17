package XML::Grammar::Screenplay;

use warnings;
use strict;

=head1 NAME

XML::Grammar::Screenplay - module implementing an XML grammar for screenplays.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.0101';

=head1 SYNOPSIS

    use XML::Grammar::Screenplay;

    my $grammar = XML::Grammar::Screenplay->new(
        {
            filename => "my-screenplay.xml",    
        }
    );

    $grammer->output_docbook({dest => "my-screenplay-docbook.xml"});

=head1 METHODS

=head2 new

=cut


sub _init
{
    my ($self, $args) = @_;

    return 0;
}

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-xml-grammar-screenplay at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Grammar-Screeplay>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 TODO

=over 4

=item * Implement SGML-like escapes - &lt; &gt; &amp; etc.

=item * Implement a direct ScreenplayXML-to-HTML backend.

=item * Document the proto-text format.

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::Grammar::Screenplay

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-Grammar-Screeplay>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-Grammar-Screeplay>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Grammar-Screeplay>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-Grammar-Screeplay>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=cut

1;


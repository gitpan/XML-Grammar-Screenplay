package XML::Grammar::Screenplay::FromProto;

use strict;
use warnings;

use Carp;

use base 'XML::Grammar::Screenplay::Base';

use XML::Writer;
use Parse::RecDescent;
use HTML::Entities ();

use XML::Grammar::Screenplay::FromProto::Nodes;

use Moose;

has "_parser" => ('isa' => "Parse::RecDescent", 'is' => "rw");
has "_writer" => ('isa' => "XML::Writer", 'is' => "rw");

=head1 NAME

XML::Grammar::Screenplay::FromProto - module that converts well-formed
text representing a screenplay to an XML format.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head2 new()

Accepts no arguments so far. May take some time as the grammar is compiled
at that point.

=head2 meta()

Internal - (to settle pod-coverage.).

=cut

sub _init
{
    my ($self, $args) = @_;

    local $Parse::RecDescent::skip = "";

    $self->_parser(
        Parse::RecDescent->new(
            $self->_calc_grammar()
        )
    );

    return 0;
}

=head2 $self->convert({ source => { file => $path_to_file } })

Converts the file $path_to_file to XML and returns it.

=cut

sub _calc_grammar
{
    my $self = shift;

    return <<'EOF';

start : tag  {$thisparser->{ret} = $item[1]; 1 }

text_unit:   tag_or_comment { $item[1] }
           | speech_or_desc { $item[1] }

tag_or_comment:   tag
                | comment

comment:    /<!--(.*?)-->/ms para_sep {
    XML::Grammar::Screenplay::FromProto::Node::Comment->new(
        text => $1
    )
    }

para_sep:      /(\n\s*)+/

speech_or_desc:   speech_unit  
                | desc_unit

plain_inner_text:  /([^\n<\[\]]+\n?)+/ { $item[1] }

inner_tag:         opening_tag  inner_text closing_tag {
        my ($open, $inside, $close) = @item[1..$#item];
        if ($open->{name} ne $close->{name})
        {
            Carp::confess("Tags do not match: $open->{name} and $close->{name}");
        }
        XML::Grammar::Screenplay::FromProto::Node::Element->new(
            name => $open->{name},
            children => XML::Grammar::Screenplay::FromProto::Node::List->new(
                contents => $inside
                ),
            attrs => $open->{attrs},
            )
    }

inner_desc:      /\[/ inner_text /\]/ {
        my $inside = $item[2];
        XML::Grammar::Screenplay::FromProto::Node::InnerDesc->new(
            children => XML::Grammar::Screenplay::FromProto::Node::List->new(
                contents => $inside
                ),
            )
    }

inner_tag_or_desc:    inner_tag
                   |  inner_desc

inner_text_unit:    plain_inner_text  { [ $item[1] ] }
                 |  inner_tag_or_desc { [ $item[1] ] }

inner_text:       inner_text_unit(s) {
        [ map { @{$_} } @{$item[1]} ]
        }

addressing: /^([^:\n\+]+): /ms { $1 }

saying_first_para: addressing inner_text para_sep {
            my ($sayer, $what) = ($item[1], $item[2]);
            +{
             character => $sayer,
             para => XML::Grammar::Screenplay::FromProto::Node::Paragraph->new(
                children =>
                XML::Grammar::Screenplay::FromProto::Node::List->new(
                    contents => $what,
                    )
                ),
            }
            }

saying_other_para: /^\++: /ms inner_text para_sep {
        XML::Grammar::Screenplay::FromProto::Node::Paragraph->new(
            children =>
                XML::Grammar::Screenplay::FromProto::Node::List->new(
                    contents => $item[2],
                    ),
        )
    }

speech_unit:  saying_first_para saying_other_para(s?)
    {
    my $first = $item[1];
    my $others = $item[2] || [];
        XML::Grammar::Screenplay::FromProto::Node::Saying->new(
            character => $first->{character},
            children => XML::Grammar::Screenplay::FromProto::Node::List->new(
                contents => [ $first->{para}, @{$others} ],
                ),
        )
    }

desc_para:  inner_text para_sep { $item[1] }

desc_unit_inner: desc_para(s?) inner_text { [ @{$item[1]}, $item[2] ] }

desc_unit: /^\[/ms desc_unit_inner /\]\s*$/ms para_sep {
        my $paragraphs = $item[2];

        XML::Grammar::Screenplay::FromProto::Node::Description->new(
            children => 
                XML::Grammar::Screenplay::FromProto::Node::List->new(
                    contents =>
                [
                map { 
                XML::Grammar::Screenplay::FromProto::Node::Paragraph->new(
                    children =>
                        XML::Grammar::Screenplay::FromProto::Node::List->new(
                            contents => $_,
                            ),
                        )
                } @$paragraphs
                ],
            ),
        )
    }

text: text_unit(s) { XML::Grammar::Screenplay::FromProto::Node::List->new(
        contents => $item[1]
        ) }
      | space { XML::Grammar::Screenplay::FromProto::Node::List->new(
        contents => []
        ) }

tag: space opening_tag space text space closing_tag space
     {
        my (undef, $open, undef, $inside, undef, $close) = @item[1..$#item];
        if ($open->{name} ne $close->{name})
        {
            Carp::confess("Tags do not match: $open->{name} and $close->{name}");
        }
        XML::Grammar::Screenplay::FromProto::Node::Element->new(
            name => $open->{name},
            children => $inside,
            attrs => $open->{attrs},
            );
     }

opening_tag: '<' id attribute(s?) '>'
    { $item[0] = { 'name' => $item[2], 'attrs' => $item[3] }; }

closing_tag: '</' id '>'
    { $item[0] = { 'name' => $item[2], }; }

attribute: space id '="' attributevalue '"' space
    { $item[0] = { 'key' => $item[2] , 'value' => $item[4] }; }

attributevalue: /[^"]+/
    { $item[0] = HTML::Entities::decode_entities($item[1]); }

space: /\s*/

id: /[a-zA-Z_\-]+/

EOF
}

use Data::Dumper;

sub _output_tag
{
    my ($self, $args) = @_;

    $self->_writer->startTag(@{$args->{start}});

    $args->{in}->($self, $args);

    $self->_writer->endTag();
}

sub _output_tag_with_childs
{
    my ($self, $args) = @_;

    return 
        $self->_output_tag({
            %$args,
            'in' => sub {
                foreach my $child (@{$args->{elem}->_get_childs()})
                {
                    $self->_write_elem({elem => $child,});
                }
            },
        });
}

sub _get_text_start
{
    my ($self, $elem) = @_;

    if ($elem->isa("XML::Grammar::Screenplay::FromProto::Node::Saying"))
    {
        return ["saying", 'character' => $elem->character()];
    }
    elsif ($elem->isa("XML::Grammar::Screenplay::FromProto::Node::Description"))
    {
        return ["description"];
    }
    else
    {
        Carp::confess ("Unknown element class - " . ref($elem) . "!");
    }
}

sub _write_elem
{
    my ($self, $args) = @_;

    my $elem = $args->{elem};

    if (ref($elem) eq "")
    {
        $self->_writer->characters($elem);
    }
    elsif ($elem->isa("XML::Grammar::Screenplay::FromProto::Node::Paragraph"))
    {
        $self->_output_tag_with_childs(
            {
               start => ["para"],
                elem => $elem,
            },
        );
    }
    elsif ($elem->isa("XML::Grammar::Screenplay::FromProto::Node::Element"))
    {
        if (($elem->name() eq "s") || ($elem->name() eq "section"))
        {
            $self->_write_scene({scene => $elem});
        }
        elsif ($elem->name() eq "a")
        {
            $self->_output_tag_with_childs(
                {
                    start => ["ulink", "url" => $elem->lookup_attr("href")],
                    elem => $elem,
                }
            );
        }
        elsif ($elem->name() eq "b")
        {
            $self->_output_tag_with_childs(
                {
                    start => ["bold"],
                    elem => $elem,
                }
            );
        }
        elsif ($elem->isa("XML::Grammar::Screenplay::FromProto::Node::InnerDesc"))
        {
            $self->_output_tag_with_childs(
                {
                    start => ["inlinedesc"],
                    elem => $elem,
                }
            );
        }
    }
    elsif ($elem->isa("XML::Grammar::Screenplay::FromProto::Node::Text"))
    {
        $self->_output_tag_with_childs(
            {
                start => $self->_get_text_start($elem),
                elem => $elem,
            },
        );
    }
    elsif ($elem->isa("XML::Grammar::Screenplay::FromProto::Node::Comment"))
    {
        $self->_writer->comment($elem->text());
    }
}

sub _write_scene
{
    my ($self, $args) = @_;

    my $scene = $args->{scene};

    my $tag = $scene->name;
    
    if (($tag eq "s") || ($tag eq "scene"))
    {
        my $id = $scene->lookup_attr("id");

        if (!defined($id))
        {
            Carp::confess("Unspecified id for scene!");
        }
        $self->_output_tag_with_childs(
            {
                'start' => ["scene", id => $id],
                elem => $scene,
            }
        );
    }
    else
    {
        confess "Improper scene tag - should be '<s>' or '<scene>'!";
    }

    return;
}

sub _read_file
{
    my ($self, $filename) = @_;

    open my $in, "<", $filename or
        confess "Could not open the file \"$filename\" for slurping.";
    my $contents;
    {
        local $/;
        $contents = <$in>;
    }
    close($in);
    
    return $contents;
}

sub convert
{
    my ($self, $args) = @_;

    # These should be un-commented for debugging.
    # local $::RD_HINT = 1;
    # local $::RD_TRACE = 1;
    
    # We need this so P::RD won't skip leading whitespace at lines
    # which are siginificant.  

    my $filename = $args->{source}->{file} or
        confess "Wrong filename given.";
    my $ret = $self->_parser->start($self->_read_file($filename));

    my $tree = $self->_parser->{ret};

    if (!defined($ret))
    {
        Carp::confess("Parsing failed.");
    }

    my $buffer = "";
    my $writer = XML::Writer->new(OUTPUT => \$buffer, ENCODING => "utf-8",);

    $writer->xmlDecl("utf-8");
    $writer->doctype("document", undef, "screenplay-xml.dtd");
    $writer->startTag("document");
    $writer->startTag("head");
    $writer->endTag();
    $writer->startTag("body", "id" => "index",);

    # Now we're inside the body.
    $self->_writer($writer);

    $self->_write_scene({scene => $tree});

    # Ending the body
    $writer->endTag();

    $writer->endTag();
    
    return $buffer;
}

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-xml-grammar-screenplay at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Grammar-Screeplay>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=cut

1;


#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Test::XML tests => 2;

use File::Spec;

use XML::LibXML;

use XML::Grammar::Screenplay::ToDocBook;

my @tests = (qw(
        with-internal-description
    ));

sub load_xml
{
    my $path = shift;

    open my $in, "<", $path;
    my $contents;
    {
        local $/;
        $contents = <$in>
    }
    close($in);
    return $contents;
}

# TEST:$num_texts=1

my $converter = XML::Grammar::Screenplay::ToDocBook->new({
        data_dir => File::Spec->catdir(File::Spec->curdir(), "extradata"),
    });

foreach my $fn (@tests)
{
    my $docbook_text = $converter->translate_to_docbook({
            source => { file => "t/data/xml/$fn.xml", },
            output => "string",
        }
        );

    # TEST*$num_texts*2
    like ($docbook_text, qr{<article id="index"},
        "Checking for article."
    );
    like ($docbook_text, qr{<section role="description"},
        "Checking for section."
    );
}

1;


use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;

use File::Find;

sub data_inc
{
    return "/usr/share/perl5/data/modules/XML-Grammar-Screenplay/data";
}

my @extradata_files;

sub filter_files
{
    my $filename = $File::Find::name;
    if ((-f $filename) && ($filename =~ /\.(?:mod|xslt|dtd|ent|cat|jpg|xcf\.bz2)$/))
    {
        push @extradata_files, $filename;
    }
}

find({ wanted => \&filter_files, no_chdir => 1}, "extradata");

my $builder = Test::Run::Builder->new(
    module_name         => 'XML::Grammar::Screenplay',
    license             => 'bsd',
    dist_author         => 'Shlomi Fish <shlomif@cpan.org>',
    dist_version_from   => 'lib/XML/Grammar/Screenplay.pm',
    build_requires => {
        'File::Find' => 0,
        'Test::More' => 0,
        'Test::XML' => 0,
    },
    requires => 
    {
        'Carp' => 0,
        'Data::Dumper' => 0,
        'List::Util' => 0,
        'Moose' => 0,
        'Parse::RecDescent' => 0,
        'warnings' => 0,
        'XML::LibXSLT' => 0,
        'XML::Writer' => 0,
    },
    add_to_cleanup      => [ 'XML-Grammar-Screeplay-*' ],
    create_makefile_pl => 'passthrough',
    install_path =>
    {
        extradata => data_inc(),
    },
    extradata_files =>
    {
        (map { $_ => $_ } @extradata_files),
    },
);


$builder->add_build_element('extradata');
$builder->install_path->{'extradata'} = ($builder->prefix() || "/usr") . "/data/modules/XML-Grammar-Screenplay/data";

$builder->config_data('extradata_install_path' => [$builder->install_path->{'extradata'}]);

$builder->create_build_script();

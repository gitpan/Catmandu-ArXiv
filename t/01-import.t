use strict;
use warnings FATAL => 'all';
use Test::More;
use YAML;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Importer::ArXiv';
    use_ok $pkg;
}

my $imp = $pkg->new( id => '1408.6349' );
is( $imp->count, 1, "count ok" );

my $imp2 = $pkg->new( id => '1408.6349,1408.6320,1408.6105' );
is( $imp2->count, 3, "count ok" );

my $imp3 = $pkg->new( query => "electron", limit => 20 );
is( $imp3->count, 20, "count ok" );

done_testing;

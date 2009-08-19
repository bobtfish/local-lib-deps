use strict;
use warnings;
use Cwd;

use Test::More tests => 9;
use Data::Dumper;
use File::Temp qw/tempdir/;

use_ok( 'local::lib::deps', '-import' );

ok( defined( &install_deps ), "install_deps imported" );
ok( defined( &locallib ), "locallib imported");

my $tmp = tempdir( 'test-XXXX', DIR => 't', CLEANUP => 1 );
{
    no warnings 'once';
    $local::lib::deps::LLPATH = getcwd() . "/$tmp";
}

diag "Hiding output from cpan build... this could take some time.\n";
diag "In event of error you can check $tmp/build.out for more information.\n";
{
    no warnings 'once';
    open( COPYSTD, ">&STDOUT" );
    open( COPYERR, ">&STDERR" );
    close( STDOUT );
    close( STDERR );
    open( STDOUT, ">$tmp/build.out" );
    open( STDERR, ">&STDOUT" );
}

install_deps( 'Fake::Module', 'CPAN::Test::Dummy::Perl5::Build' );

close( STDOUT );
close( STDERR );
open( STDOUT, ">&COPYSTD" );
open( STDERR, ">&COPYERR" );


ok( -e( $tmp . '/Fake/Module/lib/perl5/local/lib.pm'), "locallib installed to the correct place." );
ok( -e( $tmp . '/Fake/Module/lib/perl5/CPAN/Test/Dummy/Perl5/Build.pm'), "dummy installed to the correct place." );

eval 'use CPAN::Test::Dummy::Perl5::Build';
ok( $@, "Could not use module that is in locallib yet." );

ok( ! ( grep { $_ =~ m,$tmp/Fake/Module/lib/perl5/, } @INC ), "Path not yet in \@INC" );
eval 'use local::lib::deps "Fake::Module"';
ok(( grep { $_ =~ m,$tmp/Fake/Module/lib/perl5/, } @INC ), "Path now in \@INC" );

eval 'use CPAN::Test::Dummy::Perl5::Build';
ok( ! $@, "Can now use the module" );

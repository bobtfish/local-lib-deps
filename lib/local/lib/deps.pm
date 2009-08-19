package local::lib::deps;
use warnings;
use strict;
use Cwd;
use Config;
use Data::Dumper;

use base 'Exporter';
our @EXPORT = qw/locallib install_deps/;

our $VERSION = 0.02;

our $LLPATH;
BEGIN {
    $LLPATH = __FILE__;
    $LLPATH =~ s,/[^/]*$,,ig;
    $LLPATH .= '/deps';
    #$LLPATH = getcwd . "/$PATH" unless ( $PATH =~ m,^/, );
}

sub import {
    my ( $package, @params ) = @_;
    my @modules = grep { $_ !~ m/^-/ } @params;
                      # Copy $_ so we don't change @params
    my %flags = map { my $i = $_; $i =~ s/^-//g; $i => 1 } grep { $_ =~ m/^-/ } @params;
    unless ( @modules ) {
        my ($module) = caller;
        @modules = ( $module );
    }
    if ( $flags{'import'} ) {
        @params = grep { $_ ne '-import' } @params;
        @_ = ( $package, @params );
        goto &Exporter::import;
    }
    if ( $flags{locallib} ) {
        die( "Can only specify one module to use with the -locallib flag.\n" ) if @modules > 1;
        locallib( @modules );
        return;
    }
    _add_path( $_ ) for @modules;
}

sub locallib {
    my ( $module ) = @_;
    my $mpath = _full_module_path( $module );
    _add_path( $module );
    my $eval = "use local::lib '$mpath'";
    eval $eval;
    die( $@ ) if $@;
}

sub install_deps {
    my ($pkg, @deps) = @_;
    print "Forking child process to run cpan...\n";
    if ( my $pid = fork ) {
        waitpid( $pid, 0 );
    }
    else {
        _install_deps( $pkg, @deps );
        exit;
    }
}

sub _module_path {
    my ( $module ) = @_;
    my $mpath = $module;
    $mpath =~ s,::,/,g;
    return $mpath;
}

sub _full_module_path {
    return join( "/", $LLPATH, _module_path( @_ ));
}

sub _add_path {
    unshift @INC, _path( @_ ), _arch_path( @_ );
}

sub _path {
    return join( "/", _full_module_path( @_ ), "lib/perl5" );
}

sub _arch_path {
    return join( "/", _path( @_ ), $Config{archname});
}

sub _install_deps {
    my ($pkg, @deps) = @_;
    my $origin = getcwd();

    require CPAN;
    CPAN::HandleConfig->load();
    CPAN::Shell::setup_output();
    CPAN::Index->reload();
    local $CPAN::Config->{build_requires_install_policy} = 'yes';
    {
        local $CPAN::Config->{makepl_arg} = '--bootstrap=' . _full_module_path( $pkg );
        CPAN::Shell->install( 'local::lib' );
    }

    # We want to install to the locallib.
    locallib( $pkg );

    foreach my $dep ( @deps ) {
        CPAN::Shell->install( $dep );
    }

    # Be kind rewind.
    chdir( $origin );
}

1;

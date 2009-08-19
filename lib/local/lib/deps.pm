package local::lib::deps;
use warnings;
use strict;
use Cwd;
use Config;
use Data::Dumper;

=pod

=head1 NAME

local::lib::deps - Maintain a module specific lib path for that modules dependencies.

=head1 DESCRIPTION

Maintaining perl module dependencies through a distributions package manager
can be a real pain. This module helps by making it easier to simply bundle all
your applications dependencies into one lib path specific to the module. It
also makes it easy to tell your applicatin where to look for modules.

=head1 SYNOPSYS

Bootstrap your modules dependency area:

    use local::lib::deps '-import'; #import the public functions instead of bringing in a modules path.
    install_deps( 'My::Module', qw/Dep::One Dep::Two .../ );

This will create a directory specifically for the My::Module namespace and
install the specified dependencies (and local::lib) there.

To use those deps in your app:

    use local::lib::deps qw/ My::Module /;
    use Dep::One;

To initiate local::lib with the destination directory of your module:

    use local::lib::deps -locallib 'My::Module';

=head1 PUBLIC FUNCTIONS

To bring these in to your program do this:

    use local::lib::deps -import;

=over 4

=cut

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

=item locallib( $module )

Will get local::lib setup against the local::lib::deps dir for the specified module.

=cut

sub locallib {
    my ( $module ) = @_;
    my $mpath = _full_module_path( $module );
    _add_path( $module );
    my $eval = "use local::lib '$mpath'";
    eval $eval;
    die( $@ ) if $@;
}

=item install_deps( $module, @deps )

This will bootstrap local::lib into a local::lib::deps folder for the specified
module, it will then continue to install (or update) allt he dependency
modules.

=cut

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

my %_path_added;
sub _add_path {
    my ( $module ) = @_;
    return if $_path_added{ $module };
    unshift @INC, _path( $module ), _arch_path( $module );
    $_path_added{ $module }++;
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

__END__

=back

=head1 AUTHORS

=over 4

=item Chad Granum L<chad@opensourcery.com>

=back

=head1 COPYRIGHT

Copyright (C) 2004-2007 OpenSourcery, LLC

local-lib-deps is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option) any
later version.

local-lib-deps is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
Street, Fifth Floor, Boston, MA 02110-1301 USA.

local-lib-deps is packaged with a copy of the GNU General Public License.
Please see docs/COPYING in this distribution.

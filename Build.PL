#!/usr/bin/perl
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
     module_name => 'local::lib::deps',
     license  => 'perl',
     dist_abstract => 'This module uses local::lib to allow applications to maintain a private path of dependancy modules.',
);

$build->create_build_script;

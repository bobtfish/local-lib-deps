#!/usr/bin/env perl
use strict;
use warnings;
use inc::Module::Install 0.91;

name 'local-lib-deps';
all_from 'lib/local/lib/deps.pm';
license 'perl';
abstract 'This module uses local::lib to allow applications to maintain a private path of dependancy modules.';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/local/lib/deps.pm > README")
        and die;
}

WriteAll;


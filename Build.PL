#!/usr/bin/env perl

use strict;
use warnings;
use Module::Build;

Module::Build->new(
    dist_author         => 'Brandon Sandrowicz <bsandrow@gmail.com>',
    module_name         => 'Posterous',
    dist_name           => 'Posterous',
    dist_version        => 0.5,
    license             => 'mit',
    create_makefile_pl  => 'traditional',
    requires            => {
        'perl'          => '5.10.0',
        'JSON'          => 0,
        'Carp'          => 0,
        'LWP::UserAgent'=> 0,
        'URI::URL'      => 0,
        'Moose'         => 0,
        'common::sense' => 0,
    },
)->create_build_script();

# -*- perl -*-

# t/16_rt122946.t

use strict;
use warnings;

use Test::More tests => 1+1;
use Test::NoWarnings;
use Test::Exception;

use lib 't/testlib';
use testlib;

{
    package Test16;
    use MooseX::App::Simple;

    option 'parama' => (
        is => 'rw',
        isa => 'Int',
        cmd_aliases => ['a']
    );

    option 'paramb' => (
        is => 'rw',
        isa => 'Bool',
        cmd_aliases => ['b']
    );

    option 'paramab' => (
        is => 'rw',
        isa => 'Int',
        cmd_aliases => ['ab']
    );

    sub run { print "OK"; }
}

testlib::run_testclass('Test16');

subtest 'Option flags' => sub {
    throws_ok {
        Test16->new_with_options( ARGV => [ '-ab' ] )
    } qr/Option param[ab] has a single letter flag but no Bool/;
};



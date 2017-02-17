use strict;
use warnings;

use Test::More tests => 2;

use lib 't/testlib';

use TestSubCommand;

is( TestSubCommand->new_with_command( ARGV => [ 'foo' ] )->run 
    => 'running foo' 
);

is( TestSubCommand->new_with_command( ARGV => [ qw/ foo bar /] )->run
    => 'running bar' 
);

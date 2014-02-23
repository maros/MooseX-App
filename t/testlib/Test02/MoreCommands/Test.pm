# ============================================================================
package Test02::MoreCommands::Test;
# ============================================================================
use strict;
use warnings;
use utf8;

use Moose;
use MooseX::App::Command;
extends qw(Test02);

option 'local' => (
    isa             => 'Int',
    is              => 'rw',
    required        => 1,
);

1;
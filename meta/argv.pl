#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;
use FindBin qw();
use lib ("$FindBin::Bin/../lib");

use MooseX::App::ParsedArgv;
use Data::Dumper;

my $inst = MooseX::App::ParsedArgv->instance();
say Dumper($inst);

$inst->options;
say Dumper($inst);

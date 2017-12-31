#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

use FindBin qw();
use lib $FindBin::Bin.'/../testlib';

use Test11;
Test11->new_with_command->run;
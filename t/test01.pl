#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

use lib 't/testlib';
use Test01;
Test01->new_with_command->run;

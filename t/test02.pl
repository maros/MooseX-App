#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

use lib 't/testlib';
use Test02;
Test02->new_with_command->run;

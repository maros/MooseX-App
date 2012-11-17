#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

use lib 't/testlib';
use Test04;
Test04->new_with_command->run;

package Test02;

use Moose;
use MooseX::App qw(BashCompletion ConfigHome Color Version Env Fuzzy);

our $VERSION = 1.01;

app_namespace "Test02::Command";

sub run {
    print "RAN";   
}

1;
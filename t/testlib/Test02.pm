package Test02;

use Moose;
use MooseX::App qw(BashCompletion ConfigHome Color Version Env Typo);

our $VERSION = 1.01;

app_namespace "Test02::Command";
#app_fuzzy;

sub run {
    print "RAN";   
}

1;
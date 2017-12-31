package testlib;

use 5.010;
use strict;
use warnings;

# Run directly if not testing
sub run_testclass {
    my ($class, @args) = @_;

    return
        if $ENV{HARNESS_ACTIVE};

    say STDERR "# Skipping Testing since not running HARNESS_ACTIVE!";
    say STDERR "# Executing test class $class instead";
    say ("#" x 78);
    if ($class->can('new_with_command')) {
        say $class->new_with_command(@args)->run;
    } elsif ($class->can('new_with_options')) {
        say $class->new_with_options(@args)->run;
    } else {
        die('Not a MooseX::App or MooseX::App::Simple class');
    }
    say ("#" x 78);
    exit();
}

1;
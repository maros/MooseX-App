package Test01::CommandB;

use Moose;
use MooseX::App::Command;
extends qw(Test01);

has 'email' => (
    isa         => 'Str',
    is          => 'rw',
);

sub run { 
    print "RUN COMMAND-B";
}

=encoding utf8

=head1 NAME

Test01::CommandB - Test class command B for test 01

=head1 SYNOPSIS

    $ test01 command_b yadah

=head1 DESCRIPTION

Some description of B<command B>

 some code
 some code

some more desc

=over

=item * item 1

=item * item 2

=over

=item * item 2.1

=item * item 2.2

=back

=back

hase ist so super and this is a very long sentence witch breaks after i have
written some bla bla.

another interesting paragraph.

=head1 METHODS

hase

=head2 SUB A

bär

=head1 SUB B

some methods

=cut

1;

package Test01::CommandB;

use Moose;
use MooseX::App::Command;
extends qw(Test01);

has 'email' => (
    isa         => 'Str',
    is          => 'rw',
);


=encoding utf8

=head1 NAME

Test01::CommandB - Test class command B for test 01

=head1 DESCRIPTION

Some description of B<command B>

=over

=item * item 1

=item * item 2

=back

=head2 SUB A

hase

=head2 SUB B

bär

=head1 METHODS

some methods

=cut

1;
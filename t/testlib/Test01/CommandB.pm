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
    use Data::Dumper;
    {
      local $Data::Dumper::Maxdepth = 2;
      warn __FILE__.':line'.__LINE__.':'.Dumper(shift);
    }
}

=encoding utf8

=head1 NAME

Test01::CommandB - Test class command B for test 01

=head1 DESCRIPTION

Some description of B<command B>

 some code
 some code

soe more desc

=over

=item * item 1

=item * item 2

=over

=item * item 2.1

=item * item 2.2

=back

=back

hase ist super

=head1 METHODS

hase

=head2 SUB A

bär

=head1 SUB B

some methods

=cut

1;
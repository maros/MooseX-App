package Test03::SomeCommand;

use MooseX::App::Command;
extends qw(Test03);
 
has 'some_option' => (
    is            => 'rw',
    isa           => 'Str',
    documentation => q[Very important option!],
);

has 'another_option' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
    cmd_flag      => 'another',
    cmd_tags      => ['Not important'],
);
 
sub run {
    my ($self) = @_;
    # Do something
}

1;

=encoding utf8

=head1 NAME

Test03::SomeCommand - Some command description

=head1 DESCRIPTION

Some long command description

=cut

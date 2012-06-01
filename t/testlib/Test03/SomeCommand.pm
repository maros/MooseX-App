package Test03::SomeCommand;

use MooseX::App::Command;
extends qw(Test03);
with qw(Test03::Role::TestRole);
 
option 'some_option' => (
    is            => 'rw',
    isa           => 'Str',
    documentation => q[Very important option!],
);

option 'another_option' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
    cmd_flag      => 'another',
    cmd_tags      => ['Not important'],
);
 
sub run {
    my ($self) = @_;
    print "RUN";
}

1;

=encoding utf8

=head1 NAME

Test03::SomeCommand - Some command description

=head1 DESCRIPTION

Some long command description

=cut

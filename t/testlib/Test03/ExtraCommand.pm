package Test03::ExtraCommand;

use MooseX::App::Command;

parameter 'extra1' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
    documentation => q[Important extra parameter],
);

parameter 'extra2' => (
    is            => 'rw',
    isa           => 'Int',
);

option 'value' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
    default       => sub { return "hase" },
);

sub run {
    my ($self) = @_;
    use Data::Dumper;
    {
      local $Data::Dumper::Maxdepth = 2;
      warn __FILE__.':line'.__LINE__.':'.Dumper($self);
    }
}

1;
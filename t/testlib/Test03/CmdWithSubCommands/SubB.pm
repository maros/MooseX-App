package Test03::CmdWithSubCommands::SubB;

use MooseX::App::Command;

sub run {
    my ($self) = @_;
    use Data::Dumper;
    {
      local $Data::Dumper::Maxdepth = 2;
      warn __FILE__.':line'.__LINE__.':'.Dumper($self);
    }
}

1;

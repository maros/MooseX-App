package MyApp {
use MooseX::App qw(Term);
};

package MyApp::SomeCommand {
    use 5.020;
    use MooseX::App::Command;
    extends qw(MyApp);
 
option 'some_option' => (
    is             => 'rw',
    isa            => 'Int',
    documentation  => 'Something',
    cmd_term       => 1,
);
  
  sub run {
          my ($self) = @_;
              say "Some option is ".$self->some_option;
  }
};

MyApp->new_with_command->run;

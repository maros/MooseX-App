# -*- perl -*-

# t/13_rt_112156.t - RT112156 inheritance

use Test::Most tests => 1+1;
use Test::NoWarnings;

use lib 't/testlib';

{
    package Test13;
    use MooseX::App qw(Depends);
    
    option 'unrelated' => (
        is             => 'rw',
        isa            => 'Int',
        documentation  => 'One thing',
    );
}

{
    package Test13::SomeCommand;
    use MooseX::App::Command;
    # no inheritance
    
    option 'one' => (
        is             => 'rw',
        isa            => 'Int',
        documentation  => 'One thing',
        depends        => ['other'],
    );
    
    option 'other' => (
        is             => 'rw',
        isa            => 'Int',
        documentation  => 'Other thing',
    );
    
    sub run {
        my ($self) = @_;
        return "ok";
    }
}

{
    package Test13::AnotherCommand;
    use MooseX::App::Command;
    extends qw(Test13);
    
    option 'one' => (
        is             => 'rw',
        isa            => 'Int',
        documentation  => 'One thing',
        depends        => ['other'],
    );
    
    option 'other' => (
        is             => 'rw',
        isa            => 'Int',
        documentation  => 'Other thing',
    );
    
    sub run {
        my ($self) = @_;
        return "ok";
    }
}
 
subtest 'no inheritance' => sub {
   plan tests => 2;

   {
      MooseX::App::ParsedArgv->new(argv => [qw(some --one 1 --other 2)]);
      my $test01 = Test13->new_with_command();
      isa_ok($test01,'Test13::SomeCommand');
   }
   
   {
      MooseX::App::ParsedArgv->new(argv => [qw(another --one 1 --other 2)]);
      my $test02 = Test13->new_with_command();
      isa_ok($test02,'Test13::AnotherCommand');
   }
};

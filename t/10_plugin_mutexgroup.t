# -*- perl -*-

# t/10_plugin_mutexgroup.t - Test MutexGroup

use Test::Most tests => 1+1;
use Test::NoWarnings;

use lib 't/testlib';
use testlib;

{
    package Test10;
    use MooseX::App::Simple qw(MutexGroup);

    option 'UseAmmonia' => (
       is         => 'ro',
       isa        => 'Bool',
       mutexgroup => 'NonMixableCleaningChemicals',
    );

    option 'UseChlorine' => (
       is         => 'ro',
       isa        => 'Bool',
       mutexgroup => 'NonMixableCleaningChemicals'
    );

    has 'private_option' => (
       is      => 'ro',
       isa     => 'Int',
       default => 0,
    );

    sub run {
        print "ok";
    }
}

testlib::run_testclass('Test10');

subtest 'MutexGroup' => sub {
    plan tests => 7;

    {
       my $test01 = Test10->new_with_options( UseAmmonia => 1, UseChlorine => 1 );
       isa_ok( $test01, 'MooseX::App::Message::Envelope' );

       my @errors = grep { $_->block =~ /<headline=error>/ } @{ $test01->blocks };
       is( scalar @errors, 1, 'only returned a single error' );
       like( $errors[0]->block,
           qr/Options UseAmmonia and UseChlorine are mutally exclusive/,
           'generated an error when more than one option in the same mutexgroup is initialized'
       );
    }

    {
       my $test02 = Test10->new_with_options();
       isa_ok( $test02, 'MooseX::App::Message::Envelope' );

       my @errors = grep { $_->block =~ /<headline=error>/ } @{ $test02->blocks };
       is( scalar @errors, 1, 'only returned a single error' );
       like( $errors[0]->block,
           qr/Either UseAmmonia or UseChlorine must be specified/,
           'generated an error when no options in the same mutexgroup are initialized'
       );
    }

    {
       my $test03 = Test10->new_with_options( UseAmmonia => 1 );
       ok( $test03->isa('Test10'),
           'generated no errors when only a single option from the same mutexgroup is initialized'
       );
    }
};

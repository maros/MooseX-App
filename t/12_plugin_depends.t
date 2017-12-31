# -*- perl -*-

# t/12_plugin_depends.t - Test Depends

use Test::Most tests => 1+1;
use Test::NoWarnings;

use lib 't/testlib';
use testlib;

{
    package Test12;

    use MooseX::App::Simple qw(MutexGroup Depends);
    use Moose::Util::TypeConstraints;

    option 'FileFormat' => (
       is  => 'ro',
       isa => enum([qw(csv tsv xml)]),
    );

    option 'WriteToFile' => (
       is         => 'ro',
       isa        => 'Bool',
       mutexgroup => 'FileOp',
       depends    => [qw(FileFormat)],
    );

    option 'ReadFromFile' => (
       is         => 'ro',
       isa        => 'Bool',
       mutexgroup => 'FileOp',
       depends    => [qw(FileFormat)],
    );

    has 'private_option' => (
       is      => 'ro',
       isa     => 'Int',
       default => 0,
    );

}

testlib::run_testclass('Test12');

subtest 'Depends' => sub {
    plan tests => 8;

    {
        my $test01 = Test12->new_with_options( WriteToFile => 1 );
        isa_ok( $test01, 'MooseX::App::Message::Envelope' );

        my @errors = grep { $_->block =~ /<headline=error>/ } @{ $test01->blocks };
        is( scalar @errors, 1, 'only returned a single error' );
        like( $errors[0]->block,
            qr/Option 'WriteToFile' requires 'FileFormat' to be defined/,
            'generated an error when an option dependency was not present'
        );
    }

    {
        my $test02 = Test12->new_with_options( ReadFromFile => 1 );
        isa_ok( $test02, 'MooseX::App::Message::Envelope' );

        my @errors = grep { $_->block =~ /<headline=error>/ } @{ $test02->blocks };
        is( scalar @errors, 1, 'only returned a single error' );
        like( $errors[0]->block,
            qr/Option 'ReadFromFile' requires 'FileFormat' to be defined/,
            'generated an error when an option dependency was not present'
        );
    }

    {
        my $test03 = Test12->new_with_options( WriteToFile => 1, FileFormat => 'tsv' );
        ok( ! $test03->can('blocks'),
            'generated no errors when both an option and its dependencies are defined'
        );
    }

    {
        my $test04 = Test12->new_with_options( ReadFromFile => 1, FileFormat => 'tsv' );
        ok( ! $test04->can('blocks'),
            'generated no errors when both an option and its dependencies are defined'
        );
    }
};

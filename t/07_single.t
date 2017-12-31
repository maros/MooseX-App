# -*- perl -*-

# t/07_single.t- Test MooseX::App::Single

use Test::Most tests => 3+1;
use Test::NoWarnings;

use lib 't/testlib';
use testlib;

{
    package Test07;

    #use Moose;
    use MooseX::App::Simple qw(Config);
    app_fuzzy 1;

    option 'some_option' => (
        is            => 'rw',
        isa           => 'Bool',
        documentation => q[Enable this to do fancy stuff],
    );

    option 'another_option' => (
        is            => 'rw',
        isa           => 'Str',
        documentation => q[Enable this to do fancy stuff],
        required      => 1,
        cmd_env       => 'ANOTHER',
    );

    sub run {
        my ($self) = @_;
        print "OK";
    }

=head1 DESCRIPTION

this is how we use this command

=cut

}

testlib::run_testclass('Test07');

subtest 'Single command' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw()]);
    my $test07 = Test07->new_with_options;
    isa_ok($test07,'MooseX::App::Message::Envelope');
    like($test07->blocks->[0]->block,qr/Required option 'another_option' missing/,"Check for error message");
};

subtest 'Single command' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(--another_option 123)]);
    my $test07 = Test07->new_with_options({ some_option => 1 });
    isa_ok($test07,'Test07');
    is($test07->another_option,'123','Arg from command ARGV');
    is($test07->some_option,1,'Arg from new_with_options');
};

subtest 'Single command help' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(--help)]);
    my $test07 = Test07->new_with_options();
    isa_ok($test07,'MooseX::App::Message::Envelope');
    like($test07->blocks->[0]->block,qr/usage:/,"Usage header is first");
};

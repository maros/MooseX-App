# -*- perl -*-

# t/05_extended.t - Extended tests

use Test::Most tests => 8+1;
use Test::NoWarnings;

use FindBin qw();
use lib 't/testlib';

use Test03;

Test03->meta->app_fuzzy(0);

subtest 'Non-Fuzzy command matching' => sub {
    local @ARGV = qw(some --private 1);
    my $test01 = Test03->new_with_command;
    isa_ok($test01,'MooseX::App::Message::Envelope');
    is($test01->blocks->[0]->header,"Unknown command: some","Message ok");
};

subtest 'Non-Fuzzy attribute matching' => sub {
    local @ARGV = qw(some_command --private 1);
    my $test01 = Test03->new_with_command;
    isa_ok($test01,'MooseX::App::Message::Envelope');
    is($test01->blocks->[0]->header,"Unknown option: private","Message ok");
};

Test03->meta->app_fuzzy(1);

subtest 'Private option is not exposed' => sub {
    local @ARGV = qw(some --private 1);
    my $test01 = Test03->new_with_command;
    isa_ok($test01,'MooseX::App::Message::Envelope');
    is($test01->blocks->[0]->header,"Unknown option: private","Message ok");
    is($test01->blocks->[0]->type,"error",'Message is of type error');
};

subtest 'Options from role' => sub {
    local @ARGV = qw(some --another 10 --role 15);
    my $test02 = Test03->new_with_command;
    isa_ok($test02,'Test03::SomeCommand');
    is($test02->another_option,'10','Param is set');
    is($test02->roleattr,'15','Role param is set');
};

subtest 'Missing attribute value' => sub {
    local @ARGV = qw(some --another);
    my $test03 = Test03->new_with_command;
    isa_ok($test03,'MooseX::App::Message::Envelope');
    is($test03->blocks->[0]->header,"Option another requires an argument","Message ok");
    is($test03->blocks->[0]->type,"error",'Message is of type error');
};

subtest 'All options available & no description' => sub {
    local @ARGV = qw(some --help);
    my $test03 = Test03->new_with_command;
    isa_ok($test03,'MooseX::App::Message::Envelope');
    is($test03->blocks->[1]->header,'options:','No description');
    is($test03->blocks->[1]->body,"    --another          [Required; Not important]
    --global_option    Enable this to do fancy stuff [Flag]
    --help --usage -?  Prints this usage information. [Flag]
    --roleattr         [Role]
    --some_option      Very important option!","Message ok");
};

subtest 'Test wrapper script error' => sub {
    my $output = `$^X $FindBin::Bin/example/test03.pl some`;
    like($output,qr/Required option missing: another|Mandatory parameter 'another' missing/,'Output is ok');
};

subtest 'Test wrapper script encoding' => sub {
    my $output = `LANG=en_US.UTF-8 $^X $FindBin::Bin/example/test03.pl some_command --another töst\\ möre --some_option "anöther täst"`;
    is($output,'RUN:anöther täst:töst möre','Encoded output');
}

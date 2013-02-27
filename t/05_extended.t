# -*- perl -*-

# t/05_extended.t - Extended tests

use Test::Most tests => 15+1;
use Test::NoWarnings;

use FindBin qw();
use lib 't/testlib';

use Test03;

Test03->meta->app_fuzzy(0);

subtest 'Non-Fuzzy command matching' => sub {
    local @ARGV = qw(some --private 1);
    my $test01 = Test03->new_with_command;
    isa_ok($test01,'MooseX::App::Message::Envelope');
    is($test01->blocks->[0]->header,"Unknown command 'some'","Message ok");
};

subtest 'Non-Fuzzy attribute matching' => sub {
    local @ARGV = qw(somecommand --private 1);
    my $test01 = Test03->new_with_command;
    isa_ok($test01,'MooseX::App::Message::Envelope');
    is($test01->blocks->[0]->header,"Unknown option 'private'","Message ok");
};

Test03->meta->app_fuzzy(1);

subtest 'Private option is not exposed' => sub {
    local @ARGV = qw(some --private 1);
    my $test01 = Test03->new_with_command;
    isa_ok($test01,'MooseX::App::Message::Envelope');
    is($test01->blocks->[0]->header,"Unknown option 'private'","Message ok");
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
    is($test03->blocks->[0]->header,"Missing value for 'another'","Message ok");
    is($test03->blocks->[0]->type,"error",'Message is of type error');
};

subtest 'All options available & no description' => sub {
    local @ARGV = qw(some --help);
    my $test04 = Test03->new_with_command;
    isa_ok($test04,'MooseX::App::Message::Envelope');
    is($test04->blocks->[1]->header,'options:','No description');
    is($test04->blocks->[1]->body,"    --another             [Required; Not important]
    --global_option       Enable this to do fancy stuff [Flag]
    --help -h --usage -?  Prints this usage information. [Flag]
    --roleattr            [Role]
    --some_option         Very important option!","Message ok");
};

subtest 'Test wrapper script error' => sub {
    my $output = `$^X $FindBin::Bin/example/test03.pl some`;
    like($output,qr/equired option 'another' missing/,'Output is ok');
};

# Not working on cpan testers
#subtest 'Test wrapper script encoding' => sub {
#    my $output = `LANG=en_US.UTF-8 $^X $FindBin::Bin/example/test03.pl some_command --another töst\\ möre --some_option "anöther täst"`;
#    is($output,'RUN:anöther täst:töst möre','Encoded output');
#}

subtest 'Test type constraints integer' => sub {
    local @ARGV = qw(another --int 1a);
    my $test05 = Test03->new_with_command;
    isa_ok($test05,'MooseX::App::Message::Envelope');
    is($test05->blocks->[0]->header,"Invalid value for 'integer'","Message ok");
};

subtest 'Test type constraints hash' => sub {
    local @ARGV = qw(another --hash xx);
    my $test06 = Test03->new_with_command;
    isa_ok($test06,'MooseX::App::Message::Envelope');
    is($test06->blocks->[0]->header,"Invalid value for 'hash'","Message ok");
};

subtest 'Test type constraints number' => sub {
    local @ARGV = qw(another --number 2a);
    my $test07 = Test03->new_with_command;
    isa_ok($test07,'MooseX::App::Message::Envelope');
    is($test07->blocks->[0]->header,"Invalid value for 'number'","Message ok");
};

subtest 'Test type constraints custom1' => sub {
    local @ARGV = qw(another --custom1 9);
    my $test08 = Test03->new_with_command;
    isa_ok($test08,'MooseX::App::Message::Envelope');
    is($test08->blocks->[0]->header,"Invalid value for 'custom1'","Message ok");
};

subtest 'Test pass type constraints' => sub {
    local @ARGV = qw(another --hash key1=value1 --hash key2=value2 --integer 10 --number 10.10 --custom1 11 --custom2 test --extra1 wurtsch);
    my $test09 = Test03->new_with_command;
    isa_ok($test09,'Test03::AnotherCommand');
    is($test09->hash->{key1},"value1","Hash ok");
    is($test09->hash->{key2},"value2","Hash ok");
    is($test09->integer,10,"Integer ok");
    is($test09->custom1,11,"Custom type 1 ok");
    is(ref($test09->custom2),'SCALAR',"Custom type 2 ok");
    is(${$test09->custom2},'test',"Custom type 2 ok");
    is($test09->extra1,'wurtsch',"Attr set ok");
};

subtest 'Test ambiguous options' => sub {
    local @ARGV = qw(another --custom 1 --custom 2);
    my $test10 = Test03->new_with_command;
    isa_ok($test10,'MooseX::App::Message::Envelope');
    is($test10->blocks->[0]->header,"Ambiguous option 'custom'","Message ok");
    like($test10->blocks->[0]->body,qr/Could be
    custom1  
    custom2/,"Message ok");
};

subtest 'Test flags & defaults' => sub {
    local @ARGV = qw(yet --bool3);
    my $test11 = Test03->new_with_command;
    isa_ok($test11,'Test03::YetAnotherCommand');
    is($test11->bool1,undef,'Bool1 flag is undef');
    is($test11->bool2,1,'Bool2 flag is set');
    is($test11->bool3,1,'Bool3 flag is set');
    is($test11->value,'hase','Value is default');
};

subtest 'Test more flags & defaults' => sub {
    local @ARGV = qw(yet --bool3 -ab --value baer);
    my $test11 = Test03->new_with_command;
    isa_ok($test11,'Test03::YetAnotherCommand');
    is($test11->bool1,1,'Bool1 flag is undef');
    is($test11->bool2,0,'Bool2 flag is unset');
    is($test11->bool3,1,'Bool3 flag is set');
    is($test11->value,'baer','Value is set');
};
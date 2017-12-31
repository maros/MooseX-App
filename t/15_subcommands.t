# -*- perl -*-

# t/15_subcommands.t

use strict;
use warnings;

use Test::More tests => 3+1;
use Test::NoWarnings;

use lib 't/testlib';
use testlib;

{
    package Test15;
    use MooseX::App;
}

{
    package Test15::Foo;
    use MooseX::App::Command;
    sub run { "running foo" }

    command_short_description "Toplevel command";
}

{
    package Test15::Foo::Bar;
    use MooseX::App::Command;
    sub run { "running bar" }

    command_short_description "Bar subcommand";
}

{
    package Test15::Foo::Baz;
    use MooseX::App::Command;
    sub run { "running baz" }

    command_short_description "Baz subcommand";
}

testlib::run_testclass('Test15');

subtest 'Basic Subcommands' => sub {
    isa_ok(Test15->new_with_command( ARGV => [ 'foo' ] ),'Test15::Foo');
    isa_ok(Test15->new_with_command( ARGV => [ 'foo','bar' ] ),'Test15::Foo::Bar');
    isa_ok(Test15->new_with_command( ARGV => [ 'foo','baz' ] ),'Test15::Foo::Baz');
    isa_ok(Test15->new_with_command( ARGV => [ 'foo','qux' ] ),'Test15::Foo');
};

subtest 'Help Subcommand' => sub {
    my $help = Test15->new_with_command( ARGV => [ 'help' ] );
    isa_ok($help,'MooseX::App::Message::Envelope');
    is($help->blocks->[2]->block,'<headline>available commands:</headline>
<paragraph><list>
<item><key>foo</key><description>Toplevel command</description></item>
<item><key>foo bar</key><description>Bar subcommand</description></item>
<item><key>foo baz</key><description>Baz subcommand</description></item>
<item><key>help</key><description>Prints this usage information</description></item>
</list></paragraph>', 'help text ok');
};

subtest 'Help Parent' => sub {
    my $help = Test15->new_with_command( ARGV => [ 'foo','--help' ] );
    isa_ok($help,'MooseX::App::Message::Envelope');
    is($help->blocks->[3]->block,'<headline>available subcommands:</headline>
<paragraph><list>
<item><key>bar</key><description>Bar subcommand</description></item>
<item><key>baz</key><description>Baz subcommand</description></item>
<item><key>help</key><description>Prints this usage information</description></item>
</list></paragraph>', 'subcommand list ok');
};
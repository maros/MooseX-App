# -*- perl -*-

# t/03_utils.t

use Test::Most tests => 3+1;
use Test::NoWarnings;

use MooseX::App::Utils;

subtest 'Class to command' => sub {
    is(MooseX::App::Utils::class_to_command('MyApp::Commands::Command','MyApp::Commands'),'command','Command ok');
    is(MooseX::App::Utils::class_to_command('MyApp::Commands::CommandSuper','MyApp::Commands'),'command_super','Command ok');
    is(MooseX::App::Utils::class_to_command('MyApp::Commands::CommandBA','MyApp::Commands'),'command_ba','Command ok');
};

subtest 'Format text' => sub {
    is(
        MooseX::App::Utils::format_text('Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec vitae lectus purus, quis dapibus orci. Proin mollis est in nisl congue vel ornare felis imperdiet.'),
'    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec vitae
    lectus purus, quis dapibus orci. Proin mollis est in nisl congue vel
    ornare felis imperdiet.',
        'Format text ok');
    is(
        MooseX::App::Utils::format_text('Loremipsumdolorsitamet,consecteturadipiscingelit.Namegetarcunecdolorbibendumblanditsitametnonipsum.'),
'    Loremipsumdolorsitamet,consecteturadipiscingelit.
    Namegetarcunecdolorbibendumblanditsitametnonipsum.',
        'Format text ok');
    is(
        MooseX::App::Utils::format_text('LoremipsumdolorsitametconsecteturadipiscingelitNamegetarcunecdolorbibendumblanditsitametnonipsum.'),
'    LoremipsumdolorsitametconsecteturadipiscingelitNamegetarcunecdolorbibendum
    blanditsitametnonipsum.',
        'Format text ok');
};

subtest 'Formater' => sub {
    
    my $list = MooseX::App::Utils::format_list(
        ['part1','Lorem ipsum dolor sit amet, consectetur adipiscing elit. vitae lectus purus, quis dapibus orci.'],
        ['part2_something','Lorem ipsum dolor sit amet, consectetur adipiscing elit.'],
        ['part3',''],
    );
    
    is(
        $list,
'    part1            Lorem ipsum dolor sit amet, consectetur adipiscing elit.
                     vitae lectus purus, quis dapibus orci.
    part2_something  Lorem ipsum dolor sit amet, consectetur adipiscing elit.
    part3            ',
        'Format list ok'
    );
};

# -*- perl -*-

# t/03_utils.t

use Test::More tests => 9+1;
use Test::NoWarnings;

use MooseX::App::Utils;

{
    explain "Class to/from command";
    
    is(MooseX::App::Utils::class_to_command('MyApp::Commands::Command','MyApp::Commands'),'command','Command ok');
    is(MooseX::App::Utils::class_to_command('MyApp::Commands::CommandSuper','MyApp::Commands'),'command_super','Command ok');
    is(MooseX::App::Utils::class_to_command('MyApp::Commands::CommandBA','MyApp::Commands'),'command_ba','Command ok');
    
    is(MooseX::App::Utils::command_to_class('command_ba','MyApp::Commands'),'MyApp::Commands::CommandBa','Command ok');
    is(MooseX::App::Utils::command_to_class('command','MyApp::Commands'),'MyApp::Commands::Command','Command ok');
}

{
    explain "Format text";
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
}

{
    
    my $list = MooseX::App::Utils::format_list(
        ['part1','Lorem ipsum dolor sit amet, consectetur adipiscing elit. vitae lectus purus, quis dapibus orci.'],
        ['part2_something','Lorem ipsum dolor sit amet, consectetur adipiscing elit.'],
        ['part3',''],
    );
    
    explain "Format list";
    is(
        $list,
'    part1            Lorem ipsum dolor sit amet, consectetur adipiscing elit.
                     vitae lectus purus, quis dapibus orci.
    part2_something  Lorem ipsum dolor sit amet, consectetur adipiscing elit.
    part3            ',
        'Format list ok'
    );
}

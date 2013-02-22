# -*- perl -*-

# t/03_utils.t

use Test::Most tests => 4+1;
use Test::NoWarnings;

use MooseX::App::Utils;
use MooseX::App::ParsedArgv;

subtest 'Class to command' => sub {
    is(MooseX::App::Utils::class_to_command('Command'),'command','Command ok');
    is(MooseX::App::Utils::class_to_command('CommandSuper'),'command_super','Command ok');
    is(MooseX::App::Utils::class_to_command('CommandBA'),'command_ba','Command ok');
    is(MooseX::App::Utils::class_to_command('CommandBA12'),'command_ba12','Command ok');
    is(MooseX::App::Utils::class_to_command('CommandBALow'),'command_ba_low','Command ok');
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

subtest 'Parser' => sub {
    my $parser = MooseX::App::ParsedArgv->instance();
    $parser->argv(['-hui','--help','--help','--test','1','baer','--test','2','--key=value1','--key=value2','-u','--','hase']);
    
    is($parser->extra->[0],'baer','Extra parsed ok');
    is($parser->extra->[1],'hase','Extra parsed ok');
    is(scalar @{$parser->extra},'2','Two extra values');
    is($parser->options->[0]->key,'h','Parsed -h flag');
    is($parser->options->[0]->has_values,0,'-h is flag');
    is($parser->options->[1]->key,'u','Parsed -u flag');
    is($parser->options->[1]->has_values,0,'-u is flag');
    is($parser->options->[2]->key,'i','Parsed -i flag');
    is($parser->options->[2]->has_values,0,'-i is flag');
    is($parser->options->[3]->key,'help','Parsed --help flag');
    is($parser->options->[3]->has_values,0,'--help is flag');
    is($parser->options->[4]->key,'test','Parsed --test option');
    is($parser->options->[4]->has_values,'2','--test has two values');
    is($parser->options->[4]->get_value(0),'1','--test first value ok');
    is($parser->options->[4]->get_value(1),'2','--test second value ok');
    is($parser->options->[5]->key,'key','Parsed --key option');
    is($parser->options->[5]->has_values,'2','--key has two values');
    is($parser->options->[5]->get_value(0),'value1','--key first value ok');
    is($parser->options->[5]->get_value(1),'value2','--key second value ok');
    is(scalar @{$parser->options},6,'Has 6 options/flags');
};
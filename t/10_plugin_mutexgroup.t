# -*- perl -*-

# t/10_plugin_various.t - Test MutexGroup

use Test::Exception;
use Test::Most tests => 1;

use lib 't/testlib';
use Test07;

subtest 'MutexGroup' => sub {
    plan tests => 3;
   
    throws_ok {
       Test07->new_with_options( UseAmmonia => 1, UseChlorine => 1 );
    } qr/More than one attribute from mutexgroup NonMixableCleaningChemicals/,
    'MutexGroup dies when more than one option in the same mutexgroup is initialized';

    throws_ok {
       Test07->new_with_options();
    } qr/One attribute from mutexgroup NonMixableCleaningChemicals/,
    'MutexGroup dies when no options in the same mutexgroup are initialized';

    lives_ok {
       Test07->new_with_options( UseAmmonia => 1 );
    } 'MutexGroup lives when only a single option from the same mutexgroup is initialized';
};

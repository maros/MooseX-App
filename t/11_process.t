# -*- perl -*-

# t/11_process.t - Test via subprocesses

use Test::Most tests => 1+1;
use Test::NoWarnings;

use FindBin qw();
use IPC::Open3 qw(open3);
use Symbol qw(gensym);

my $BASE = "$^X $FindBin::Bin/example";

subtest 'Test basic exit codes' => sub {
    SKIP: {
        skip "Cannot test on MSWin",7
            if $^O =~ /^MSWin/;
        skip "Cannot test on *BSD",7
            if $^O =~ /bsd$/;

        test_subprocess(
            bin     => 'test11.pl',
            exit    => 127,
            out     => '',
            err     => qr/Missing command/,
        );

        test_subprocess(
            bin     => 'test11.pl error',
            exit    => 25,
            err     => qr/XXX/,
        );

        test_subprocess(
            bin     => 'test11.pl version',
            exit    => 0,
            out     => qr/VERSION/,
            err     => '',
        );

        test_subprocess(
            bin     => 'test11.pl version',
            exit    => 0,
            out     => qr/VERSION/,
            err     => '',
        );

        test_subprocess(
            bin     => 'test11.pl record --help',
            exit    => 0,
            out     => qr/usage:/,
            err     => '',
        );

        test_subprocess(
            bin     => 'test11.pl record',
            exit    => 0,
            out     => qr/RAN/,
            err     => '',
        );

        test_subprocess(
            bin     => 'test11.pl record --notthere',
            exit    => 1,
            out     => '',
            err     => qr/Unknown option 'notthere'/,
        );
    }
};

sub test_subprocess {
    my (%params) = @_;
    $params{args} ||= [];

    my($in_fh, $out_fh, $err_fh, $out, $err, $pid, $exit);
    eval {
        # Set timeout
        local $SIG{ALRM} = sub { die('timeout') };
        alarm(3);

        $err_fh = gensym();
        $pid = open3(
            $in_fh, $out_fh, $err_fh,
            $BASE.'/'.$params{bin},
        );

        if (defined $pid) {
            waitpid($pid,0);
            $pid = undef;
            $exit = $? >> 8;

            $out = '';
            while(<$out_fh>) {
                $out .= $_;
            }

            $err = '';
            while(<$err_fh>) {
                $err .= $_;
            }

            # Compare exitcode
            if (exists $params{exit}) {
                is($exit,$params{exit},'Exitcode '.$params{bin}.' ok');
            }

            # Comare STDOUT
            if (exists $params{out}) {
                if (ref $params{out} eq 'Regexp') {
                    like($out,$params{out},'Output '.$params{bin}.' ok');
                } else {
                    is($out,$params{out},'Output '.$params{bin}.' ok');
                }
            }

            # Compare STDERR
            if (exists $params{err}) {
                if (ref $params{err} eq 'Regexp') {
                    like($err,$params{err},'Error '.$params{bin}.' ok');
                } else {
                    is($err,$params{err},'Error '.$params{bin}.' ok');
                }
            }
        } else {
            fail('Could not start process :'.$!);
        }

    };
    alarm(0);
    kill 'KILL', $pid
        if defined $pid;
    if ($@ ) {
        # Kill pid if still there
        fail('Error running '.$params{bin}.' :'.($@ || 'unknown'));
        return;
    }


    return;
}
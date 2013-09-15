use strict;
use warnings;
use Test::More tests => 8;
use File::Slurp;
use POSIX;

use DDP;

my $t = time;

$ENV{_SMD_pid} = 't/_smd_t_pid_'.$t;
$ENV{_SMD_outfile} = 't/_smd_t_outfile_'.$t;
$ENV{_SMD_errfile} = 't/_smd_t_errfile_'.$t;
$ENV{_SMD_frequency} = 4;

my $dc = require 'system_monitor_d.pl';

diag('Test to check if log file has the expected data.');
{
    $dc->do_start;
    $dc->do_status;
    my $outlog = read_file( "t/_smd_t_outfile_$t", array_ref => 1);
    my @outlog = split ' ', $outlog->[0];
    my $pid = read_file( "t/_smd_t_pid_$t");
    is($outlog[0], ( strftime "%F", localtime ),'Date is expected');
    is($outlog[1], ( strftime "%H:%M:%S", localtime ), 'Hour is equal to expected');
    is($outlog[2], $pid, "Pid is equal to expect");
    is($outlog[3], (uname)[1], 'Hostname is equal to expected');
    like($outlog[4], qr/avg1:\d+\.\d+/, "Load avg is expected");
    like($outlog[7], qr/\w+\:\d+\.\d+\.\d+\.\d+/,"IP is expected");
    like($outlog[8], qr/\w+:\w+:\w+:\w+:\w+:\w+/,"MacAddress is expected");
    $dc->do_stop;
    $dc->do_start;
    $dc->do_stop;
    unlink("t/_smd_t_outfile_$t");
}

diag('Test to check if daemon is still running after some time');
$dc->do_start;
diag('Lets wait 10 seconds');
sleep 10;
{
    my $outlog = read_file( "t/_smd_t_outfile_$t", array_ref => 1);
    cmp_ok($outlog,'>' ,2, 'I have multiple lines in my log');
    $dc->do_stop;
    unlink("t/_smd_t_outfile_$t");
}

done_testing;

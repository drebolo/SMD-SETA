#!/usr/bin/env perl

use 5.012;
use strict;
use warnings;

use Config::Simple;
use Daemon::Control;
use POSIX;
use Net::Ifconfig::Wrapper;
use Sys::Statistics::Linux;

my $cfg = new Config::Simple('system_monitor.conf');

#options are read from the configuration file or 
#revert to default values if not any configuration
my $frequency = ( $cfg && $cfg->param('frequency') ) || 10;
my $outfile = ( $cfg && $cfg->param('outfile')) || 'outfile.log';
my $errfile = ( $cfg && $cfg->param('errfile')) || 'errfile';
my $pidfile = ( $cfg && $cfg->param('pidfile')) || 'pidfile';
my $output_format = ($cfg && $cfg->param('output_format')) || 'plain';
if ($output_format ne 'plain') {
    die "output_format should be 'plain' or 'json' " if $output_format ne 'json';
    eval {
        require JSON;
        JSON->import;
    };
    die "you need to install JSON to use json as output format" if $@;
}
my $out_order = [qw /timestamp pid hostname loadavg netstats network_adaptors/];
if ($cfg && $cfg->param('output_order') ) {
    $out_order = [ split '\s+', ($cfg->param('output_order')) ];
}

if ( caller && caller[1] =~ /system_monitor_d.t/) {
    $outfile = $ENV{_SMD_outfile};
    $errfile = $ENV{_SMD_errtfile};
    $pidfile = $ENV{_SMD_pid};
    $frequency = $ENV{_SMD_frequency};
}

my $lxs = Sys::Statistics::Linux->new(loadavg  => 1);
my $Info = Net::Ifconfig::Wrapper::Ifconfig('list');

sub format_output {
    my ($data_out) = @_;
    
    if ($output_format eq 'json') {
        print to_json($data_out) . "\n";
    }
    else {
        my $str = "";
        foreach my $e (@$out_order) {
            next if not $data_out->{$e};
            if ( $e eq 'loadavg' ) {
                $str .=
                    "avg1:$data_out->{$e}{avg_1} "
                . "avg5:$data_out->{$e}{avg_5} "
                . "avg15:$data_out->{$e}{avg_15} ";
            }
            elsif ( $e eq 'network_adaptors' ) {
                foreach my $a ( keys %{ $data_out->{$e} } ) {
                    if ( $data_out->{$e}{$a}{ether} && $data_out->{$e}{$a}{inet} ) {
                        $str .= "$a:"
                        . ( join ",", ( keys %{ $data_out->{$e}{$a}{inet} } ) )
                        . " $data_out->{$e}{$a}{ether} ";
                    }
                }
            }
            else {
                $str .= "$data_out->{$e} ";
            }
        }
        $str =~ s/\s*$//g;
        print "$str;\n";
    }
}

my $get_info = sub {
    while (1) {
        my $data_out = {
            pid              => $$,
            timestamp        => ( strftime "%F %T", localtime ),
            hostname         => (uname)[1],
            loadavg          => { %{ $lxs->get->loadavg } },
            network_adaptors => $Info
        };
        format_output($data_out);
        sleep $frequency;
    }
};

my $dc = Daemon::Control->new(
    {
        program     => $get_info,
        stderr_file => $errfile,
        stdout_file => $outfile,
        fork        => 2,
        pid_file    => $pidfile,
        name        => 'system_monitor_d'
    }
);
if (caller && caller[1] =~ /system_monitor_d.pl/) {
    return $dc;
}
else {
    $dc->run;
}

=head1 NAME

system_monitor_d - A small daemon to check system status

=head1 SYNOPSIS

perl system_monitor_d.pl [start|stop|restart|reload|status|show_warnings|get_init_file|help]

=head1 DESCRIPTION

A configuration file 'system_monitor.conf' can be used to change default values.

=head1 VERSION

This man page documents "system_monitor_d.pl" version 0.001.

=head1 AUTHOR

Dinis Rebolo
dinisrebolo@gmail.com

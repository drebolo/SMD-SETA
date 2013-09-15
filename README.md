SMD-SETA
========

*system_monitor_d* - A small daemon to check system status

Install
-------

To install all depencies do:

cpanm -v --installdeps .

Execute daemon
--------------

perl system_monitor_d.pl [start|stop|restart|reload|status|show_warnings|get_init_file|help]

By default 3 files are created:
    a logfile "out_file.log" (is updated every 10 seconds).
    a error log "err_file.log"
    a pidfile

Run Tests
---------

perl|prove t/system_monitor_d.t

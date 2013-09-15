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

Run Tests
---------

perl|prove t/system_monitor_d.t

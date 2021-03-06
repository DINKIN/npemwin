#!%TCLSH%
#
# $Id$
#
# Usage: startstop <start|stop>
#
set usage {Usage: startstop <start|stop>};

set defaultsfile "/usr/local/etc/npemwin/filters.conf";
## The common defaults
if {[file exists $defaultsfile] == 0} {
    puts "$argv0 disabled: $defaultsfile not found.";
    return 1;
}
source $defaultsfile;

## The filter library
if {[file exists $gf(filterlib)] == 0} {
    puts "$argv0 disabled: $gf(filterlib) not found.";
    return 1;
}
source $gf(filterlib);

#
# Default schedule
#
set startstop(rc) "startstop.rc";

# Location (use the last one found)
set startstop(confdirs) [linsert $gf(localconfdirs) 0 $gf(confdir)];

#
# main
#

set startstop(stage) "";
if {$argc == 1} {
    set startstop(stage) [lindex $argv 0];
}
if {($startstop(stage) ne "start") && ($startstop(stage) ne "stop")} {
    log_msg "$argv0 disabled: $usage";
    return 1;
}

set conffile "";
foreach _d $startstop(confdirs) {
    set _f [file join ${_d} $startstop(rc)]; 
    if {[file exists ${_f}]} {
	set conffile ${_f};
    }
}
if {$conffile == ""} {
    log_msg "$startstop(rc) not found.";
    return 1;
}

set start [list];
set stop [list];
source $conffile;
eval set script_list \$$startstop(stage);

foreach script $script_list {

    # The eval causes the $program string to be split on blanks
    # in case there are options, and any variables to be substituted
    # by their value.

    set status [catch {
        eval $script;
    } errmsg];

    if {$status != 0} {
        log_msg $errmsg;
    }     
}

#!%TCLSH%
#
# $Id$
#
# Usage: nbspmtrplotdat [-o outputfile [-b basedir] [-d subdir]] \
#			[-m marker] [-n numpoints] [-r] [-s separator] \
#                       [-f datafile | station]
#
# Without options, the data is written to stdout. Otherwise, 
# the tool will cd to the "basedir", create "subdir", and save
# the data in <station>.<ext> or what is given in the [-o] option.
# By default, the number of points included is defined by the
# value of the variable $metarfilter(plotnumpoints).
# The number can be specified with [-n] option; if it is 0 or negative
# then all points are included. The [-m] option specifies
# a marker to use when the slp is missing. (See sanity_check() below.)
# The data is separated by a space, or by the character(s) in the -s option.
#
# If a station name given in the argument then the data file is searched
# in the "Metarweather" utility data directory. Otherwise a data file
# can be given with the -f option, in the same format:
#
#    TJSJ 020056Z 00000KT 10SM SCT031 BKN110 2 7/20 A2997
#    TJSJ 012356Z 07007KT 10SM SCT031 BKN110 2
#
# Without any argument, the program reads from stdin in that same format.
#
# The Metarweather files are assumed to be in reverse chronological order
# while any other data file (via -f) is assumed  to be in the standard
# chronological order. The -r option can be used to revert this interpretation
# in both cases.
#
package require fileutil;
package require cmdline;

set usage {nbspmtrplotdat [-o outputfile [-b basedir] [-d subdir]]
    [-n numpoints] [-f] [-r] [-s separator] <station|datafile>};

set optlist {f r {b.arg ""} {d.arg ""} {m.arg "na"}
    {n.arg ""} {o.arg ""} {s.arg ""}};

proc err {s} {

    global argv0;

    puts "Error: $s";
    exit 1;
}

proc sanity_check dataline {
#
# Check that the fields are non blank. Fields 0-7 are the importat ones.
# Field 8 is the slp but we do not use it in the plots so its check is
# omited ; if it missing a special marker (na) is substituted
# in the convert function.
#
    set fields [lrange [split $dataline ","] 0 end-1];
    foreach f $fields {
	if {$f eq ""} {
	    return 1;
	}
    }

    return 0;
}

proc convert_list {origlist numpoints slp_missing_mark OFS revert_order} {
#
# The data file is split into lines, and the list of lines is passed
# to this function. If the original file has the lines in reverse
# chronological order (metarweather file list) here we rearrange that and
# also eliminate lines that duplicate the data for a given hour.
# The function returns the new list, with each field separated by a space
# (for gnuplot). In addition to the original fields, two calculated
# fields are included at the end: pressure in mb, and relative humidity.
# Only the last $numpoints lines are included, unless it is 0 or negative.

    # Determine the field separator from the first line. If there are commas
    # we take FS to be a comma, otherwise a blank.
    set FS ",";
    if {[string match *,* [lindex $origlist 0]] == 0} {
	set FS " ";
    }

    set newlist [list];
    set i 0;
    foreach line $origlist {
	set a [split $line $FS];
	set hhmm [lindex $a 2];
	set ddhh [lindex $a 1][string range $hhmm 0 1];
	if {([info exists data($ddhh)] == 0) && ([sanity_check $line] == 0)} {
	    set data($ddhh) 1;
	    # If slp is missing insert a marker
	    set slp [lindex $a 8];
	    if {$slp eq ""} {
		set a [lreplace $a 8 8 $slp_missing_mark];
	    }
	    # Add the pressure in mb and relative humid at the end of the data.
	    # (We use two decimal places for the pressure.)
	    lappend a [format "%.2f" [expr [lindex $a 7] * 33.8639]];
	    lappend a [relative_humidity [lindex $a 5] [lindex $a 6]];

	    if {$revert_order == 1} {
		set newlist [linsert $newlist 0 [join $a $OFS]];
	    } else {
		lappend newlist [join $a $OFS];
	    }

	    incr i;

	    if {($numpoints > 0) && ($i == $numpoints)} {
		break;
	    }
	}
    }

    return $newlist;
}

proc relative_humidity {T D} {
#
# T and D are supplied in fahrenheit.
#
#########################################################################
# We use formulas based on those given in
#
# http://www.srh.noaa.gov/elp/wxcalc/formulas/rhTdFromWetBulb.html
#
# According to these, the relative humidity is given by
#
#	H = (e/e_s) * 100
#
# where
#
#	e = 6.112 * exp^{f(t)}
#
# and
#
#	e_s = 6.112 * exp^{f(d)}  (obtained by inverting their formula for T_d)
#
# with t and d here being T and D but expressed in degC. The function f(x)
# is given by
#
#	f(x) = \frac{bx}{a + x}
#
# with
#
#	b = 17.67
#	a = 243.5
#
# We first define (for X = T,D)
#
#	x = (5/9)*(X - 32)
#
#	F(X) = f(x) = f((5/9)*(X - 32))
#
# and then
#
#	H/100 = exp^{F(D) - F(T)}
#
# F(X) is given by
#
#	F(X) = \frac{9.82 X - 314.13}{225.72 + 0.56 X}
#########################################################################
    
    set FT [expr (9.82*$T - 314.13)/(225.72 + 0.56*$T)];
    set FD [expr (9.82*$D - 314.13)/(225.72 + 0.56*$D)];
    
    set H [expr $FD - $FT];
    set H [expr int(100*exp($H))];

    return $H;
}

## The common defaults
set _defaultsfile "/usr/local/etc/npemwin/filters.conf";
if {[file exists ${_defaultsfile}] == 0} {
    err "${_defaultsfile} not found.";
}
source ${_defaultsfile};
unset _defaultsfile;

# The default configuration is shared between the filter and cmd-line tools
# and therefore it is in a separate file that is read by both.
set metar_init_file [file join $gf(filterdir) metarfilter.init];
if {[file exists $metar_init_file] == 0} {
    err "$metar_init_file not found.";
}
source $metar_init_file;
unset metar_init_file;

array set option [::cmdline::getoptions argv $optlist $usage];
set argc [llength $argv];

set station "";
set datafile "";

if {$argc != 0} {
    if {$option(f) == 0} {
	set station [lindex $argv 0];
    } else {
	set datafile [lindex $argv 0];
    }
}

if {$station ne ""} {
    set dir [file join $metarfilter(datadir) $metarfilter(mwdir)];
    append fname $station $metarfilter(mwfext); 
    set datafile [exec find $dir -name $fname];
    if {$datafile eq ""} {
	err "$fname not found in $dir.";
    }
    set revert_order 1;
    if {$option(r) == 1} {
	set revert_order 0;
    }
} else {
    set revert_order 0;
    if {$option(r) == 1} {
	set revert_order 1;
    }
}

if {$option(s) ne ""} {
    set OFS $option(s);
} else {
    set OFS " ";
}

set numpoints $metarfilter(plotnumpoints);
if {$option(n) ne ""} {
    set numpoints $option(n);
}

if {$datafile ne ""} {
    set body [exec nbspmtrd -t -d $datafile];
} else {
    set body [exec nbspmtrd -t -d];
}

set lineslist [split $body "\n"];
set newlist [convert_list $lineslist $numpoints $option(m) $OFS $revert_order];
if {[llength $newlist] == 0} {
    err "No useful data in $datafile.";
}
set newbody [join $newlist "\n"];

if {($option(b) eq "") && ($option(d) eq "") && ($option(o) eq "")} {
    puts $newbody;
    exit 0;
}

if {$option(b) ne ""} {
    cd $option(b);
}

if {$option(d) ne ""} {    
    file mkdir $option(d);
    cd $option(d);
}

if {$option(o) eq ""} {
    set outputfile $station$metarfilter(plotdataext);
} else {
    set outputfile $option(o);
}

set status [catch {
    ::fileutil::writeFile $outputfile $newbody;
} errmsg];

if {$status != 0} {
    err $errmsg;
}

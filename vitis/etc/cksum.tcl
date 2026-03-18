#!/usr/bin/tclsh
#-------------------------------------------------------------------------------
#  Sensor to Image GmbH
#-------------------------------------------------------------------------------
#  TCL script to calculate checksum of a file.
#  Complementary tool for the GigE Vision IP core development environment.
#
#  Usage:
#    xtclsh cksum.tcl -b <filename>     : calculate checksum of a binary file
#    xtclsh cksum.tcl -x <filename>     : calculate checksum of a binary file
#                                         transferred using the XMODEM protocol
#-------------------------------------------------------------------------------
#  0.1  |  2014-01-27  |  JP  |  Initial release based on original Perl script,
#       |              |      |  discontinued ASCII mode support
#-------------------------------------------------------------------------------


# ---- Procedures --------------------------------------------------------------

# Print usage information
proc printhelp {} {
    puts "Usage: cksum.tcl -b <filename> for binary file"
    puts "       cksum.tcl -x <filename> for XMODEM file"
}


# ---- Main Program ------------------------------------------------------------

# Check number of arguments
if { $::argc != 2 } {
    printhelp
    exit -1
}

# Parse the arguments
switch -- [lindex $::argv 0] {
    -b {
        set mode "binary"
    }
    -x {
        set mode "XMODEM"
    }
    default {
        printhelp
        exit -1
    }
}
set name [lindex $::argv 1]

# Read the input file
if { [file exists $name] == 0 } {
    puts "File $name does not exist!"
    printhelp
    exit -1
}
set f [open $name r]
fconfigure $f -translation binary
set data [read $f]
close $f
binary scan $data c* bin

# Calculate the checksum
set sum 0
set len 0
foreach i $bin {
    set sum [expr {$sum + ($i & 0xFF)}]
    incr len
}

# Adjust results for XMODEM mode
if { $mode eq "XMODEM" } {
    set pad [expr {(128 - ($len % 128)) & 0x7F}]
    set sum [expr {$sum + ($pad * 26)}]
    set len [expr {$len +  $pad}]
}

# Print the results
puts "Filename = $name"
puts "Mode     = $mode"
puts "Length   = 0x[format %08X $len] ($len bytes)"
puts "Checksum = 0x[format %08X $sum] ($sum)"

#!/usr/bin/tclsh
#-------------------------------------------------------------------------------
#  Sensor to Image GmbH
#-------------------------------------------------------------------------------
#  TCL script to skip first bytes from a file. Used to convert FPGA bitsreams
#  to a raw binary form for programming configuration memories.
#  Complementary tool for the GigE Vision IP core development environment.
#
#  Usage:
#    xtclsh bit2bin.tcl <n> <infile> <outfile>
#
#  Parameters:
#    <n>        number of bytes to skip from file beginning
#    <infile>   input bitstream file
#    <outfile>  output binary file
#-------------------------------------------------------------------------------
#  0.1  |  2014-01-29  |  JP  |  Initial release
#-------------------------------------------------------------------------------


# ---- Procedures --------------------------------------------------------------

# Error message, usage information, and exit
proc err {{msg ""}} {
    if { $msg ne "" } {
        puts $msg
    }
    puts "Usage:"
    puts "  xtclsh bit2bin.tcl <n> <infile> <outfile>"
    puts "Parameters:"
    puts "  <n>        number of bytes to skip from file beginning"
    puts "  <infile>   input bitstream file"
    puts "  <outfile>  output binary file"
    exit -1
}


# ---- Main Program ------------------------------------------------------------

# Check number of arguments
if { $::argc != 3 } {
    err
}

# Get the arguments
set nskip [lindex $::argv 0]
set ifile [lindex $::argv 1]
set ofile [lindex $::argv 2]

# Read the input file
if { [file exists $ifile] == 0 } {
    err "File $ifile does not exist!"
}
set fd [open $ifile r]
fconfigure $fd -translation binary
seek $fd $nskip start
set data [read $fd]
close $fd
#binary scan $data c* bin

# Write the output file
set fd [open $ofile w]
fconfigure $fd -translation binary
puts -nonewline $fd $data
close $fd

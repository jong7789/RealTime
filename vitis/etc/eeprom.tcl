#!/usr/bin/tclsh
#-------------------------------------------------------------------------------
#  Sensor to Image GmbH
#-------------------------------------------------------------------------------
#  TCL script to generate the EEPROM image.
#  Complementary tool for the GigE Vision IP core development environment.
#
#  Usage:
#    xtclsh eeprom.tcl [options] -x <xml_file> -o <output>
#
#  Options:
#    -m     device MAC address in format hh:hh:hh:hh:hh:hh
#    -c     enabled IP configuration methods (1, 2, 4 and combinations)
#    -i     static IP address of the device in format d.d.d.d
#    -n     static network mask in format d.d.d.d
#    -g     static default gateway d.d.d.d
#    -p     GVCP UDP port number (1 to 65535)
#    -u     user defined device name, maximum length is 15 characters
#    -d     GVSP destination IP address for point-to-point operation
#    -s     GVSP UDP port number for point-to-point operation
#    -e     serial number of the device, maximum length 15 characters
#    -t     generate C source code instead of binary image
#    -v     verbose console output
#    -x     device description XML file (the file must exist)
#    -a     address of the XML file within GigE Vision address space
#    -r     number of image replications with increased MAC (default 1)
#    -o     output file containing EEPROM image
#  
#  Example:
#    eeprom.pl -m 00:0C:6B:00:01:2C -c 6 -i 192.168.2.50 -n 255.255.255.0      \
#              -g 192.168.2.1 -p 3956 -u "Test Device" -d 192.168.2.1 -s 49150 \
#              -e "SN_12345" -x device.xml -a FFA10000 -C dhcp_client_id       \
#              -o eeprom.bin
#-------------------------------------------------------------------------------
#  0.1  |  2014-01-28  |  JP  |  Initial release based on original Perl script,
#       |              |      |  discontinued long command line options, added
#       |              |      |  the -v option, unoccupied cells set to 0xFF   
#  0.2  |  2017-09-07  |  JP  |  No fixed array size in the output C source
#  0.3  |  2020-05-12  |  JP  |  New parameter -r to replicate the EEPROM image
#  0.4  |  2022-10-21  |  JP  |  Option -C for optional DHCP client-identifier
#-------------------------------------------------------------------------------


# ---- Procedures --------------------------------------------------------------

# Error message, usage information, and exit
proc err {{msg ""}} {
    if { $msg ne "" } {
        puts $msg
    }
    puts "Usage:"
    puts "  xtclsh eeprom.tcl \[options\] -x <xml_file> -o <output>"
    puts "Options:"
    puts "  -m     device MAC address in format hh:hh:hh:hh:hh:hh"
    puts "  -c     enabled IP configuration methods (1, 2, 4 and combinations)"
    puts "  -i     static IP address of the device in format d.d.d.d"
    puts "  -n     static network mask in format d.d.d.d"
    puts "  -g     static default gateway d.d.d.d"
    puts "  -p     GVCP UDP port number (1 to 65535)"
    puts "  -u     user defined device name, maximum length is 15 characters"
    puts "  -d     GVSP destination IP address for point-to-point operation"
    puts "  -s     GVSP UDP port number for point-to-point operation"
    puts "  -e     serial number of the device, maximum length 15 characters"
    puts "  -t     generate C source code instead of binary image"
    puts "  -v     verbose console output"
    puts "  -x     device description XML file (the file must exist)"
    puts "  -a     address of the XML file within GigE Vision address space"
    puts "  -r     number of image replications with increased MAC (default 1)"
    puts "  -C     DHCP client-identifier, maximum length is 254 characters"
    puts "  -o     output file containing EEPROM image"
    puts "Example:"
    puts "  xtclsh eeprom.tcl -m 00:0C:6B:00:01:2C -c 6 -i 192.168.2.50 -n 255.255.255.0 \\"
    puts "                    -g 192.168.2.1 -p 3956 -u \"TstDev\" -d 192.168.2.1 -s 49150 \\"
    puts "                    -e \"SN_12345\" -x device.xml -a FFA10000 -C dhcp_client_id \\"
    puts "                    -o eeprom.bin"
    exit -1
}

# Get command line parameter
proc getopt {_argv name {_var ""} {default ""}} {
    upvar 1 $_argv argv $_var var
    set pos [lsearch -regexp $argv ^$name]
    if {$pos>=0} {
        set to $pos
        if {$_var ne ""} {
            set var [lindex $argv [incr to]]
        }
        set argv [lreplace $argv $pos $to]
        return 1
    } else {
        if {[llength [info level 0]] == 5} {set var $default}
        return 0
    }
}

# Convert IPv4 string to list
proc ip2list {str retval} {
    upvar 1 $retval ret
    if {[scan $str %d.%d.%d.%d a b c d] == 4 &&
        0 <= $a && $a <= 255 && 0 <= $b && $b <= 255 &&
        0 <= $c && $c <= 255 && 0 <= $d && $d <= 255} {
        set ret [list $a $b $c $d]
        return 1
    } else {
        set ret {0 0 0 0}
        return 0
    }
}

# Convert MAC address string to list
proc mac2list {str retval} {
    upvar 1 $retval ret
    if {[scan $str %x:%x:%x:%x:%x:%x a b c d e f] == 6 &&
        0 <= $a && $a <= 0xff && 0 <= $b && $b <= 0xff &&
        0 <= $c && $c <= 0xff && 0 <= $d && $d <= 0xff &&
        0 <= $e && $e <= 0xff && 0 <= $f && $f <= 0xff} {
        set ret [list $a $b $c $d $e $f]
        return 1
    } else {
        set ret {0 0 0 0 0 0}
        return 0
    }
}

# Increment MAC address by one
proc macinc mac {
    set ret $mac
    for {set i 5} {$i >= 0} {incr i -1} {
        lset ret $i [expr [lindex $ret $i] + 1]
        if {[lindex ret $i] > 255} {
            lset ret $i 0
        } else {
            break
        }
    }
    return $ret
}


# ---- Main Program ------------------------------------------------------------

# EEPROM image size
set ee_size 8192

# EEPROM memory map
set ee_map_mac    0x0000
set ee_map_ipcfg  0x0007
set ee_map_ip     0x0014
set ee_map_net    0x0024
set ee_map_gw     0x0034
set ee_map_port   0x003A
set ee_map_uname  0x0040
set ee_map_dest   0x005C
set ee_map_stream 0x0062
set ee_map_serial 0x0064
set ee_map_id     0x0100
set ee_map_custom 0x1000
set ee_map_xml1   0x1C00
set ee_map_xml2   0x1E00

# EEPROM defaults
set ee_def_mac    {0x00 0x0C 0x6B 0x00 0x01 0x2C}
set ee_def_ipcfg  0x06
set ee_def_ip     {192 168 2 51}
set ee_def_net    {255 255 255 0}
set ee_def_gw     {192 168 2 1}
set ee_def_port   3956
set ee_def_uname  "\0"
set ee_def_dest   {0 0 0 0}
set ee_def_stream 0
set ee_def_serial "\0"
set ee_def_custom {239 192 0 1 239 192 0 2 239 192 0 3}
set ee_def_addr   "FFA10000"

# Parse the command line...
set temp ""
# ... XML file
if { [getopt argv -x ee_cmd_xml] == 0 } {
    err "No XML file specified!"
}
if { [file exists $ee_cmd_xml] == 0 } {
    puts "File $ee_cmd_xml does not exist!"
}
set ee_cmd_xsize [format "%08X" [file size $ee_cmd_xml]]
# ... output file
if { [getopt argv -o ee_cmd_out] == 0 } {
    err "No output file specified!"
}
if { $ee_cmd_out eq "" } {
    err "No output file specified!"
}
# ... MAC address
if { [getopt argv -m temp] == 0 } {
    set ee_cmd_mac $ee_def_mac
} else {
    if { [mac2list $temp ee_cmd_mac] == 0 } {
        err "Invalid MAC address $temp!"
    }
}
# ... enabled IP configuration
if { [getopt argv -c temp] == 0 } {
    set ee_cmd_ipcfg $ee_def_ipcfg
} else {
    set ee_cmd_ipcfg [expr {$temp + 0}]
}
# ... static IP address
if { [getopt argv -i temp] == 0 } {
    set ee_cmd_ip $ee_def_ip
} else {
    if { [ip2list $temp ee_cmd_ip] == 0 } {
        err "Invalid IP address $temp!"
    }
}
# ... static network mask
if { [getopt argv -n temp] == 0 } {
    set ee_cmd_net $ee_def_net
} else {
    if { [ip2list $temp ee_cmd_net] == 0 } {
        err "Invalid network mask $temp!"
    }
}
# ... static default gateway
if { [getopt argv -g temp] == 0 } {
    set ee_cmd_gw $ee_def_gw
} else {
    if { [ip2list $temp ee_cmd_gw] == 0 } {
        err "Invalid gateway IP address $temp!"
    }
}
# ... GVCP UDP port
if { [getopt argv -p temp] == 0 } {
    set ee_cmd_port $ee_def_port
} else {
    set ee_cmd_port [expr {$temp + 0}]
}
# ... user defined name
if { [getopt argv -u temp] == 0 } {
    set ee_cmd_uname $ee_def_uname
} else {
    if { [string length $temp] >= 16 } {
        set ee_cmd_uname [string range $temp 0 14]
    } else {
        set ee_cmd_uname $temp
    }
}
# ... GVSP destination IP address
if { [getopt argv -d temp] == 0 } {
    set ee_cmd_dest $ee_def_dest
} else {
    if { [ip2list $temp ee_cmd_dest] == 0 } {
        err "Invalid destination IP address $temp!"
    }
}
# ... GVSP UDP port
if { [getopt argv -s temp] == 0 } {
    set ee_cmd_stream $ee_def_stream
} else {
    set ee_cmd_stream [expr {$temp + 0}]
}
# ... serial number
if { [getopt argv -e temp] == 0 } {
    set ee_cmd_serial $ee_def_serial
} else {
    if { [string length $temp] >= 16 } {
        set ee_cmd_serial [string range $temp 0 14]
    } else {
        set ee_cmd_serial $temp
    }
}
# ... XML address
if { [getopt argv -a temp] == 0 } {
    set ee_cmd_addr $ee_def_addr
} else {
    if { [string length $temp] >= 8 } {
        set ee_cmd_addr [string range $temp [expr {[string length $temp] - 8}] [expr {[string length $temp] - 1}]]
    } else {
        set ee_cmd_addr [string range "00000000" 0 [expr {7 - [string length $temp]}]]$temp
    }
}
# ... number of replications
if { [getopt argv -r temp] == 0 } {
    set ee_cmd_repl 1
} else {
    set ee_cmd_repl [expr {$temp + 0}]
    if { $ee_cmd_repl < 1 } {
        set ee_cmd_repl 1
    }
}
# ... DHCP client-identifier
if { [getopt argv -C temp] == 0 } {
    set ee_cmd_idlen 0
    set ee_cmd_id ""
} else {
    set ee_cmd_idlen [string length $temp]
    if { $ee_cmd_idlen > 254 } {
        set ee_cmd_idlen 254
        set ee_cmd_id [string range $temp 0 254]
    } else {
        set ee_cmd_id $temp
    }
}
# ... text mode output
set ee_cmd_txt [getopt argv -t]
# ... verbose mode
set ee_cmd_verbose [getopt argv -v]
# ... custom data
set ee_cmd_custom $ee_def_custom

# Print the setup in verbose mode
if { $ee_cmd_verbose } {
    puts "========== EEPROM configuration =========="
    puts -nonewline "First MAC address : "
    foreach i $ee_cmd_mac {
        puts -nonewline "[format %02X $i] "
    }
    puts ""
    puts "IP configuration  : $ee_cmd_ipcfg"
    puts "Static IP address : $ee_cmd_ip"
    puts "Static netmask    : $ee_cmd_net"
    puts "Default gateway   : $ee_cmd_gw"
    puts "GVCP UDP port     : $ee_cmd_port"
    puts "User defined name : $ee_cmd_uname"
    puts "GVSP destination  : $ee_cmd_dest"
    puts "GVSP UDP port     : $ee_cmd_stream"
    puts "Serial number     : $ee_cmd_serial"
    puts "Custom data       : $ee_cmd_custom"
    puts "XML file          : $ee_cmd_xml"
    puts "XML address       : $ee_cmd_addr"
    puts "Number of images  : $ee_cmd_repl"
    puts "DHCP client ID    : $ee_cmd_id"
}

# Loop through all images
for {set repl 0} {$repl < $ee_cmd_repl} {incr repl} {
    # Prepare the memory array...
    for {set i 0} {$i < $ee_size} {incr i} {
        set mem([expr {($repl * $ee_size) + $i}]) [expr {0xFF + 0}]
    }
    # ... MAC address
    set i [expr {$ee_map_mac + ($repl * $ee_size)}]
    foreach n $ee_cmd_mac {
        set mem($i) $n
        incr i
    }
    set ee_cmd_mac [macinc $ee_cmd_mac]
    # ... IP configuration
    set mem([expr {$ee_map_ipcfg + ($repl * $ee_size)}]) $ee_cmd_ipcfg
    # ... static IP address
    set i [expr {$ee_map_ip + ($repl * $ee_size)}]
    foreach n $ee_cmd_ip {
        set mem($i) $n
        incr i
    }
    # ... static network mask
    set i [expr {$ee_map_net + ($repl * $ee_size)}]
    foreach n $ee_cmd_net {
        set mem($i) $n
        incr i
    }
    # ... static default gateway
    set i [expr {$ee_map_gw + ($repl * $ee_size)}]
    foreach n $ee_cmd_gw {
        set mem($i) $n
        incr i
    }
    # ... GVCP UDP port
    set mem([expr {$ee_map_port + ($repl * $ee_size)    }]) [expr {($ee_cmd_port >> 8) & 0xFF}]
    set mem([expr {$ee_map_port + ($repl * $ee_size) + 1}]) [expr { $ee_cmd_port       & 0xFF}]
    # ... user defined name
    set i [expr {$ee_map_uname + ($repl * $ee_size)}]
    foreach n [split $ee_cmd_uname {}] {
        set mem($i) [scan $n %c]
        incr i
    }
    set mem($i) 0
    # ... GVSP destination IP address
    set i [expr {$ee_map_dest + ($repl * $ee_size)}]
    foreach n $ee_cmd_dest {
        set mem($i) $n
        incr i
    }
    # ... GVSP UDP port
    set mem([expr {$ee_map_stream + ($repl * $ee_size)    }]) [expr {($ee_cmd_stream >> 8) & 0xFF}]
    set mem([expr {$ee_map_stream + ($repl * $ee_size) + 1}]) [expr { $ee_cmd_stream       & 0xFF}]
    # ... serial number
    set i [expr {$ee_map_serial + ($repl * $ee_size)}]
    foreach n [split $ee_cmd_serial {}] {
        set mem($i) [scan $n %c]
        incr i
    }
    set mem($i) 0
    # ... customer specific
    set i [expr {$ee_map_custom + ($repl * $ee_size)}]
    foreach n $ee_cmd_custom {
        set mem($i) $n
        incr i
    }
    # ... XML file
    set i [expr {$ee_map_xml1 + ($repl * $ee_size)}]
    foreach n [split "Local:[file tail $ee_cmd_xml];$ee_cmd_addr;$ee_cmd_xsize" {}] {
        set mem($i) [scan $n %c]
        incr i
    }
    set mem($i) 0
    set i [expr {$ee_map_xml2 + ($repl * $ee_size)}]
    foreach n [split "File:[file tail $ee_cmd_xml]" {}] {
        set mem($i) [scan $n %c]
        incr i
    }
    set mem($i) 0
    # ... DHCP client-identifier
    if {$ee_cmd_idlen} {
        set i [expr {$ee_map_id + ($repl * $ee_size)}]
        set mem($i) $ee_cmd_idlen
        incr i
        incr i
        foreach n [split $ee_cmd_id {}] {
            set mem($i) [scan $n %c]
            incr i
        }
    }
}

# Write the output file...
# ... C source code
if {$ee_cmd_txt} {
    set fd [open $ee_cmd_out w]
    puts $fd "/*"
    puts $fd " *  EEPROM image file for the CANCam-GigE reference design."
    puts $fd " *  The file is automatically generated during the firmware"
    puts $fd " *  build process. Do not edit it manually!"
    puts $fd " *"
    puts -nonewline $fd " *  First MAC address : "
    foreach i $ee_cmd_mac {
        puts -nonewline $fd "[format %02X $i] "
    }
    puts $fd ""
    puts $fd " *  IP configuration  : $ee_cmd_ipcfg"
    puts $fd " *  Static IP address : $ee_cmd_ip"
    puts $fd " *  Static netmask    : $ee_cmd_net"
    puts $fd " *  Default gateway   : $ee_cmd_gw"
    puts $fd " *  GVCP UDP port     : $ee_cmd_port"
    puts $fd " *  User defined name : $ee_cmd_uname"
    puts $fd " *  GVSP destination  : $ee_cmd_dest"
    puts $fd " *  GVSP UDP port     : $ee_cmd_stream"
    puts $fd " *  Serial number     : $ee_cmd_serial"
    puts $fd " *  Custom data       : $ee_cmd_custom"
    puts $fd " *  XML file          : $ee_cmd_xml"
    puts $fd " *  XML address       : $ee_cmd_addr"
    puts $fd " *  Number of images  : $ee_cmd_repl"
    puts $fd " *  DHCP client ID    : $ee_cmd_id"
    puts $fd " */"
    puts $fd ""
    puts $fd "#include \"gige.h\""
    puts $fd ""
    puts $fd "u8 EEPROM\[\] ="
    puts -nonewline $fd "{"
    for {set i 0} {$i < [expr {$ee_size * $ee_cmd_repl}]} {incr i} {
        if {($i % 16) == 0} {
            puts -nonewline $fd "\n    /* 0x[format %04X $i] */   "
        }
        puts -nonewline $fd " 0x[format %02X [expr {$mem($i) & 0xFF}]]"
        if {$i != [expr ($ee_size * $ee_cmd_repl) - 1]} {
            puts -nonewline $fd ","
        }
    }
    puts $fd "\n};";
    close $fd
# ... binary image
} else {
    set fd [open $ee_cmd_out w]
    fconfigure $fd -translation binary
    for {set i 0} {$i < [expr {$ee_size * $ee_cmd_repl}]} {incr i} {
        puts -nonewline $fd [format "%c" $mem($i)]
    }
    close $fd
}

# Print info
if {$ee_cmd_txt} {
    puts "eeprom.tcl: generated C source file $ee_cmd_out";
} else {
    puts "eeprom.tcl: generated EEPROM image file $ee_cmd_out";
}

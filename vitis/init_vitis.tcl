proc helper {} {
    puts "Supported options are:"
    puts "      -hw <path to xsa file>"
    puts "      -workspace <workspace_name>"
}

proc board_info {xsa} {
    hsi::open_hw_design $xsa
    set board [common::get_property BOARD [hsi::current_hw_design]]
    set board [lindex [split $board ":"] 1]
    set board [string toupper $board]
    hsi::close_hw_design [hsi::current_hw_design]
    if {$board != ""} {
        return $board
    } else {
        return 0
    }
}

proc download_git {} {
    if {file exists embeddedsw] != 1} {
        exec git clone https://github.com/Xilinx/embeddedsw
    } else {
        puts "embeddedsw repo already exists. Using this one!"
    }
}

proc def_hw {} {
    set dir_name [def_ws]
    set hws [glob -directory $dir_name -- "*.xsa"]
    if {[llength $hws] != 0} {
        return [lindex $hws 0]
    } else {
        return 0
    }
}

proc def_ws {} {
    return [file dirname [file normalize [info script]]]
}

proc create_workspace {args} {
    set hw_found 0
    set ws_found 0
    for {set i 0} {$i < [llength $args]} {incr i} {
        if {[lindex $args $i] == "-hw"} {
            set hw [lindex $args [expr {$i + 1}]]
            if {[file extension $hw] != ".xsa"} {
                puts "Invalid file [file extension $hw] expecting .xsa"
            } else {
                set hw_found 1
            }
        }
        if {[lindex $args $i] == "-workspace"} {
            set ws [lindex $args [expr {$i + 1}]]
            set ws_found 1
        }
    }
    if {$hw_found == 0} {
        set hw [def_hw]
        if {$hw == 0} {
            puts "no hardware (.xsa) file found"
            return
        }
    }
    if {$ws_found == 0} {
        set ws [def_ws]
    }
    puts $ws
    puts $hw
    generate_project $hw $ws
}

proc get_proc {xsa} {
    hsi::open_hw_design $xsa
    set proc [hsi::get_cells -filter {IP_TYPE==PROCESSOR}]
    set first_proc [split $proc " "]
    set proc [lindex $first_proc 0]
    hsi::close_hw_design [hsi::current_hw_design]
    return $proc
}

proc generate_project {xsa workspace} {
    set root_name [file tail [file rootname $xsa]]
    set proc [get_proc $xsa]
    puts "Targeting processor $proc"
    setws $workspace
    importprojects $workspace
    platform create -name "${root_name}_platform" -hw $xsa
    domain create -name "domain_0" -os standalone -proc $proc
    app config -name ${root_name} -set build-config release
    app switch -name ${root_name} -platform ${root_name}_platform -domain domain_0
}

create_workspace

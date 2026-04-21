connect
targets -set -filter {jtag_cable_serial =~ "*00001abd04f901*" && name =~ "MicroBlaze #0*"}
loadhw ./EXTREAM_R_platform/export/EXTREAM_R_platform/hw/EXTREAM_R.xsa
rst -processor
dow ./EXTREAM_fw/Release/EXTREAM_fw.elf
con
exit

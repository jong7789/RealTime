connect
targets -set -filter {jtag_cable_serial =~ "*00001abd04f901*" && name =~ "xc7k*"}
fpga ./bin/bitstream.bit
exit

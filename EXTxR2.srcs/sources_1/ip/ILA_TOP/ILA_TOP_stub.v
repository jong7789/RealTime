// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
// Date        : Tue Jan 13 12:33:26 2026
// Host        : fpga-core running 64-bit Ubuntu 16.04.7 LTS
// Command     : write_verilog -force -mode synth_stub -rename_top ILA_TOP -prefix
//               ILA_TOP_ ILA_TOP_stub.v
// Design      : ILA_TOP
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k160tffg676-3
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "ila,Vivado 2022.2" *)
module ILA_TOP(clk, probe0, probe1, probe2, probe3, probe4, probe5, 
  probe6, probe7, probe8, probe9, probe10, probe11, probe12, probe13, probe14, probe15, probe16, probe17, 
  probe18, probe19)
/* synthesis syn_black_box black_box_pad_pin="clk,probe0[0:0],probe1[0:0],probe2[9:0],probe3[11:0],probe4[63:0],probe5[0:0],probe6[0:0],probe7[11:0],probe8[11:0],probe9[63:0],probe10[0:0],probe11[0:0],probe12[11:0],probe13[11:0],probe14[63:0],probe15[0:0],probe16[0:0],probe17[11:0],probe18[11:0],probe19[63:0]" */;
  input clk;
  input [0:0]probe0;
  input [0:0]probe1;
  input [9:0]probe2;
  input [11:0]probe3;
  input [63:0]probe4;
  input [0:0]probe5;
  input [0:0]probe6;
  input [11:0]probe7;
  input [11:0]probe8;
  input [63:0]probe9;
  input [0:0]probe10;
  input [0:0]probe11;
  input [11:0]probe12;
  input [11:0]probe13;
  input [63:0]probe14;
  input [0:0]probe15;
  input [0:0]probe16;
  input [11:0]probe17;
  input [11:0]probe18;
  input [63:0]probe19;
endmodule

// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.3.1 (win64) Build 2489853 Tue Mar 26 04:20:25 MDT 2019
// Date        : Mon May 19 22:48:53 2025
// Host        : TS-Always running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               D:/MyProjects/2_MyDesigns/USB3_Artix_GTP/xillyusb-bundle-artix7-trenz-1.10/vivado-essentials/fifo_8/fifo_8_stub.v
// Design      : fifo_8
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a35tcsg325-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v13_2_3,Vivado 2018.3.1" *)
module fifo_8(clk, srst, din, wr_en, rd_en, dout, full, empty)
/* synthesis syn_black_box black_box_pad_pin="clk,srst,din[7:0],wr_en,rd_en,dout[7:0],full,empty" */;
  input clk;
  input srst;
  input [7:0]din;
  input wr_en;
  input rd_en;
  output [7:0]dout;
  output full;
  output empty;
endmodule

`timescale 1ns / 10ps

module xillyusb(gpio_led, user_w_write_32_wren, user_w_write_32_data,
  user_w_write_32_full, user_w_write_32_open, user_w_write_8_wren,
  user_w_write_8_data, user_w_write_8_full, user_w_write_8_open,
  user_w_mem_8_wren, user_w_mem_8_data, user_w_mem_8_full, user_w_mem_8_open,
  user_r_mem_8_rden, user_r_mem_8_data, user_r_mem_8_empty, user_r_mem_8_eof,
  user_r_mem_8_open, user_mem_8_addr, user_mem_8_addr_update,
  user_r_read_32_rden, user_r_read_32_eof, user_r_read_32_open,
  user_r_read_32_data, user_r_read_32_empty, user_r_read_8_rden,
  user_r_read_8_eof, user_r_read_8_open, user_r_read_8_data,
  user_r_read_8_empty, gtx_rxn, gtx_rxp, gtx_txn, gtx_txp, gtx_refclk_n,
  gtx_refclk_p, bus_clk, quiesce);

  input  user_w_write_32_full;
  input  user_w_write_8_full;
  input  user_w_mem_8_full;
  input [7:0] user_r_mem_8_data;
  input  user_r_mem_8_empty;
  input  user_r_mem_8_eof;
  input  user_r_read_32_eof;
  input [31:0] user_r_read_32_data;
  input  user_r_read_32_empty;
  input  user_r_read_8_eof;
  input [7:0] user_r_read_8_data;
  input  user_r_read_8_empty;
  input  gtx_rxn;
  input  gtx_rxp;
  input  gtx_refclk_n;
  input  gtx_refclk_p;
  output [7:0] gpio_led;
  output  user_w_write_32_wren;
  output [31:0] user_w_write_32_data;
  output  user_w_write_32_open;
  output  user_w_write_8_wren;
  output [7:0] user_w_write_8_data;
  output  user_w_write_8_open;
  output  user_w_mem_8_wren;
  output [7:0] user_w_mem_8_data;
  output  user_w_mem_8_open;
  output  user_r_mem_8_rden;
  output  user_r_mem_8_open;
  output [4:0] user_mem_8_addr;
  output  user_mem_8_addr_update;
  output  user_r_read_32_rden;
  output  user_r_read_32_open;
  output  user_r_read_8_rden;
  output  user_r_read_8_open;
  output  gtx_txn;
  output  gtx_txp;
  output  bus_clk;
  output  quiesce;
  wire  pll_locked;
  wire  frontend_rst;
  wire  refclk_locked;
  wire  mgt_en;
  wire  lfps_en;
  wire  mgt_powerdown;
  wire  rx_dontmess;
  wire  rx_phy_ready;
  wire  rx_resync;
  wire  rx_detect_revpolarity;
  wire  rx_detect_revpolarity_clear;
  wire  rx_align_enable;
  wire  rx_elecidle;
  wire  receiver_detect;
  wire  receiver_present;
  wire  receiver_present_valid;
  wire [31:0] pipe_rx;
  wire [3:0] pipe_rx_k;
  wire  pipe_rx_valid;
  wire [31:0] pipe_tx;
  wire [3:0] pipe_tx_k;
  wire  pipe_tx_ready;
  wire  version_gtp_1_0;
  wire  pipe_rx_clk;

  xillyusb_core  xillyusb_core_ins(.pll_locked(pll_locked),
    .gpio_led(gpio_led), .frontend_rst(frontend_rst),
    .refclk_locked(refclk_locked), .user_w_write_32_wren(user_w_write_32_wren),
    .user_w_write_32_data(user_w_write_32_data), .user_w_write_32_full(user_w_write_32_full),
    .user_w_write_32_open(user_w_write_32_open), .mgt_en(mgt_en),
    .user_w_write_8_wren(user_w_write_8_wren), .user_w_write_8_data(user_w_write_8_data),
    .user_w_write_8_full(user_w_write_8_full), .user_w_write_8_open(user_w_write_8_open),
    .lfps_en(lfps_en), .user_w_mem_8_wren(user_w_mem_8_wren),
    .user_w_mem_8_data(user_w_mem_8_data), .user_w_mem_8_full(user_w_mem_8_full),
    .user_w_mem_8_open(user_w_mem_8_open), .user_r_mem_8_rden(user_r_mem_8_rden),
    .user_r_mem_8_data(user_r_mem_8_data), .user_r_mem_8_empty(user_r_mem_8_empty),
    .user_r_mem_8_eof(user_r_mem_8_eof), .user_r_mem_8_open(user_r_mem_8_open),
    .user_mem_8_addr(user_mem_8_addr), .user_mem_8_addr_update(user_mem_8_addr_update),
    .mgt_powerdown(mgt_powerdown), .rx_dontmess(rx_dontmess),
    .user_r_read_32_rden(user_r_read_32_rden), .user_r_read_32_eof(user_r_read_32_eof),
    .user_r_read_32_open(user_r_read_32_open), .user_r_read_32_data(user_r_read_32_data),
    .user_r_read_32_empty(user_r_read_32_empty), .user_r_read_8_rden(user_r_read_8_rden),
    .user_r_read_8_eof(user_r_read_8_eof), .user_r_read_8_open(user_r_read_8_open),
    .user_r_read_8_data(user_r_read_8_data), .user_r_read_8_empty(user_r_read_8_empty),
    .rx_phy_ready(rx_phy_ready), .rx_resync(rx_resync),
    .rx_detect_revpolarity(rx_detect_revpolarity),
    .rx_detect_revpolarity_clear(rx_detect_revpolarity_clear),
    .rx_align_enable(rx_align_enable), .rx_elecidle(rx_elecidle),
    .receiver_detect(receiver_detect), .receiver_present(receiver_present),
    .receiver_present_valid(receiver_present_valid), .pipe_rx(pipe_rx),
    .pipe_rx_k(pipe_rx_k), .pipe_rx_valid(pipe_rx_valid), .pipe_tx(pipe_tx),
    .pipe_tx_k(pipe_tx_k), .pipe_tx_ready(pipe_tx_ready),
    .version_gtp_1_0(version_gtp_1_0), .pipe_rx_clk(pipe_rx_clk),
    .bus_clk(bus_clk), .quiesce(quiesce));

  gtp_frontend  gtp_frontend_ins(.gtx_rxn(gtx_rxn), .gtx_rxp(gtx_rxp),
    .gtx_txn(gtx_txn), .gtx_txp(gtx_txp), .gtx_refclk_n(gtx_refclk_n),
    .gtx_refclk_p(gtx_refclk_p), .pipe_rx_clk(pipe_rx_clk), .pipe_clk(bus_clk),
    .pll_locked(pll_locked), .frontend_rst(frontend_rst),
    .refclk_locked(refclk_locked), .mgt_en(mgt_en), .lfps_en(lfps_en),
    .mgt_powerdown(mgt_powerdown), .rx_dontmess(rx_dontmess),
    .rx_phy_ready(rx_phy_ready), .rx_resync(rx_resync),
    .rx_detect_revpolarity(rx_detect_revpolarity),
    .rx_detect_revpolarity_clear(rx_detect_revpolarity_clear),
    .rx_align_enable(rx_align_enable), .rx_elecidle(rx_elecidle),
    .receiver_detect(receiver_detect), .receiver_present(receiver_present),
    .receiver_present_valid(receiver_present_valid), .pipe_rx(pipe_rx),
    .pipe_rx_k(pipe_rx_k), .pipe_rx_valid(pipe_rx_valid), .pipe_tx(pipe_tx),
    .pipe_tx_k(pipe_tx_k), .pipe_tx_ready(pipe_tx_ready),
    .version_gtp_1_0(version_gtp_1_0));

endmodule

`timescale 1ns / 10ps

module gtp_frontend(gtx_rxn, gtx_rxp, gtx_txn, gtx_txp, gtx_refclk_n,
  gtx_refclk_p, pipe_rx_clk, pipe_clk, pll_locked, frontend_rst, refclk_locked,
  mgt_en, lfps_en, mgt_powerdown, rx_dontmess, rx_phy_ready, rx_resync,
  rx_detect_revpolarity, rx_detect_revpolarity_clear, rx_align_enable,
  rx_elecidle, receiver_detect, receiver_present, receiver_present_valid,
  pipe_rx, pipe_rx_k, pipe_rx_valid, pipe_tx, pipe_tx_k, pipe_tx_ready,
  version_gtp_1_0);

  input  gtx_rxn;
  input  gtx_rxp;
  input  gtx_refclk_n;
  input  gtx_refclk_p;
  input  mgt_en;
  input  lfps_en;
  input  mgt_powerdown;
  input  rx_dontmess;
  input  rx_resync;
  input  rx_detect_revpolarity;
  input  rx_align_enable;
  input  receiver_detect;
  input [31:0] pipe_tx;
  input [3:0] pipe_tx_k;
  output  gtx_txn;
  output  gtx_txp;
  output  pipe_rx_clk;
  output  pipe_clk;
  output  pll_locked;
  output  frontend_rst;
  output  refclk_locked;
  output  rx_phy_ready;
  output  rx_detect_revpolarity_clear;
  output  rx_elecidle;
  output  receiver_present;
  output  receiver_present_valid;
  output [31:0] pipe_rx;
  output [3:0] pipe_rx_k;
  output  pipe_rx_valid;
  output  pipe_tx_ready;
  output  version_gtp_1_0;
  reg  pll_locked;
  reg  frontend_rst;
  reg  rx_phy_ready;
  reg  rx_detect_revpolarity_clear;
  reg  rx_elecidle;
  reg  receiver_present;
  reg  receiver_present_valid;
  reg [4:0] mgt_reset_rx;
  reg [4:0] mgt_reset_tx;
  reg  txelecidle;
  reg  pll_lock_d;
  reg  pll_lock_d2;
  reg  rxelecidle_d;
  reg  rxelecidle_d2;
  reg [4:0] elecidle_cnt;
  reg [31:0] txdata;
  reg [3:0] txdata_k;
  reg  txdata_extend;
  reg [1:0] lfps_toggler;
  reg  tx_coding_bypass;
  reg [6:0] wakeup_counter;
  reg  rxdlysreset;
  reg  rxresetdone_d;
  reg  rxresetdone_sync;
  reg  rxsyncdone_d;
  reg  rxsyncdone_sync;
  reg  rxdlysresetdone_d;
  reg  rxdlysresetdone_sync;
  reg  rxphaligndone_d;
  reg  rxphaligndone_sync;
  reg [2:0] ph_state;
  reg  pending_align;
  reg [1:0] powerdown;
  reg  mgt_powerdown_d;
  reg  txdetectrx;
  reg  toggle_phystatus;
  reg  rxstatus_latch;
  reg [3:0] toggle_phystatus_d;
  reg  rxstatus_latch_d;
  reg [6:0] polarity_debounce_cnt;
  reg  rxpolarity;
  reg  rx_align_enable_d;
  reg  rx_align_enable_d2;
  reg [17:0] rx_selfreset_cnt;
  reg  rx_selfreset;
  reg  rxusrclk_locked_d;
  reg  rxusrclk_locked_sync;
  reg  rxusrclk_locked_sync_d;
  reg  txusrclk_locked_d;
  reg  txusrclk_locked_sync;
  wire  reset_rx;
  wire  reset_tx;
  wire  rxelecidle;
  wire  txoutclk;
  wire  txoutclk_w;
  wire  rxoutclk;
  wire  rxoutclk_w;
  wire  refclk;
  wire  pll0clk;
  wire  pll0refclk;
  wire  pll1clk;
  wire  pll1refclk;
  wire  pll_lock;
  wire  rxphaligndone;
  wire  rxdlysresetdone;
  wire  txresetdone;
  wire  rxresetdone;
  wire  rxsyncdone;
  wire  phystatus;
  wire [2:0] rxstatus;
  wire  pipe_rx_clk_pll;
  wire  pipe_rx_clk_x_2_pll;
  wire  pipe_rx_clk_x_2;
  wire  clkfbout_rx_pll;
  wire  rxusrclk_locked;
  wire  pipe_clk_pll;
  wire  pipe_clk_x_2_pll;
  wire  pipe_clk_x_2;
  wire  clkfbout_tx_pll;
  wire  txusrclk_locked;

   parameter RXELECIDLE_DEBOUNCE = 14; // ~ f_usrclk * 0.1 us

   parameter refclk_freq = 125; // In MHz

   // Signals related to TX/RXUSRCLK PLLs

   localparam st_idle = 0,
     st_rstdone = 1,
     st_start = 2,
     st_wait1 = 3,
     st_wait2 = 4;

   initial wakeup_counter = 0;

   assign version_gtp_1_0 = 1;

   assign pipe_tx_ready = 1;
   assign pipe_rx_valid = 1;
   assign refclk_locked = 1;

   assign reset_rx = mgt_reset_rx[4];
   assign reset_tx = mgt_reset_tx[4];

   always @(posedge pipe_clk)
     begin
	rx_phy_ready <= (ph_state == st_idle);

	// Polarity detection debouncing is required to clear the pipeline
	// of data before the next verdict.

	rx_detect_revpolarity_clear <= (polarity_debounce_cnt != 0);

	if (polarity_debounce_cnt != 0)
	  polarity_debounce_cnt <= polarity_debounce_cnt - 1;
	else if (rx_detect_revpolarity)
	  begin
	     polarity_debounce_cnt <= polarity_debounce_cnt - 1; // Wrap to max
	     rxpolarity <= !rxpolarity;
	  end

	// PLL lock indicator is asynchronous
	pll_lock_d <= pll_lock;
	pll_lock_d2 <= pll_lock_d;
	pll_locked <= pll_lock_d2;

	// rxelecidle is an async signal, hence metastability guarded
	rxelecidle_d <= rxelecidle;
	rxelecidle_d2 <= rxelecidle_d;

	if (!rxelecidle_d2)
	  elecidle_cnt <= RXELECIDLE_DEBOUNCE;
	else if (elecidle_cnt != 0)
	  elecidle_cnt <= elecidle_cnt - 1;

	rx_elecidle <= (elecidle_cnt == 0);

	txusrclk_locked_d <= txusrclk_locked;
	txusrclk_locked_sync <= txusrclk_locked_d;

	if ((wakeup_counter == 125) || (pll_lock_d2 && !pll_locked))
	  begin
	     mgt_reset_rx <= ~0;
	     mgt_reset_tx <= ~0;
	  end
	else
	  begin
	     mgt_reset_rx <= { mgt_reset_rx, 1'b0 };
	     mgt_reset_tx <= { mgt_reset_tx, 1'b0 };
	  end

	// Self-reset the rx part every 1.5 ms, unless the LTSSM is in a
	// mode it expects the MGT to work in, as indicated by rx_dontmess.
	// As the LTSSM asserts rx_resync before starting to rely on the
	// MGT, it's harmless if rx_selfreset is asserted slightly after
	// rx_dontmess goes high. On the other hand, this self reset
	// mechanism is pointless in all situations because of rx_resync,
	// except when the Polling.LFPS signal can't be detected, in which case
	// the bringup relies on detection of MGT data. In that case, the MGT's
	// receiver must be ensured not be get messed up by noise on the wire.
	// In short: This self reset thing is quite far fetched, and can be
	// removed if it causes any trouble.

	if (rx_selfreset_cnt == 187499)
	  begin
	     rx_selfreset <= !rx_dontmess;
	     rx_selfreset_cnt <= 0;
	  end
	else
	  begin
	     rx_selfreset <= 0;
	     rx_selfreset_cnt <= rx_selfreset_cnt + 1;
	  end

	if (rx_resync || rx_selfreset)
	  mgt_reset_rx <= ~0;

	if (!txusrclk_locked_sync)
	  wakeup_counter <= 0;
	else if (!(&wakeup_counter))
	  wakeup_counter <= wakeup_counter + 1;

	frontend_rst <= !(&wakeup_counter) || !pll_locked;

	lfps_toggler <= lfps_toggler + 1;

	powerdown <= mgt_powerdown ? 2'b10 : 2'b00;
	mgt_powerdown_d <= mgt_powerdown;

	if (mgt_powerdown_d && !mgt_powerdown)
	  mgt_reset_tx <= ~0;

	if (mgt_en)
	  begin
	     txelecidle <= 0;
	     txdata <= pipe_tx;
	     txdata_k <= pipe_tx_k;
	     txdata_extend <= 0;
	     tx_coding_bypass <= 0;
	  end
	else if (lfps_en)
	  begin
	     txelecidle <= 0;
	     txdata <= { 32{lfps_toggler[1]} };
	     txdata_extend <= lfps_toggler[1];
	     tx_coding_bypass <= 1;
	  end
	else // Electrical Idle
	  begin
	     txelecidle <= 1;
	  end

	// Crossing clock domain and detecting a toggle a phystatus event

	toggle_phystatus_d <= { toggle_phystatus_d, toggle_phystatus };
	rxstatus_latch_d <= rxstatus_latch;

	receiver_present_valid <= txdetectrx && ^toggle_phystatus_d[3:2];
	receiver_present <= rxstatus_latch_d;

	if (reset_tx || ^toggle_phystatus_d[3:2])
	  txdetectrx <= 0;
	else if (receiver_detect)
	  txdetectrx <= 1;

	// State machine for phase alignment GTP/GTH

	rxresetdone_d <= rxresetdone;
	rxresetdone_sync <= rxresetdone_d;

	rxsyncdone_d <= rxsyncdone;
	rxsyncdone_sync <= rxsyncdone_d;

	rxdlysresetdone_d <= rxdlysresetdone;
	rxdlysresetdone_sync <= rxdlysresetdone_d;

	rxphaligndone_d <= rxphaligndone;
	rxphaligndone_sync <= rxphaligndone_d;

	rxusrclk_locked_d <= rxusrclk_locked;
	rxusrclk_locked_sync <= rxusrclk_locked_d;
	rxusrclk_locked_sync_d <= rxusrclk_locked_sync;

	rxdlysreset <= 0; // Possibly overridden below

	case (ph_state)
	  st_idle:
	    if (pending_align)
	      ph_state <= st_start;

	  st_rstdone:
	    if (rxresetdone_sync)
	      ph_state <= st_start;

	  st_start:
	    begin
	       rxdlysreset <= 1;
	       pending_align <= 0;
	       ph_state <= st_wait1;
	    end

	  st_wait1:
	    if (rxdlysresetdone_sync)
	      ph_state <= st_wait2;

	  st_wait2:
	    if (rxsyncdone_sync)
	      ph_state <= st_idle;

	  default:
	    ph_state <= st_idle;
	endcase

	if (reset_rx)
	  ph_state <= st_rstdone;

	if ((rxusrclk_locked_sync && !rxusrclk_locked_sync_d) ||
	    ((ph_state == st_idle) && !rxphaligndone_sync))
	  pending_align <= 1;
     end

   always @(posedge pipe_rx_clk)
     begin
	rx_align_enable_d <= rx_align_enable;
	rx_align_enable_d2 <= rx_align_enable_d;

	if (phystatus)
	  begin
	     toggle_phystatus <= !toggle_phystatus;
	     rxstatus_latch <= rxstatus[0];
	  end
     end

   GTPE2_CHANNEL #
     (
      .SIM_RECEIVER_DETECT_PASS("TRUE"),
      .SIM_TX_EIDLE_DRIVE_LEVEL("X"),
      .SIM_RESET_SPEEDUP("FALSE"),
      .SIM_VERSION("2.0"),

      .ALIGN_COMMA_DOUBLE("FALSE"),
      .ALIGN_COMMA_ENABLE(10'h3ff),
      .ALIGN_COMMA_WORD(1),
      .ALIGN_MCOMMA_DET("TRUE"),
      .ALIGN_MCOMMA_VALUE(10'h283),
      .ALIGN_PCOMMA_DET("TRUE"),
      .ALIGN_PCOMMA_VALUE(10'h17c),
      .SHOW_REALIGN_COMMA("TRUE"),
      .RXSLIDE_AUTO_WAIT(7),
      .RXSLIDE_MODE("PCS"),
      .RX_SIG_VALID_DLY(10),

      .RX_DISPERR_SEQ_MATCH("TRUE"),
      .DEC_MCOMMA_DETECT("TRUE"),
      .DEC_PCOMMA_DETECT("TRUE"),
      .DEC_VALID_COMMA_ONLY("FALSE"),

      .CBCC_DATA_SOURCE_SEL("DECODED"),
      .CLK_COR_SEQ_2_USE("FALSE"),
      .CLK_COR_KEEP_IDLE("FALSE"),
      .CLK_COR_MAX_LAT(9),
      .CLK_COR_MIN_LAT(7),
      .CLK_COR_PRECEDENCE("TRUE"),
      .CLK_COR_REPEAT_WAIT(0),
      .CLK_COR_SEQ_LEN(1),
      .CLK_COR_SEQ_1_ENABLE(4'hf),
      .CLK_COR_SEQ_1_1(10'h100),
      .CLK_COR_SEQ_1_2(10'h000),
      .CLK_COR_SEQ_1_3(10'h000),
      .CLK_COR_SEQ_1_4(10'h000),
      .CLK_CORRECT_USE("FALSE"),
      .CLK_COR_SEQ_2_ENABLE(4'hf),
      .CLK_COR_SEQ_2_1(10'h100),
      .CLK_COR_SEQ_2_2(10'h000),
      .CLK_COR_SEQ_2_3(10'h000),
      .CLK_COR_SEQ_2_4(10'h000),

      .CHAN_BOND_KEEP_ALIGN("FALSE"),
      .CHAN_BOND_MAX_SKEW(1),
      .CHAN_BOND_SEQ_LEN(1),
      .CHAN_BOND_SEQ_1_1(10'h000),
      .CHAN_BOND_SEQ_1_2(10'h000),
      .CHAN_BOND_SEQ_1_3(10'h000),
      .CHAN_BOND_SEQ_1_4(10'h000),
      .CHAN_BOND_SEQ_1_ENABLE(4'hf),
      .CHAN_BOND_SEQ_2_1(10'h000),
      .CHAN_BOND_SEQ_2_2(10'h000),
      .CHAN_BOND_SEQ_2_3(10'h000),
      .CHAN_BOND_SEQ_2_4(10'h000),
      .CHAN_BOND_SEQ_2_ENABLE(4'hf),
      .CHAN_BOND_SEQ_2_USE("FALSE"),
      .FTS_DESKEW_SEQ_ENABLE(4'hf),
      .FTS_LANE_DESKEW_CFG(4'hf),
      .FTS_LANE_DESKEW_EN("FALSE"),

      .ES_CONTROL(6'h00),
      .ES_ERRDET_EN("FALSE"),
      .ES_EYE_SCAN_EN("FALSE"),
      .ES_HORZ_OFFSET(12'h010),
      .ES_PMA_CFG(10'h000),
      .ES_PRESCALE(5'h00),
      .ES_QUALIFIER(80'h00000000000000000000),
      .ES_QUAL_MASK(80'h00000000000000000000),
      .ES_SDATA_MASK(80'h00000000000000000000),
      .ES_VERT_OFFSET(9'h000),

      .RX_DATA_WIDTH(40),

      .OUTREFCLK_SEL_INV(2'h3),
      .PMA_RSV(32'h00000333),
      .PMA_RSV2(32'h00002040),
      .PMA_RSV3(2'h0),
      .PMA_RSV4(4'h0),
      .RX_BIAS_CFG(16'h0f33),
      .DMONITOR_CFG(24'h000a00),
      .RX_CM_SEL(2'h3),
      .RX_CM_TRIM(4'ha), // Common mode voltage = 800 mV
      .RX_DEBUG_CFG(14'h0000),
      .RX_OS_CFG(13'h0080),
      .TERM_RCAL_CFG(15'h4210),
      .TERM_RCAL_OVRD(3'h0),
      .TST_RSV(32'h00000000),
      .RX_CLK25_DIV(5),
      .TX_CLK25_DIV(5),
      .UCODEER_CLR(1'b0),

      .PCS_PCIE_EN("FALSE"),

      .PCS_RSVD_ATTR(48'h000000000100),

      .RXBUF_ADDR_MODE("FAST"),
      .RXBUF_EIDLE_HI_CNT(4'h8),
      .RXBUF_EIDLE_LO_CNT(4'h0),
      .RXBUF_EN("FALSE"),
      .RX_BUFFER_CFG(6'h00),
      .RXBUF_RESET_ON_CB_CHANGE("TRUE"),
      .RXBUF_RESET_ON_COMMAALIGN("FALSE"),
      .RXBUF_RESET_ON_EIDLE("FALSE"),
      .RXBUF_RESET_ON_RATE_CHANGE("TRUE"),
      .RXBUFRESET_TIME(5'h01),
      .RXBUF_THRESH_OVFLW(61),
      .RXBUF_THRESH_OVRD("FALSE"),
      .RXBUF_THRESH_UNDFLW(4),
      .RXDLY_CFG(16'h001f),
      .RXDLY_LCFG(9'h030),
      .RXDLY_TAP_CFG(16'h0000),
      .RXPH_CFG(24'hc00002),
      .RXPHDLY_CFG(24'h084020),
      .RXPH_MONITOR_SEL(5'h00),
      .RX_XCLK_SEL("RXUSR"),
      .RX_DDI_SEL(6'h00),
      .RX_DEFER_RESET_BUF_EN("TRUE"),

      .RXCDR_CFG(83'h0000087fe206024441010),
      .RXCDR_FR_RESET_ON_EIDLE(1'b0),
      .RXCDR_HOLD_DURING_EIDLE(1'b0),
      .RXCDR_PH_RESET_ON_EIDLE(1'b0),
      .RXCDR_LOCK_CFG(6'h09),

      .RXCDRFREQRESET_TIME(5'h01),
      .RXCDRPHRESET_TIME(5'h01),
      .RXISCANRESET_TIME(5'h01),
      .RXPCSRESET_TIME(5'h01),
      .RXPMARESET_TIME(5'h03),

      .RXOOB_CFG(7'h06),

      .RXGEARBOX_EN("FALSE"),
      .GEARBOX_MODE(3'h0),

      .RXPRBS_ERR_LOOPBACK(1'b0),

      .PD_TRANS_TIME_FROM_P2(12'h03c),
      .PD_TRANS_TIME_NONE_P2(8'h3c),
      .PD_TRANS_TIME_TO_P2(8'h64),

      .SAS_MAX_COM(64),
      .SAS_MIN_COM(36),
      .SATA_BURST_SEQ_LEN(4'hf),
      .SATA_BURST_VAL(3'h4),
      .SATA_EIDLE_VAL(3'h4),
      .SATA_MAX_BURST(8),
      .SATA_MAX_INIT(21),
      .SATA_MAX_WAKE(7),
      .SATA_MIN_BURST(4),
      .SATA_MIN_INIT(12),
      .SATA_MIN_WAKE(4),

      .TRANS_TIME_RATE(8'h0e),

      .TXBUF_EN("TRUE"),
      .TXBUF_RESET_ON_RATE_CHANGE("TRUE"),
      .TXDLY_CFG(16'h001f),
      .TXDLY_LCFG(9'h030),
      .TXDLY_TAP_CFG(16'h0000),
      .TXPH_CFG(16'h0780),
      .TXPHDLY_CFG(24'h084020),
      .TXPH_MONITOR_SEL(5'h00),
      .TX_XCLK_SEL("TXOUT"),

      .TX_DATA_WIDTH(40),

      .TX_DEEMPH0(6'h00),
      .TX_DEEMPH1(6'h00),
      .TX_EIDLE_ASSERT_DELAY(3'h6),
      .TX_EIDLE_DEASSERT_DELAY(3'h4),
      .TX_LOOPBACK_DRIVE_HIZ("FALSE"),
      .TX_MAINCURSOR_SEL(1'b0),
      .TX_DRIVE_MODE("DIRECT"),
      .TX_MARGIN_FULL_0(7'h4e),
      .TX_MARGIN_FULL_1(7'h49),
      .TX_MARGIN_FULL_2(7'h45),
      .TX_MARGIN_FULL_3(7'h42),
      .TX_MARGIN_FULL_4(7'h40),
      .TX_MARGIN_LOW_0(7'h46),
      .TX_MARGIN_LOW_1(7'h44),
      .TX_MARGIN_LOW_2(7'h42),
      .TX_MARGIN_LOW_3(7'h40),
      .TX_MARGIN_LOW_4(7'h40),

      .TXGEARBOX_EN("FALSE"),

      .TXPCSRESET_TIME(5'h01),
      .TXPMARESET_TIME(5'h01),

      .TX_RXDETECT_CFG(refclk_freq),
      .TX_RXDETECT_REF(3'h4),

      .ACJTAG_DEBUG_MODE(1'b0),
      .ACJTAG_MODE(1'b0),
      .ACJTAG_RESET(1'b0),

      .CFOK_CFG(43'h49000040e80),
      .CFOK_CFG2(7'h20),
      .CFOK_CFG3(7'h20),
      .CFOK_CFG4(1'b0),
      .CFOK_CFG5(2'h0),
      .CFOK_CFG6(4'h0),
      .RXOSCALRESET_TIME(5'h03),
      .RXOSCALRESET_TIMEOUT(5'h00),

      .CLK_COMMON_SWING(1'b0),
      .RX_CLKMUX_EN(1'b1),
      .TX_CLKMUX_EN(1'b1),
      .ES_CLK_PHASE_SEL(1'b0),
      .USE_PCS_CLK_PHASE_SEL(1'b0),
      .PMA_RSV6(1'b0),
      .PMA_RSV7(1'b0),

      .TX_PREDRIVER_MODE(1'b0),
      .PMA_RSV5(1'b0),
      .SATA_PLL_CFG("VCO_3000MHZ"),

      .RXOUT_DIV(1),

      .TXOUT_DIV(1),

      .RXPI_CFG0(3'h0),
      .RXPI_CFG1(1'b1),
      .RXPI_CFG2(1'b1),

      .ADAPT_CFG0(20'h00000),
      .RXLPMRESET_TIME(7'h0f),
      .RXLPM_BIAS_STARTUP_DISABLE(1'b0),
      .RXLPM_CFG(4'h6),
      .RXLPM_CFG1(1'b0),
      .RXLPM_CM_CFG(1'b0),
      .RXLPM_GC_CFG(9'h1e2),
      .RXLPM_GC_CFG2(3'h1),
      .RXLPM_HF_CFG(14'h03f0),
      .RXLPM_HF_CFG2(5'h0a),
      .RXLPM_HF_CFG3(4'h0),
      .RXLPM_HOLD_DURING_EIDLE(1'b0),
      .RXLPM_INCM_CFG(1'b1),
      .RXLPM_IPCM_CFG(1'b0),
      .RXLPM_LF_CFG(18'h003f0),
      .RXLPM_LF_CFG2(5'h0a),
      .RXLPM_OSINT_CFG(3'h4),

      .TXPI_CFG0(2'h0),
      .TXPI_CFG1(2'h0),
      .TXPI_CFG2(2'h0),
      .TXPI_CFG3(1'b0),
      .TXPI_CFG4(1'b0),
      .TXPI_CFG5(3'h0),
      .TXPI_GREY_SEL(1'b0),
      .TXPI_INVSTROBE_SEL(1'b0),
      .TXPI_PPMCLK_SEL("TXUSRCLK2"),
      .TXPI_PPM_CFG(8'h00),
      .TXPI_SYNFREQ_PPM(3'h0),

      .LOOPBACK_CFG(1'b0),
      .PMA_LOOPBACK_CFG(1'b0),

      .RXOOB_CLK_CFG("PMA"),

      .TXOOB_CFG(1'b0),

      .RXSYNC_MULTILANE(1'b0),
      .RXSYNC_OVRD(1'b0),
      .RXSYNC_SKIP_DA(1'b0),

      .TXSYNC_MULTILANE(1'b0),
      .TXSYNC_OVRD(1'b0), // Following wizard, not UG482
      .TXSYNC_SKIP_DA(1'b0)
      )
   gtpe2_i
     (
      .GTRSVD(16'h0000),
      .PCSRSVDIN(16'h0000),
      .TSTIN(20'hfffff),

      .DRPADDR(9'd0),
      .DRPCLK(1'b0),
      .DRPDI(16'd0),
      .DRPDO(),
      .DRPEN(1'b0),
      .DRPRDY(),
      .DRPWE(1'b0),

      .RXSYSCLKSEL(2'h0),
      .TXSYSCLKSEL(2'h0),

      .TX8B10BEN(1'b1),

      .PLL0CLK(pll0clk),
      .PLL0REFCLK(pll0refclk),
      .PLL1CLK(pll1clk),
      .PLL1REFCLK(pll1refclk),

      .LOOPBACK(3'h0),

      .PHYSTATUS(phystatus),
      .RXRATE(3'h0),
      .RXVALID(),

      .PMARSVDIN3(1'b0),
      .PMARSVDIN4(1'b0),

      .RXPD(powerdown),
      .TXPD(powerdown),

      .SETERRSTATUS(1'b0),

      .EYESCANRESET(1'b0),
      .RXUSERRDY(1'b1),

      .EYESCANDATAERROR(),
      .EYESCANMODE(1'b0),
      .EYESCANTRIGGER(1'b0),

      .CLKRSVD0(1'b0),
      .CLKRSVD1(1'b0),
      .DMONFIFORESET(1'b0),
      .DMONITORCLK(1'b0),
      .RXPMARESETDONE(), // Unused, not supported by GTX
      .SIGVALIDCLK(1'b0),

      .RXCDRFREQRESET(1'b0),
      .RXCDRHOLD(1'b0),
      .RXCDRLOCK(),
      .RXCDROVRDEN(1'b0),
      .RXCDRRESET(1'b0),
      .RXCDRRESETRSV(1'b0),
      .RXOSCALRESET(1'b0),
      .RXOSINTCFG(4'h2),
      .RXOSINTDONE(),
      .RXOSINTHOLD(1'b0),
      .RXOSINTOVRDEN(1'b0),
      .RXOSINTPD(1'b0),
      .RXOSINTSTARTED(),
      .RXOSINTSTROBE(1'b0),
      .RXOSINTSTROBESTARTED(),
      .RXOSINTTESTOVRDEN(1'b0),

      .RXCLKCORCNT(),

      .RX8B10BEN(1'b1),

      .RXDATA(pipe_rx),
      .RXUSRCLK(pipe_rx_clk_x_2),
      .RXUSRCLK2(pipe_rx_clk),

      .RXPRBSERR(),
      .RXPRBSSEL(3'h0),

      .RXPRBSCNTRESET(1'b0),

      .RXCHARISCOMMA(),
      .RXCHARISK(pipe_rx_k),
      .RXDISPERR(),
      .RXNOTINTABLE(),

      .GTPRXN(gtx_rxn),
      .GTPRXP(gtx_rxp),
      .PMARSVDIN2(1'b0),
      .PMARSVDOUT0(),
      .PMARSVDOUT1(),

      .RXBUFRESET(1'b0),
      .RXBUFSTATUS(),
      .RXDDIEN(1'b1),
      .RXDLYBYPASS(1'b0),
      .RXDLYEN(1'b0),
      .RXDLYOVRDEN(1'b0),
      .RXDLYSRESET(rxdlysreset),
      .RXDLYSRESETDONE(rxdlysresetdone),
      .RXPHALIGN(1'b0),
      .RXPHALIGNDONE(rxphaligndone),
      .RXPHALIGNEN(1'b0),
      .RXPHDLYPD(1'b0),
      .RXPHDLYRESET(1'b0),
      .RXPHMONITOR(),
      .RXPHOVRDEN(1'b0),
      .RXPHSLIPMONITOR(),
      .RXSTATUS(rxstatus),
      .RXSYNCALLIN(rxphaligndone),
      .RXSYNCDONE(rxsyncdone),
      .RXSYNCIN(1'b0),
      .RXSYNCMODE(1'b1),
      .RXSYNCOUT(),

      .RXBYTEISALIGNED(),
      .RXBYTEREALIGN(),
      .RXCOMMADET(),
      .RXCOMMADETEN(1'b1),
      .RXMCOMMAALIGNEN(rx_align_enable_d2),
      .RXPCOMMAALIGNEN(rx_align_enable_d2),
      .RXSLIDE(1'b0),

      .RXCHANBONDSEQ(),
      .RXCHBONDEN(1'b0),
      .RXCHBONDI(4'h0),
      .RXCHBONDLEVEL(3'h0),
      .RXCHBONDMASTER(1'b0),
      .RXCHBONDO(),
      .RXCHBONDSLAVE(1'b0),

      .RXCHANISALIGNED(),
      .RXCHANREALIGN(),

      .DMONITOROUT(),
      .RXADAPTSELTEST(14'h0000),
      .RXDFEXYDEN(1'b0),
      .RXOSINTEN(1'b1),
      .RXOSINTID0(4'h0),
      .RXOSINTNTRLEN(1'b0),
      .RXOSINTSTROBEDONE(),

      .RXLPMLFOVRDEN(1'b0),
      .RXLPMOSINTNTRLEN(1'b0),

      .RXLPMHFHOLD(1'b0),
      .RXLPMHFOVRDEN(1'b0),
      .RXLPMLFHOLD(1'b0),

      .RXOSHOLD(1'b0),
      .RXOSOVRDEN(1'b0),

      .RXRATEDONE(),

      .RXRATEMODE(1'b0),

      .RXOUTCLK(rxoutclk),
      .RXOUTCLKFABRIC(),
      .RXOUTCLKPCS(),
      .RXOUTCLKSEL(3'h2),

      .RXDATAVALID(),
      .RXHEADER(),
      .RXHEADERVALID(),
      .RXSTARTOFSEQ(),

      .RXGEARBOXSLIP(1'b0),

      .GTRXRESET(reset_rx),
      .RXLPMRESET(1'b0),
      .RXOOBRESET(1'b0),
      .RXPCSRESET(1'b0),
      .RXPMARESET(1'b0),

      .RXCOMSASDET(),
      .RXCOMWAKEDET(),

      .RXCOMINITDET(),

      .RXELECIDLE(rxelecidle),
      .RXELECIDLEMODE(2'h0),

      .RXPOLARITY(rxpolarity),

      .RXRESETDONE(rxresetdone),

      .TXPHDLYTSTCLK(1'b0),

      .TXPOSTCURSOR(5'h00),
      .TXPOSTCURSORINV(1'b0),
      .TXPRECURSOR(5'h00),
      .TXPRECURSORINV(1'b0),

      .TXRATEMODE(1'b0),

      .CFGRESET(1'b0),
      .GTTXRESET(reset_tx),
      .PCSRSVDOUT(),
      .TXUSERRDY(1'b1),

      .TXPIPPMEN(1'b0),
      .TXPIPPMOVRDEN(1'b0),
      .TXPIPPMPD(1'b0),
      .TXPIPPMSEL(1'b1),
      .TXPIPPMSTEPSIZE(5'h00),

      .GTRESETSEL(1'b0),
      .RESETOVRD(1'b0),

      .TXPMARESETDONE(),

      .PMARSVDIN0(1'b0),
      .PMARSVDIN1(1'b0),

      .TXDATA(txdata),
      .TXUSRCLK(pipe_clk_x_2),
      .TXUSRCLK2(pipe_clk),

      .TXELECIDLE(txelecidle),
      .TXMARGIN(3'h0),
      .TXRATE(3'h0),
      .TXSWING(1'b0),

      .TXPRBSFORCEERR(1'b0),

      .TX8B10BBYPASS({ 4{tx_coding_bypass} }),
      .TXCHARDISPMODE({ 4{txdata_extend} }),
      .TXCHARDISPVAL({ 4{txdata_extend} }),
      .TXCHARISK(txdata_k),

      .TXDLYBYPASS(1'b1),
      .TXDLYEN(1'b0),
      .TXDLYHOLD(1'b0),
      .TXDLYOVRDEN(1'b0),
      .TXDLYSRESET(1'b0),
      .TXDLYSRESETDONE(),
      .TXDLYUPDOWN(1'b0),
      .TXPHALIGN(1'b0),
      .TXPHALIGNDONE(),
      .TXPHALIGNEN(1'b0),
      .TXPHDLYPD(1'b0),
      .TXPHDLYRESET(1'b0),
      .TXPHINIT(1'b0),
      .TXPHINITDONE(),
      .TXPHOVRDEN(1'b0),

      .TXBUFSTATUS(),

      .TXSYNCALLIN(1'b0),
      .TXSYNCDONE(),
      .TXSYNCIN(1'b0),
      .TXSYNCMODE(1'b0),
      .TXSYNCOUT(),

      .GTPTXN(gtx_txn),
      .GTPTXP(gtx_txp),
      .TXBUFDIFFCTRL(3'h4),
      .TXDEEMPH(1'b0),
      .TXDIFFCTRL(4'hc),
      .TXDIFFPD(1'b0),
      .TXINHIBIT(1'b0),
      .TXMAINCURSOR(7'h00),
      .TXPISOPD(1'b0),

      .TXOUTCLK(txoutclk),
      .TXOUTCLKFABRIC(),
      .TXOUTCLKPCS(),
      .TXOUTCLKSEL(3'h3),
      .TXRATEDONE(),

      .TXGEARBOXREADY(),
      .TXHEADER(3'h0),
      .TXSEQUENCE(7'h00),
      .TXSTARTSEQ(1'b0),

      .TXPCSRESET(1'b0),
      .TXPMARESET(1'b0),
      .TXRESETDONE(txresetdone),

      .TXCOMFINISH(),
      .TXCOMINIT(1'b0),
      .TXCOMSAS(1'b0),
      .TXCOMWAKE(1'b0),
      .TXPDELECIDLEMODE(1'b1),

      .TXPOLARITY(1'b0),

      .TXDETECTRX(txdetectrx),

      .TXPRBSSEL(3'h0)
      );

   // Using PLL0 locked on GTREFCLK1

   GTPE2_COMMON #
     (
      // Simulation attributes
      .SIM_RESET_SPEEDUP("FALSE"),
      .SIM_PLL0REFCLK_SEL(3'd2),
      .SIM_PLL1REFCLK_SEL(3'd2),
      .SIM_VERSION("2.0"),

      .PLL0_FBDIV(4),
      .PLL0_FBDIV_45(5),
      .PLL0_REFCLK_DIV(1),
      .PLL1_FBDIV(4),
      .PLL1_FBDIV_45(5),
      .PLL1_REFCLK_DIV(1),

      .BIAS_CFG(64'h0000000000050001),
      .COMMON_CFG(32'h00000000),

      .PLL0_CFG(27'h01f03dc),
      .PLL0_DMON_CFG(1'b0),
      .PLL0_INIT_CFG(24'h00001e),
      .PLL0_LOCK_CFG(9'h1e8),
      .PLL1_CFG(27'h01f03dc),
      .PLL1_DMON_CFG(1'b0),
      .PLL1_INIT_CFG(24'h00001e),
      .PLL1_LOCK_CFG(9'h1e8),
      .PLL_CLKOUT_CFG(8'h00),

      .RSVD_ATTR0(16'h0000),
      .RSVD_ATTR1(16'h0000)

      )
   gtpe2_common_i
     (
      .DMONITOROUT(),

      .DRPADDR(8'd0),
      .DRPCLK(1'b0),
      .DRPDI(16'd0),
      .DRPDO(),
      .DRPEN(1'b0),
      .DRPRDY(),
      .DRPWE(1'b0),

      .GTEASTREFCLK0(1'b0),
      .GTEASTREFCLK1(1'b0),
      .GTGREFCLK1(1'b0),
      .GTREFCLK0(1'b0),
      .GTREFCLK1(refclk),
      .GTWESTREFCLK0(1'b0),
      .GTWESTREFCLK1(1'b0),
      .PLL0OUTCLK(pll0clk),
      .PLL0OUTREFCLK(pll0refclk),
      .PLL1OUTCLK(pll1clk),
      .PLL1OUTREFCLK(pll1refclk),

      .PLL0FBCLKLOST(),
      .PLL0LOCK(pll_lock),
      .PLL0LOCKDETCLK(1'b0),
      .PLL0LOCKEN(1'b1),
      .PLL0PD(1'b0),
      .PLL0REFCLKLOST(),
      .PLL0REFCLKSEL(3'd2), // GTREFCLK1
      .PLL0RESET(1'b0),
      .PLL1FBCLKLOST(),
      .PLL1LOCK(),
      .PLL1LOCKDETCLK(1'b0),
      .PLL1LOCKEN(1'b1),
      .PLL1PD(1'b1), // Powered down!
      .PLL1REFCLKLOST(),
      .PLL1REFCLKSEL(3'd2), // GTREFCLK1
      .PLL1RESET(1'b0),

      .BGRCALOVRDENB(1'b1),
      .GTGREFCLK0(1'b0),
      .PLLRSVD1(16'h0000),
      .PLLRSVD2(5'h00),
      .REFCLKOUTMONITOR0(),
      .REFCLKOUTMONITOR1(),

      .PMARSVDOUT(),

      .BGBYPASSB(1'b1),
      .BGMONITORENB(1'b1),
      .BGPDB(1'b1),
      .BGRCALOVRD(5'h1f),
      .PMARSVD(8'h00),
      .RCALENB(1'b1)
      );

   IBUFDS_GTE2 ibufgte
     (
      .O(refclk),
      .ODIV2(),
      .CEB(1'b0),
      .I(gtx_refclk_p),
      .IB(gtx_refclk_n)
      );

   // RXOUTCLK is the CDR's output, and runs at 250 MHz, which is the internal
   // XCLK frequency with a 20 bit internal data width. Hence divide it by
   // two for generating the 125 MHz clock seen by logic fabric (USRCLK2).

   PLLE2_ADV
     #(.BANDWIDTH("OPTIMIZED"),
       .COMPENSATION("ZHOLD"),
       .DIVCLK_DIVIDE(1),
       .CLKFBOUT_MULT(4),
       .CLKFBOUT_PHASE(0.000),
       .CLKOUT0_DIVIDE(8),
       .CLKOUT0_PHASE(0.000),
       .CLKOUT0_DUTY_CYCLE(0.500),
       .CLKOUT1_DIVIDE(4),
       .CLKOUT1_PHASE(0.000),
       .CLKOUT1_DUTY_CYCLE(0.500),
       .CLKIN1_PERIOD(4.0))
   rxusrclk_pll
     (
      .CLKFBOUT(clkfbout_rx_pll),
      .CLKOUT0(pipe_rx_clk_pll),
      .CLKOUT1(pipe_rx_clk_x_2_pll),
      .CLKOUT2(),
      .CLKOUT3(),
      .CLKOUT4(),
      .CLKOUT5(),

      .CLKFBIN(clkfbout_rx_pll),
      .CLKIN1(rxoutclk_w),
      .CLKIN2(1'b0),

      .CLKINSEL(1'b1),

      .DADDR(7'h0),
      .DCLK(1'b0),
      .DEN(1'b0),
      .DI(16'h0),
      .DO(),
      .DRDY(),
      .DWE(1'b0),

      .LOCKED(rxusrclk_locked),
      .PWRDWN(1'b0),
      .RST(!pll_lock));

   // TXOUTCLK is connected directly to the GTP's reference clock input
   // and is therefore free running at 125 MHz (or what the board supplies).
   PLLE2_ADV
     #(.BANDWIDTH("OPTIMIZED"),
       .COMPENSATION("ZHOLD"),
       .DIVCLK_DIVIDE(1),
       .CLKFBOUT_MULT(8),
       .CLKFBOUT_PHASE(0.000),
       .CLKOUT0_DIVIDE(8),
       .CLKOUT0_PHASE(0.000),
       .CLKOUT0_DUTY_CYCLE(0.500),
       .CLKOUT1_DIVIDE(4),
       .CLKOUT1_PHASE(0.000),
       .CLKOUT1_DUTY_CYCLE(0.500),
       .CLKIN1_PERIOD(8.0))
   txusrclk_pll
     (
      .CLKFBOUT(clkfbout_tx_pll),
      .CLKOUT0(pipe_clk_pll),
      .CLKOUT1(pipe_clk_x_2_pll),
      .CLKOUT2(),
      .CLKOUT3(),
      .CLKOUT4(),
      .CLKOUT5(),

      .CLKFBIN(clkfbout_tx_pll),
      .CLKIN1(txoutclk_w),
      .CLKIN2(1'b0),

      .CLKINSEL(1'b1),

      .DADDR(7'h0),
      .DCLK(1'b0),
      .DEN(1'b0),
      .DI(16'h0),
      .DO(),
      .DRDY(),
      .DWE(1'b0),

      .LOCKED(txusrclk_locked),
      .PWRDWN(1'b0),
      .RST(1'b0));

   BUFG txoutclk_bufg
     (.I(txoutclk), .O(txoutclk_w));

   BUFG rxoutclk_bufg
     (.I(rxoutclk), .O(rxoutclk_w));

   BUFG rxusrclk_bufg
     (.I(pipe_rx_clk_x_2_pll), .O(pipe_rx_clk_x_2));

   BUFG rxusrclk2_bufg
     (.I(pipe_rx_clk_pll), .O(pipe_rx_clk));

   BUFG txusrclk_bufg
     (.I(pipe_clk_x_2_pll), .O(pipe_clk_x_2));

   BUFG txusrclk2_bufg
     (.I(pipe_clk_pll), .O(pipe_clk));

endmodule

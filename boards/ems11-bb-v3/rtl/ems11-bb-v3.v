/*
 *  Zet SoC top level file for ems11-bb-v3.0 board
 *  Copyright (C) 2014  Charley Picker <charleypicker@yahoo.com>
 *
 *  This file is part of the Zet processor. This processor is free
 *  hardware; you can redistribute it and/or modify it under the terms of
 *  the GNU General Public License as published by the Free Software
 *  Foundation; either version 3, or (at your option) any later version.
 *
 *  Zet is distrubuted in the hope that it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 *  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
 *  License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Zet; see the file COPYING. If not, see
 *  <http://www.gnu.org/licenses/>.
 */
 
module ems11_bb_v3 (

  // Clock input
  input        CLK50,

  // General purpose IO
  input RESET_N,     // System reset <- ems11-bb-v3.0 RESET push button
  input M1_T1,          // Flash floppy image boot <- ems11-bb-v3.0 S2 push button
  input M1_T2,          // Bootstrap BIOS from SD CARD <- ems11-bb-v3.0 S1 push button
  input DIAG_N,      // NMI pushbutton 

  // Segment display for BIOS Post Code
  output [6:0]  M1_SSEG_A,
  output [6:0]  M1_SSEG_B,

  output M1_LED1,
  output LED2,
  
    // sdram signals
    output [12:0] DR_A,
    inout  [15:0] DR_D,
    output        DR_DQMH,
    output        DR_DQML,
    output [ 1:0] DR_BA,
    output        DR_RAS_N,
    output        DR_CAS_N,
    output        DR_CKE,
    output        DR_CLK_O,
    output        DR_WE_N,
    output        DR_CS_N,

    // VGA signals
    output [ 3:0] M1_VGA_RED,
    output [ 3:0] M1_VGA_GREEN,
    output [ 3:0] M1_VGA_BLUE,
    output        M1_VGA_HSYNC,
    output        M1_VGA_VSYNC,
    output        M1_VGA_CLOCK,

    // PS2 signals
    input         M1_PS2_A_CLK, // PS2 keyboard Clock
    inout         M1_PS2_A_DATA, // PS2 Keyboard Data
    inout         M1_PS2_B_CLK, // PS2 Mouse Clock
    inout         M1_PS2_B_DATA, // PS2 Mouse Data

    // To speaker output
//    output        chassis_spk_,
//    output        speaker_l_,   // Speaker output, left channel
//    output        speaker_r_,   // Speaker output, right channel

  // Serial master bus signals 
  output FPGA_CCLK_2,  // spi_sclk
  input  FPGA_MISO1,   // spi_miso
  output FPGA_MOSI0,   // spi_mosi

  // Serial slave select signals
  output FPGA_CSO      // S25FL064P flash select

 ); 

  // Registers and nets
  wire        clk;
  wire        rst_lck;
  wire        lock;

  // Unused outputs
  wire [17:0] leds;
  
  wire [1:0] sdram_dqm_;  // Leave module pins unconnected
  assign DR_DQMH = 1'b0;  // Physical board pin must be tied to ground
  assign DR_DQML = 1'b0;  // Physical board pin must be tied to ground
  
  wire       a12;         // Leave module pin unconnected
  assign DR_A[12] = 1'b0; // Physical board pin must be tied to ground
  wire [2:0] s19_17;

  // wires to postcode port
  wire [ 7:0] postcode;

  // wires to SDRAM controller
  wire [ 2:0] csr_a;
  wire        csr_we;
  wire [15:0] csr_dw;
  wire [15:0] csr_dr_hpdmc;

  // wires to hpdmc slave interface 
  wire [25:0] fml_adr;
  wire        fml_stb;
  wire        fml_we;
  wire        fml_ack;
  wire [ 1:0] fml_sel;
  wire [15:0] fml_di;
  wire [15:0] fml_do;

  // wires to default stb/ack
  wire        sdram_clk;
  wire        sdram_clk_; // with phase adjustment
  wire        vga_clk;

  wire [19:0] cpu_pc;
  reg  [16:0] rst_debounce;
  
`ifndef SIMULATION
  /*
   * Debounce it (counter holds reset for 10.49ms),
   * and generate power-on reset.
   */
  initial rst_debounce <= 17'h1FFFF;
  reg rst;
  initial rst <= 1'b1;
  always @(posedge clk) begin
    if(~rst_lck) /* reset is active low */
      rst_debounce <= 17'h1FFFF;
    else if(rst_debounce != 17'd0)
      rst_debounce <= rst_debounce - 17'd1;
    rst <= rst_debounce != 17'd0;
  end
`else
  wire rst;
  assign rst = !rst_lck;
`endif

  // wires to spi master bus controller
  wire [15:0] spi_dat_i;
  wire [15:0] spi_dat_o;
  wire        spi_tga_o;
  wire [19:1] spi_adr_o;
  wire        spi_we_o;
  wire [ 1:0] spi_sel_o;
  wire        spi_stb_o;
  wire        spi_cyc_o;
  wire        spi_ack_i;
  
  // wires to spi bus
  wire        spi_sclk;
  wire        spi_miso;
  wire        spi_mosi;
  wire [7:0]  spi_ss;

  // Module instantiations
  kotku #(
  .fml_depth(23)
  ) kotku (
    // Clock input
    .clk_100_i(sdram_clk),
    .clk_12_5_i(clk),
    .rst_i(rst),

    // General purpose IO
    .sw_i({13'b0, M1_T2, M1_T1, !RESET_N}),
    .key_i(!DIAG_N),
    .leds_o({leds[17:6], LED2, M1_LED1, leds[3:0]}),

    // Diagnostic code port
    .postcode_o(postcode),

    // CPU Instruction Pointer
    .cpu_pc_o(cpu_pc),

    // CSR control bus - master interface - Clocked at 100Mhz
    .csr_adr_o(csr_a),
    .csr_we_o(csr_we),
    .csr_do(csr_dw),

    // FML 8x16  master interface - Clocked at 100Mhz
    .fml_adr_o(fml_adr),
    .fml_stb_o(fml_stb),
    .fml_we_o(fml_we),
    .fml_ack_i(fml_ack),
    .fml_sel_o(fml_sel),
    .fml_do(fml_do),
    .fml_di(fml_di),

    .fml_csr_di(csr_dr_hpdmc),

    // SD card signals - Clocked at 100Mhz
    .sd_sclk_o(),
    .sd_miso_i(),
    .sd_mosi_o(),
    .sd_ss_o(),

    // VGA signals - Clocked at 25Mhz
    .tft_lcd_r_o(M1_VGA_RED),
    .tft_lcd_g_o(M1_VGA_GREEN),
    .tft_lcd_b_o(M1_VGA_BLUE),
    .tft_lcd_hsync_o(M1_VGA_HSYNC),
    .tft_lcd_vsync_o(M1_VGA_VSYNC),
    .tft_lcd_clk_o(vga_clk),

    // Master interface - external flash controller - Clocked at 12.5Mhz
    .wb_fl_dat_i(spi_dat_i),
    .wb_fl_dat_o(spi_dat_o),
    .wb_fl_tga_o(spi_tga_o),
    .wb_fl_adr_o(spi_adr_o),
    .wb_fl_sel_o(spi_sel_o),
    .wb_fl_we_o(spi_we_o),
    .wb_fl_cyc_o(spi_cyc_o),
    .wb_fl_stb_o(spi_stb_o),
    .wb_fl_ack_i(spi_ack_i),

    // UART signals - Clocked at 12.5Mhz
    .uart_txd_o(),
    .uart_rxd_i(),

    // PS2 signals - Clocked at 12.5Mhz
    .ps2_kclk_i(M1_PS2_A_CLK), 	// PS2 keyboard Clock
    .ps2_kdat_io(M1_PS2_A_DATA), // PS2 Keyboard Data
    .ps2_mclk_io(M1_PS2_B_CLK), 	// PS2 Mouse Clock
    .ps2_mdat_io(M1_PS2_B_DATA), // PS2 Mouse Data

    // To expansion header - Clocked at 12.5Mhz
    .chassis_spk_o(),
    .speaker_l_o(),   // Speaker output, left channel
    .speaker_r_o()    // Speaker output, right channel

  );
  
  pll pll (
    .inclk0 (CLK50),
    .c0     (sdram_clk),  // 100 Mhz
    .c1     (sdram_clk_), // 100 Mhz with 30% phase to SDRAM chip
    .c2     (),           // 25Mhz - vga_clk
    .c3     (clk),        // 12.5 Mhz
    .locked (lock)
  );

  // The following spartan-6 clock forwarding technique
  // is needed when driving external clock pins
  wire sdram_clk_inv_;
  wire vga_clk_inv;

  assign sdram_clk_inv_ = ! sdram_clk_;
  assign vga_clk_inv = ! vga_clk;
  
  // Forward the sdram_clk_ clock
  ODDR2 #(
    .DDR_ALIGNMENT("NONE"),
    .INIT(1'b1),
    .SRTYPE("SYNC")
    ) sdram_oddr2 (
      .Q(DR_CLK_O),         // Now we have the correct clock to drive sdram chip!!!
      .C0(sdram_clk_),
      .C1(sdram_clk_inv_),   // Inverted clock input
      .CE(1'b1),
      .D0(1'b1),
      .D1(1'b0),
      .R(0),    // 1-bit reset input
      .S(0)     // 1-bit set input	 
  );
  
  // Forward the vga_clk clock
  ODDR2 #(
    .DDR_ALIGNMENT("NONE"),
    .INIT(1'b1),
    .SRTYPE("SYNC")
    ) vga_oddr2 (
      .Q(M1_VGA_CLOCK),     // Now we have the correct clock to drive vga DAC chip!!!
      .C0(vga_clk),
      .C1(vga_clk_inv),     // Inverted clock input
      .CE(1'b1),
      .D0(1'b1),
      .D1(1'b0),
      .R(0),    // 1-bit reset input
      .S(0)     // 1-bit set input   
  );

  hpdmc #(
    .csr_addr          (1'b0),
    .sdram_depth       (26),
    .sdram_columndepth (10)
    ) hpdmc (
    .sys_clk (sdram_clk),
    .sys_rst (rst),

    // CSR slave interface
    .csr_a  (csr_a),
    .csr_we (csr_we),
    .csr_di (csr_dw),
    .csr_do (csr_dr_hpdmc),

    // FML slave interface
    .fml_adr (fml_adr),
    .fml_stb (fml_stb),
    .fml_we  (fml_we),
    .fml_ack (fml_ack),
    .fml_sel (fml_sel),
    .fml_di  (fml_do),
    .fml_do  (fml_di),

    // SDRAM pad signals
    .sdram_cke   (DR_CKE),
    .sdram_cs_n  (DR_CS_N),
    .sdram_we_n  (DR_WE_N),
    .sdram_cas_n (DR_CAS_N),
    .sdram_ras_n (DR_RAS_N),
    .sdram_dqm   (sdram_dqm_),
    .sdram_adr   ({a12,DR_A[11:0]}),
    .sdram_ba    (DR_BA),
    .sdram_dq    (DR_D)
  );

  // Signals are inverted on the ems11-bb-v3.0 board!!!
  wire [6:0] M1_SSEG_A_INV;
  wire [6:0] M1_SSEG_B_INV;

  hex_display hex16 (
    .num ({postcode, 4'b0, cpu_pc[19:0]}),
    .en  (1'b1),

    .hex0 (hex0_),
    .hex1 (hex1_),
    .hex2 (hex2_),
    .hex3 (hex3_),
    .hex4 (hex4_),
    .hex5 (hex5_),
    .hex6 (M1_SSEG_A_INV),
    .hex7 (M1_SSEG_B_INV)
  );  

  // Perform bitwise inversion
  assign M1_SSEG_A = ~(M1_SSEG_A_INV);
  assign M1_SSEG_B = ~(M1_SSEG_B_INV);

spi spi (
    .wb_clk_i(clk), 
    .wb_rst_i(rst),
    .wb_dat_i(spi_dat_o),
    .wb_dat_o(spi_dat_i[7:0]),
    .wb_cyc_i(spi_cyc_o),
    .wb_stb_i(spi_stb_o),
    .wb_sel_i(spi_sel_o),
    .wb_we_i(spi_we_o),
    .wb_ack_o(spi_ack_i),

    // Serial master bus signals
    .sclk(spi_sclk),   // spi_sclk
    .miso(spi_miso),   // spi_miso
    .mosi(spi_mosi),   // spi_mosi

    // Max 1 slave per spi bus cycle
    .ss(spi_ss)
  );

  // Continuous assignments
  assign rst_lck    = RESET_N & lock;

  // External fpga spi pins 
  assign FPGA_CCLK_2 = spi_sclk; // spi_sclk
  assign spi_miso = FPGA_MISO1; // spi_miso
  assign FPGA_MOSI0  = spi_mosi; // spi_mosi

  // Spi S25FL064P flash memory select 
  assign FPGA_CSO = spi_ss[0];

endmodule
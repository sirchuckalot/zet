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
 
module kotku (

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
    output [11:0] DR_A,
    inout  [15:0] DR_D,
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
    output        chassis_spk_,
    output        speaker_l_,   // Speaker output, left channel
    output        speaker_r_,   // Speaker output, right channel

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
  wire [15:0] dat_o;
  wire [15:0] dat_i;
  wire [19:1] adr;
  wire        we;
  wire        tga;
  wire [ 1:0] sel;
  wire        stb;
  wire        cyc;
  wire        ack;
  wire        lock;

  // wires to BIOS ROM
  wire [15:0] rom_dat_o;
  wire [15:0] rom_dat_i;
  wire        rom_tga_i;
  wire [19:1] rom_adr_i;
  wire [ 1:0] rom_sel_i;
  wire        rom_we_i;
  wire        rom_cyc_i;
  wire        rom_stb_i;
  wire        rom_ack_o;

  // Unused outputs
  wire [17:0] leds;
  wire [1:0] sdram_dqm_;
  wire [2:0] s19_17;

  // Unused inputs
  wire uart_rxd_;

  // wires to vga controller
  wire [15:0] vga_dat_o;
  wire [15:0] vga_dat_i;
  wire        vga_tga_i;
  wire [19:1] vga_adr_i;
  wire [ 1:0] vga_sel_i;
  wire        vga_we_i;
  wire        vga_cyc_i;
  wire        vga_stb_i;
  wire        vga_ack_o;

  // cross clock domain synchronized signals
  wire [15:0] vga_dat_o_s;
  wire [15:0] vga_dat_i_s;
  wire        vga_tga_i_s;
  wire [19:1] vga_adr_i_s;
  wire [ 1:0] vga_sel_i_s;
  wire        vga_we_i_s;
  wire        vga_cyc_i_s;
  wire        vga_stb_i_s;
  wire        vga_ack_o_s;

  // wires for Sound module
  wire [19:1] wb_sb_adr_i;        // Sound Address
  wire [15:0] wb_sb_dat_i;        // Sound
  wire [15:0] wb_sb_dat_o;        // Sound
  wire [ 1:0] wb_sb_sel_i;        // Sound
  wire        wb_sb_cyc_i;        // Sound
  wire        wb_sb_stb_i;        // Sound
  wire        wb_sb_we_i;         // Sound
  wire        wb_sb_ack_o;        // Sound
  wire        wb_sb_tga_i;        // Sound

  // wires to keyboard controller
  wire [15:0] keyb_dat_o;
  wire [15:0] keyb_dat_i;
  wire        keyb_tga_i;
  wire [19:1] keyb_adr_i;
  wire [ 1:0] keyb_sel_i;
  wire        keyb_we_i;
  wire        keyb_cyc_i;
  wire        keyb_stb_i;
  wire        keyb_ack_o;

  // wires to timer controller
  wire [15:0] timer_dat_o;
  wire [15:0] timer_dat_i;
  wire        timer_tga_i;
  wire [19:1] timer_adr_i;
  wire [ 1:0] timer_sel_i;
  wire        timer_we_i;
  wire        timer_cyc_i;
  wire        timer_stb_i;
  wire        timer_ack_o;

  // wires to sd controller
  wire [19:1] sd_adr_i;
  wire [ 7:0] sd_dat_o;
  wire [15:0] sd_dat_i;
  wire        sd_tga_i;
  wire [ 1:0] sd_sel_i;
  wire        sd_we_i;
  wire        sd_cyc_i;
  wire        sd_stb_i;
  wire        sd_ack_o;

  // wires to sd bridge
  wire [19:1] sd_adr_i_s;
  wire [15:0] sd_dat_o_s;
  wire [15:0] sd_dat_i_s;
  wire        sd_tga_i_s;
  wire [ 1:0] sd_sel_i_s;
  wire        sd_we_i_s;
  wire        sd_cyc_i_s;
  wire        sd_stb_i_s;
  wire        sd_ack_o_s;
  
  // wires to gpio controller
  wire [15:0] gpio_dat_o;
  wire [15:0] gpio_dat_i;
  wire        gpio_tga_i;
  wire [19:1] gpio_adr_i;
  wire [ 1:0] gpio_sel_i;
  wire        gpio_we_i;
  wire        gpio_cyc_i;
  wire        gpio_stb_i;
  wire        gpio_ack_o;
  
  // wires to postcode port
  wire        post_stb_i;
  wire        post_cyc_i;
  wire        post_tga_i;
  wire [19:1] post_adr_i;
  wire        post_we_i;
  wire [ 1:0] post_sel_i;
  wire [15:0] post_dat_i;
  wire [15:0] post_dat_o;
  wire        post_ack_o;

  wire [ 7:0] postcode;

  // wires to SDRAM controller
  wire [19:1] fmlbrg_adr_s;
  wire [15:0] fmlbrg_dat_w_s;
  wire [15:0] fmlbrg_dat_r_s;
  wire [ 1:0] fmlbrg_sel_s;
  wire        fmlbrg_cyc_s;
  wire        fmlbrg_stb_s;
  wire        fmlbrg_tga_s;
  wire        fmlbrg_we_s;
  wire        fmlbrg_ack_s;

  wire [19:1] fmlbrg_adr;
  wire [15:0] fmlbrg_dat_w;
  wire [15:0] fmlbrg_dat_r;
  wire [ 1:0] fmlbrg_sel;
  wire        fmlbrg_cyc;
  wire        fmlbrg_stb;
  wire        fmlbrg_tga;
  wire        fmlbrg_we;
  wire        fmlbrg_ack;

  wire [19:1] csrbrg_adr_s;
  wire [15:0] csrbrg_dat_w_s;
  wire [15:0] csrbrg_dat_r_s;
  wire [ 1:0] csrbrg_sel_s;
  wire        csrbrg_cyc_s;
  wire        csrbrg_stb_s;
  wire        csrbrg_tga_s;
  wire        csrbrg_we_s;
  wire        csrbrg_ack_s;

  wire [19:1] csrbrg_adr;
  wire [15:0] csrbrg_dat_w;
  wire [15:0] csrbrg_dat_r;
  wire [ 1:0] csrbrg_sel;
  wire        csrbrg_tga;
  wire        csrbrg_cyc;
  wire        csrbrg_stb;
  wire        csrbrg_we;
  wire        csrbrg_ack;

  wire [ 2:0] csr_a;
  wire        csr_we;
  wire [15:0] csr_dw;
  wire [15:0] csr_dr_hpdmc;

  // wires to hpdmc slave interface 
  wire [22:0] fml_adr;
  wire        fml_stb;
  wire        fml_we;
  wire        fml_ack;
  wire [ 1:0] fml_sel;
  wire [15:0] fml_di;
  wire [15:0] fml_do;

  // wires to fml bridge master interface 
  wire [19:0] fml_fmlbrg_adr;
  wire        fml_fmlbrg_stb;
  wire        fml_fmlbrg_we;
  wire        fml_fmlbrg_ack;
  wire [ 1:0] fml_fmlbrg_sel;
  wire [15:0] fml_fmlbrg_di;
  wire [15:0] fml_fmlbrg_do;

  // wires to VGA CPU FML master interface
  wire [19:0]   vga_cpu_fml_adr;  // 1MB Memory Address range
  wire          vga_cpu_fml_stb;
  wire          vga_cpu_fml_we;
  wire          vga_cpu_fml_ack;
  wire [1:0]    vga_cpu_fml_sel;
  wire [15:0]   vga_cpu_fml_do;
  wire [15:0]   vga_cpu_fml_di;

  // wires to VGA LCD FML master interface
  wire [19:0]   vga_lcd_fml_adr;  // 1MB Memory Address range
  wire          vga_lcd_fml_stb;
  wire          vga_lcd_fml_we;
  wire          vga_lcd_fml_ack;
  wire [1:0]    vga_lcd_fml_sel;
  wire [15:0]   vga_lcd_fml_do;
  wire [15:0]   vga_lcd_fml_di;

  // wires to default stb/ack
  wire [15:0] sw_dat_o;
  wire        sdram_clk;
  wire        vga_clk;

  wire [ 7:0] intv;
  wire [ 2:0] iid;
  wire        intr;
  wire        inta;

  wire        nmi_pb;
  wire        nmi;
  wire        nmia;
  
  wire [19:0] cpu_pc;
  reg  [16:0] rst_debounce;
  
  wire        timer_clk;
  wire        timer2_o;

  // Audio only signals
  wire [ 7:0] aud_dat_o;
  wire        aud_cyc_i;
  wire        aud_ack_o;
  wire        aud_sel_cond;

  // Keyboard-audio shared signals
  wire [ 7:0] kaud_dat_o;
  wire        kaud_cyc_i;
  wire        kaud_ack_o;

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
  wire        spi_tga_i;
  wire [19:1] spi_adr_i;
  wire        spi_we_i;
  wire [ 1:0] spi_sel_i;
  wire        spi_stb_i;
  wire        spi_cyc_i;
  wire        spi_ack_o;
  
  // wires to spi bus
  wire        spi_sclk;
  wire        spi_miso;
  wire        spi_mosi;
  wire [7:0]  spi_ss;

  // Module instantiations
  pll pll (
    .inclk0 (CLK50),
    .c0     (sdram_clk),  // 100 Mhz
    .c1     (),           // 25 Mhz
    .c2     (clk),        // 12.5 Mhz
    .locked (lock)
  );
  
  // The following spartan-6 clock forwarding technique
  // is needed when driving external clock pins
  wire sdram_oddr2_clk;
  ODDR2 sdram_oddr2 (
    .D0(1'b1),
    .D1(1'b0),
	 .C0(!sdram_clk),     // Invert the input clock
	 .C1(sdram_oddr2_clk) // Now we have the correct clock to drive sdram chip!!!
  );
  
  wire vga_oddr2_clk;
  ODDR2 vga_oddr2 (
    .D0(1'b1),
    .D1(1'b0),
	 .C0(!vga_clk),     // Invert the input clock
	 .C1(vga_oddr2_clk) // Now we have the correct clock to drive vga DAC chip!!!
  );

  bootrom bootrom (
    .clk (clk),            // Wishbone slave interface
    .rst (rst),
    .wb_dat_i (rom_dat_i),
    .wb_dat_o (rom_dat_o),
    .wb_adr_i (rom_adr_i),
    .wb_we_i  (rom_we_i ),
    .wb_tga_i (rom_tga_i),
    .wb_stb_i (rom_stb_i),
    .wb_cyc_i (rom_cyc_i),
    .wb_sel_i (rom_sel_i),
    .wb_ack_o (rom_ack_o)
  );

  wb_abrgr wb_fmlbrg (
    .sys_rst (rst),

    // Wishbone slave interface
    .wbs_clk_i (clk),
    .wbs_adr_i (fmlbrg_adr_s),
    .wbs_dat_i (fmlbrg_dat_w_s),
    .wbs_dat_o (fmlbrg_dat_r_s),
    .wbs_sel_i (fmlbrg_sel_s),
    .wbs_tga_i (fmlbrg_tga_s),
    .wbs_stb_i (fmlbrg_stb_s),
    .wbs_cyc_i (fmlbrg_cyc_s),
    .wbs_we_i  (fmlbrg_we_s),
    .wbs_ack_o (fmlbrg_ack_s),

    // Wishbone master interface
    .wbm_clk_i (sdram_clk),
    .wbm_adr_o (fmlbrg_adr),
    .wbm_dat_o (fmlbrg_dat_w),
    .wbm_dat_i (fmlbrg_dat_r),
    .wbm_sel_o (fmlbrg_sel),
    .wbm_tga_o (fmlbrg_tga),
    .wbm_stb_o (fmlbrg_stb),
    .wbm_cyc_o (fmlbrg_cyc),
    .wbm_we_o  (fmlbrg_we),
    .wbm_ack_i (fmlbrg_ack)
  );

  fmlbrg #(
    .fml_depth   (20),  // 8086 can only address 1 MB
    .cache_depth (10)   // 1 Kbyte cache
    ) fmlbrg (
    .sys_clk  (sdram_clk),
    .sys_rst  (rst),

    // Wishbone slave interface
    .wb_adr_i (fmlbrg_adr),
    .wb_cti_i(3'b0),
    .wb_dat_i (fmlbrg_dat_w),
    .wb_dat_o (fmlbrg_dat_r),
    .wb_sel_i (fmlbrg_sel),
    .wb_cyc_i (fmlbrg_cyc),
    .wb_stb_i (fmlbrg_stb),
    .wb_tga_i (fmlbrg_tga),
    .wb_we_i  (fmlbrg_we),
    .wb_ack_o (fmlbrg_ack),

    // FML master 1 interface
    .fml_adr (fml_fmlbrg_adr),
    .fml_stb (fml_fmlbrg_stb),
    .fml_we  (fml_fmlbrg_we),
    .fml_ack (fml_fmlbrg_ack),
    .fml_sel (fml_fmlbrg_sel),
    .fml_do  (fml_fmlbrg_do),
    .fml_di  (fml_fmlbrg_di),

    // Direct Cache Bus
    .dcb_stb(1'b0),
    .dcb_adr(20'b0),
    .dcb_dat(),
    .dcb_hit()

  );

  wb_abrgr wb_csrbrg (
    .sys_rst (rst),

    // Wishbone slave interface
    .wbs_clk_i (clk),
    .wbs_adr_i (csrbrg_adr_s),
    .wbs_dat_i (csrbrg_dat_w_s),
    .wbs_dat_o (csrbrg_dat_r_s),
    .wbs_sel_i (csrbrg_sel_s),
    .wbs_tga_i (csrbrg_tga_s),
    .wbs_stb_i (csrbrg_stb_s),
    .wbs_cyc_i (csrbrg_cyc_s),
    .wbs_we_i  (csrbrg_we_s),
    .wbs_ack_o (csrbrg_ack_s),

    // Wishbone master interface
    .wbm_clk_i (sdram_clk),
    .wbm_adr_o (csrbrg_adr),
    .wbm_dat_o (csrbrg_dat_w),
    .wbm_dat_i (csrbrg_dat_r),
    .wbm_sel_o (csrbrg_sel),
    .wbm_tga_o (csrbrg_tga),
    .wbm_stb_o (csrbrg_stb),
    .wbm_cyc_o (csrbrg_cyc),
    .wbm_we_o  (csrbrg_we),
    .wbm_ack_i (csrbrg_ack)
  );

  csrbrg csrbrg (
    .sys_clk (sdram_clk),
    .sys_rst (rst),

    // Wishbone slave interface
    .wb_adr_i (csrbrg_adr[3:1]),
    .wb_dat_i (csrbrg_dat_w),
    .wb_dat_o (csrbrg_dat_r),
    .wb_cyc_i (csrbrg_cyc),
    .wb_stb_i (csrbrg_stb),
    .wb_we_i  (csrbrg_we),
    .wb_ack_o (csrbrg_ack),

    // CSR master interface
    .csr_a  (csr_a),
    .csr_we (csr_we),
    .csr_do (csr_dw),
    .csr_di (csr_dr_hpdmc)
  );

  fmlarb #(
    .fml_depth         (23)
    ) fmlarb (
    .sys_clk (sdram_clk),
  .sys_rst (rst),

  // Master 0 interface - VGA LCD FML (Reserved video memory port has highest priority)
  .m0_adr ({3'b001, vga_lcd_fml_adr}),  // 1 - 2 MB Addressable memory range
  .m0_stb (vga_lcd_fml_stb),
  .m0_we  (vga_lcd_fml_we),
  .m0_ack (vga_lcd_fml_ack),
  .m0_sel (vga_lcd_fml_sel),
  .m0_di  (vga_lcd_fml_do),
  .m0_do  (vga_lcd_fml_di),

  // Master 1 interface - Wishbone FML bridge
  .m1_adr ({3'b000, fml_fmlbrg_adr}),  // 0 - 1 MB Addressable memory range
  .m1_stb (fml_fmlbrg_stb),
  .m1_we  (fml_fmlbrg_we),
  .m1_ack (fml_fmlbrg_ack),
  .m1_sel (fml_fmlbrg_sel),
  .m1_di  (fml_fmlbrg_do),
  .m1_do  (fml_fmlbrg_di),

  // Master 2 interface - VGA CPU FML
  .m2_adr ({3'b001, vga_cpu_fml_adr}),  // 1 - 2 MB Addressable memory range
  .m2_stb (vga_cpu_fml_stb),
  .m2_we  (vga_cpu_fml_we),
  .m2_ack (vga_cpu_fml_ack),
  .m2_sel (vga_cpu_fml_sel),
  .m2_di  (vga_cpu_fml_do),
  .m2_do  (vga_cpu_fml_di),

  // Master 3 interface - not connected
  .m3_adr ({3'b010, 20'b0}),  // 2 - 3 MB Addressable memory range
  .m3_stb (1'b0),
  .m3_we  (1'b0),
  .m3_ack (),
  .m3_sel (2'b00),
  .m3_di  (16'h0000),
  .m3_do  (),

  // Master 4 interface - not connected
  .m4_adr ({3'b011, 20'b0}),  // 3 - 4 MB Addressable memory range
  .m4_stb (1'b0),
  .m4_we  (1'b0),
  .m4_ack (),
  .m4_sel (2'b00),
  .m4_di  (16'h0000),
  .m4_do  (),

  // Master 5 interface - not connected
  .m5_adr ({3'b100, 20'b0}),  // 4 - 5 MB Addressable memory range
  .m5_stb (1'b0),
  .m5_we  (1'b0),
  .m5_ack (),
  .m5_sel (2'b00),
  .m5_di  (16'h0000),
  .m5_do  (),

  // Arbitrer Slave interface - connected to hpdmc
  .s_adr (fml_adr),
  .s_stb (fml_stb),
  .s_we  (fml_we),
  .s_ack (fml_ack),
  .s_sel (fml_sel),
  .s_di  (fml_di),
  .s_do  (fml_do)
  );

  hpdmc #(
    .csr_addr          (1'b0),
    .sdram_depth       (23),
    .sdram_columndepth (8)
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
    .sdram_adr   (DR_A),
    .sdram_ba    (DR_BA),
    .sdram_dq    (DR_D)
  );

  wb_abrgr vga_brg (
    .sys_rst (rst),

    // Wishbone slave interface
    .wbs_clk_i (clk),
    .wbs_adr_i (vga_adr_i_s),
    .wbs_dat_i (vga_dat_i_s),
    .wbs_dat_o (vga_dat_o_s),
    .wbs_sel_i (vga_sel_i_s),
    .wbs_tga_i (vga_tga_i_s),
    .wbs_stb_i (vga_stb_i_s),
    .wbs_cyc_i (vga_cyc_i_s),
    .wbs_we_i  (vga_we_i_s),
    .wbs_ack_o (vga_ack_o_s),

    // Wishbone master interface
    .wbm_clk_i (sdram_clk),
    .wbm_adr_o (vga_adr_i),
    .wbm_dat_o (vga_dat_i),
    .wbm_dat_i (vga_dat_o),
    .wbm_sel_o (vga_sel_i),
    .wbm_tga_o (vga_tga_i),
    .wbm_stb_o (vga_stb_i),
    .wbm_cyc_o (vga_cyc_i),
    .wbm_we_o  (vga_we_i),
    .wbm_ack_i (vga_ack_o)
  );

  vga_fml #(
    .fml_depth   (20)  // 1MB Memory Address range
  ) vga (
    .wb_rst_i (rst),

    // Wishbone slave interface
    .wb_clk_i (sdram_clk),   // 100MHz VGA clock
    .wb_dat_i (vga_dat_i),
    .wb_dat_o (vga_dat_o),
    .wb_adr_i (vga_adr_i[16:1]),  // 128K
    .wb_we_i  (vga_we_i),
    .wb_tga_i (vga_tga_i),
    .wb_sel_i (vga_sel_i),
    .wb_stb_i (vga_stb_i),
    .wb_cyc_i (vga_cyc_i),
    .wb_ack_o (vga_ack_o),

    // VGA pad signals
    .vga_red_o   (M1_VGA_RED),
    .vga_green_o (M1_VGA_GREEN),
    .vga_blue_o  (M1_VGA_BLUE),
    .horiz_sync  (M1_VGA_HSYNC),
    .vert_sync   (M1_VGA_VSYNC),

    // VGA CPU FML master interface
    .vga_cpu_fml_adr(vga_cpu_fml_adr),
    .vga_cpu_fml_stb(vga_cpu_fml_stb),
    .vga_cpu_fml_we(vga_cpu_fml_we),
    .vga_cpu_fml_ack(vga_cpu_fml_ack),
    .vga_cpu_fml_sel(vga_cpu_fml_sel),
    .vga_cpu_fml_do(vga_cpu_fml_do),
    .vga_cpu_fml_di(vga_cpu_fml_di),

    // VGA LCD FML master interface
    .vga_lcd_fml_adr(vga_lcd_fml_adr),
    .vga_lcd_fml_stb(vga_lcd_fml_stb),
    .vga_lcd_fml_we(vga_lcd_fml_we),
    .vga_lcd_fml_ack(vga_lcd_fml_ack),
    .vga_lcd_fml_sel(vga_lcd_fml_sel),
    .vga_lcd_fml_do(vga_lcd_fml_do),
    .vga_lcd_fml_di(vga_lcd_fml_di),

    .vga_clk(vga_clk)

  );

  // Sound Module Instantiation
  sound sound (
    .wb_clk_i (clk),                // Main Clock
    .wb_rst_i (rst),                // Reset Line
    .wb_dat_i (wb_sb_dat_i),        // Command to send
    .wb_dat_o (wb_sb_dat_o),        // Received data
    .wb_cyc_i (wb_sb_cyc_i),        // Cycle
    .wb_stb_i (wb_sb_stb_i),        // Strobe
    .wb_adr_i (wb_sb_adr_i[3:1]),   // Address lines
    .wb_sel_i (wb_sb_sel_i),        // Select lines
    .wb_we_i  (wb_sb_we_i),         // Write enable
    .wb_ack_o (wb_sb_ack_o),        // Normal bus termination

    .audio_l (speaker_l_),          // Audio Output Left  Channel
    .audio_r (speaker_r_)           // Audio Output Right Channel
  );

  ps2 ps2 (
    .wb_clk_i (clk),             // Main Clock
    .wb_rst_i (rst),             // Reset Line
    .wb_adr_i (keyb_adr_i[2:1]), // Address lines
    .wb_sel_i (keyb_sel_i),      // Select lines
    .wb_dat_i (keyb_dat_i),      // Command to send to Ethernet
    .wb_dat_o (keyb_dat_o),
    .wb_we_i  (keyb_we_i),       // Write enable
    .wb_stb_i (keyb_stb_i),
    .wb_cyc_i (keyb_cyc_i),
    .wb_ack_o (keyb_ack_o),
    .wb_tgk_o (intv[1]),         // Keyboard Interrupt request
    .wb_tgm_o (intv[3]),         // Mouse Interrupt request

    .ps2_kbd_clk_ (M1_PS2_A_CLK),
    .ps2_kbd_dat_ (M1_PS2_A_DATA),
    .ps2_mse_clk_ (M1_PS2_B_CLK),
    .ps2_mse_dat_ (M1_PS2_B_DATA)
  );

  speaker speaker (
    .clk (clk),
    .rst (rst),

    .wb_dat_i (keyb_dat_i[15:8]),
    .wb_dat_o (aud_dat_o),
    .wb_we_i  (keyb_we_i),
    .wb_stb_i (keyb_stb_i),
    .wb_cyc_i (aud_cyc_i),
    .wb_ack_o (aud_ack_o),

    .timer2   (timer2_o),

    .speaker_ (chassis_spk_)
  );

  // Selection logic between keyboard and audio ports (port 65h: audio)
  assign aud_sel_cond = keyb_adr_i[2:1]==2'b00 && keyb_sel_i[1];
  assign aud_cyc_i    = kaud_cyc_i && aud_sel_cond;
  assign keyb_cyc_i   = kaud_cyc_i && !aud_sel_cond;
  assign kaud_ack_o   = aud_cyc_i & aud_ack_o | keyb_cyc_i & keyb_ack_o;
  assign kaud_dat_o   = {8{aud_cyc_i}} & aud_dat_o
                      | {8{keyb_cyc_i}} & keyb_dat_o[15:8];

  timer timer (
    .wb_clk_i (clk),
    .wb_rst_i (rst),
    .wb_adr_i (timer_adr_i[1]),
    .wb_sel_i (timer_sel_i),
    .wb_dat_i (timer_dat_i),
    .wb_dat_o (timer_dat_o),
    .wb_stb_i (timer_stb_i),
    .wb_cyc_i (timer_cyc_i),
    .wb_we_i  (timer_we_i),
    .wb_ack_o (timer_ack_o),
    .wb_tgc_o (intv[0]),
    .tclk_i   (timer_clk),     // 1.193182 MHz = (14.31818/12) MHz
    .gate2_i  (aud_dat_o[0]),
    .out2_o   (timer2_o)
  );

  simple_pic pic0 (
    .clk  (clk),
    .rst  (rst),
    .intv (intv),
    .inta (inta),
    .intr (intr),
    .iid  (iid)
  );

  wb_abrgr sd_brg (
    .sys_rst (rst),

    // Wishbone slave interface
    .wbs_clk_i (clk),
    .wbs_adr_i (sd_adr_i_s),
    .wbs_dat_i (sd_dat_i_s),
    .wbs_dat_o (sd_dat_o_s),
    .wbs_sel_i (sd_sel_i_s),
    .wbs_tga_i (sd_tga_i_s),
    .wbs_stb_i (sd_stb_i_s),
    .wbs_cyc_i (sd_cyc_i_s),
    .wbs_we_i  (sd_we_i_s),
    .wbs_ack_o (sd_ack_o_s),

    // Wishbone master interface
    .wbm_clk_i (sdram_clk),
    .wbm_adr_o (sd_adr_i),
    .wbm_dat_o (sd_dat_i),
    .wbm_dat_i ({8'h0,sd_dat_o}),
    .wbm_tga_o (sd_tga_i),
    .wbm_sel_o (sd_sel_i),
    .wbm_stb_o (sd_stb_i),
    .wbm_cyc_o (sd_cyc_i),
    .wbm_we_o  (sd_we_i),
    .wbm_ack_i (sd_ack_o)
  );

  sdspi sdspi (
    // Serial pad signal
    .sclk (sd_sclk_),
    .miso (sd_miso_),
    .mosi (sd_mosi_),
    .ss   (sd_ss_),

    // Wishbone slave interface
    .wb_clk_i (sdram_clk),
    .wb_rst_i (rst),
    .wb_dat_i (sd_dat_i[8:0]),
    .wb_dat_o (sd_dat_o),
    .wb_we_i  (sd_we_i),
    .wb_sel_i (sd_sel_i),
    .wb_stb_i (sd_stb_i),
    .wb_cyc_i (sd_cyc_i),
    .wb_ack_o (sd_ack_o)
  );

  post post (
    .wb_clk_i (clk),
    .wb_rst_i (rst),

    .wb_stb_i (post_stb_i),
    .wb_cyc_i (post_cyc_i),
    .wb_adr_i (post_adr_i),
    .wb_we_i  (post_we_i),
    .wb_sel_i (post_sel_i),
    .wb_dat_i (post_dat_i),
    .wb_dat_o (post_dat_o),
    .wb_ack_o (post_ack_o),

    .postcode (postcode)
  ); 
  
  // Switches and leds
  sw_leds sw_leds (
    .wb_clk_i (clk),
    .wb_rst_i (rst),

    // Wishbone slave interface
    .wb_adr_i (gpio_adr_i[1]),
    .wb_dat_o (gpio_dat_o),
    .wb_dat_i (gpio_dat_i),
    .wb_sel_i (gpio_sel_i),
    .wb_we_i  (gpio_we_i),
    .wb_stb_i (gpio_stb_i),
    .wb_cyc_i (gpio_cyc_i),
    .wb_ack_o (gpio_ack_o),

    // GPIO inputs/outputs
    // .leds_ ({ledr_,ledg_[7:4]}),
	 .leds_ ({leds[17:6], LED2, M1_LED1, leds[3:0]}), // output [9:0] ledr_, output [7:0] ledg_,
	 // .sw_   (sw_),
    .sw_   ({5'b0, M1_T2, M1_T1, !RESET_N}), // input  [7:0] sw_
    // .pb_   (key_),
	 .pb_   (!DIAG_N),
    .tick  (intv[0]),
    .nmi_pb (nmi_pb) // NMI from pushbutton
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
    .wb_dat_i(spi_dat_i),
    .wb_dat_o(spi_dat_o[7:0]),
    .wb_cyc_i(spi_cyc_i),
    .wb_stb_i(spi_stb_i),
    .wb_sel_i(spi_sel_i),
    .wb_we_i(spi_we_i),
    .wb_ack_o(spi_ack_o),

    // Serial master bus signals
    .sclk(spi_sclk),   // spi_sclk
    .miso(spi_miso),   // spi_miso
    .mosi(spi_mosi),   // spi_mosi

    // Max 1 slave per spi bus cycle
    .ss(spi_ss)
  );

  zet zet (
    .pc (cpu_pc),

    // Wishbone master interface
    .wb_clk_i (clk),
    .wb_rst_i (rst),
    .wb_dat_i (dat_i),
    .wb_dat_o (dat_o),
    .wb_adr_o (adr),
    .wb_we_o  (we),
    .wb_tga_o (tga),
    .wb_sel_o (sel),
    .wb_stb_o (stb),
    .wb_cyc_o (cyc),
    .wb_ack_i (ack),
    .wb_tgc_i (intr),
    .wb_tgc_o (inta),
    .nmi      (nmi),
    .nmia     (nmia)
  );

  wb_switch #(
    .s0_addr_1 (20'b0_1111_1111_1110_0000_000), // bios boot mem 0xffe00 - 0xfffff
    .s0_mask_1 (20'b1_1111_1111_1110_0000_000), // bios boot ROM Memory
	 
    .s1_addr_1 (20'b0_1010_0000_0000_0000_000), // mem 0xa0000 - 0xbffff
    .s1_mask_1 (20'b1_1110_0000_0000_0000_000), // VGA

    .s1_addr_2 (20'b1_0000_0000_0011_1100_000), // io 0x3c0 - 0x3df
    .s1_mask_2 (20'b1_0000_1111_1111_1110_000), // VGA IO

    .s2_addr_1 (20'b1_0000_0000_0011_1111_100), // io 0x3f8 - 0x3ff
    .s2_mask_1 (20'b1_0000_1111_1111_1111_100), // RS232 IO

    .s3_addr_1 (20'b1_0000_0000_0000_0110_000), // io 0x60, 0x64
    .s3_mask_1 (20'b1_0000_1111_1111_1111_101), // Keyboard / Mouse IO

    .s4_addr_1 (20'b1_0000_0000_0001_0000_000), // io 0x100 - 0x101
    .s4_mask_1 (20'b1_0000_1111_1111_1111_111), // SD Card IO

    .s5_addr_1 (20'b1_0000_1111_0001_0000_000), // io 0xf100 - 0xf103
    .s5_mask_1 (20'b1_0000_1111_1111_1111_110), // GPIO

    .s6_addr_1 (20'b1_0000_1111_0010_0000_000), // io 0xf200 - 0xf20f
    .s6_mask_1 (20'b1_0000_1111_1111_1111_000), // CSR Bridge SDRAM Control

    .s7_addr_1 (20'b1_0000_0000_0000_0100_000), // io 0x40 - 0x43
    .s7_mask_1 (20'b1_0000_1111_1111_1111_110), // Timer control port

    .s8_addr_1 (20'b1_0000_0000_0010_0011_100), // io 0x0238 - 0x023f
    .s8_mask_1 (20'b1_0000_1111_1111_1111_100), // SPI IO port

    .s9_addr_1 (20'b1_0000_0000_0010_0001_000), // io 0x0210 - 0x021F
    .s9_mask_1 (20'b1_0000_1111_1111_1111_000), // Sound Blaster

    .sA_addr_1 (20'b1_0000_1111_0011_0000_000), // io 0xf300 - 0xf3ff
    .sA_mask_1 (20'b1_0000_1111_1111_0000_000), // SDRAM Control
    .sA_addr_2 (20'b0_0000_0000_0000_0000_000), // mem 0x00000 - 0xfffff
    .sA_mask_2 (20'b1_0000_0000_0000_0000_000), // Base RAM
    
    .sB_addr_1 (20'h1_00000), //
    .sB_mask_1 (20'h1_FFFFF), // not used

    .sC_addr_1 (20'h1_00000), //
    .sC_mask_1 (20'h1_FFFFF), // not used

    .sD_addr_1 (20'b1_0000_0000_0000_1000_000), // io 0x0080
    .sD_mask_1 (20'b1_0000_1111_1111_1111_110), // postcode register

    .sE_addr_1 (20'h1_00000), //
    .sE_mask_1 (20'h1_FFFFF), // not used

    .sF_addr_1 (20'h1_00000), //
    .sF_mask_1 (20'h1_FFFFF)  // not used

    ) wbs (

    // Master interface
    .m_dat_i (dat_o),
    .m_dat_o (sw_dat_o),
    .m_adr_i ({tga,adr}),
    .m_sel_i (sel),
    .m_we_i  (we),
    .m_cyc_i (cyc),
    .m_stb_i (stb),
    .m_ack_o (ack),

    // Slave 0 interface - bios rom
    .s0_dat_i (rom_dat_o),
    .s0_dat_o (rom_dat_i),
    .s0_adr_o ({rom_tga_i,rom_adr_i}),
    .s0_sel_o (rom_sel_i),
    .s0_we_o  (rom_we_i),
    .s0_cyc_o (rom_cyc_i),
    .s0_stb_o (rom_stb_i),
    .s0_ack_i (rom_ack_o),

     // Slave 1 interface - vga
    .s1_dat_i (vga_dat_o_s),
    .s1_dat_o (vga_dat_i_s),
    .s1_adr_o ({vga_tga_i_s,vga_adr_i_s}),
    .s1_sel_o (vga_sel_i_s),
    .s1_we_o  (vga_we_i_s),
    .s1_cyc_o (vga_cyc_i_s),
    .s1_stb_o (vga_stb_i_s),
    .s1_ack_i (vga_ack_o_s),

    // Slave 2 interface - uart
    .s2_dat_i (16'h0000),
    .s2_dat_o (),
    .s2_adr_o (),
    .s2_sel_o (),
    .s2_we_o  (),
    .s2_cyc_o (),
    .s2_stb_o (),
    .s2_ack_i (1'b0),

    // Slave 3 interface - keyb
    .s3_dat_i ({kaud_dat_o,keyb_dat_o[7:0]}),
    .s3_dat_o (keyb_dat_i),
    .s3_adr_o ({keyb_tga_i,keyb_adr_i}),
    .s3_sel_o (keyb_sel_i),
    .s3_we_o  (keyb_we_i),
    .s3_cyc_o (kaud_cyc_i),
    .s3_stb_o (keyb_stb_i),
    .s3_ack_i (kaud_ack_o),

    // Slave 4 interface - sd
    .s4_dat_i (sd_dat_o_s),
    .s4_dat_o (sd_dat_i_s),
    .s4_adr_o ({sd_tga_i_s,sd_adr_i_s}),
    .s4_sel_o (sd_sel_i_s),
    .s4_we_o  (sd_we_i_s),
    .s4_cyc_o (sd_cyc_i_s),
    .s4_stb_o (sd_stb_i_s),
    .s4_ack_i (sd_ack_o_s),

    // Slave 5 interface - gpio
    .s5_dat_i (gpio_dat_o),
    .s5_dat_o (gpio_dat_i),
    .s5_adr_o ({gpio_tga_i,gpio_adr_i}),
    .s5_sel_o (gpio_sel_i),
    .s5_we_o  (gpio_we_i),
    .s5_cyc_o (gpio_cyc_i),
    .s5_stb_o (gpio_stb_i),
    .s5_ack_i (gpio_ack_o),

    // Slave 6 interface - csr bridge
    .s6_dat_i (csrbrg_dat_r_s),
    .s6_dat_o (csrbrg_dat_w_s),
    .s6_adr_o ({csrbrg_tga_s,csrbrg_adr_s}),
    .s6_sel_o (csrbrg_sel_s),
    .s6_we_o  (csrbrg_we_s),
    .s6_cyc_o (csrbrg_cyc_s),
    .s6_stb_o (csrbrg_stb_s),
    .s6_ack_i (csrbrg_ack_s),

    // Slave 7 interface - timer
    .s7_dat_i (timer_dat_o),
    .s7_dat_o (timer_dat_i),
    .s7_adr_o ({timer_tga_i,timer_adr_i}),
    .s7_sel_o (timer_sel_i),
    .s7_we_o  (timer_we_i),
    .s7_cyc_o (timer_cyc_i),
    .s7_stb_o (timer_stb_i),
    .s7_ack_i (timer_ack_o),

    // Slave 8 interface - spi
    .s8_dat_i (spi_dat_o),
    .s8_dat_o (spi_dat_i),
    .s8_adr_o ({spi_tga_i,spi_adr_i}),
    .s8_sel_o (spi_sel_i),
    .s8_we_o  (spi_we_i),
    .s8_cyc_o (spi_cyc_i),
    .s8_stb_o (spi_stb_i),
    .s8_ack_i (spi_ack_o),

    // Slave 9 interface - sb16
    .s9_dat_i (wb_sb_dat_o),
    .s9_dat_o (wb_sb_dat_i),
    .s9_adr_o ({wb_sb_tga_i,wb_sb_adr_i}),
    .s9_sel_o (wb_sb_sel_i),
    .s9_we_o  (wb_sb_we_i),
    .s9_cyc_o (wb_sb_cyc_i),
    .s9_stb_o (wb_sb_stb_i),
    .s9_ack_i (wb_sb_ack_o),

    // Slave A interface - sdram
    .sA_dat_i (fmlbrg_dat_r_s),
    .sA_dat_o (fmlbrg_dat_w_s),
    .sA_adr_o ({fmlbrg_tga_s,fmlbrg_adr_s}),
    .sA_sel_o (fmlbrg_sel_s),
    .sA_we_o  (fmlbrg_we_s),
    .sA_cyc_o (fmlbrg_cyc_s),
    .sA_stb_o (fmlbrg_stb_s),
    .sA_ack_i (fmlbrg_ack_s),

    // Slave B interface - not connected
        .sB_dat_i (16'h0000),
    .sB_dat_o (),
    .sB_adr_o (),   // tga_s, adr_s
    .sB_sel_o (),
    .sB_we_o  (),
    .sB_cyc_o (),
    .sB_stb_o (),
    .sB_ack_i (1'b0),

    // Slave C interface - not connected
    .sC_dat_i (16'h0000),
    .sC_dat_o (),
    .sC_adr_o (),   // tga_s, adr_s
    .sC_sel_o (),
    .sC_we_o  (),
    .sC_cyc_o (),
    .sC_stb_o (),
    .sC_ack_i (1'b0),

    // Slave D interface - bios post code port
    .sD_dat_i (post_dat_o),
    .sD_dat_o (post_dat_i),
    .sD_adr_o ({post_tga_i, post_adr_i}),   // tga_s, adr_s
    .sD_sel_o (post_sel_i),
    .sD_we_o  (post_we_i),
    .sD_cyc_o (post_cyc_i),
    .sD_stb_o (post_stb_i),
    .sD_ack_i (post_ack_o),

    // Slave E interface - not connected
    .sE_dat_i (16'h0000),
    .sE_dat_o (),
    .sE_adr_o (),   // tga_s, adr_s
    .sE_sel_o (),
    .sE_we_o  (),
    .sE_cyc_o (),
    .sE_stb_o (),
    .sE_ack_i (1'b0),

    // Slave F interface - not connected
    .sF_dat_i (16'h0000),
    .sF_dat_o (),
    .sF_adr_o (),   // tga_s, adr_s
    .sF_sel_o (),
    .sF_we_o  (),
    .sF_cyc_o (),
    .sF_stb_o (),
    .sF_ack_i (1'b0)
 
  );

  // Continuous assignments
  assign rst_lck    = RESET_N & lock;

  assign nmi = nmi_pb;
  assign dat_i = nmia ? 16'h0002 :
                (inta ? { 13'b0000_0000_0000_1, iid } :
                        sw_dat_o);

  assign DR_CLK_O = sdram_oddr2_clk;

  // Required ems11-bb-v3.0 adv7123 vga dac clock
  assign	M1_VGA_CLOCK = vga_oddr2_clk;
  
  // External fpga spi pins 
  assign FPGA_CCLK_2 = spi_sclk; // spi_sclk
  assign spi_miso = FPGA_MISO1; // spi_miso
  assign FPGA_MOSI0  = spi_mosi; // spi_mosi

  // Spi S25FL064P flash memory select 
  assign FPGA_CSO = spi_ss[0];

endmodule
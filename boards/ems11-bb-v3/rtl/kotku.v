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
	output LED2
		
 ); 

  // Registers and nets
  wire        clk;
  wire        rst;
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

  // wires to default stb/ack
  wire        sdram_clk;
  wire        vga_clk;

  wire [ 7:0] intv;
  
  wire        nmi_pb;
  
  wire [19:0] cpu_pc;
  
  // Module instantiations
  pll pll (
    .inclk0 (CLK50),
    .c0     (sdram_clk),  // 100 Mhz
    .c1     (vga_clk),    // 25 Mhz
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
    .sw_   ({5'b0, M1_T2, M1_T1, RESET_N}), // input  [7:0] sw_
    // .pb_   (key_),
	 .pb_   (DIAG_N),
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
    .wb_tgc_i (1'b0),
    .wb_tgc_o (),
    .nmi      (1'b0),
    .nmia     ()
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

    .s8_addr_1 (20'b1_0000_0000_0010_0011_100), // io 0x0238 - 0x023b
    .s8_mask_1 (20'b1_0000_1111_1111_1111_110), // Flash IO port

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
    .m_dat_o (dat_i),
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
    .s1_dat_i (16'h0000),
    .s1_dat_o (),
    .s1_adr_o (),
    .s1_sel_o (),
    .s1_we_o  (),
    .s1_cyc_o (),
    .s1_stb_o (),
    .s1_ack_i (1'b0),

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
    .s3_dat_i (16'h0000),
    .s3_dat_o (),
    .s3_adr_o (),
    .s3_sel_o (),
    .s3_we_o  (),
    .s3_cyc_o (),
    .s3_stb_o (),
    .s3_ack_i (1'b0),

    // Slave 4 interface - sd
    .s4_dat_i (),
    .s4_dat_o (),
    .s4_adr_o (),
    .s4_sel_o (),
    .s4_we_o  (),
    .s4_cyc_o (),
    .s4_stb_o (),
    .s4_ack_i (1'b0),

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
    .s6_dat_i (16'h0000),
    .s6_dat_o (),
    .s6_adr_o (),
    .s6_sel_o (),
    .s6_we_o  (),
    .s6_cyc_o (),
    .s6_stb_o (),
    .s6_ack_i (1'b0),

    // Slave 7 interface - timer
    .s7_dat_i (16'h0000),
    .s7_dat_o (),
    .s7_adr_o (),
    .s7_sel_o (),
    .s7_we_o  (),
    .s7_cyc_o (),
    .s7_stb_o (),
    .s7_ack_i (1'b0),

    // Slave 8 interface - flash
    .s8_dat_i (16'h0000),
    .s8_dat_o (),
    .s8_adr_o (),
    .s8_sel_o (),
    .s8_we_o  (),
    .s8_cyc_o (),
    .s8_stb_o (),
    .s8_ack_i (1'b0),

    // Slave 9 interface - not connected
    .s9_dat_i (16'h0000),
    .s9_dat_o (),
    .s9_adr_o (),   // tga_s, adr_s
    .s9_sel_o (),
    .s9_we_o  (),
    .s9_cyc_o (),
    .s9_stb_o (),
    .s9_ack_i (1'b0),

    // Slave A interface - sdram
    .sA_dat_i (16'h0000),
    .sA_dat_o (),
    .sA_adr_o (),
    .sA_sel_o (),
    .sA_we_o  (),
    .sA_cyc_o (),
    .sA_stb_o (),
    .sA_ack_i (1'b0),

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
  assign rst = !lock;

  assign DR_CLK_O = sdram_oddr2_clk;
  
  // Required ems11-bb-v3.0 adv7123 vga dac clock
  assign	M1_VGA_CLOCK = vga_oddr2_clk;
  
endmodule
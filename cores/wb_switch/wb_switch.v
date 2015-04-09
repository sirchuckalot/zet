/*
 *  Wishbone switch and address decoder
 *  Copyright (C) 2010  Zeus Gomez Marmolejo <zeus@aluzina.org>
 *  Copyright (C) 2008, 2009 Sebastien Bourdeauducq - http://lekernel.net
 *  Copyright (C) 2000 Johny Chi - chisuhua@yahoo.com.cn
 *  Updated to multi-master and wb bursting support by Charley Picker <charleypicker@yahoo.com>
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

module wb_switch #(
    parameter s0_addr_1 = 20'h00000,  // Default Values
    parameter s0_mask_1 = 20'h00000,
    parameter s1_addr_1 = 20'h00000,
    parameter s1_mask_1 = 20'h00000,
    parameter s1_addr_2 = 20'h00000,
    parameter s1_mask_2 = 20'h00000,
    parameter s2_addr_1 = 20'h00000,
    parameter s2_mask_1 = 20'h00000,
    parameter s3_addr_1 = 20'h00000,
    parameter s3_mask_1 = 20'h00000,
    parameter s4_addr_1 = 20'h00000,
    parameter s4_mask_1 = 20'h00000,
    parameter s5_addr_1 = 20'h00000,
    parameter s5_mask_1 = 20'h00000,
    parameter s6_addr_1 = 20'h00000,
    parameter s6_mask_1 = 20'h00000,
    parameter s7_addr_1 = 20'h00000,
    parameter s7_mask_1 = 20'h00000,
    parameter s8_addr_1 = 20'h00000,
    parameter s8_mask_1 = 20'h00000,
    parameter s9_addr_1 = 20'h00000,
    parameter s9_mask_1 = 20'h00000,
    parameter sA_addr_1 = 20'h00000,
    parameter sA_mask_1 = 20'h00000,
    parameter sA_addr_2 = 20'h00000,
    parameter sA_mask_2 = 20'h00000,
    parameter sB_addr_1 = 20'h00000,
    parameter sB_mask_1 = 20'h00000,
    parameter sC_addr_1 = 20'h00000,
    parameter sC_mask_1 = 20'h00000,
    parameter sD_addr_1 = 20'h00000,
    parameter sD_mask_1 = 20'h00000,
    parameter sE_addr_1 = 20'h00000,
    parameter sE_mask_1 = 20'h00000,
    parameter sF_addr_1 = 20'h00000,
    parameter sF_mask_1 = 20'h00000
  )(
    input sys_clk,
    input sys_rst,

    // Master 0 interface
    input  [15:0] m0_dat_i,
    output [15:0] m0_dat_o,
    input  [20:1] m0_adr_i,
    input  [ 2:0] m0_cti_i,
    input  [ 1:0] m0_sel_i,
    input         m0_we_i,
    input         m0_cyc_i,
    input         m0_stb_i,
    output        m0_ack_o,
    
    // Master 1 interface
    input  [15:0] m1_dat_i,
    output [15:0] m1_dat_o,
    input  [20:1] m1_adr_i,
    input  [ 2:0] m1_cti_i,
    input  [ 1:0] m1_sel_i,
    input         m1_we_i,
    input         m1_cyc_i,
    input         m1_stb_i,
    output        m1_ack_o,

    // Master 2 interface
    input  [15:0] m2_dat_i,
    output [15:0] m2_dat_o,
    input  [20:1] m2_adr_i,
    input  [ 2:0] m2_cti_i,
    input  [ 1:0] m2_sel_i,
    input         m2_we_i,
    input         m2_cyc_i,
    input         m2_stb_i,
    output        m2_ack_o,

    // Master 3 interface
    input  [15:0] m3_dat_i,
    output [15:0] m3_dat_o,
    input  [20:1] m3_adr_i,
    input  [ 2:0] m3_cti_i,
    input  [ 1:0] m3_sel_i,
    input         m3_we_i,
    input         m3_cyc_i,
    input         m3_stb_i,
    output        m3_ack_o,

    // Master 4 interface
    input  [15:0] m4_dat_i,
    output [15:0] m4_dat_o,
    input  [20:1] m4_adr_i,
    input  [ 2:0] m4_cti_i,
    input  [ 1:0] m4_sel_i,
    input         m4_we_i,
    input         m4_cyc_i,
    input         m4_stb_i,
    output        m4_ack_o,

    // Slave 0 interface
    input  [15:0] s0_dat_i,
    output [15:0] s0_dat_o,
    output [20:1] s0_adr_o,
    output [ 2:0] s0_cti_o,
    output [ 1:0] s0_sel_o,
    output        s0_we_o,
    output        s0_cyc_o,
    output        s0_stb_o,
    input         s0_ack_i,

    // Slave 1 interface
    input  [15:0] s1_dat_i,
    output [15:0] s1_dat_o,
    output [20:1] s1_adr_o,
    output [ 2:0] s1_cti_o,
    output [ 1:0] s1_sel_o,
    output        s1_we_o,
    output        s1_cyc_o,
    output        s1_stb_o,
    input         s1_ack_i,

    // Slave 2 interface
    input  [15:0] s2_dat_i,
    output [15:0] s2_dat_o,
    output [20:1] s2_adr_o,
    output [ 2:0] s2_cti_o,
    output [ 1:0] s2_sel_o,
    output        s2_we_o,
    output        s2_cyc_o,
    output        s2_stb_o,
    input         s2_ack_i,

    // Slave 3 interface
    input  [15:0] s3_dat_i,
    output [15:0] s3_dat_o,
    output [20:1] s3_adr_o,
    output [ 2:0] s3_cti_o,
    output [ 1:0] s3_sel_o,
    output        s3_we_o,
    output        s3_cyc_o,
    output        s3_stb_o,
    input         s3_ack_i,

    // Slave 4 interface
    input  [15:0] s4_dat_i,
    output [15:0] s4_dat_o,
    output [20:1] s4_adr_o,
    output [ 2:0] s4_cti_o,
    output [ 1:0] s4_sel_o,
    output        s4_we_o,
    output        s4_cyc_o,
    output        s4_stb_o,
    input         s4_ack_i,

    // Slave 5 interface
    input  [15:0] s5_dat_i,
    output [15:0] s5_dat_o,
    output [20:1] s5_adr_o,
    output [ 2:0] s5_cti_o,
    output [ 1:0] s5_sel_o,
    output        s5_we_o,
    output        s5_cyc_o,
    output        s5_stb_o,
    input         s5_ack_i,

    // Slave 6 interface
    input  [15:0] s6_dat_i,
    output [15:0] s6_dat_o,
    output [20:1] s6_adr_o,
    output [ 2:0] s6_cti_o,
    output [ 1:0] s6_sel_o,
    output        s6_we_o,
    output        s6_cyc_o,
    output        s6_stb_o,
    input         s6_ack_i,

    // Slave 7 interface
    input  [15:0] s7_dat_i,
    output [15:0] s7_dat_o,
    output [20:1] s7_adr_o,
    output [ 2:0] s7_cti_o,
    output [ 1:0] s7_sel_o,
    output        s7_we_o,
    output        s7_cyc_o,
    output        s7_stb_o,
    input         s7_ack_i,

    // Slave 8 interface
    input  [15:0] s8_dat_i,
    output [15:0] s8_dat_o,
    output [20:1] s8_adr_o,
    output [ 2:0] s8_cti_o,
    output [ 1:0] s8_sel_o,
    output        s8_we_o,
    output        s8_cyc_o,
    output        s8_stb_o,
    input         s8_ack_i,

    // Slave 9 interface
    input  [15:0] s9_dat_i,
    output [15:0] s9_dat_o,
    output [20:1] s9_adr_o,
    output [ 2:0] s9_cti_o,
    output [ 1:0] s9_sel_o,
    output        s9_we_o,
    output        s9_cyc_o,
    output        s9_stb_o,
    input         s9_ack_i,

    // Slave A interface
    input  [15:0] sA_dat_i,
    output [15:0] sA_dat_o,
    output [20:1] sA_adr_o,
    output [ 2:0] sA_cti_o,
    output [ 1:0] sA_sel_o,
    output        sA_we_o,
    output        sA_cyc_o,
    output        sA_stb_o,
    input         sA_ack_i,

    // Slave B interface
    input  [15:0] sB_dat_i,
    output [15:0] sB_dat_o,
    output [20:1] sB_adr_o,
    output [ 2:0] sB_cti_o,
    output [ 1:0] sB_sel_o,
    output        sB_we_o,
    output        sB_cyc_o,
    output        sB_stb_o,
    input         sB_ack_i,
    
    // Slave C interface
    input  [15:0] sC_dat_i,
    output [15:0] sC_dat_o,
    output [20:1] sC_adr_o,
    output [ 2:0] sC_cti_o,
    output [ 1:0] sC_sel_o,
    output        sC_we_o,
    output        sC_cyc_o,
    output        sC_stb_o,
    input         sC_ack_i,
    
    // Slave D interface
    input  [15:0] sD_dat_i,
    output [15:0] sD_dat_o,
    output [20:1] sD_adr_o,
    output [ 2:0] sD_cti_o,
    output [ 1:0] sD_sel_o,
    output        sD_we_o,
    output        sD_cyc_o,
    output        sD_stb_o,
    input         sD_ack_i,
    
    // Slave E interface
    input  [15:0] sE_dat_i,
    output [15:0] sE_dat_o,
    output [20:1] sE_adr_o,
    output [ 2:0] sE_cti_o,
    output [ 1:0] sE_sel_o,
    output        sE_we_o,
    output        sE_cyc_o,
    output        sE_stb_o,
    input         sE_ack_i,
    
    // Slave F interface
    input  [15:0] sF_dat_i,
    output [15:0] sF_dat_o,
    output [20:1] sF_adr_o,
    output [ 2:0] sF_cti_o,
    output [ 1:0] sF_sel_o,
    output        sF_we_o,
    output        sF_cyc_o,
    output        sF_stb_o,
    input         sF_ack_i

  );

// address + cti + data + byte select + cyc + we + stb
`define mbusw_ls  20 + 3 + 16 + 2 + 1 + 1 + 1

wire [15:0] slave_sel;
wire [ 2:0] gnt;
reg [`mbusw_ls -1:0] i_bus_m; // internal shared bus, master data and control to slave
wire [15:0] i_dat_s;    // internal shared bus, slave data to master
wire        def_ack_i; // default ack (we don't want to stall the bus)
wire        i_bus_ack; // internal shared bus, ack signal

// master 0
assign m0_dat_o = i_dat_s;
assign m0_ack_o = i_bus_ack & (gnt == 3'd0);

// master 1
assign m1_dat_o = i_dat_s;
assign m1_ack_o = i_bus_ack & (gnt == 3'd1);

// master 2
assign m2_dat_o = i_dat_s;
assign m2_ack_o = i_bus_ack & (gnt == 3'd2);

// master 3
assign m3_dat_o = i_dat_s;
assign m3_ack_o = i_bus_ack & (gnt == 3'd3);

// master 4
assign m4_dat_o = i_dat_s;
assign m4_ack_o = i_bus_ack & (gnt == 3'd4);

// not implemented devices..
assign def_ack_i = m_stb_i & m_cyc_i & ~(|slave_sel[15:0]);

// Bus Acknowlegement
assign i_bus_ack =   s0_ack_i | s1_ack_i | s2_ack_i | s3_ack_i | s4_ack_i | s5_ack_i | s6_ack_i |
                     s7_ack_i | s8_ack_i | s9_ack_i | sA_ack_i | sB_ack_i | sC_ack_i | sD_ack_i |
                     sE_ack_i | sF_ack_i | def_ack_i;
                     

// slave 0
assign {s0_adr_o, s0_cti_o, s0_sel_o, s0_dat_o, s0_we_o, s0_cyc_o, s0_stb_o} 
  = {i_bus_m[`mbusw_ls -1:2], i_bus_m[1] & slave_sel[0], i_bus_m[0]};

// slave 1
assign {s1_adr_o, s1_cti_o, s1_sel_o, s1_dat_o, s1_we_o, s1_cyc_o, s1_stb_o} 
  = {i_bus_m[`mbusw_ls -1:2], i_bus_m[1] & slave_sel[1], i_bus_m[0]};

// slave 2
assign {s2_adr_o, s2_cti_o, s2_sel_o, s2_dat_o, s2_we_o, s2_cyc_o, s2_stb_o} 
  = {i_bus_m[`mbusw_ls -1:2], i_bus_m[1] & slave_sel[2], i_bus_m[0]};

// slave 3
assign {s3_adr_o, s3_cti_o, s3_sel_o, s3_dat_o, s3_we_o, s3_cyc_o, s3_stb_o} 
  = {i_bus_m[`mbusw_ls -1:2], i_bus_m[1] & slave_sel[3], i_bus_m[0]};

// slave 4
assign {s4_adr_o, s4_cti_o, s4_sel_o, s4_dat_o, s4_we_o, s4_cyc_o, s4_stb_o} 
  = {i_bus_m[`mbusw_ls -1:2], i_bus_m[1] & slave_sel[4], i_bus_m[0]};

// slave 5
assign {s5_adr_o, s5_cti_o, s5_sel_o, s5_dat_o, s5_we_o, s5_cyc_o, s5_stb_o} 
  = {i_bus_m[`mbusw_ls -1:2], i_bus_m[1] & slave_sel[5], i_bus_m[0]};

// slave 6
assign {s6_adr_o, s6_cti_o, s6_sel_o, s6_dat_o, s6_we_o, s6_cyc_o, s6_stb_o} 
  = {i_bus_m[`mbusw_ls -1:2], i_bus_m[1] & slave_sel[6], i_bus_m[0]};

// slave 7
assign {s7_adr_o, s7_cti_o, s7_sel_o, s7_dat_o, s7_we_o, s7_cyc_o, s7_stb_o} 
  = {i_bus_m[`mbusw_ls -1:2], i_bus_m[1] & slave_sel[7], i_bus_m[0]};

// slave 8
assign {s8_adr_o, s8_cti_o, s8_sel_o, s8_dat_o, s8_we_o, s8_cyc_o, s8_stb_o} 
  = {i_bus_m[`mbusw_ls -1:2], i_bus_m[1] & slave_sel[8], i_bus_m[0]};

// slave 9
assign {s9_adr_o, s9_cti_o, s9_sel_o, s9_dat_o, s9_we_o, s9_cyc_o, s9_stb_o} 
  = {i_bus_m[`mbusw_ls -1:2], i_bus_m[1] & slave_sel[9], i_bus_m[0]};

// slave A
assign {sA_adr_o, sA_cti_o, sA_sel_o, sA_dat_o, sA_we_o, sA_cyc_o, sA_stb_o} 
  = {i_bus_m[`mbusw_ls -1:2], i_bus_m[1] & slave_sel[10], i_bus_m[0]};

// slave B
assign {sB_adr_o, sB_cti_o, sB_sel_o, sB_dat_o, sB_we_o, sB_cyc_o, sB_stb_o} 
  = {i_bus_m[`mbusw_ls -1:2], i_bus_m[1] & slave_sel[11], i_bus_m[0]};

// slave C
assign {sC_adr_o, sC_cti_o, sC_sel_o, sC_dat_o, sC_we_o, sC_cyc_o, sC_stb_o} 
  = {i_bus_m[`mbusw_ls -1:2], i_bus_m[1] & slave_sel[12], i_bus_m[0]};

// slave D
assign {sD_adr_o, sD_cti_o, sD_sel_o, sD_dat_o, sD_we_o, sD_cyc_o, sD_stb_o} 
  = {i_bus_m[`mbusw_ls -1:2], i_bus_m[1] & slave_sel[13], i_bus_m[0]};

// slave E
assign {sE_adr_o, sE_cti_o, sE_sel_o, sE_dat_o, sE_we_o, sE_cyc_o, sE_stb_o} 
  = {i_bus_m[`mbusw_ls -1:2], i_bus_m[1] & slave_sel[14], i_bus_m[0]};

// slave F
assign {sF_adr_o, sF_cti_o, sF_sel_o, sF_dat_o, sF_we_o, sF_cyc_o, sF_stb_o} 
  = {i_bus_m[`mbusw_ls -1:2], i_bus_m[1] & slave_sel[15], i_bus_m[0]};

always @(*) begin
  case(gnt)
    3'd0:    i_bus_m = {m0_adr_i, m0_cti_i, m0_sel_i, m0_dat_i, m0_we_i, m0_cyc_i, m0_stb_i};
    3'd1:    i_bus_m = {m1_adr_i, m1_cti_i, m1_sel_i, m1_dat_i, m1_we_i, m1_cyc_i, m1_stb_i};
    3'd2:    i_bus_m = {m2_adr_i, m2_cti_i, m2_sel_i, m2_dat_i, m2_we_i, m2_cyc_i, m2_stb_i};
    3'd3:    i_bus_m = {m3_adr_i, m3_cti_i, m3_sel_i, m3_dat_i, m3_we_i, m3_cyc_i, m3_stb_i};
    default: i_bus_m = {m4_adr_i, m4_cti_i, m4_sel_i, m4_dat_i, m4_we_i, m4_cyc_i, m4_stb_i};
  endcase
end

assign i_dat_s =   ({16{slave_sel[ 0]}} & s0_dat_i)
                  |({16{slave_sel[ 1]}} & s1_dat_i)
                  |({16{slave_sel[ 2]}} & s2_dat_i)
                  |({16{slave_sel[ 3]}} & s3_dat_i)
                  |({16{slave_sel[ 4]}} & s4_dat_i)
                  |({16{slave_sel[ 5]}} & s5_dat_i)
                  |({16{slave_sel[ 6]}} & s6_dat_i)
                  |({16{slave_sel[ 7]}} & s7_dat_i)
                  |({16{slave_sel[ 8]}} & s8_dat_i)
                  |({16{slave_sel[ 9]}} & s9_dat_i)
                  |({16{slave_sel[10]}} & sA_dat_i)
                  |({16{slave_sel[11]}} & sB_dat_i)
                  |({16{slave_sel[12]}} & sC_dat_i)
                  |({16{slave_sel[13]}} & sD_dat_i)
                  |({16{slave_sel[14]}} & sE_dat_i)
                  |({16{slave_sel[15]}} & sF_dat_i);

wire [4:0] req = {m4_cyc_i, m3_cyc_i, m2_cyc_i, m1_cyc_i, m0_cyc_i};

conbus_arb5 arb(
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),
  .req(req),
  .gnt(gnt)
);

// Bus Selection logic
assign slave_sel[ 0] =  ((i_bus_m[`mbusw_ls -1:20-1] & s0_mask_1) == s0_addr_1);

assign slave_sel[ 1] =  ((i_bus_m[`mbusw_ls -1:20-1] & s1_mask_1) == s1_addr_1)  |
                        ((i_bus_m[`mbusw_ls -1:20-1] & s1_mask_2) == s1_addr_2);

assign slave_sel[ 2] =  ((i_bus_m[`mbusw_ls -1:20-1] & s2_mask_1) == s2_addr_1);
assign slave_sel[ 3] =  ((i_bus_m[`mbusw_ls -1:20-1] & s3_mask_1) == s3_addr_1);
assign slave_sel[ 4] =  ((i_bus_m[`mbusw_ls -1:20-1] & s4_mask_1) == s4_addr_1);
assign slave_sel[ 5] =  ((i_bus_m[`mbusw_ls -1:20-1] & s5_mask_1) == s5_addr_1);
assign slave_sel[ 6] =  ((i_bus_m[`mbusw_ls -1:20-1] & s6_mask_1) == s6_addr_1);
assign slave_sel[ 7] =  ((i_bus_m[`mbusw_ls -1:20-1] & s7_mask_1) == s7_addr_1);
assign slave_sel[ 8] =  ((i_bus_m[`mbusw_ls -1:20-1] & s8_mask_1) == s8_addr_1);
assign slave_sel[ 9] =  ((i_bus_m[`mbusw_ls -1:20-1] & s9_mask_1) == s9_addr_1);

assign slave_sel[10] = (((i_bus_m[`mbusw_ls -1:20-1] & sA_mask_1) == sA_addr_1)  | 
                        (( i_bus_m[`mbusw_ls -1:20-1] & sA_mask_2)== sA_addr_2)) &
                           ~(|slave_sel[9:0]);

assign slave_sel[11] =  ((i_bus_m[`mbusw_ls -1:20-1] & sB_mask_1) == sB_addr_1);
assign slave_sel[12] =  ((i_bus_m[`mbusw_ls -1:20-1] & sC_mask_1) == sC_addr_1);
assign slave_sel[13] =  ((i_bus_m[`mbusw_ls -1:20-1] & sD_mask_1) == sD_addr_1);
assign slave_sel[14] =  ((i_bus_m[`mbusw_ls -1:20-1] & sE_mask_1) == sE_addr_1);
assign slave_sel[15] =  ((i_bus_m[`mbusw_ls -1:20-1] & sF_mask_1) == sF_addr_1);

endmodule

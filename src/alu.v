
//************************************************************************//
//PODES:    Processor Optimization for Deeply Embedded System                                                                 
//Web:      www.mcucore.club                         
//Bug report: sunyata.peng@foxmail.com                                                                          
//Q_Q:   2143971503         
//************************************************************************//
//                                                                          
//  PODES_M0O - PODES IP Core                              
//                                      
//                                                                          
//  This library is free software; you can redistribute it and/or           
//  modify it under the terms of the GNU Lesser General Public              
//  License as published by the Free Software Foundation; either            
//  version 2.1 of the License, or (at your option) any later version.      
//                                                                          
//  This library is distributed in the hope that it will be useful,         
//  but WITHOUT ANY WARRANTY; without even the implied warranty of          
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU       
//  Lesser General Public License for more details.                         
//                                                                          
//  Full details of the license can be found in the file LGPL.TXT.          
//                                                                          
//  You should have received a copy of the GNU Lesser General Public        
//  License along with this library; if not, write to the Free Software     
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA 
//                                                                          
//************************************************************************//
// File        : alu.v
// Author      : PODES
// Date        : 20200101
// Version     : 1.0
// Description : Algorithm Logic Unit for PODES.
//               Add, Mul, shift, logic.
// -----------------------------History-----------------------------------//
// Date      BY   Version  Change Description
//
// 20200101  PODES   1.0      Initial Release. 
//                                                                        
//************************************************************************//
// --- CVS information:
// ---    $Author: $
// ---    $Revision: $
// ---    $Id: $
// ---    $Log$ 
//
//************************************************************************//

module alu (
             opand1,
             opand2,
             optype,
             carry_in,
             nzcv,
             N_flag,
             Z_flag,
             C_flag,
             V_flag,
             
             alu_N_flag,
             alu_Z_flag,
             alu_C_flag,
             alu_V_flag,
             alu_result
             );

             
//-----------------------------------------------------------//
//                      INPUTS                               //
//-----------------------------------------------------------//
input [31:0]      opand1;
input [31:0]      opand2;
input [4:0]       optype;
input             carry_in;
input [1:0]       nzcv;
input             N_flag;
input             Z_flag;
input             C_flag;
input             V_flag;

//-----------------------------------------------------------//
//                      OUTPUTS                              //
//-----------------------------------------------------------//
             
output             alu_N_flag;
output             alu_Z_flag;
output             alu_C_flag;
output             alu_V_flag;
output [31:0]      alu_result;


//-----------------------------------------------------------//
//                    REGISTERS & WIRES                      //
//-----------------------------------------------------------//

reg         alu_N_flag;
reg         alu_Z_flag;
reg         alu_C_flag;
reg         alu_V_flag;

wire        add_carry_out;
wire        add_ov;
wire        add_C_flag;
wire        add_V_flag;
wire [31:0] add_result;

wire [31:0] log_shft_result;
wire        log_shft_cout;
wire        log_shft_C_flag;


wire [31:0] mul_opand1;
wire [31:0] mul_opand2;
wire [64:0] mul_result;


reg [31:0]  mux_result;


wire        tmp_N_flag;
wire        tmp_Z_flag;
wire        tmp_C_flag;
wire        tmp_V_flag;


wire [31:0] alu_result;

//-----------------------------------------------------------//
//                          PARAMETERS                       //
//-----------------------------------------------------------//
//parameter INV_0  = 1'b0;

`define OP_IDLE    5'h00
`define OP_BL      5'h01
`define OP_MSR     5'h02
`define OP_MRS     5'h03
`define OP_LSL     5'h04
`define OP_LSR     5'h05
`define OP_ASR     5'h06
`define OP_ADD     5'h07
`define OP_OR      5'h08
`define OP_AND     5'h09
`define OP_XOR     5'h0a
`define OP_RSR     5'h0b
`define OP_MUL     5'h0c
`define OP_MR      5'h0d
`define OP_MW      5'h0e
`define OP_CPS     5'h0f
`define OP_PUSH    5'h10
`define OP_POP     5'h11
`define OP_BX      5'h12
`define OP_BLX     5'h13


//-----------------------------------------------------------//
//                          ARCHITECTURE                     //
//-----------------------------------------------------------//

//adder
adder32 adder32_u0 (
                   .opand1(opand1),
                   .opand2(opand2),
                   .cin   (carry_in),
                   .cout  (add_carry_out),
                   .ov    (add_ov),
                   .sum   (add_result)
                   );               
 assign add_C_flag = add_carry_out;
 assign add_V_flag = add_ov;
                


//logic and shifter
log_shft log_shft_u0 (
                    .optype(optype),
                    .opand1 (opand1),
                    .opand2 (opand2),
                    .result (log_shft_result),
                    .cin    (C_flag),
                    .cout   (log_shft_cout)
                    );
assign log_shft_C_flag = log_shft_cout;



//multiplier
assign mul_opand1 = (optype == `OP_MUL) ? opand1 : 32'b0;
assign mul_opand2 = (optype == `OP_MUL) ? opand2 : 32'b0;
mul32x32 mul32x32_u0 (
                    .mul_result(mul_result),
                    .opand1 (mul_opand1),
                    .opand2 (mul_opand2)
                    );                 


always @ *
begin
    case (optype) 
          `OP_LSL,
          `OP_LSR,
          `OP_ASR,
          `OP_RSR,
          `OP_OR,
          `OP_XOR,
          `OP_AND:  mux_result = log_shft_result;
          `OP_MUL:  mux_result = mul_result[31:0];
          default: mux_result = add_result;
    endcase
end
      
assign tmp_N_flag = mux_result[31];
assign tmp_Z_flag = ~(|mux_result);   
assign tmp_C_flag = (optype == `OP_ADD) ? add_C_flag : log_shft_C_flag;
assign tmp_V_flag = add_V_flag;

assign alu_result = mux_result;

always @ *
begin
    case (nzcv) 
        2'b00: begin
                 alu_N_flag = tmp_N_flag;
                 alu_Z_flag = tmp_Z_flag;
                 alu_C_flag = tmp_C_flag;
                 alu_V_flag = tmp_V_flag;
               end
        2'b01: begin
                 alu_N_flag = N_flag;
                 alu_Z_flag = Z_flag;
                 alu_C_flag = C_flag;
                 alu_V_flag = V_flag;
               end
        2'b10: begin
                 alu_N_flag = tmp_N_flag;
                 alu_Z_flag = tmp_Z_flag;
                 alu_C_flag = C_flag;
                 alu_V_flag = V_flag;
               end
        2'b11: begin
                 alu_N_flag = tmp_N_flag;
                 alu_Z_flag = tmp_Z_flag;
                 alu_C_flag = tmp_C_flag;
                 alu_V_flag = V_flag;
               end
    endcase
end
   

endmodule



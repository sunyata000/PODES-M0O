
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
// File        : opand_proc.v
// Author      : PODES
// Date        : 20200101
// Version     : 1.0
// Description : operators decoder. 
//             If immediate, opand_in = {IMM_1, SIGN_0, INV_0, imm13}, where 
//             imm13[12] is sign flag.
//             else if register, opand_in = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0,
//             RegNum_5bit, ALIGN_0, 3'b0, 2'b01/10/11}
//             where 01: Halfword reorder; 10: Halfword reorder and sign extension; 
//             11: Byte reorder.
//             if ALIGN_1, low 2bit will be replaced by 2'b00.
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

module opand_proc (
                opand_in,
                opand_out,
                
                R0 ,
                R1 ,
                R2 ,
                R3 ,
                R4 ,
                R5 ,
                R6 ,
                R7 ,
                R8 ,
                R9 ,
                R10,
                R11,
                R12,
                SP ,
                LR ,
                PC 
                
                );

//-----------------------------------------------------------//
//                      INPUTS, OUTPUT                       //
//-----------------------------------------------------------//                                 
input [15:0] opand_in;   

input [31:0] R0 ;
input [31:0] R1 ;
input [31:0] R2 ;
input [31:0] R3 ;
input [31:0] R4 ;
input [31:0] R5 ;
input [31:0] R6 ;
input [31:0] R7 ;
input [31:0] R8 ;
input [31:0] R9 ;
input [31:0] R10;
input [31:0] R11;
input [31:0] R12;
input [31:0] SP ;
input [31:0] LR ;
input [31:0] PC ;

output [31:0] opand_out;   

//-----------------------------------------------------------//
//                      REGISTERS AND WIRES                  //
//-----------------------------------------------------------//
reg  [31:0] reg_val;
reg  [31:0] reg_val_tmp0;
wire [31:0] reg_val_tmp;

reg [31:0] opand_out;   


//-----------------------------------------------------------//
//                      PARAMETERS                           //
//-----------------------------------------------------------//




//-----------------------------------------------------------//
//                          ARCHITECTURE                     //
//-----------------------------------------------------------//
always @ *
begin
    if (opand_in[15] == 1'b0) //{IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, RegNum_5bit, 6'b0};
    case (opand_in[10:6])
//        5'b1????: reg_val = R0;
        5'b00000: reg_val = R0;
        5'b00001: reg_val = R1;
        5'b00010: reg_val = R2;
        5'b00011: reg_val = R3;
        5'b00100: reg_val = R4;
        5'b00101: reg_val = R5;
        5'b00110: reg_val = R6;
        5'b00111: reg_val = R7;
        5'b01000: reg_val = R8;
        5'b01001: reg_val = R9;
        5'b01010: reg_val = R10;
        5'b01011: reg_val = R11;
        5'b01100: reg_val = R12;
        5'b01101: reg_val = SP;
        5'b01110: reg_val = LR;
        5'b01111: reg_val = PC + 4;
        default:  reg_val = R0;
    endcase
    else
        reg_val = R0;
end

always @ * 
begin
    if (opand_in[15] == 1'b0) //{IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, RegNum_5bit, ALIGN_0, 5'b0};
    case (opand_in[1:0])
        2'b00: reg_val_tmp0 = reg_val;
        2'b01: reg_val_tmp0 = {reg_val[23:16], reg_val[31:24], reg_val[7:0], reg_val[15:8]}; //Halfword reorder
        2'b10: reg_val_tmp0 = {{16{reg_val[7]}}, reg_val[7:0], reg_val[15:8]}; //Halfword reorder and sign extention
        2'b11: reg_val_tmp0 = {reg_val[7:0], reg_val[15:8], reg_val[23:16], reg_val[31:24]}; //byte reorder  
    endcase
    else
        reg_val_tmp0 = reg_val;
end

assign reg_val_tmp[1:0]  = (opand_in[5]) ? 2'b00 : reg_val_tmp0[1:0];
assign reg_val_tmp[31:2] = reg_val_tmp0[31:2];

always @*
begin
    if (opand_in[15] == 1'b1) //{IMM_1, SIGN_0, INV_0, imm13};
        case (opand_in[14:13])
            2'b00: opand_out = {16'b0, 3'b0, opand_in[12:0]};
            2'b01: opand_out = ~({16'b0, 3'b0, opand_in[12:0]});
            2'b10: opand_out = {{19{opand_in[12]}}, opand_in[12:0]}; // Only B inst need it.
            2'b11: opand_out = ~({16'b0, 3'b0, opand_in[12:0]}); //if INV_1, then there is not SIGN_1.
        endcase
    else //{IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, RegNum_5bit, 6'b0};
        case (opand_in[14:11])      
            4'b0000: opand_out = reg_val_tmp;
            4'b0100: opand_out = ~(reg_val_tmp); 
            4'b0001: opand_out = {16'b0, reg_val_tmp[15:0]};
            4'b0010: opand_out = {24'b0, reg_val_tmp[7:0]};
            4'b1001: opand_out = {{16{reg_val_tmp[15]}}, reg_val_tmp[15:0]};
            4'b1010: opand_out = {{24{reg_val_tmp[7]}}, reg_val_tmp[7:0]};
            
            4'b0011: opand_out = reg_val_tmp;//Conflicted condition, dont care
            4'b0101: opand_out = reg_val_tmp;//if INV_1, there is not BYTE_1/HALF_1.
            4'b0110: opand_out = reg_val_tmp;//if INV_1, there is not BYTE_1/HALF_1.
            4'b0111: opand_out = reg_val_tmp;//if INV_1, there is not BYTE_1/HALF_1.
            4'b1000: opand_out = reg_val_tmp;//don't care
            4'b1011: opand_out = reg_val_tmp;//Conflicted condition, dont care
            4'b1100: opand_out = reg_val_tmp;//Conflicted condition, dont care
            4'b1101: opand_out = reg_val_tmp;//Conflicted condition, dont care
            4'b1110: opand_out = reg_val_tmp;//Conflicted condition, dont care
            4'b1111: opand_out = reg_val_tmp;//Conflicted condition, dont care
        endcase
end  

endmodule            
   
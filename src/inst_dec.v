
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
// File        : inst_dec.v
// Author      : PODES
// Date        : 20200101
// Version     : 1.0
// Description : Instruction decoder stage of IU. 
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

module inst_dec (

                rst_n,
                clk,
                inst,       //instruction input
                if_pc,      //PC of current instruction.
                fetch_nop,
                
                dec_hold,   //decoder stage has to be held. from Main FSM.
                dec_expt_insert, //insert exception instruction
                dec_nop ,
                id_bsy ,
                id_is_idle,
                id_thumb2,
                id_branch_op,                                
                id_data_depend,
                id_hardfault,   //hardfault is generated at decoder stage.
                
                id_pc ,
                optype,     //optype to execution stage
                opand1,
                opand2,
                opand3,
                opand4,
                carry_in,
                nzcv,
                sign_ext,
                byte_en,
                pc_used_for_dec_opand,
                                
                new_opand1, //input   get opand1,2
                new_opand2, //input   get opand1,2                
                xPSR,       //xPSR register  
                SP,         //SP (PSP or MSP)         
                tmp_opand1, //output  to generate opand1,2
                tmp_opand2, //output  to generate opand1,2
                
                dsb_inst,
                dmb_inst,
                isb_inst,
                bkpt_inst,
                yield_inst,
                wfe_inst  ,
                wfi_inst  ,
                sev_inst  ,
                svcall

                );
//-----------------------------------------------------------//
//                      INPUTS/OUTPUTS ports                 //
//-----------------------------------------------------------//
input             rst_n ;
input             clk   ;
input  [15:0]     inst  ;
input  [31:0]     if_pc ;
input             fetch_nop;

output [31:0]     id_pc ;
input             dec_hold;
input             dec_expt_insert;
input             dec_nop ;
output            id_bsy ;
output            id_is_idle;
output            id_thumb2;
output            id_branch_op;
output            id_data_depend;
output            id_hardfault;

output [4:0]      optype  ;
output [31:0]     opand1  ;
output [31:0]     opand2  ;
output [4:0]      opand3  ;
output [15:0]     opand4  ;
output            carry_in;
output [1:0]      nzcv    ;
output            sign_ext;
output [1:0]      byte_en;
output [31:0]     pc_used_for_dec_opand;

input  [31:0]     new_opand1;
input  [31:0]     new_opand2;
input  [31:0]     xPSR;
input  [31:0]     SP;
output [15:0]     tmp_opand1;
output [15:0]     tmp_opand2;

output            dsb_inst;
output            dmb_inst;
output            isb_inst;
output            bkpt_inst;
output            yield_inst;
output            wfe_inst  ;
output            wfi_inst  ;
output            sev_inst  ;
output            svcall     ;

//-----------------------------------------------------------//
//                    REGISTERS & WIRES                      //
//-----------------------------------------------------------//
reg [15:0]   tmp_opand1;
reg [15:0]   tmp_opand2;
reg [7:0]    shift_n;

reg [31:0]   id_pc;   

reg [4:0]    optype  ;     //optype to execution stage
reg [31:0]   opand1  ;
reg [31:0]   opand2  ;
reg [4:0]    opand3  ;
reg [15:0]   opand4  ;
reg          carry_in;
reg [1:0]    nzcv    ;
reg          sign_ext;
wire [31:0]  pc_used_for_dec_opand;

reg          dsb_inst;
reg          dmb_inst;
reg          isb_inst;

reg          bkpt_inst;
reg          yield_inst;
reg          wfe_inst  ;
reg          wfi_inst  ;
reg          sev_inst  ;

reg          id_hardfault; //Hardfault is generated at decoder stage.
reg          svcall     ;


reg [4:0]    nxt_optype  ;
reg [4:0]    nxt_opand3  ;
reg [15:0]   nxt_opand4  ;
reg          nxt_carry_in;
reg [1:0]    nxt_nzcv    ;
reg          nxt_sign_ext;

reg          nxt_dsb_inst;
reg          nxt_dmb_inst;
reg          nxt_isb_inst;


reg          nxt_bkpt_inst;
reg          nxt_yield_inst;
reg          nxt_wfe_inst  ;
reg          nxt_wfi_inst  ;
reg          nxt_sev_inst  ;

reg          nxt_id_hardfault; //Hardfault is generated at decoder stage.
reg          nxt_svcall    ;

wire [31:0]   nxt_opand1  ;
wire [31:0]   nxt_opand2  ;

wire [3:0]   pushpop_op2;  //RegNum to be push pop
wire [5:0]   regnum4;
wire [3:0]   stmldm_op2;
wire [5:0]   stmldm_regnum;

reg          cond_pass;

wire         I1;
wire         I2;
wire [31:0]  bl_op2;

reg  [1:0]   current_state;
reg  [1:0]   next_state;

reg  [15:0]  arm_inst_buf;

reg  [1:0]   byte_en;
reg  [1:0]   nxt_byte_en;


wire         N_flag ;
wire         Z_flag ;
wire         C_flag ;
wire         V_flag ;

//-----------------------------------------------------------//
//                          PARAMETERS                       //
//-----------------------------------------------------------//
parameter INV_0   = 1'b0;
parameter INV_1   = 1'b1;
parameter BYTE_0  = 1'b0;
parameter BYTE_1  = 1'b1;
parameter HALF_0  = 1'b0;
parameter HALF_1  = 1'b1;
parameter SIGN_0  = 1'b0;
parameter SIGN_1  = 1'b1;
parameter IMM_0   = 1'b0;
parameter IMM_1   = 1'b1;
parameter ALIGN_1 = 1'b1;

parameter ZERO_16 = 16'b0;
parameter ZERO_5  = 5'b0;


 parameter THUMB_STATE = 2'b01;
 parameter THUMB2_STATE  = 2'b10;
 
 
 parameter OP_IDLE     =  5'h00;
 parameter OP_BL       =  5'h01;
 parameter OP_MSR      =  5'h02;
 parameter OP_MRS      =  5'h03;
 parameter OP_LSL      =  5'h04;
 parameter OP_LSR      =  5'h05;
 parameter OP_ASR      =  5'h06;
 parameter OP_ADD      =  5'h07;
 parameter OP_OR       =  5'h08;
 parameter OP_AND      =  5'h09;
 parameter OP_XOR      =  5'h0a;
 parameter OP_RSR      =  5'h0b;
 parameter OP_MUL      =  5'h0c;
 parameter OP_MR       =  5'h0d;
 parameter OP_MW       =  5'h0e;
 parameter OP_CPS      =  5'h0f;
 parameter OP_PUSH     =  5'h10;
 parameter OP_POP      =  5'h11;
 parameter OP_BX       =  5'h12;
 parameter OP_BLX      =  5'h13;
 parameter OP_STM      =  5'h14;
 parameter OP_EXPT     =  5'h15;
 


//-----------------------------------------------------------//
//                          ARCHITECTURE                     //
//-----------------------------------------------------------//

assign N_flag = xPSR[31];
assign Z_flag = xPSR[30];
assign C_flag = xPSR[29];
assign V_flag = xPSR[28];

//switch between Thumb-2 state and Thumb state
//If dec_hold or dec_nop inserted, FSM should stayed at current state.
always @ *
begin
case (current_state)
    THUMB_STATE: begin
                if ((~dec_hold) && (~dec_nop) && (inst[15:11] == 5'b11110))
                    next_state = THUMB2_STATE;
                else
                    next_state = THUMB_STATE;
                end
    THUMB2_STATE: begin
                if ((~dec_hold) && (~dec_nop) )                
                    next_state = THUMB_STATE;
                else
                    next_state = THUMB2_STATE;
                end
    default:  next_state = THUMB_STATE;
endcase
end

always@ (posedge clk or negedge rst_n)
begin
  if (!rst_n)
    current_state <= THUMB_STATE;
 else 
    current_state <= next_state;
end

//buffer the first 16bit of ARM instruction
always@ (posedge clk or negedge rst_n)
begin
  if (!rst_n)
    arm_inst_buf <= 16'b0;
 else if ((~dec_hold) && (~dec_nop)) 
    arm_inst_buf <= inst;
end


always@*
begin
    nxt_optype  = OP_IDLE; //5'b00000;
    tmp_opand1  = 16'h8000;
    tmp_opand2  = 16'h8000;
	shift_n     = 8'b0;
    nxt_opand3  = 5'b10000;
    nxt_carry_in= 1'b0;
    nxt_nzcv    = 2'b01;
    nxt_sign_ext= 1'b0;
    nxt_byte_en = 2'b10;

    nxt_dsb_inst = 1'b0;
    nxt_dmb_inst = 1'b0;
    nxt_isb_inst = 1'b0;

    nxt_opand4 = 16'b0;
    nxt_id_hardfault = 1'b0;

    nxt_bkpt_inst = 1'b0;
    nxt_yield_inst = 1'b0;
    nxt_wfe_inst = 1'b0;
    nxt_wfi_inst = 1'b0;
    nxt_sev_inst = 1'b0;

    nxt_svcall = 1'b0;

    if ((current_state == THUMB2_STATE)) //begin to decode the 32bit Thrumb instruction.
    begin
        if ( {inst[15:14],inst[12]} == 3'b111) //BL instruction 31
        begin
            nxt_optype  = OP_BL;
            tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 1'b0, 4'b1111,6'b0}; //PC
            tmp_opand2  = {IMM_1, SIGN_0, INV_0, 13'b0};//no meaning. imm32 opand2 will be generated after opand_proc module.
            nxt_opand3  = {1'b0,4'b1111}; //PC, need update PC.
            nxt_carry_in= 1'b0;
            nxt_nzcv    = 2'b01; //No NZCV
            nxt_sign_ext= 1'b0;
        end
        else if ( (arm_inst_buf[10:5] == 6'b011100) && ({inst[15:14],inst[12]} == 3'b100) ) //MSR_REG instruction  72
        begin
            nxt_optype  = OP_MSR;
            tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 1'b0, arm_inst_buf[3:0],6'b0}; //Rn
            tmp_opand2  = {IMM_1, SIGN_0, INV_0, 13'b0}; //No meaning
            nxt_opand3  = (inst[7:1] == 7'b0000100) ? {1'b0,4'b1101} : {1'b1,4'b0000}; //if SYSm = 8/9, update SP.
            nxt_opand4  = {8'b0,inst[7:0]}; //SYSm value.
            nxt_carry_in= 1'b0;
            nxt_nzcv    = (inst[7:2] == 6'b0) ? 2'b00 : 2'b01; //if SYSm = 0/1/2/3, update NZCV, else No NZCV.
            nxt_sign_ext= 1'b0;
        end
        else if ( (arm_inst_buf[10:5] == 6'b011111) && ({inst[15:14],inst[12]} == 3'b100) ) //MRS instruction  72
        begin
            nxt_optype  = OP_MRS;
            tmp_opand1  = {IMM_1, SIGN_0, INV_0, 13'b0}; //No meaning
            tmp_opand2  = {IMM_1, SIGN_0, INV_0, 13'b0}; //No meaning
            nxt_opand3  = {1'b0,inst[11:8]}; //register to be write.
            nxt_opand4  = {8'b0,inst[7:0]}; //SYSm value.
            nxt_carry_in= 1'b0;
            nxt_nzcv    = 2'b01; //No NZCV
            nxt_sign_ext= 1'b0;
        end
        else if ( (inst[7:4] == 4'b0100) && ({inst[15:14],inst[13]} == 3'b100) && (arm_inst_buf[10:4] == 7'b0111011)) //DSB instruction 43
        begin
            nxt_optype = OP_IDLE;
            nxt_dsb_inst = 1'b1;  //No operation in next stage, just inform main FSM for DSB event.
        end
        else if ( (inst[7:4] == 4'b0101) && ({inst[15:14],inst[13]} == 3'b100) && (arm_inst_buf[10:4] == 7'b0111011)) //DMB instruction 41
        begin
            nxt_optype = OP_IDLE;
            nxt_dmb_inst = 1'b1; //No operation in next stage, just inform main FSM for DMB event.
        end
        else if ( (inst[7:4] == 4'b0110) && ({inst[15:14],inst[13]} == 3'b100) && (arm_inst_buf[10:4] == 7'b0111011)) //ISB instruction 46
        begin
            nxt_optype = OP_IDLE;
            nxt_isb_inst = 1'b1;  //No operation in next stage, just inform main FSM for ISB event.
        end
        else  //Unimplemented instruction
        begin
            nxt_optype = OP_IDLE;
            nxt_id_hardfault = 1'b1;
        end
    end
    else //16bit Thumb instruction
    begin
      case (inst[15:11])
          5'b11110: begin //first half of a Thumb-2 inst
                      nxt_optype  = OP_IDLE;  //No operation in this cycle.
                    end


          5'b00000: begin //LSL 63
                      nxt_optype  = OP_LSL;
                      tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00, inst[5:3],6'b0};
                      tmp_opand2  = {IMM_1, SIGN_0, INV_0, 8'b0, inst[10:6]};
                      nxt_opand3  = {2'b0,inst[2:0]};
                      nxt_carry_in= 1'b0;
                      nxt_nzcv    = 2'b11; //NZC
                      nxt_sign_ext= 1'b0;
                    end


          5'b00001: begin //LSR 65
                      nxt_optype  = OP_LSR;
                      tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00, inst[5:3],6'b0};
                      shift_n     = (inst[10:6] == 5'b0) ? 8'h20 : {3'b0, inst[10:6]};
                      tmp_opand2  = {IMM_1, SIGN_0, INV_0, 5'b0, shift_n};
                      nxt_opand3  = {2'b0,inst[2:0]};
                      nxt_carry_in= 1'b0;
                      nxt_nzcv    = 2'b11; //NZC
                      nxt_sign_ext= 1'b0;
                    end


          5'b00010: begin //ASR 25
                      nxt_optype  = OP_ASR;
                      tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00, inst[5:3],6'b0};
                      shift_n     = (inst[10:6] == 5'b0) ? 8'h20 : {3'b0, inst[10:6]};
					  tmp_opand2  = {IMM_1, SIGN_0, INV_0, 5'b0, shift_n};
                      nxt_opand3  = {2'b0,inst[2:0]};
                      nxt_carry_in= 1'b0;
                      nxt_nzcv    = 2'b11; //NZC
                      nxt_sign_ext= 1'b0;
                    end


          5'b00011: begin //ADD_REG 19, SUB_REG 101, ADD_IMM 17, SUB_IMM 99
                      nxt_optype  = OP_ADD;
                      tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00, inst[5:3],6'b0};
                      nxt_opand3  = {2'b0,inst[2:0]};
                      nxt_nzcv    = 2'b00;  //NZCV
                      nxt_sign_ext= 1'b0;
                      case(inst[10:9])
                        2'b00: begin //ADD_REG 19
                                 tmp_opand2  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00, inst[8:6],6'b0};
                                 nxt_carry_in= 1'b0;
                               end
                        2'b01: begin //SUB_REG 101
                                 tmp_opand2  = {IMM_0, SIGN_0, INV_1, BYTE_0, HALF_0, 2'b00, inst[8:6],6'b0};
                                 nxt_carry_in= 1'b1;
                               end
                        2'b10: begin //ADD_IMM 17
                                 tmp_opand2  = {IMM_1, SIGN_0, INV_0, 10'b0,inst[8:6]};
                                 nxt_carry_in= 1'b0;
                               end
                        2'b11: begin //SUB_IMM 99
                                 tmp_opand2  = {IMM_1, SIGN_0, INV_1, 10'b0,inst[8:6]};
                                 nxt_carry_in= 1'b1;
                               end
                      endcase
                    end


          5'b00100: begin //MOV_IMM 67
                      nxt_optype  = OP_OR;
                      tmp_opand1  = {IMM_1, SIGN_0, INV_0, 5'b0,inst[7:0]};
                      tmp_opand2  = {IMM_1, SIGN_0, INV_0, 13'b0};
                      nxt_opand3  = {2'b0,inst[10:8]};
                      nxt_carry_in= 1'b0;
                      nxt_nzcv    = 2'b10; //NZ
                      nxt_sign_ext= 1'b0;
                    end


          5'b00101: begin //CMP_IMM 35
                      nxt_optype  = OP_ADD;
                      tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00,inst[10:8], 6'b0};
                      tmp_opand2  = {IMM_1, SIGN_0, INV_1, 5'b0, inst[7:0]}; //inverting
                      nxt_opand3  = {2'b10,inst[10:8]}; //Cancel result
                      nxt_carry_in= 1'b1;
                      nxt_nzcv    = 2'b00; //NZCV
                      nxt_sign_ext= 1'b0;
                    end


          5'b00110: begin //ADD_IMM 17
                      nxt_optype  = OP_ADD;
                      tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00,inst[10:8], 6'b0};
                      tmp_opand2  = {IMM_1, SIGN_0, INV_0, 5'b0, inst[7:0]};
                      nxt_opand3  = {2'b00,inst[10:8]};
                      nxt_carry_in= 1'b0;
                      nxt_nzcv    = 2'b00; //NZCV
                      nxt_sign_ext= 1'b0;
                    end


          5'b10100: begin //ADR 23
                      nxt_optype  = OP_ADD;
                      tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 1'b0, 4'b1111, ALIGN_1, 5'b0}; //PC
                      tmp_opand2  = {IMM_1, SIGN_0, INV_0, 3'b0, inst[7:0], 2'b00}; //imm8*4
                      nxt_opand3  = {2'b00,inst[10:8]};
                      nxt_carry_in= 1'b0;
                      nxt_nzcv    = 2'b01; //no NZCV
                      nxt_sign_ext= 1'b0;
                    end


          5'b00111: begin //SUB_IMM 99
                      nxt_optype  = OP_ADD;
                      tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00,inst[10:8], 6'b0};
                      tmp_opand2  = {IMM_1, SIGN_0, INV_1, 5'b0, inst[7:0]}; //inverting
                      nxt_opand3  = {2'b0,inst[10:8]};
                      nxt_carry_in= 1'b1;
                      nxt_nzcv    = 2'b00; //NZCV
                      nxt_sign_ext= 1'b0;
                    end


          5'b01000: begin //AND_REG 24, and other 20 instructions.
                      if(inst[10] == 1'b0)
                        case (inst[9:6])
                          4'b0000: begin //AND_REG 24
                                     nxt_optype  = OP_AND;
                                     tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00,inst[2:0], 6'b0};
                                     tmp_opand2  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00,inst[5:3], 6'b0};
                                     nxt_opand3  = {2'b0,inst[2:0]};
                                     nxt_carry_in= 1'b0;
                                     nxt_nzcv    = 2'b10; //NZ
                                     nxt_sign_ext= 1'b0;
                                   end
                          4'b0001: begin //XOR_REG 45
                                     nxt_optype  = OP_XOR;
                                     tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00,inst[2:0], 6'b0};
                                     tmp_opand2  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00,inst[5:3], 6'b0};
                                     nxt_opand3  = {2'b0,inst[2:0]};
                                     nxt_carry_in= 1'b0;
                                     nxt_nzcv    = 2'b10; //NZ
                                     nxt_sign_ext= 1'b0;
                                   end
                          4'b0010: begin //LSL_REG 64
                                     nxt_optype  = OP_LSL;
                                     tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00,inst[2:0], 6'b0};
                                     tmp_opand2  = {IMM_0, SIGN_0, INV_0, BYTE_1, HALF_0, 2'b00,inst[5:3], 6'b0};
                                     nxt_opand3  = {2'b0,inst[2:0]};
                                     nxt_carry_in= 1'b0;
                                     nxt_nzcv    = 2'b11; //NZC
                                     nxt_sign_ext= 1'b0;
                                   end
                          4'b0011: begin //LSR_REG 66
                                     nxt_optype  = OP_LSR;
                                     tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00,inst[2:0], 6'b0};
                                     tmp_opand2  = {IMM_0, SIGN_0, INV_0, BYTE_1, HALF_0, 2'b00,inst[5:3], 6'b0};
                                     nxt_opand3  = {2'b0,inst[2:0]};
                                     nxt_carry_in= 1'b0;
                                     nxt_nzcv    = 2'b11; //NZC
                                     nxt_sign_ext= 1'b0;
                                   end
                          4'b0100: begin //ASR_REG 26
                                     nxt_optype  = OP_ASR;
                                     tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00,inst[2:0], 6'b0};
                                     tmp_opand2  = {IMM_0, SIGN_0, INV_0, BYTE_1, HALF_0, 2'b00,inst[5:3], 6'b0};
                                     nxt_opand3  = {2'b0,inst[2:0]};
                                     nxt_carry_in= 1'b0;
                                     nxt_nzcv    = 2'b11; //NZC
                                     nxt_sign_ext= 1'b0;
                                   end
                          4'b0101: begin //ADC_REG 15
                                     nxt_optype  = OP_ADD;
                                     tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00,inst[2:0], 6'b0};
                                     tmp_opand2  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00,inst[5:3], 6'b0};
                                     nxt_opand3  = {2'b0,inst[2:0]};
                                     nxt_carry_in= C_flag;
                                     nxt_nzcv    = 2'b00; //NZCV
                                     nxt_sign_ext= 1'b0;
                                   end
                          4'b0110: begin //SBC_REG 87
                                     nxt_optype  = OP_ADD;
                                     tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00,inst[2:0], 6'b0};
                                     tmp_opand2  = {IMM_0, SIGN_0, INV_1, BYTE_0, HALF_0, 2'b00,inst[5:3], 6'b0};
                                     nxt_opand3  = {2'b0,inst[2:0]};
                                     nxt_carry_in= C_flag;
                                     nxt_nzcv    = 2'b00; //NZCV
                                     nxt_sign_ext= 1'b0;
                                   end
                          4'b0111: begin //ROR_REG 85
                                     nxt_optype  = OP_RSR;
                                     tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00,inst[2:0], 6'b0};
                                     tmp_opand2  = {IMM_0, SIGN_0, INV_0, BYTE_1, HALF_0, 2'b00,inst[5:3], 6'b0};
                                     nxt_opand3  = {2'b0,inst[2:0]};
                                     nxt_carry_in= C_flag;
                                     nxt_nzcv    = 2'b11; //NZC
                                     nxt_sign_ext= 1'b0;
                                   end
                          4'b1000: begin //TST_REG 106
                                     nxt_optype  = OP_AND;
                                     tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00,inst[2:0], 6'b0};
                                     tmp_opand2  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00,inst[5:3], 6'b0};
                                     nxt_opand3  = {2'b10,inst[2:0]}; //Cancel result
                                     nxt_carry_in= 1'b0;
                                     nxt_nzcv    = 2'b11; //NZC
                                     nxt_sign_ext= 1'b0;
                                   end
                          4'b1001: begin //RSB_IMM 86
                                     nxt_optype  = OP_ADD;
                                     tmp_opand1  = {IMM_1, SIGN_0, INV_0, 13'b0};
                                     tmp_opand2  = {IMM_0, SIGN_0, INV_1, BYTE_0, HALF_0, 2'b00,inst[5:3], 6'b0};
                                     nxt_opand3  = {2'b00,inst[2:0]};
                                     nxt_carry_in= 1'b1;
                                     nxt_nzcv    = 2'b00; //NZCV
                                     nxt_sign_ext= 1'b0;
                                   end
                          4'b1010: begin //CMP_REG 37
                                     nxt_optype  = OP_ADD;
                                     tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00,inst[2:0], 6'b0};
                                     tmp_opand2  = {IMM_0, SIGN_0, INV_1, BYTE_0, HALF_0, 2'b00,inst[5:3], 6'b0};
                                     nxt_opand3  = {2'b10,inst[2:0]}; //Cancel result
                                     nxt_carry_in= 1'b1;
                                     nxt_nzcv    = 2'b00; //NZCV
                                     nxt_sign_ext= 1'b0;
                                   end
                          4'b1011: begin //CMN_REG 34
                                     nxt_optype  = OP_ADD;
                                     tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00,inst[2:0], 6'b0};
                                     tmp_opand2  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00,inst[5:3], 6'b0};
                                     nxt_opand3  = {2'b10,inst[2:0]}; //Cancel result
                                     nxt_carry_in= 1'b0;
                                     nxt_nzcv    = 2'b00; //NZCV
                                     nxt_sign_ext= 1'b0;
                                   end
                          4'b1100: begin //ORR_REG 78
                                     nxt_optype  = OP_OR;
                                     tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00,inst[2:0], 6'b0};
                                     tmp_opand2  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00,inst[5:3], 6'b0};
                                     nxt_opand3  = {2'b00,inst[2:0]};
                                     nxt_carry_in= 1'b0;
                                     nxt_nzcv    = 2'b10; //NZ
                                     nxt_sign_ext= 1'b0;
                                   end
                          4'b1101: begin //MUL_REG 73
                                     nxt_optype  = OP_MUL;
                                     tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00,inst[2:0], 6'b0};
                                     tmp_opand2  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00,inst[5:3], 6'b0};
                                     nxt_opand3  = {2'b00,inst[2:0]};
                                     nxt_carry_in= 1'b0;
                                     nxt_nzcv    = 2'b10; //NZ
                                     nxt_sign_ext= 1'b0;
                                   end
                          4'b1110: begin //BIC_REG 29
                                     nxt_optype  = OP_AND;
                                     tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00,inst[2:0], 6'b0};
                                     tmp_opand2  = {IMM_0, SIGN_0, INV_1, BYTE_0, HALF_0, 2'b00,inst[5:3], 6'b0}; //inverting
                                     nxt_opand3  = {2'b00,inst[2:0]};
                                     nxt_carry_in= 1'b0;
                                     nxt_nzcv    = 2'b10; //NZ
                                     nxt_sign_ext= 1'b0;
                                   end
                          4'b1111: begin //MVN_REG 75
                                     nxt_optype  = OP_OR;
                                     tmp_opand1  = {IMM_1, SIGN_0, INV_0, 13'b0};
                                     tmp_opand2  = {IMM_0, SIGN_0, INV_1, BYTE_0, HALF_0, 2'b00,inst[5:3], 6'b0};
                                     nxt_opand3  = {2'b00,inst[2:0]};
                                     nxt_carry_in= 1'b0;
                                     nxt_nzcv    = 2'b10; //NZ
                                     nxt_sign_ext= 1'b0;
                                   end
                        endcase
                      else
                        case (inst[9:8])
                          2'b00: begin //ADD_REG 19
                                     nxt_optype   = OP_ADD;
                                     tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 1'b0,inst[7], inst[2:0], 6'b0};
                                     tmp_opand2  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 1'b0,inst[6:3], 6'b0};
                                     nxt_opand3   = {1'b0,inst[7],inst[2:0]};
                                     nxt_carry_in = 1'b0;
                                     nxt_nzcv     = 2'b01; //No flag
                                     nxt_sign_ext = 1'b0;
                                 end
                          2'b01: begin //CMP_REG 37
                                     nxt_optype   = OP_ADD;
                                     tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 1'b0,inst[7], inst[2:0], 6'b0};
                                     tmp_opand2  = {IMM_0, SIGN_0, INV_1, BYTE_0, HALF_0, 1'b0,inst[6:3], 6'b0};
                                     nxt_opand3   = {2'b10,inst[2:0]}; //Cancel result
                                     nxt_carry_in = 1'b1;
                                     nxt_nzcv     = 2'b00; //NZCV
                                     nxt_sign_ext = 1'b0;
                                 end
                          2'b10: begin //MOV_REG 69
                                     nxt_optype   = OP_ADD;
                                     tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 1'b0, inst[6:3], 6'b0};
                                     tmp_opand2  = {IMM_1, SIGN_0, INV_0, 13'b0};
                                     nxt_opand3   = {1'b0,inst[7],inst[2:0]};
                                     nxt_carry_in = 1'b0;
                                     nxt_nzcv     = 2'b01; //No flag
                                     nxt_sign_ext = 1'b0;
                                 end
                          2'b11: begin //BX 33 and BLX_REG 32
                                     nxt_optype   = (inst[7] == 1'b0)? OP_BX : OP_BLX;
                                     tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 1'b0, inst[6:3], 6'b0};
                                     tmp_opand2  = {IMM_1, SIGN_0, INV_0, 13'b0};
                                     nxt_opand3   = {1'b0,4'b1111}; //PC
                                     nxt_carry_in = 1'b0;
                                     nxt_nzcv     = 2'b01; //No flag
                                     nxt_sign_ext = 1'b0;
                                 end
                         endcase
                    end


          5'b01010: begin //STR_REG 93, STRH_REG 97, STRB_REG 95, LDRSB_REG 61
                      tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00, inst[5:3], 6'b0};
                      tmp_opand2  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00, inst[8:6], 6'b0};
                      nxt_opand3  = {2'b0,inst[2:0]};
                      nxt_carry_in= 1'b0;
                      case (inst[10:9])
                        2'b00: begin
                                 nxt_optype  = OP_MW; //STR_REG 93
                                 nxt_byte_en = 2'b10; //Word operation
                                 nxt_sign_ext= 1'b0;
                               end
                        2'b01: begin
                                 nxt_optype  = OP_MW;//STRH_REG 97
                                 nxt_byte_en = 2'b01; //HalfWord operation
                                 nxt_sign_ext= 1'b0;
                               end
                        2'b10: begin
                                 nxt_optype  = OP_MW; //STRB_REG 95
                                 nxt_byte_en    = 2'b00; //Byte operation
                                 nxt_sign_ext= 1'b0;
                               end
                        2'b11: begin
                                 nxt_optype  = OP_MR; //LDRSB_REG 61
                                 nxt_byte_en    = 2'b00; //Byte operation
                                 nxt_sign_ext = 1'b1;
                               end
                      endcase
                    end


          5'b01011: begin //LDR_REG 53, LDRH_REG 59, LDRB_REG 56, LDRSH_REG 62
                      nxt_optype  = OP_MR;
                      tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00, inst[5:3], 6'b0};
                      tmp_opand2  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00, inst[8:6], 6'b0};
                      nxt_opand3  = {2'b0,inst[2:0]};
                      nxt_carry_in= 1'b0;
                      case (inst[10:9])
                        2'b00: begin //LDR_REG 53
                                 nxt_byte_en    = 2'b10; //Word operation
                                 nxt_sign_ext = 1'b0;
                               end
                        2'b01: begin //LDRH_REG 59
                                 nxt_byte_en    = 2'b01; //HalfWord operation
                                 nxt_sign_ext= 1'b0;
                               end
                        2'b10: begin //LDRB_REG 56
                                 nxt_byte_en    = 2'b00; //Byte operation
                                 nxt_sign_ext = 1'b0;
                               end
                        2'b11: begin //LDRSH_REG 62
                                 nxt_byte_en    = 2'b01; //HalfWord operation
                                 nxt_sign_ext = 1'b1;
                               end
                      endcase
                    end


          5'b01100: begin //STR_IMM 91
                      nxt_optype  = OP_MW;
                      tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00, inst[5:3], 6'b0};
                      tmp_opand2  = {IMM_1, SIGN_0, INV_0, 6'b0, inst[10:6], 2'b00}; //mul4
                      nxt_opand3  = {2'b0,inst[2:0]};
                      nxt_carry_in= 1'b0;
                      nxt_byte_en    = 2'b10; //Word operation
                      nxt_sign_ext= 1'b0;
                    end


          5'b01001: begin //LDR_literal 51
                      nxt_optype  = OP_MR;
                      tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 1'b0, 4'b1111, ALIGN_1, 5'b0}; //PC
                      tmp_opand2  = {IMM_1, SIGN_0, INV_0, 3'b0, inst[7:0], 2'b00};//mul4
                      nxt_opand3  = {2'b00,inst[10:8]};
                      nxt_carry_in= 1'b0;
                      nxt_byte_en    = 2'b10; //Word operation
                      nxt_sign_ext= 1'b0;
                    end


          5'b01101: begin //LDR_IMM 49
                      nxt_optype  = OP_MR;
                      tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00, inst[5:3], 6'b0};
                      tmp_opand2  = {IMM_1, SIGN_0, INV_0, 6'b0, inst[10:6], 2'b00};//mul4
                      nxt_opand3  = {2'b00,inst[2:0]};
                      nxt_carry_in= 1'b0;
                      nxt_byte_en    = 2'b10; //Word operation
                      nxt_sign_ext= 1'b0;
                    end


          5'b01110: begin //STRB_IMM 94
                      nxt_optype  = OP_MW;
                      tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00, inst[5:3], 6'b0};
                      tmp_opand2  = {IMM_1, SIGN_0, INV_0, 8'b0, inst[10:6]};
                      nxt_opand3  = {2'b00,inst[2:0]};
                      nxt_carry_in= 1'b0;
                      nxt_byte_en    = 2'b00; //Byte operation
                      nxt_sign_ext= 1'b0;
                    end


          5'b01111: begin //LDRB_IMM 55
                      nxt_optype  = OP_MR;
                      tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00, inst[5:3], 6'b0};
                      tmp_opand2  = {IMM_1, SIGN_0, INV_0, 8'b0, inst[10:6]};
                      nxt_opand3  = {2'b0,inst[2:0]};
                      nxt_carry_in= 1'b0;
                      nxt_byte_en    = 2'b00; //Byte operation
                      nxt_sign_ext= 1'b0;
                    end


          5'b10000: begin //STRH_IMM 96
                      nxt_optype  = OP_MW;
                      tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00, inst[5:3], 6'b0};
                      tmp_opand2  = {IMM_1, SIGN_0, INV_0, 7'b0, inst[10:6], 1'b0};
                      nxt_opand3  = {2'b0,inst[2:0]};
                      nxt_carry_in= 1'b0;
                      nxt_byte_en    = 2'b01; //HalfWord operation
                      nxt_sign_ext= 1'b0;
                    end


          5'b10001: begin //LDRH_IMM 57
                      nxt_optype  = OP_MR;
                      tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00, inst[5:3], 6'b0};
                      tmp_opand2  = {IMM_1, SIGN_0, INV_0, 7'b0, inst[10:6], 1'b0};
                      nxt_opand3  = {2'b0,inst[2:0]};
                      nxt_carry_in= 1'b0;
                      nxt_byte_en    = 2'b01; //HalfWord operation
                      nxt_sign_ext= 1'b0;
                    end


          5'b10010: begin //STR_IMM 91
                      nxt_optype  = OP_MW;
                      tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 1'b0, 4'b1101, 6'b0};
                      tmp_opand2  = {IMM_1, SIGN_0, INV_0, 3'b0, inst[7:0], 2'b00};
                      nxt_opand3  = {2'b0,inst[10:8]};
                      nxt_carry_in= 1'b0;
                      nxt_byte_en    = 2'b10; //Word operation
                      nxt_sign_ext= 1'b0;
                    end


          5'b10011: begin //LDR_IMM 49
                      nxt_optype  = OP_MR;
                      tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 1'b0, 4'b1101, 6'b0};
                      tmp_opand2  = {IMM_1, SIGN_0, INV_0, 3'b0, inst[7:0], 2'b00};
                      nxt_opand3  = {2'b00,inst[10:8]};
                      nxt_carry_in= 1'b0;
                      nxt_byte_en    = 2'b10; //Word operation
                      nxt_sign_ext= 1'b0;
                    end


          5'b10101: begin //ADD_SP_IMM 21
                      nxt_optype  = OP_ADD;
                      tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 1'b0, 4'b1101, 6'b0};
                      tmp_opand2  = {IMM_1, SIGN_0, INV_0, 3'b0, inst[7:0], 2'b00};
                      nxt_opand3  = {2'b00,inst[10:8]};
                      nxt_carry_in= 1'b0;
                      nxt_nzcv    = 2'b01; //No NZCV
                      nxt_sign_ext= 1'b0;
                    end


          5'b10110: begin //
                      case (inst[10:8])
                        3'b110: begin //CPS 39
                                  nxt_optype  = OP_CPS;
                                  tmp_opand1  = {IMM_1, SIGN_0, INV_0, 13'b0}; //No meaning.
                                  tmp_opand2  = {IMM_1, SIGN_0, INV_0, 8'b0, inst[4:0]}; //primask0 will be set at next stage.
                                  nxt_opand3  = {2'b10,3'b0}; //No meaning.
                                  nxt_carry_in= 1'b0;
                                  nxt_nzcv    = 2'b01; //No NZCV
                                  nxt_sign_ext= 1'b0;
                                end
                        3'b000: begin //ADD_SP_IMM 21 SUB_SP_IMM 102
                                  nxt_optype  = OP_ADD;
                                  tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 1'b0, 4'b1101, 6'b0};
                                  nxt_opand3  = {1'b0,4'b1101}; //SP
                                  nxt_carry_in= inst[7];
                                  nxt_nzcv    = 2'b01; //No NZCV
                                  nxt_sign_ext= 1'b0;
                                  if(inst[7] == 1'b0) //ADD_SP_IMM 21
                                    tmp_opand2  = {IMM_1, SIGN_0, INV_0, 4'b0, inst[6:0], 2'b00};
                                  else                //SUB_SP_IMM 102
                                    tmp_opand2  = {IMM_1, SIGN_0, INV_1, 4'b0, inst[6:0], 2'b00};
                                end
                        3'b010: begin //SXTH 105, SXTB 104, UXTH 108, UXTB 107
                                  nxt_optype  = OP_LSL;
                                  tmp_opand2  = {IMM_1, SIGN_0, INV_0, 13'b0}; //imm32 = 0.
                                  nxt_opand3  = {2'b00,inst[2:0]};
                                  nxt_carry_in= 1'b0;
                                  nxt_nzcv    = 2'b01; //No NZCV
                                  nxt_sign_ext= 1'b0;
                                  case(inst[7:6])
                                    2'b00: begin //SXTH 105
                                           tmp_opand1  = {IMM_0, SIGN_1, INV_0, BYTE_0, HALF_1, 2'b00, inst[5:3], 6'b0};
                                           end
                                    2'b01: begin //SXTB 104
                                           tmp_opand1  = {IMM_0, SIGN_1, INV_0, BYTE_1, HALF_0, 2'b00, inst[5:3], 6'b0};
                                           end
                                    2'b10: begin //UXTH 108
                                           tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_1, 2'b00, inst[5:3], 6'b0};
                                           end
                                    2'b11: begin //UXTB 107
                                           tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_1, HALF_0, 2'b00, inst[5:3], 6'b0};
                                           end
                                  endcase
                                end
                        3'b101,
                        3'b100: begin  //PUSH 81
                                  nxt_optype  = OP_PUSH;
                                  tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 1'b0, 4'b1101, 6'b0}; //SP
                                  tmp_opand2  = {IMM_1, SIGN_0, INV_1, 7'b0, regnum4}; //offset address of SP.
                                  nxt_opand3  = {1'b0,4'b1101}; //SP to writeback
                                  nxt_opand4  = {7'b0,inst[8:0]}; //reglist to be push.
                                  nxt_carry_in= 1'b1;
                                  nxt_byte_en    = 2'b10; //Word
                                  nxt_sign_ext= 1'b0;
                                end
                        default: begin  //unimplemented instruction, Unpredictable behavior.
                                 nxt_optype = OP_IDLE;
                                 nxt_id_hardfault = 1'b1;
                                 end
                      endcase
                    end


          5'b10111: begin //
                      case (inst[10:8])
                        3'b010: begin //REV 82, REV16 83, REVH 84
                                  nxt_optype  = OP_LSL;
                                  tmp_opand2  = {IMM_1, SIGN_0, INV_0, 13'b0}; //imm32 = 0.
                                  nxt_opand3  = {2'b00,inst[2:0]};
                                  nxt_carry_in= 1'b0;
                                  nxt_nzcv    = 2'b01; //No NZCV
                                  nxt_sign_ext= 1'b0;
                                  case(inst[7:6])
                                    2'b00: begin //REV 82
                                           tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00, inst[5:3], 4'b0, 2'b11};
                                           end
                                    2'b01: begin //REV16 83
                                           tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00, inst[5:3], 4'b0, 2'b01};
                                           end
                                    2'b11: begin //REVH 84
                                           tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00, inst[5:3], 4'b0, 2'b10};
                                           end
                                    default: begin  //unimplemented instruction, Unpredictable behavior.
                                             nxt_optype = OP_IDLE;
                                             nxt_id_hardfault = 1'b1;
                                             end
                                  endcase
                                end
                        3'b100,
                        3'b101: begin //POP 79
                                nxt_optype  = OP_POP;
                                tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 1'b0, 4'b1101, 6'b0}; //SP
                                tmp_opand2  = {IMM_1, SIGN_0, INV_0, 7'b0, regnum4}; //offset address of SP.
                                nxt_opand3  = {1'b0,4'b1101}; //SP
                                nxt_opand4  = {7'b0,inst[8:0]}; //reglist to be pop.
                                nxt_carry_in= 1'b0;
                                nxt_byte_en    = 2'b10; //word operation
                                nxt_sign_ext= 1'b0;
                                end
                        3'b110: begin //BKPT 30
                                nxt_optype = OP_IDLE;
                                nxt_bkpt_inst = 1'b1;
                                end
                        3'b111: begin
                                nxt_optype = OP_IDLE;
                                if (inst[3:0] == 4'b0000)
                                begin
                                  case (inst[6:4])
                                      3'b000: ; //NOP 77;
                                      3'b001: begin //YIELD 111  (Don't know what need to do)
                                              nxt_yield_inst = 1'b1;
                                              end
                                      3'b010: begin //WFE 109
                                              nxt_wfe_inst = 1'b1;
                                              end
                                      3'b011: begin //WFI 110
                                              nxt_wfi_inst = 1'b1;
                                              end
                                      3'b100: begin //SEV 88
                                              nxt_sev_inst = 1'b1;
                                              end
                                      default: ;//other encoding, execute as NOPs.
                                  endcase
                                end
                                else //unimplemented instruction, Unpredictable behavior.
                                begin
                                  nxt_id_hardfault = 1'b1;                                  
                                end
                                end
                        default:begin  //unimplemented instruction, Unpredictable behavior.
                                  nxt_optype = OP_IDLE;
                                  nxt_id_hardfault = 1'b1;
                                end
                      endcase
                    end
                    
                    
          5'b11000: begin //STM/STMIA/STMEA 89
                      nxt_optype  = OP_STM;
                      tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00, inst[10:8], 6'b0}; //Rn
                      tmp_opand2  = {IMM_1, SIGN_0, INV_0, 7'b0, stmldm_regnum}; //writeback to Rn.
                      nxt_opand3  = {2'b00,inst[10:8]}; //Rn to be writeback
                      nxt_opand4  = {8'b0,inst[7:0]}; //reglist to be push.
                      nxt_carry_in= 1'b0;
                      nxt_byte_en    = 2'b10; //Word
                      nxt_sign_ext= 1'b0;
                    end
                    
                    
          5'b11001: begin //LDM/LDMIA/LDMFD 47
                      nxt_optype  = OP_POP;
                      tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 2'b00, inst[10:8], 6'b0}; //Rn
                      tmp_opand2  = {IMM_1, SIGN_0, INV_0, 7'b0, stmldm_regnum}; //writeback to Rn.
                      nxt_opand3[4] = (((inst[10:8] == 3'b000) & inst[0]) |
                                       ((inst[10:8] == 3'b001) & inst[1]) |
                                       ((inst[10:8] == 3'b010) & inst[2]) |
                                       ((inst[10:8] == 3'b011) & inst[3]) |
                                       ((inst[10:8] == 3'b100) & inst[4]) |
                                       ((inst[10:8] == 3'b101) & inst[5]) |
                                       ((inst[10:8] == 3'b110) & inst[6]) |
                                       ((inst[10:8] == 3'b111) & inst[7]) );
                      nxt_opand3[3:0]  = {1'b0,inst[10:8]}; //Rn to be writeback
                      nxt_opand4  = {8'b0,inst[7:0]}; //reglist to be pop.
                      nxt_carry_in= 1'b0;
                      nxt_byte_en    = 2'b10; //Word
                      nxt_sign_ext= 1'b0;
                    end
                    
                    
          5'b11010,
          5'b11011: begin //B t1 27, SVC 103
                      if (cond_pass) //B t1 27
                      begin
                          nxt_optype  = OP_ADD;
                          tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 1'b0, 4'b1111, 6'b0}; //PC
                          tmp_opand2  = {IMM_1, SIGN_1, INV_0, {4{inst[7]}}, inst[7:0], 1'b0}; //imm8 sign extention.
                          nxt_opand3  = {1'b0,4'b1111};  //PC
                          nxt_carry_in= 1'b0;
                          nxt_nzcv    = 2'b01; //No NZCV
                          nxt_sign_ext= 1'b0;
                      end
                      else if (inst[11:8] == 4'b1111) //SVC  103 instruction
                      begin
                          nxt_optype = OP_IDLE;
                          nxt_svcall = 1'b1;
                      end
                      else  //Ignore this instr. No operation
                      begin
                          nxt_optype = OP_IDLE;
                      end
                    end


          5'b11100: begin //B t2 27
                      nxt_optype  = OP_ADD;
                      tmp_opand1  = {IMM_0, SIGN_0, INV_0, BYTE_0, HALF_0, 1'b0, 4'b1111, 6'b0}; //PC
                      tmp_opand2  = {IMM_1, SIGN_1, INV_0, inst[10], inst[10:0], 1'b0}; //imm13 sign extention.
                      nxt_opand3  = {1'b0,4'b1111}; //PC
                      nxt_carry_in= 1'b0;
                      nxt_nzcv    = 2'b01; //No NZCV
                      nxt_sign_ext= 1'b0;
                    end


          default: begin  //unimplemented instruction, Unpredictable behavior.
                     nxt_optype = OP_IDLE;
                     nxt_id_hardfault = 1'b1;   
                   end
      endcase
    end
end

//generate opand for push/pop instruction.
//Need think out how to implement below algorithm.
assign pushpop_op2 = inst[8]+inst[7]+inst[6]+inst[5]+inst[4]+inst[3]+inst[2]+inst[1]+inst[0];  //
assign regnum4 = {pushpop_op2, 2'b00};
assign stmldm_op2  = inst[7]+inst[6]+inst[5]+inst[4]+inst[3]+inst[2]+inst[1]+inst[0];  //
assign stmldm_regnum ={stmldm_op2, 2'b00};

assign I1 = ~(arm_inst_buf[10] ^ inst[13]);
assign I2 = ~(arm_inst_buf[10] ^ inst[11]);
assign bl_op2 = {{7{I1}},arm_inst_buf[10],I1,I2,arm_inst_buf[9:0],inst[10:0],1'b0};

//ConditionPassed
//cond_pass?
always @*
begin
    case (inst[11:9])
    3'b000: cond_pass = inst[8] ^ Z_flag;
    3'b001: cond_pass = inst[8] ^ C_flag;
    3'b010: cond_pass = inst[8] ^ N_flag;
    3'b011: cond_pass = inst[8] ^ V_flag;
    3'b100: cond_pass = inst[8] ^ (C_flag & (~Z_flag));
    3'b101: cond_pass = inst[8] ^ (N_flag == V_flag);
    3'b110: cond_pass = inst[8] ^ ((~Z_flag) & (N_flag == V_flag));
    3'b111: cond_pass = 1'b1; //"111x" always true. 20130707;
    endcase
end

assign nxt_opand1 = new_opand1;

assign nxt_opand2 = (nxt_optype == OP_BL) ? bl_op2 : new_opand2;


//--------------------------------------//
//Pipeline output in decoder stage
//--------------------------------------//
always@ (posedge clk or negedge rst_n)
begin
  if (!rst_n)
  begin
    optype            <= OP_IDLE;
    opand1            <= 32'b0;
    opand2            <= 32'b0;
    opand3            <= 5'b10000;
    opand4            <= 16'b0;
    carry_in          <= 1'b0;
    nzcv              <= 2'b01;
    sign_ext          <= 1'b0;
    byte_en           <= 2'b10;
                     
    dsb_inst         <= 1'b0;
    dmb_inst         <= 1'b0;
    isb_inst         <= 1'b0;
                     
    id_hardfault      <= 1'b0;
                     
    bkpt_inst        <= 1'b0;
    yield_inst       <= 1'b0;
    wfe_inst         <= 1'b0;
    wfi_inst         <= 1'b0;
    sev_inst         <= 1'b0;
                     
    svcall            <= 1'b0;
  end
  else if (dec_expt_insert == 1'b1)// Need insert a exception instruction.
  begin
    optype            <=   OP_EXPT ;
    opand1            <=   SP ;
    opand2            <=   32'hffff_ffe0 ; //complement of 0x20.
    opand3            <=   5'h10 ;
    opand4            <=   16'b0 ;
    carry_in          <=   1'b0  ;
    nzcv              <=   2'b01 ;
    sign_ext          <=   1'b0  ;
    byte_en           <=   2'b10 ;
                                
    dsb_inst         <=   1'b0  ;
    dmb_inst         <=   1'b0  ;
    isb_inst         <=   1'b0  ;
                                
    id_hardfault      <=   1'b0  ;
                                
    bkpt_inst        <=   1'b0;
    yield_inst       <=   1'b0  ;
    wfe_inst         <=   1'b0  ;
    wfi_inst         <=   1'b0  ;
    sev_inst         <=   1'b0  ;
                     
    svcall            <=   1'b0  ;
 end
  else if (dec_hold == 1'b0)// if ask me hold, I should not update output.
  begin
    optype            <=  dec_nop ? OP_IDLE : nxt_optype        ;
    opand1            <=  dec_nop ? 32'b0 : nxt_opand1          ;
    opand2            <=  dec_nop ? 32'b0 : nxt_opand2          ;
    opand3            <=  dec_nop ? 5'h10 : nxt_opand3          ;
    opand4            <=  dec_nop ? 16'b0 : nxt_opand4          ;
    carry_in          <=  dec_nop ? 1'b0  : nxt_carry_in        ;
    nzcv              <=  dec_nop ? 2'b01 : nxt_nzcv            ;
    sign_ext          <=  dec_nop ? 1'b0  : nxt_sign_ext        ;
    byte_en           <=  dec_nop ? 2'b10 : nxt_byte_en        ;
                     
    dsb_inst         <=  dec_nop ? 1'b0  : nxt_dsb_inst       ;
    dmb_inst         <=  dec_nop ? 1'b0  : nxt_dmb_inst       ;
    isb_inst         <=  dec_nop ? 1'b0  : nxt_isb_inst       ;
                     
    id_hardfault      <=  dec_nop ? 1'b0  : nxt_id_hardfault   ;
                     
    bkpt_inst        <=  dec_nop ? 1'b0  : nxt_bkpt_inst      ;
    yield_inst       <=  dec_nop ? 1'b0  : nxt_yield_inst     ;
    wfe_inst         <=  dec_nop ? 1'b0  : nxt_wfe_inst       ;
    wfi_inst         <=  dec_nop ? 1'b0  : nxt_wfi_inst       ;
    sev_inst         <=  dec_nop ? 1'b0  : nxt_sev_inst       ;
                     
    svcall            <=  dec_nop ? 1'b0  : nxt_svcall          ;
 end
end

//====================
//PC for current instruction
//If it is 32bit inst, PC should be the address of low 16bit.
//====================
always@ (posedge clk or negedge rst_n)
begin
  if (!rst_n)
  begin
      id_pc <= 32'b0;
  end
  else if ((!(dec_hold || dec_nop || fetch_nop)) && (current_state == THUMB_STATE))
  begin
      id_pc <= if_pc;
  end
end

assign pc_used_for_dec_opand = (current_state == THUMB2_STATE)? id_pc : if_pc;



//===============================
//Data dependence
//===============================
wire  [4:0] dec_rd_reg1 = (tmp_opand1[15] == 1'b0) ? tmp_opand1[10:6] : 5'd30;
wire  [4:0] dec_rd_reg2 = (tmp_opand2[15] == 1'b0) ? tmp_opand2[10:6] : 5'd30;
wire  [4:0] dec_wr_reg  = (optype == OP_IDLE)? 5'd30 : opand3;
wire  [15:0] dec_wr_reglist = (optype == OP_POP) ? {opand4[8], 7'b0, opand4[7:0]} : 
                             ((optype == OP_BLX) |(optype == OP_BL))? 16'h4000 : 16'h0000;  //BL,BLX will write LR.

wire [15:0] rd_reg1_list = dec5to16 (dec_rd_reg1);
wire [15:0] rd_reg2_list = dec5to16 (dec_rd_reg2);
wire [15:0] wr_reg_list  = dec5to16 (dec_wr_reg );

//assign id_data_depend = |((rd_reg1_list | rd_reg2_list ) & (wr_reg_list | dec_wr_reglist));
//Read or Write PC doesn't bring data dependence.??
wire reg_data_depend = |((rd_reg1_list[14:0] | rd_reg2_list[14:0] ) & (wr_reg_list[14:0] | dec_wr_reglist[14:0]));
wire flag_data_depend = (nzcv != 2'b01) & ((inst[15:12] == 4'b1101) |           //B will use flag bits.
                                            (inst[15:6] == 10'b01000_0_0101) |  //ADC will use flag bits.
											(inst[15:6] == 10'b01000_0_0110)); //SBC will use flag bits.
assign id_data_depend = reg_data_depend | flag_data_depend;
//MSR will write xPSR, SP, PRIMASK, read Rx. MRS will read xPSR, PRIMASK, CONTROL, write Rx.
//The PRIMASK, CONTROL, EPSR.T, IPSR are changed only by MSR, MRS, both INSTs take two cycles, data_depend will not occur.
// 
//
//===========================
//branch Inst flag.
//===========================
assign  id_branch_op = (nxt_opand3 == {1'b0, 4'b1111}) | (nxt_opand4[8] & (nxt_optype == OP_POP));



//===========================
// ID stage status
//===========================
//ID is OP_IDLE
assign id_is_idle = (optype == OP_IDLE);
//ID only need one clock cycle.
assign  id_bsy = 1'b0;
//Thumb2 inst should be completed before exception inserted to the pipeline.
assign  id_thumb2 = (current_state == THUMB2_STATE); 




//===============================
//function
//===============================
function [15:0] dec5to16 ;
input [4:0] dec_num;
begin
    if      (dec_num == 5'h0)  dec5to16 = 16'h0001;
    else if (dec_num == 5'h1)  dec5to16 = 16'h0002;
    else if (dec_num == 5'h2)  dec5to16 = 16'h0004;
    else if (dec_num == 5'h3)  dec5to16 = 16'h0008;
    else if (dec_num == 5'h4)  dec5to16 = 16'h0010;
    else if (dec_num == 5'h5)  dec5to16 = 16'h0020;
    else if (dec_num == 5'h6)  dec5to16 = 16'h0040;
    else if (dec_num == 5'h7)  dec5to16 = 16'h0080;
    else if (dec_num == 5'h8)  dec5to16 = 16'h0100;
    else if (dec_num == 5'h9)  dec5to16 = 16'h0200;
    else if (dec_num == 5'ha)  dec5to16 = 16'h0400;
    else if (dec_num == 5'hb)  dec5to16 = 16'h0800;
    else if (dec_num == 5'hc)  dec5to16 = 16'h1000;
    else if (dec_num == 5'hd)  dec5to16 = 16'h2000;
    else if (dec_num == 5'he)  dec5to16 = 16'h4000;
    else if (dec_num == 5'hf)  dec5to16 = 16'h8000; 
    else                       dec5to16 = 16'h0000;
end
endfunction


endmodule


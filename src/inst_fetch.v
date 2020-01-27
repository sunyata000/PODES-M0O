
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
// File        : inst_fetch.v
// Author      : PODES
// Date        : 20200101
// Version     : 1.0
// Description : Instruction fetch stage of IU. 
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

module inst_fetch (
             clk,
             rst_n,
             
             lockup,
             branch_addr,
             branch_valid,             
             fetch_hold,
             fetch_nop,
             inst_keep,
             inst_latch,
             
             inst,
             if_bsy,
             if_pc,
             startup,
             reset_trap, 
             MSP_rst_val,
             MSP_rst_flg,
             EPSR_T_rst_val,
             EPSR_T_rst_flg,
						 
             inst_addr,
             inst_req,
             inst_rd_data,
             inst_rdy
             );

  
//-----------------------------------------------------------//
//                      INPUTS/OUTPUTS                       //
//-----------------------------------------------------------//
input             clk  ;
input             rst_n;
          
input             lockup;          
input [31:0]      branch_addr ;
input             branch_valid;
input             fetch_hold;
input             fetch_nop;
input             inst_keep;
input             inst_latch;

output [15:0]     inst;
output            if_bsy;
output [31:0]     if_pc ;
input             startup ;
output            reset_trap; 
output [31:0]     MSP_rst_val;
output            MSP_rst_flg;
output            EPSR_T_rst_val;
output            EPSR_T_rst_flg;

output [31:0]     inst_addr   ;
output            inst_req    ;
input  [31:0]     inst_rd_data;
input             inst_rdy    ;



//-----------------------------------------------------------//
//                    REGISTERS & WIRES                      //
//-----------------------------------------------------------//

wire [31:0]  if_pc ;
wire [15:0]  inst;
wire         if_bsy;
reg          reset_trap; 
           
reg  [31:0] MSP_rst_val ;
reg         MSP_rst_flg ;
reg         EPSR_T_rst_val;
reg         EPSR_T_rst_flg;

wire [31:0] inst_addr;
wire        inst_req;

reg         access_req;


//---------------
reg  [2:0]  next_fetch_state;
reg  [2:0]  current_fetch_state;

reg         nxt_reset_trap; 
reg         nxt_access_req;
reg  [31:0] nxt_pc_counter;
reg         nxt_MSP_rst_flg ;
reg  [31:0] nxt_MSP_rst_val ;
reg         nxt_EPSR_T_rst_val;
reg         nxt_EPSR_T_rst_flg;

reg  [31:0] pc_counter;

//-----------------------------------------------------------//
//                          PARAMETERS                       //
//-----------------------------------------------------------//
parameter NOP_INST  = 16'b1011_1111_0000_0000;

parameter STARTUP_VECTOR = 32'h0000_0000;
parameter RESET_VECTOR   = 32'h0000_0004;

parameter FETCH_IDLE      = 3'b000;
parameter FETCH_MSP       = 3'b001;
parameter FETCH_RSTVECT   = 3'b011;
parameter FETCH_SKIP      = 3'b010;
parameter FETCH_INST_CTRL = 3'b110;
parameter FETCH_INST      = 3'b100;

//-----------------------------------------------------------//
//                          ARCHITECTURE                     //
//-----------------------------------------------------------//


//==================
//Start up flow and inst fetch
//==================
wire [31:0] tmp_pc_counter = branch_valid ? {branch_addr[31:1], 1'b1} : pc_counter;
         
always @*
begin
    next_fetch_state = 	current_fetch_state;
    nxt_pc_counter = pc_counter;
    nxt_access_req = access_req;
    nxt_MSP_rst_flg = 1'b0;
    nxt_MSP_rst_val = MSP_rst_val;
    nxt_EPSR_T_rst_flg = 1'b0;
    nxt_EPSR_T_rst_val = EPSR_T_rst_val;
    nxt_reset_trap = reset_trap;
        
    case (current_fetch_state)
    FETCH_IDLE: 
        begin
            if (startup)
            begin  //
                next_fetch_state = FETCH_MSP;
                nxt_pc_counter = STARTUP_VECTOR;
                nxt_access_req = 1'b1;
            end
        end
    FETCH_MSP: 
        begin
            if (inst_rdy)
            begin  //control phase for MSP.
                next_fetch_state = FETCH_RSTVECT;
                nxt_pc_counter = RESET_VECTOR;
                nxt_access_req = 1'b1;
            end
        end
    FETCH_RSTVECT: //data phase for MSP. control phase for RESETVECTOR.
        begin
            if (inst_rdy) 
            begin
                nxt_MSP_rst_flg = 1'b1;
                nxt_MSP_rst_val = inst_rd_data;                
                
                next_fetch_state = FETCH_SKIP;
                nxt_access_req = 1'b0;//Skip one cycle.
            end
        end
    FETCH_SKIP: //data phase for RESETVECTOR. control phase for SKIP.
        begin
            if (inst_rdy) 
            begin
                nxt_pc_counter = {inst_rd_data[31:1], 1'b0};
                nxt_EPSR_T_rst_val = inst_rd_data[0];
                nxt_EPSR_T_rst_flg = 1'b1;
                nxt_access_req = 1'b1;   
				
                next_fetch_state = FETCH_INST_CTRL;
            end
        end
    FETCH_INST_CTRL: //control phase for first INST access
        begin
            if (inst_rdy)
            begin
                next_fetch_state = FETCH_INST;
                nxt_pc_counter = pc_counter + 32'h2;
                nxt_access_req = 1'b1; 
                nxt_reset_trap = 1'b0; //reset trap is done.
            end
        end
    FETCH_INST: //data and control of instruction.
        begin    
            if (!startup) 
            begin
                next_fetch_state = FETCH_IDLE;
                nxt_access_req = 1'b0;
                nxt_reset_trap = 1'b1; //enter reset trap again.
            end
            if(lockup)
            begin
                nxt_pc_counter = 32'hffff_fffe;
                nxt_access_req = 1'b1;
            end
            else if(branch_valid && ((!inst_rdy) || fetch_hold))
            begin
                nxt_pc_counter = {branch_addr[31:1], 1'b1}; //bit0 is branch flg.
                nxt_access_req = 1'b1;
            end
            else if ((!fetch_hold) && inst_rdy)
            begin
                nxt_pc_counter = {tmp_pc_counter[31:1], 1'b0} + 32'h2;
                nxt_access_req = 1'b1;
            end
        end
    default: 
        begin
            next_fetch_state = FETCH_IDLE;
            nxt_access_req = 1'b0;
        end
    endcase         
end

always@ (posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        current_fetch_state <= FETCH_IDLE;
        pc_counter     <= STARTUP_VECTOR;
        access_req     <= 1'b0;
        EPSR_T_rst_val <= 1'b1;
        EPSR_T_rst_flg <= 1'b0;
        MSP_rst_val    <= 32'b0;
        MSP_rst_flg    <= 1'b0;
        reset_trap     <= 1'b1;  
        
    end
    else
    begin
        current_fetch_state <= next_fetch_state;
        pc_counter     <= nxt_pc_counter    ;
        access_req     <= nxt_access_req    ;
        EPSR_T_rst_val <= nxt_EPSR_T_rst_val;
        EPSR_T_rst_flg <= nxt_EPSR_T_rst_flg;
        MSP_rst_val    <= nxt_MSP_rst_val   ;
        MSP_rst_flg    <= nxt_MSP_rst_flg   ;
        reset_trap     <= nxt_reset_trap    ;
    end 
end

assign inst_addr = tmp_pc_counter;
assign inst_req  = access_req & startup & (~fetch_hold);



//==================
//inst data and status
//==================

reg [31:0] if_pc_tmp;
always@ (posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        if_pc_tmp <= 32'b0;   
    end
    else if ((!fetch_hold) && inst_rdy) 
    begin
        if_pc_tmp <= {inst_addr[31:1], 1'b0};
    end 
end

assign if_bsy = (reset_trap)? 1'b1 : ~inst_rdy;

reg [15:0] inst_tmp;
always @*
begin
    if (reset_trap)
    begin //before the first inst is available.
        inst_tmp = NOP_INST;
    end
	else //during fetching the inst.
    begin                                     
        if (lockup) inst_tmp = NOP_INST;
        else if (fetch_nop) inst_tmp = NOP_INST;
        else if (!inst_rdy) inst_tmp = NOP_INST;//access but not ready.
        else  inst_tmp = (if_pc_tmp[1])? inst_rd_data[31:16] : inst_rd_data[15:0];//ready.
    end       
end

reg [15:0] inst_dly;
reg [31:0] if_pc_dly;
always@ (posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        inst_dly  <= NOP_INST;
        if_pc_dly <= 32'b0;
    end
    else if (inst_latch)
    begin
        inst_dly  <= inst_tmp;
        if_pc_dly <= if_pc_tmp;
    end
end

assign inst  = inst_keep ? inst_dly : inst_tmp;
assign if_pc = inst_keep ? if_pc_dly : if_pc_tmp;

endmodule



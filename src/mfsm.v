
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
// File        : mfsm.v
// Author      : PODES
// Date        : 20200101
// Version     : 1.0
// Description : Main FSM for IU. 
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

module mfsm   (
                rst_n        ,
                clk          ,
                //fetch
                
                if_pc,
                startup,
                reset_trap,
                if_bsy    ,           
                fetch_hold,
                fetch_nop,
                inst_keep,
                inst_latch,
                
                //decoder
                id_pc,
                dec_hold,   
                dec_nop ,
                id_bsy ,
                id_is_idle,
                id_thumb2,
                id_branch_op,                                
                id_data_depend,
                id_hardfault,   
                dec_expt_insert,
                                
                dsb_inst    ,
                dmb_inst    ,
                isb_inst    , 
                bkpt_inst   ,        
                yield_inst  ,
                wfe_inst    ,
                wfi_inst    ,
                sev_inst    ,   
                svcall       ,
               
                //execute
                ie_pc           ,
                ie_bsy          ,
                exception_entry ,
                exception_return,
                tail_chaining   ,
                ie_hardfault   ,
                exe_cancel     ,
                                
                //exception
                PRIMASK,
                hardfault_req ,
                svcall_req,
                exception_req,
                exception_req_num,
                exception_ack,
                exception_ack_num,
                
                //debug
                c_debugen,       
                c_maskints,
				ie_stop_req,
                core_reset,
                core_lockup,
				core_halted,
                core_sleep,
                core_hardfault,
                core_id_pc,
                core_bkpt_inst       
                );

             
//-----------------------------------------------------------//
//                      INPUTS , OUTPUT                      //
//-----------------------------------------------------------//
input        rst_n;
input        clk;

//fetch              
input [31:0] if_pc;
output       startup;
input        reset_trap;
input        if_bsy;
output       fetch_hold;
output       fetch_nop;
output       inst_keep;
output       inst_latch;
                   
//decoder               
input [31:0] id_pc;
output       dec_hold;
output       dec_nop;
input        id_bsy;
input        id_is_idle;
input        id_thumb2;
input        id_branch_op;
input        id_data_depend ;
input        id_hardfault;
output       dec_expt_insert;

input        dsb_inst;
input        dmb_inst;
input        isb_inst;         
input        bkpt_inst;      
input        yield_inst;
input        wfe_inst;
input        wfi_inst;
input        sev_inst; 
input        svcall;

//execute
input [31:0] ie_pc;
input        ie_bsy;
input        exception_entry;
input        exception_return;
input        tail_chaining;
input        ie_hardfault;
output       exe_cancel;

//exception
input        PRIMASK;
output       hardfault_req;
output       svcall_req;
input        exception_req;  
input [8:0]  exception_req_num;
input        exception_ack;
input [8:0]  exception_ack_num;

                //debug
input        c_debugen;     
input        c_maskints;
input        ie_stop_req;
output       core_reset;
output       core_lockup;
input        core_halted;
output       core_sleep;
output       core_hardfault;  
output [31:0] core_id_pc;   
output       core_bkpt_inst;

//-----------------------------------------------------------//
//                    REGISTERS & WIRES                      //
//-----------------------------------------------------------//

wire        startup;
wire        fetch_hold;
wire        fetch_nop;
wire        dec_hold;
wire        dec_nop;
wire        dec_expt_insert;
wire        exe_cancel;
            
wire        hardfault_req;
wire        svcall_req;
reg         lockup;

wire        core_reset;
wire        core_lockup;
wire        core_sleep;  
wire [31:0] core_id_pc; 

reg         flg_dsb_inst    ;
reg         flg_dmb_inst    ;
reg         flg_isb_inst    ;         
reg         flg_bkpt_inst   ;      
reg         flg_yield_inst  ;
reg         flg_wfe_inst    ;
reg         flg_wfi_inst    ;
reg         flg_sev_inst    ;   
reg         flg_dec_hardfault;
reg         flg_svcall       ;
reg         flg_exe_hardfault;
            
wire        svcall_fault;
            
wire        expt_request;
            
wire        data_depend;
//-----------------------------------------------------------//
//                          PARAMETERS                       //
//-----------------------------------------------------------//

parameter DEP_IDLE   = 1'b0;
parameter DEP_DEPEND = 1'b1;

parameter BR_IDLE    = 2'b00;
parameter BR_ID      = 2'b01;
parameter BR_IE      = 2'b10;

parameter EXPT_IDLE  = 2'b00;
parameter EXPT_FALT  = 2'b01;
parameter EXPT_ID    = 2'b10;
parameter EXPT_IE    = 2'b11;


//-----------------------------------------------------------//
//                          ARCHITECTURE                     //
//-----------------------------------------------------------//


//=======================
//specific instructions. TBD.
//=======================
always@ (posedge clk or negedge rst_n)
begin
  if (!rst_n)
  begin
    flg_dsb_inst    <= 1'b0;
    flg_dmb_inst    <= 1'b0;
    flg_isb_inst    <= 1'b0;         
    flg_bkpt_inst   <= 1'b0;        
    flg_yield_inst  <= 1'b0;
    flg_wfe_inst    <= 1'b0;
    flg_wfi_inst    <= 1'b0;
    flg_sev_inst    <= 1'b0;   
    flg_dec_hardfault<= 1'b0;
    flg_svcall       <= 1'b0;
    flg_exe_hardfault<= 1'b0;
  end  
  else 
  begin
    flg_dsb_inst    <= dsb_inst     ;
    flg_dmb_inst    <= dmb_inst     ;
    flg_isb_inst    <= isb_inst     ;           
    flg_bkpt_inst   <= bkpt_inst    ;      
    flg_yield_inst  <= yield_inst   ;
    flg_wfe_inst    <= wfe_inst     ;
    flg_wfi_inst    <= wfi_inst     ;
    flg_sev_inst    <= sev_inst     ;   
    flg_dec_hardfault<= id_hardfault  ; //Only for debug flag.
    flg_svcall       <= svcall        ;
    flg_exe_hardfault<= ie_hardfault  ;
  end  
end


//need confirm the timing delay for that handler.
assign hardfault_req =  ie_hardfault | svcall_fault | (~c_debugen & bkpt_inst);
assign svcall_req    = svcall;  //need confirm the timing delay for that handler.

//===============================
//Pipeline control
// 
//================================


//======================
//structure dependence.
//======================
//If IF rdy but IE is not rdy, IF should hold on.
wire fetch_hold_structure = ie_bsy;
//replaced by NOP.
wire fetch_nop_structure  = ie_bsy;

//If IE is not rdy, ID should hold on.
wire dec_hold_structure   = (~id_bsy) & ie_bsy;
//If IF is not rdy, need insert NOP in ID. This id_nop is also used to hold the value of ID_PC.
wire dec_nop_structure    = (~ie_bsy) & if_bsy & (~data_depend);



//======================
//Data dependence.
//======================
reg   dep_cur_state;
reg   dep_nxt_state;

always @*
begin
    case (dep_cur_state)
    DEP_IDLE: begin
        if (id_data_depend)
            dep_nxt_state = DEP_DEPEND;
        else
            dep_nxt_state = DEP_IDLE;
    end
    DEP_DEPEND: begin
        if(ie_bsy)
           dep_nxt_state = DEP_DEPEND;
        else
           dep_nxt_state = DEP_IDLE;    
    end
    default: begin
            dep_nxt_state = DEP_IDLE;    
    end
    endcase         
end

always@ (posedge clk or negedge rst_n)
begin
    if (!rst_n)
        dep_cur_state <= DEP_IDLE;
    else 
        dep_cur_state <= dep_nxt_state;
end

assign data_depend = (dep_cur_state == DEP_DEPEND) ? 1'b1: 1'b0;

wire fetch_hold_data = (~ie_bsy) & data_depend;
wire fetch_nop_data  = 1'b0;

wire dec_hold_data   = 1'b0;
wire dec_nop_data    = id_data_depend ? 1'b1 : 1'b0;

assign  inst_latch = (~if_bsy) & (~ie_bsy);
assign  inst_keep  = fetch_hold_data;


//======================
//Branch transition.
//======================
reg [1:0]  br_cur_state;
reg [1:0]  br_nxt_state;

always @*
begin
    case (br_cur_state)
    BR_IDLE: begin
        if ((id_branch_op) && (!id_data_depend))
            br_nxt_state = BR_ID;
        else
            br_nxt_state = BR_IDLE;
    end
    BR_ID: begin
        if(ie_bsy)
            br_nxt_state = BR_ID;
        else
           br_nxt_state = BR_IE;    
    end
    BR_IE: begin
        if(ie_bsy | if_bsy)
            br_nxt_state = BR_IE;
        else
            br_nxt_state = BR_IDLE;    
    end 
    default: begin
            br_nxt_state = BR_IDLE;    
    end
    endcase         
end

always@ (posedge clk or negedge rst_n)
begin
    if (!rst_n)
        br_cur_state <= BR_IDLE;
    else 
        br_cur_state <= br_nxt_state;
end

wire fetch_hold_branch = (br_cur_state == BR_ID);
wire fetch_nop_branch  = (br_cur_state == BR_ID)|(br_cur_state == BR_IE);


wire dec_hold_branch = 1'b0;
wire dec_nop_branch  = 1'b0;




//======================
//Exception. 
//======================

reg [1:0]  expt_cur_state;
reg [1:0]  expt_nxt_state;

always @*
begin
    case (expt_cur_state)
    EXPT_IDLE: begin
        if (ie_hardfault) //hardfault exception.
            expt_nxt_state = EXPT_FALT;
        else if (expt_request)  //other exceptions.
            expt_nxt_state = EXPT_ID;
        else
            expt_nxt_state = EXPT_IDLE;
    end
    EXPT_FALT: begin
        if (expt_request)
            expt_nxt_state = EXPT_ID;
        else
            expt_nxt_state = EXPT_FALT;
    end
    EXPT_ID: begin
        if(exception_entry)
            expt_nxt_state = EXPT_IE;
        else
           expt_nxt_state = EXPT_ID;    
    end
    EXPT_IE: begin
        if(exception_entry)
            expt_nxt_state = EXPT_IE;
        else
            expt_nxt_state = EXPT_IDLE;    
    end 
    endcase         
end

always@ (posedge clk or negedge rst_n)
begin
    if (!rst_n)
        expt_cur_state <= EXPT_IDLE;
    else 
        expt_cur_state <= expt_nxt_state;
end

wire expt_entry_if_hold = (expt_request)|(expt_cur_state == EXPT_FALT)|(expt_cur_state == EXPT_ID);
wire expt_entry_if_nop  = (expt_request)|(expt_cur_state == EXPT_FALT)|(expt_cur_state == EXPT_ID) | (expt_cur_state == EXPT_IE);
wire expt_entry_id_nop = ie_hardfault|(expt_cur_state == EXPT_FALT);  //how about ID_PC value?

//below case is covered by branch condition.
wire expt_tail_if_hold = 1'b0;
wire expt_tail_if_nop  = 1'b0;
wire expt_return_if_hold = 1'b0;
wire expt_return_if_nop = 1'b0;


wire fetch_hold_exception = expt_entry_if_hold;
wire fetch_nop_exception  = expt_entry_if_nop;

wire dec_hold_exception = 1'b0;
wire dec_nop_exception  = expt_entry_id_nop;



//======================
//debug event. 
//======================
//Debug events will trigger pipeline be held. 
//It is processed in debugger module.
wire fetch_hold_debug = 1'b0;
wire fetch_nop_debug  = 1'b0;
wire dec_hold_debug   = 1'b0;
wire dec_nop_debug    = 1'b0;




//============================
assign fetch_hold = fetch_hold_structure | 
                    fetch_hold_branch | 
                    fetch_hold_data | 
                    fetch_hold_exception |
                    fetch_hold_debug;

assign fetch_nop  = fetch_nop_structure | 
                    fetch_nop_branch | 
                    fetch_nop_data | 
                    fetch_nop_exception |
                    fetch_nop_debug;
                    
                    
assign dec_hold   = dec_hold_structure | 
                    dec_hold_branch | 
                    dec_hold_data | 
                    dec_hold_exception |
                    dec_hold_debug;

assign dec_nop    = dec_nop_structure | 
                    dec_nop_branch | 
                    dec_nop_data | 
                    dec_nop_exception |
                    dec_nop_debug;




//======================================
//Startup
//======================================
reg [7:0] startup_latency;

always@ (posedge clk or negedge rst_n)
begin
    if (!rst_n)
        startup_latency <= 8'h00;
    else 
        startup_latency <= {startup_latency[6:0],1'b1};
end
assign startup = startup_latency[7];



//=======================
//Mask interrupts
//=======================
wire exception_req_mask           = (c_maskints & (exception_req_num[5:0] > 6'd11))?
                                    1'b0 : exception_req;
									
wire [8:0] exception_req_num_mask = (c_maskints & (exception_req_num[5:0] > 6'd11))?
                                    9'b111_000_000 : exception_req_num;



//=======================
//priority boosting condition.
//=======================
//raise the execution priority to 0. (I think it should excluding reset_stra, NMI, Hardfault and Thread mode)
wire [8:0] exception_ack_pri_boost = (PRIMASK && (exception_ack_num[8:6]> 3'b010) && (exception_ack_num[8:6] != 3'b111)) ? 
                                    3'b011 : exception_ack_num[8:6];


//=======================
//priority escalation condition.
//=======================
assign svcall_fault = (exception_req_mask & (exception_req_num_mask[5:0] == 6'd11)) &   //SVCall
                    (exception_ack_num[8:6] > 3'b010)&                      //not NMI or HardFault
                    (exception_ack_num[8:6] <= exception_req_num_mask[8:6]);       //lower Priority



//=======================
//preemption condition.
//=======================
//Only the exception with higher priority should be taken immediately. 
wire preemption_cnd = exception_req_mask & (exception_req_num_mask[8:6] < exception_ack_pri_boost);

reg     preemption;
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        preemption      <= 1'b0;
    end
    else
    begin 
        preemption      <= preemption_cnd;
    end
end    
//???
assign expt_request    = (~ie_stop_req) & 
                         (preemption) & 
						 (~exception_entry) & 
						 (~exception_return) & 
						 (~tail_chaining);
						 
assign exe_cancel      = expt_request;
assign dec_expt_insert = expt_request;


//=======================
//Lockup condition
//=======================
wire lockup_entry = ((exception_ack_num[8:6] == 3'b001 ) | 
                     (exception_ack_num[8:6] == 3'b010 )) 
                     & (hardfault_req | svcall_req);
					 
wire lockup_exit = (exception_ack_num[8:6] == 3'b010 ) & 
                   (exception_req_mask & (exception_req_num_mask[8:6] == 3'b001))
                   | core_halted ;   
				   
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        lockup      <= 1'b0;
    else if (lockup_entry)
        lockup      <= 1'b1;
    else if (lockup_exit)
        lockup      <= 1'b0;
end    


//=======================
//Core status to debug function
//=======================
assign  core_reset   = reset_trap;
assign  core_lockup  = lockup;
assign  core_sleep   = 1'b0;  //TBD
assign  core_hardfault = ie_hardfault;
assign  core_id_pc   = id_pc;
assign  core_bkpt_inst = bkpt_inst;
            

endmodule




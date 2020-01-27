
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
// File        : inst_exe.v
// Author      : PODES
// Date        : 20200101
// Version     : 1.0
// Description : Instruction execution stage of IU. 
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

module inst_exe (
                //INPUTS
                rst_n,
                clk,                
                
                //ID interface      
                id_pc ,
                id_hardfault,
                optype,     //optype to execution stage
                opand1,
                opand2,
                opand3,
                opand4,
                carry_in,
                nzcv,
                sign_ext,     
                byte_en,           

                //registers         
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
                PC,
                branch_addr , //new branch address to be loaded. 
                branch_valid, //new branch addr is valid.           
                xPSR,       //xPSR register
                PRIMASK,    //PRIMASK register
				CONTROL,    //CONTROL register
                
                //exception information
                exe_cancel,
                exception_req_vector,  //32bits vector.
                exception_req_num, //requested number.
                exception_ack,    //one cycle high.
                exception_ack_num,//Acked number. 
                exception_entry,  //high period indicates entry is on the way.
                exception_return, //Return is on the way.
                tail_chaining, //tail_chaining exception is on the way.
              
                //Memory access I/F
                mem_req      ,
                mem_addr     ,
                mem_rdy      ,
                mem_rd_data  ,
                mem_wr_data  , 
                mem_wr       ,
                mem_byte_en  ,
                
                //IE status
                ie_pc        ,
                ie_hardfault ,
                ie_bsy       ,
				core_halted  ,
                
                //reset trap information
                EPSR_T_rst_val,
                EPSR_T_rst_flg,
                MSP_rst_val,
                MSP_rst_flg,
                reset_trap,
                
				//Debug control from debugger
				ie_stop_req,
				
                //Register access I/F for Debugger
                reg_acc_req,
                reg_sel,
                reg_wnr,
                reg_rdy,
                reg_to_cpu,
                reg_from_cpu
                  

             );

             
//-----------------------------------------------------------//
//                      INPUTS/OUTPUTS                                  //
//-----------------------------------------------------------//
input                   rst_n   ;
input                   clk     ;

input  [31:0]           id_pc ;   
input                   id_hardfault;         
input  [4:0]            optype;     //optype to execution stage
input  [31:0]           opand1;
input  [31:0]           opand2;
input  [4:0]            opand3;
input  [15:0]           opand4;
input                   carry_in;
input  [1:0]            nzcv    ;
input                   sign_ext;  
input  [1:0]            byte_en;              

output [31:0]           R0  ;
output [31:0]           R1  ;
output [31:0]           R2  ;
output [31:0]           R3  ;
output [31:0]           R4  ;
output [31:0]           R5  ;
output [31:0]           R6  ;
output [31:0]           R7  ;
output [31:0]           R8  ;
output [31:0]           R9  ;
output [31:0]           R10 ;
output [31:0]           R11 ;
output [31:0]           R12 ;
output [31:0]           SP  ;
output [31:0]           LR  ;
output  [31:0]          PC  ;
output [31:0]           branch_addr  ; 
output                  branch_valid;
output [31:0]           xPSR  ;  
output [31:0]           PRIMASK;   
output [31:0]           CONTROL; 

input                   exe_cancel;
input  [7:0]            exception_req_vector;  //32bits vector.
input  [8:0]            exception_req_num; //requested number.
output                  exception_ack;    //one cycle high.
output [8:0]            exception_ack_num;//Acked number. 
output                  exception_entry;  //high period indicates entry is on the way.
output                  exception_return;             
output                  tail_chaining;

output                  mem_req      ;
output [31:0]           mem_addr     ; 
input                   mem_rdy      ;
input  [31:0]           mem_rd_data  ;
output [31:0]           mem_wr_data  ;
output                  mem_wr       ;
output [1:0]            mem_byte_en  ;

output [31:0]           ie_pc        ;
output                  ie_hardfault ;
output                  ie_bsy       ;
output                  core_halted  ;

input                   EPSR_T_rst_val ;
input                   EPSR_T_rst_flg ;
input [31:0]            MSP_rst_val    ;
input                   MSP_rst_flg    ;
input                   reset_trap     ;

                //Debug control from debugger.
input                   ie_stop_req     ;
                //Register access I/F for Debugger 
input                   reg_acc_req;
input [4:0]             reg_sel;
input                   reg_wnr;
output                  reg_rdy;
input  [31:0]           reg_to_cpu;
output [31:0]           reg_from_cpu;
//-----------------------------------------------------------//
//                    REGISTERS & WIRES                      //
//-----------------------------------------------------------//

   
reg [31:0]           nxt_R0  ;
reg [31:0]           nxt_R1  ;
reg [31:0]           nxt_R2  ;
reg [31:0]           nxt_R3  ;
reg [31:0]           nxt_R4  ;
reg [31:0]           nxt_R5  ;
reg [31:0]           nxt_R6  ;
reg [31:0]           nxt_R7  ;
reg [31:0]           nxt_R8  ;
reg [31:0]           nxt_R9  ;
reg [31:0]           nxt_R10 ;
reg [31:0]           nxt_R11 ;
reg [31:0]           nxt_R12 ;
reg [31:0]           nxt_PSP  ;
reg [31:0]           nxt_MSP  ;
reg [31:0]           nxt_LR  ;
reg [31:0]           nxt_branch_addr  ;   
reg                  nxt_branch_valid;             

reg [31:0]           R0  ;
reg [31:0]           R1  ;
reg [31:0]           R2  ;
reg [31:0]           R3  ;
reg [31:0]           R4  ;
reg [31:0]           R5  ;
reg [31:0]           R6  ;
reg [31:0]           R7  ;
reg [31:0]           R8  ;
reg [31:0]           R9  ;
reg [31:0]           R10 ;
reg [31:0]           R11 ;
reg [31:0]           R12 ;
reg [31:0]           PSP  ;
reg [31:0]           MSP  ;
reg [31:0]           LR  ;
reg [31:0]          branch_addr  ;   
reg                 branch_valid;     

reg [31:0]           ie_pc;

reg [31:0]           reg_from_cpu;

wire [31:0]  SP;

reg          nxt_N_flag;
reg          nxt_Z_flag;
reg          nxt_C_flag;
reg          nxt_V_flag;  
reg          nxt_PRIMASK_flag;
reg          nxt_EPSR_T;


reg          N_flag;
reg          Z_flag;
reg          C_flag;
reg          V_flag;  
reg          PRIMASK_flag;
reg          EPSR_T;


reg [31:0]   mem_addr;
reg [31:0]   nxt_mem_addr;
reg          mem_wr  ;
reg          nxt_mem_wr  ;
reg          mem_req ;
reg          nxt_mem_req ;
reg [31:0]   mem_wr_data ;
reg [31:0]   tmp_mem_wr_data;
reg [31:0]   nxt_mem_wr_data;
reg [1:0]    mem_byte_en ;
reg [1:0]    nxt_mem_byte_en ;

reg          core_halted;

reg [3:0]    reg_num;
reg [3:0]    nxt_reg_num;

wire [31:0]           APSR;      //APSR register
wire [31:0]           IPSR;
wire [31:0]           EPSR;
wire [31:0]           PRIMASK;
wire [31:0]           CONTROL;
                
               
reg        nxt_act_SP;
reg        act_SP;

wire        alu_N_flag;          
wire        alu_Z_flag;
wire        alu_C_flag;
wire        alu_V_flag;
wire [31:0] alu_result;


reg [31:0]  blx_addr;

reg [31:0]  mrs_result;

reg         ie_hardfault;
reg         nxt_ie_hardfault;
 
reg  [4:0]  current_exe_state;
reg  [4:0]  next_exe_state;

reg  [8:0]  nxt_reg_pop_flag;
reg  [8:0]  reg_pop_flag;
reg  [8:0]  nxt_reg_push_flag;
reg  [8:0]  reg_push_flag;

reg         exception_return;
reg         nxt_exception_return;
reg         exception_ack;    
reg         nxt_exception_ack;    
wire[8:0]   exception_ack_num;
reg         exception_entry;  
reg         nxt_exception_entry;  
reg         inst_mode;
reg         nxt_inst_mode;
reg [3:0]   exc_return;
reg [3:0]   nxt_exc_return;
reg [31:0]  tmp_nxt_MSP;
reg         tmp_psr9;
reg [31:0]  tmp_nxt_PSP;
reg [4:0]   Rx_for_MR;
reg [4:0]   nxt_Rx_for_MR;

reg [31:0]  frameptr;
reg         nxt_frameptralign;
reg         frameptralign;
reg [4:0]   opand3_kpt;
reg [4:0]   nxt_opand3_kpt;
reg [31:0]  alu_result_kpt;
reg [31:0]  nxt_alu_result_kpt;
reg         tail_chaining ;
reg         nxt_tail_chaining;

reg  [31:0]  canceled_pc;
wire [31:0]  xPSR;
reg  [8:0]   nxt_IPSR8_0;
reg  [8:0]   IPSR8_0;

reg  [2:0]   nxt_nested_pri_num ;
reg  [2:0]   nested_pri_num ;

reg  [31:0]  conved_rdata;
reg  [2:0]   pre_rdata_conv;
reg  [2:0]   nxt_pre_rdata_conv;
reg  [2:0]   rdata_conv;
reg  [2:0]   nxt_rdata_conv;

//-----------------------------------------------------------//
//                          PARAMETERS                       //
//-----------------------------------------------------------//
parameter THREAD_MODE   = 1'b0;
parameter HANDLER_MODE  = 1'b1;

parameter EXE_IDLE  =5'h1f;
parameter EXE_STP0  =5'h00;

parameter EXE_PUSH9 =5'h01;
parameter EXE_PUSH0 =5'h02;
parameter EXE_PUSH1 =5'h03;
parameter EXE_PUSH2 =5'h04;
parameter EXE_PUSH3 =5'h05;
parameter EXE_PUSH4 =5'h06;
parameter EXE_PUSH5 =5'h07;
parameter EXE_PUSH6 =5'h08;
parameter EXE_PUSH7 =5'h09;
parameter EXE_PUSH8 =5'h0a;
parameter EXE_MWR1  =5'h0b;
parameter EXE_MWR2  =5'h0c;

parameter EXE_POP9  =5'h11;
parameter EXE_POP0  =5'h12;
parameter EXE_POP1  =5'h13;
parameter EXE_POP2  =5'h14;
parameter EXE_POP3  =5'h15;
parameter EXE_POP4  =5'h16;
parameter EXE_POP5  =5'h17;
parameter EXE_POP6  =5'h18;
parameter EXE_POP7  =5'h19;
parameter EXE_POP8  =5'h1a;
parameter EXE_MRD1  =5'h1b;
parameter EXE_MRD2  =5'h1c;
parameter EXE_TAIL  =5'h1d;


 parameter OP_IDLE  =  5'h00;
 parameter OP_BL    =  5'h01;
 parameter OP_MSR   =  5'h02;
 parameter OP_MRS   =  5'h03;
 parameter OP_LSL   =  5'h04;
 parameter OP_LSR   =  5'h05;
 parameter OP_ASR   =  5'h06;
 parameter OP_ADD   =  5'h07;
 parameter OP_OR    =  5'h08;
 parameter OP_AND   =  5'h09;
 parameter OP_XOR   =  5'h0a;
 parameter OP_RSR   =  5'h0b;
 parameter OP_MUL   =  5'h0c;
 parameter OP_MR    =  5'h0d;
 parameter OP_MW    =  5'h0e;
 parameter OP_CPS   =  5'h0f;
 parameter OP_PUSH  =  5'h10;
 parameter OP_POP   =  5'h11;
 parameter OP_BX    =  5'h12;
 parameter OP_BLX   =  5'h13;
 parameter OP_STM   =  5'h14;
 parameter OP_EXPT  =  5'h15;



//-----------------------------------------------------------//
//                          ARCHITECTURE                     //
//-----------------------------------------------------------//

//this module should be in top level.
alu alu_u0 (
             .opand1    (opand1    ),
             .opand2    (opand2    ),
             .optype    (optype    ),
             .carry_in  (carry_in  ),
             .nzcv      (nzcv      ),
             .N_flag    (N_flag    ),
             .Z_flag    (Z_flag    ),
             .C_flag    (C_flag    ),
             .V_flag    (V_flag    ),
                              
             .alu_N_flag(alu_N_flag),
             .alu_Z_flag(alu_Z_flag),
             .alu_C_flag(alu_C_flag),
             .alu_V_flag(alu_V_flag),
             .alu_result(alu_result)
             );


//Update registers and memory operations
always @ *
begin
    nxt_R0  =  R0 ;
    nxt_R1  =  R1 ;
    nxt_R2  =  R2 ;
    nxt_R3  =  R3 ;
    nxt_R4  =  R4 ;
    nxt_R5  =  R5 ;
    nxt_R6  =  R6 ;
    nxt_R7  =  R7 ;
    nxt_R8  =  R8 ;
    nxt_R9  =  R9 ;
    nxt_R10 =  R10;
    nxt_R11 =  R11;
    nxt_R12 =  R12;
    nxt_PSP =  PSP ;
    nxt_MSP =  MSP ;
    nxt_act_SP = act_SP;
    nxt_LR  =  LR ;
    nxt_branch_addr  = branch_addr;
    nxt_branch_valid = 1'b0;
    nxt_N_flag       = N_flag;
    nxt_Z_flag       = Z_flag;
    nxt_C_flag       = C_flag;
    nxt_V_flag       = V_flag;    
    nxt_PRIMASK_flag = PRIMASK_flag;
    nxt_EPSR_T       = EPSR_T;
    
    nxt_mem_addr = mem_addr;
    nxt_mem_wr   = mem_wr;
    nxt_mem_wr_data = mem_wr_data;
    nxt_mem_byte_en  = mem_byte_en;
    nxt_mem_req  = mem_req;  //keep the valid.
    tmp_mem_wr_data = 32'b0;
    
    nxt_Rx_for_MR   = Rx_for_MR;
    
    next_exe_state = EXE_STP0;
    
    nxt_ie_hardfault = 1'b0;  
    
    nxt_reg_num  = 4'hf;
    
    nxt_reg_pop_flag      = reg_pop_flag;
    nxt_reg_push_flag     = reg_push_flag;
    nxt_exception_return = exception_return;
    nxt_exception_entry  = exception_entry;
    nxt_inst_mode  = inst_mode;
    nxt_exc_return = exc_return;
    nxt_exception_ack = 1'b0;
    
    nxt_IPSR8_0   = IPSR8_0;
    frameptr   = 32'b0;
    nxt_opand3_kpt = opand3_kpt;
    nxt_alu_result_kpt = alu_result_kpt;
    
    nxt_tail_chaining = tail_chaining;
    
    nxt_nested_pri_num = nested_pri_num;
    nxt_frameptralign = frameptralign;
    
    conved_rdata  = 32'b0;
    nxt_pre_rdata_conv = 3'b010;
    nxt_rdata_conv = 3'b010;
    
    blx_addr = 32'b0;
    mrs_result = 32'b0;
    tmp_nxt_MSP = 32'b0;
    tmp_psr9 = 1'b0;
    tmp_nxt_PSP = 32'b0;
                
    if(exe_cancel)
    begin
       nxt_branch_addr  = 32'b0;
       nxt_branch_valid = 1'b0;
       nxt_mem_wr   = 1'b0;
       nxt_mem_req  = 1'b0;
       next_exe_state = EXE_STP0;
       nxt_reg_pop_flag = 9'b0;
       nxt_reg_push_flag = 9'b0;
    end
	
	else if(current_exe_state == EXE_STP0)
    begin
       if (ie_stop_req)
	   begin
	       next_exe_state = EXE_STP0;
	   end
	   else  //To execute inst during ie_stop_req is low level.	   
       begin
	     case (optype) //synopsys parallel_case
             OP_LSL,
             OP_LSR,
             OP_ASR,
             OP_RSR,
             OP_ADD,
             OP_OR,
             OP_XOR,
             OP_AND,
             OP_MUL:begin //They have same calculation architecture
                      next_exe_state =  EXE_STP0;
                      nxt_N_flag  = alu_N_flag;
                      nxt_Z_flag  = alu_Z_flag;
                      nxt_C_flag  = alu_C_flag;
                      nxt_V_flag  = alu_V_flag;
                      
                      case (opand3)
                          5'b00000: nxt_R0  = alu_result;
                          5'b00001: nxt_R1  = alu_result;
                          5'b00010: nxt_R2  = alu_result;
                          5'b00011: nxt_R3  = alu_result;
                          5'b00100: nxt_R4  = alu_result;
                          5'b00101: nxt_R5  = alu_result;
                          5'b00110: nxt_R6  = alu_result;
                          5'b00111: nxt_R7  = alu_result;
                          5'b01000: nxt_R8  = alu_result;
                          5'b01001: nxt_R9  = alu_result;
                          5'b01010: nxt_R10 = alu_result;
                          5'b01011: nxt_R11 = alu_result;
                          5'b01100: nxt_R12 = alu_result;
                          5'b01101: if (act_SP) nxt_PSP = alu_result; else nxt_MSP = alu_result;
                          5'b01110: nxt_LR  = alu_result;
                          5'b01111: begin
                                        nxt_branch_addr  = alu_result;
                                        nxt_branch_valid = 1'b1;
                                    end
                          default: ;   //Nothing to be updated. ????
                      endcase
                    end
                    
             OP_IDLE :begin
                      next_exe_state =  EXE_STP0;
                      nxt_ie_hardfault = id_hardfault; //if high, unimplemented instruction.
                    end
                    
                    
             OP_BL :begin
                      next_exe_state =  EXE_STP0;
                      nxt_LR = {id_pc[31:1], 1'b0} + 5; //address for next INST.
                      nxt_branch_addr = alu_result;
                      nxt_branch_valid = 1'b1;
                    end
                    
             OP_BX :begin
                      if ((opand1[31:28] == 4'b1111) && (inst_mode == HANDLER_MODE)) //exception return start
                      begin
                          if (exception_req_num[8:6] < nested_pri_num) //tail_chaining.
                          begin //ExceptionTaken
                            nxt_tail_chaining = 1'b1;
                            next_exe_state = EXE_MRD1;//Need read back the handler address from vector table.
                            nxt_mem_addr = {24'b0, exception_req_vector};  
                            nxt_mem_byte_en  = 2'b10;
                            nxt_mem_wr   = 1'b0; //read
                            nxt_mem_req  = 1'b1;
                            
                            nxt_exception_ack = 1'b1;  
                            nxt_inst_mode = HANDLER_MODE;
                            nxt_IPSR8_0 = exception_req_num;
                            nxt_LR = {28'hf000000, opand1[3:0]};//keep the EXC_RETURN value.
                            nxt_act_SP = 1'b0; 
                          end
                          else //normal exception return.
                          begin	
                            next_exe_state =  EXE_POP0;
                            nxt_exception_return = 1'b1;
                            nxt_exc_return = opand1[3:0];
                            nxt_reg_pop_flag = 9'b110111111; //PSR,PC,0,LR,R12,R3,R2,R1,R0;
                            nxt_reg_num = 4'hf;
                            nxt_mem_byte_en  = 2'b10; //word access
                            nxt_mem_wr   = 1'b0;  //read
                            nxt_mem_req  = 1'b1;     
                            case (opand1[3:0])
                              4'b0001 :
                                begin
                                    nxt_mem_addr  = MSP;
                                    nxt_inst_mode = HANDLER_MODE;
                                    nxt_act_SP    = 1'b0;
                                end
                              4'b1001 :
                                begin
                                    nxt_mem_addr  = MSP;
                                    nxt_inst_mode = THREAD_MODE;
                                    nxt_act_SP    = 1'b0;
                                end
                              4'b1101 :
                                begin
                                    nxt_mem_addr  = PSP;
                                    nxt_inst_mode = THREAD_MODE;
                                    nxt_act_SP    = 1'b1;
                                end
                              default : 
                                begin
                                    nxt_exception_return = 1'b0;
                                    nxt_exc_return = 4'b0;
                                    nxt_reg_pop_flag = 9'b0;
                                    nxt_mem_req = 1'b0;
                                    nxt_ie_hardfault = 1'b1;
                                    next_exe_state = EXE_STP0;
                                end
                            endcase
                            if (nxt_mem_addr[1:0] != 2'b00)
                            begin
                                nxt_exception_return = 1'b0;
                                nxt_exc_return = 4'b0;
                                nxt_reg_pop_flag = 9'b0;
                                nxt_mem_req = 1'b0;
                                nxt_ie_hardfault = 1'b1;
                                next_exe_state = EXE_STP0;
                            end
                          end               
                      end
                      else if ((opand1[31:28] == 4'b1111) && (inst_mode == THREAD_MODE)) //Unexpected exception return
                      begin
                          next_exe_state =  EXE_STP0;
                          nxt_ie_hardfault = 1'b1;  //exception   
                      end
                      else //normal branch
                      begin
                          next_exe_state =  EXE_STP0;
                          nxt_ie_hardfault = opand1[0]? 1'b0: 1'b1;  //Hard Fault Exception
                          if (opand1[0])
                          begin
                            nxt_branch_addr = {opand1[31:1],1'b0};
                            nxt_branch_valid = 1'b1;
                            nxt_EPSR_T = opand1[0];
                          end
                      end
                    end
                    
             OP_BLX:begin
                      next_exe_state =  EXE_STP0;
                      nxt_ie_hardfault = opand1[0] ? 1'b0:1'b1; //Hard Fault Exception
                      if (opand1[0])
                      begin
                        blx_addr = id_pc + 2; //address for next INST.  
                        nxt_LR = {blx_addr[31:1], 1'b1};
                        nxt_branch_addr = {opand1[31:1],1'b0};
                        nxt_branch_valid = 1'b1;
                        nxt_EPSR_T = opand1[0];
                      end
                    end
                    
             OP_MSR:begin
                      next_exe_state =  EXE_STP0;
                      case (opand4[7:0])
                          8'd0, 8'd1, 8'd2, 8'd3: 
                                 begin
                                   nxt_N_flag = opand1[31];
                                   nxt_Z_flag = opand1[30];
                                   nxt_C_flag = opand1[29];
                                   nxt_V_flag = opand1[28];
                                 end
                          8'd8:  nxt_MSP          = opand1;
                          8'd9:  nxt_PSP          = opand1;
                          8'd16: nxt_PRIMASK_flag = opand1[0];
                          8'd20: if (inst_mode) nxt_act_SP = opand1[1]; else nxt_act_SP = act_SP;
                          default: ;  //Nothing to be updated.???
                      endcase
                    end
                    
             OP_MRS:begin
                      next_exe_state =  EXE_STP0;
                      case (opand4[7:0])
                          8'd0:    mrs_result = APSR;
                          8'd1:    mrs_result = IPSR | APSR; 
                          8'd2:    mrs_result = APSR; //EPSR | APSR; //read EPSR return 0;
                          8'd3:    mrs_result = IPSR | APSR; //IPSR | APSR | EPSR;  //read EPSR return 0;
                          8'd5:    mrs_result = IPSR; 
                          8'd6:    mrs_result = 32'd0; //EPSR;  //read EPSR return 0;
                          8'd7:    mrs_result = IPSR; //IPSR | EPSR;  //read EPSR return 0;
                          8'd8:    mrs_result = MSP; 
                          8'd9:    mrs_result = PSP; 
                          8'd16:   mrs_result = PRIMASK; 
                          8'd20:   mrs_result = CONTROL; 
                          default: mrs_result = 32'd0; 
                      endcase
                      case (opand3[3:0])
                          4'b0000: nxt_R0  = mrs_result;
                          4'b0001: nxt_R1  = mrs_result;
                          4'b0010: nxt_R2  = mrs_result;
                          4'b0011: nxt_R3  = mrs_result;
                          4'b0100: nxt_R4  = mrs_result;
                          4'b0101: nxt_R5  = mrs_result;
                          4'b0110: nxt_R6  = mrs_result;
                          4'b0111: nxt_R7  = mrs_result;
                          4'b1000: nxt_R8  = mrs_result;
                          4'b1001: nxt_R9  = mrs_result;
                          4'b1010: nxt_R10 = mrs_result;
                          4'b1011: nxt_R11 = mrs_result;
                          4'b1100: nxt_R12 = mrs_result;                     
                          default:  ;  //if 13-15, unpredictable. no update registers
                      endcase
                    end
             
             OP_MR :begin
                      next_exe_state = EXE_MRD1;
                      nxt_mem_addr = alu_result;
                      nxt_mem_byte_en  = byte_en; //byte/half/word access
                      nxt_pre_rdata_conv = {sign_ext, byte_en};
                      nxt_mem_wr   = 1'b0;
                      nxt_mem_req  = 1'b1;
                      nxt_Rx_for_MR = opand3; //latch the target register num.
                      if (((byte_en == 2'b01) && (nxt_mem_addr[0] !== 1'b0)) || ((byte_en == 2'b10) && (nxt_mem_addr[1:0] !== 2'b00)))
                      begin
                          nxt_ie_hardfault = 1'b1;  //address alignment. exception
                          nxt_mem_req  = 1'b0;
                          next_exe_state = EXE_STP0;
                      end
                    end
                    
             OP_MW :begin
                      next_exe_state =EXE_MWR1;
                      nxt_mem_addr = alu_result;                   
                      case (opand3[2:0])
                          3'b000: tmp_mem_wr_data = R0;
                          3'b001: tmp_mem_wr_data = R1;
                          3'b010: tmp_mem_wr_data = R2;
                          3'b011: tmp_mem_wr_data = R3;
                          3'b100: tmp_mem_wr_data = R4;
                          3'b101: tmp_mem_wr_data = R5;
                          3'b110: tmp_mem_wr_data = R6;
                          3'b111: tmp_mem_wr_data = R7; 
                      endcase 
                      if (byte_en == 2'b00)
                         nxt_mem_wr_data = {4{tmp_mem_wr_data[7:0]}};
                      else if (byte_en == 2'b01)
                         nxt_mem_wr_data = {2{tmp_mem_wr_data[15:0]}};
                      else 
                         nxt_mem_wr_data = tmp_mem_wr_data;                   
                      nxt_mem_byte_en  = byte_en;//byte/half/word access
                      nxt_mem_wr   = 1'b1;
                      nxt_mem_req  = 1'b1;
                      if (((byte_en == 2'b01) && (nxt_mem_addr[0] !== 1'b0)) || ((byte_en == 2'b10) && (nxt_mem_addr[1:0] !== 2'b00)))
                      begin  
                          nxt_ie_hardfault = 1'b1;  //address alignment. Hard Fault Exception
                          nxt_mem_req  = 1'b0;
                          next_exe_state = EXE_STP0;
                      end
                    end
                    
             OP_CPS:begin
                      next_exe_state =  EXE_STP0;
                      nxt_PRIMASK_flag = opand2[1] ? opand2[4] : PRIMASK_flag;
                    end
                    
             OP_EXPT:begin
                      nxt_mem_req = 1'b1;
                      nxt_mem_byte_en = 2'b10;
                      nxt_mem_wr = 1'b1;
                      next_exe_state = EXE_PUSH0;
                      nxt_mem_wr_data = R0;
                      frameptr = {alu_result[31:3], 1'b0, alu_result[1:0]};
                      if(act_SP &&(inst_mode == THREAD_MODE)) 
                      begin
                        nxt_frameptralign = PSP[2];
                        nxt_PSP = frameptr;
                      end
                      else
                      begin
                        nxt_frameptralign = MSP[2];
                        nxt_MSP = frameptr;
                      end
                      nxt_mem_addr = frameptr;
                      nxt_reg_push_flag = 9'b111111111; //R(Vector), W(PSR, ReturnAddr, LR, R12, R3, R2, R1, R0)
                      nxt_exception_entry = 1'b1;  
                          
                      if (nxt_mem_addr[1:0] !== 2'b00)
                      begin  
                          nxt_ie_hardfault = 1'b1;  //address alignment. exception
                          nxt_mem_req  = 1'b0;
                          next_exe_state = EXE_STP0;
                      end       
                               
                    end                 
                    
             OP_STM,       
             OP_PUSH:begin  
                      nxt_reg_push_flag = opand4[8:0];                 
                      if (opand4[8:0] == 9'b0)  //if no register need to be pushed, ignore.
                      begin
                          nxt_mem_req = 1'b0;
                          next_exe_state =  EXE_STP0;                      
                      end
                      else //one or more registers need be pushed.
                      begin
                          nxt_mem_req  = 1'b1;  //memory access request.
                          nxt_mem_byte_en  = 2'b10; //word write
                          nxt_mem_wr   = 1'b1; 
                          //store base address at last stage.
                          //To maintain a correct SP value if an exception occurs during STM/PUSH inst.
                          //case (opand3[3:0])
                          //    4'b0000: nxt_R0 = alu_result;
                          //    4'b0001: nxt_R1 = alu_result;
                          //    4'b0010: nxt_R2 = alu_result;
                          //    4'b0011: nxt_R3 = alu_result;
                          //    4'b0100: nxt_R4 = alu_result;
                          //    4'b0101: nxt_R5 = alu_result;
                          //    4'b0110: nxt_R6 = alu_result;
                          //    4'b0111: nxt_R7 = alu_result; 
                          //    4'b1101: begin
                          //               if (act_SP) nxt_PSP = alu_result; 
                          //               else nxt_MSP = alu_result;
                          //             end
                          //    default: ; //nothing to do.
                          //endcase     
                          nxt_opand3_kpt = opand3;
                          nxt_alu_result_kpt = alu_result;                   
                          if (optype == OP_STM)  
                              nxt_mem_addr = opand1; //first address for push.  
                          else  //PUSH     
                              nxt_mem_addr = alu_result; //first address for push.                         
                          if (nxt_mem_addr[1:0] !== 2'b00)
                          begin  
                              nxt_ie_hardfault = 1'b1;  //address alignment. exception
                              nxt_mem_req  = 1'b0;
                              next_exe_state = EXE_STP0;
                          end
                          if (opand4[0]) 
                          begin 
                            next_exe_state = EXE_PUSH0;
                            nxt_mem_wr_data = R0;
                          end
                          else if (opand4[1]) 
                          begin
                            next_exe_state = EXE_PUSH1;
                            nxt_mem_wr_data = R1;
                          end
                          else if (opand4[2]) 
                          begin
                            next_exe_state = EXE_PUSH2;
                            nxt_mem_wr_data = R2;
                          end
                          else if (opand4[3]) 
                          begin
                            next_exe_state = EXE_PUSH3;
                            nxt_mem_wr_data = R3;
                          end
                          else if (opand4[4]) 
                          begin
                            next_exe_state = EXE_PUSH4;
                            nxt_mem_wr_data = R4;
                          end
                          else if (opand4[5]) 
                          begin
                            next_exe_state = EXE_PUSH5;
                            nxt_mem_wr_data = R5;
                          end
                          else if (opand4[6]) 
                          begin
                            next_exe_state = EXE_PUSH6;
                            nxt_mem_wr_data = R6;
                          end
                          else if (opand4[8]) 
                          begin
                            next_exe_state = EXE_PUSH8;
                            nxt_mem_wr_data = LR;
                          end
                          else // 
                          begin
                            next_exe_state = EXE_PUSH7;
                            nxt_mem_wr_data = R7;
                          end
                      end
                    end
                   
             OP_POP:begin
                      nxt_reg_pop_flag = opand4[8:0];
                      if (opand4 == 9'b0)  //if no register need to be popped, ignore.
                      begin
                          nxt_mem_req = 1'b0;
                          next_exe_state =  EXE_STP0;                  
                      end
                      else //one or more registers need be popped.
                      begin
                          nxt_mem_req  = 1'b1;
                          nxt_mem_byte_en  = 2'b10; //word read
                          nxt_mem_wr   = 1'b0;
                          //store base address at last stage.
                          //To maintain a correct SP value if an exception occurs during SDM/POP inst.
                          // case (opand3[3:0])//synopsys parallel_case
                          //    4'b0000: nxt_R0 = alu_result;
                          //    4'b0001: nxt_R1 = alu_result;
                          //    4'b0010: nxt_R2 = alu_result;
                          //    4'b0011: nxt_R3 = alu_result;
                          //    4'b0100: nxt_R4 = alu_result;
                          //    4'b0101: nxt_R5 = alu_result;
                          //    4'b0110: nxt_R6 = alu_result;
                          //    4'b0111: nxt_R7 = alu_result; 
                          //    4'b1101: begin
                          //               if (act_SP) nxt_PSP = alu_result; 
                          //               else nxt_MSP = alu_result;
                          //             end
                          //    default: ; //nothing to do.
                          //endcase     
                          nxt_opand3_kpt = opand3;
                          nxt_alu_result_kpt = alu_result;      
                          nxt_mem_addr = opand1; //first address for pop. 
                          if (nxt_mem_addr[1:0] !== 2'b00)
                          begin  
                          //synopsys translate_off
                          `ifdef DEBUG_SIM
                              $display ("[IE stage] POP first Memory address is unaligned. HardFault. Time is %d ",$time );
                          `endif
                          //synopsys translate_on
                              nxt_ie_hardfault = 1'b1;  //address alignment. exception
                              nxt_mem_req  = 1'b0;
                              next_exe_state = EXE_STP0;
                          end
                                                 
                          nxt_reg_num = 4'hf; //first control phase, no data.   
                          if (opand4[0]) 
                          begin
                              next_exe_state = EXE_POP0; 
                          end
                          else if (opand4[1]) 
                          begin
                              next_exe_state = EXE_POP1;
                          end
                          else if (opand4[2]) 
                          begin
                              next_exe_state = EXE_POP2; 
                          end
                          else if (opand4[3]) 
                          begin
                              next_exe_state = EXE_POP3;
                          end
                          else if (opand4[4]) 
                          begin
                              next_exe_state = EXE_POP4; 
                          end
                          else if (opand4[5]) 
                          begin
                              next_exe_state = EXE_POP5;
                          end
                          else if (opand4[6]) 
                          begin
                              next_exe_state = EXE_POP6; 
                          end
                          else if (opand4[8]) 
                          begin
                              next_exe_state = EXE_POP8; 
                          end                           
                          else // if not R0-6, PC, opand4[7]should be 1.
                          begin
                              next_exe_state = EXE_POP7; 
                          end
                      end 
                    end
                    
             default:  
                   begin
                     next_exe_state =  EXE_STP0;  //return to step0 state;
                   end
         endcase 
       end
    end
	
    else if (current_exe_state == EXE_MRD1) //Control Phase
    begin
      if (mem_rdy == 1'b0)//Wait until the access is accepted.
        next_exe_state = EXE_MRD1;
      else
      begin //control phase is done, turn to data phase
        next_exe_state = EXE_MRD2;
        nxt_mem_req  = 1'b0; 
        nxt_rdata_conv = pre_rdata_conv;
      end
    end
    
    else if (current_exe_state == EXE_MRD2) //Data Phase
    begin
      if (mem_rdy == 1'b0)//Wait until the data is ready.
        next_exe_state = EXE_MRD2;
      else
      begin
      	if (tail_chaining) //tail_chaining need insert a wait for branch.
      	begin
      	   next_exe_state =  EXE_STP0;  //Just like a branch condtion.
           nxt_tail_chaining = 1'b0;
      	   nxt_branch_valid = 1'b1;
      	   nxt_branch_addr = {mem_rd_data[31:1], 1'b0}; //get Handler entry address.
           nxt_EPSR_T = mem_rd_data[0];        	   
      	end
      	else
      	begin
           next_exe_state =  EXE_STP0;
           case (rdata_conv[2:0])
               3'b000:  conved_rdata  = {24'b0, mem_rd_data[7:0]};
               3'b001:  conved_rdata  = {16'b0, mem_rd_data[15:0]};
               3'b100:  conved_rdata  = {{24{mem_rd_data[7]}}, mem_rd_data[7:0]};
               3'b101:  conved_rdata  = {{16{mem_rd_data[15]}}, mem_rd_data[15:0]};
               default: conved_rdata  = mem_rd_data;
           endcase            
           case (Rx_for_MR[2:0])
               3'b000: nxt_R0  = conved_rdata;
               3'b001: nxt_R1  = conved_rdata;
               3'b010: nxt_R2  = conved_rdata;
               3'b011: nxt_R3  = conved_rdata;
               3'b100: nxt_R4  = conved_rdata;
               3'b101: nxt_R5  = conved_rdata;
               3'b110: nxt_R6  = conved_rdata;
               3'b111: nxt_R7  = conved_rdata; 
           endcase 
        end
      end
    end    
    
    else if (current_exe_state == EXE_MWR1)
    begin
        if (mem_rdy == 1'b0)//Wait until the access is accepted.
        next_exe_state = EXE_MWR1;
      else
      begin//control phase is done, turn to data phase
        next_exe_state = EXE_STP0;// it is accetable to skip over MWR2. //EXE_MWR2;        
        nxt_mem_wr   = 1'b0;
        nxt_mem_req  = 1'b0;
      end
    end
    
    else if (current_exe_state == EXE_MWR2) //Data Phase
    begin
      if (mem_rdy == 1'b0)//Wait until the data phase is ended.
        next_exe_state = EXE_MWR2;
      else
      begin
        next_exe_state =  EXE_STP0;
      end
    end

    else if (current_exe_state == EXE_PUSH0) //control phase
    begin
      if (mem_rdy == 1'b0) //Wait until the control phase is ended.
      begin
        next_exe_state = EXE_PUSH0;
      end
      else //Generate control signals for next memory write, provide data for current access.
      begin
      if (reg_push_flag[1])
        begin
          next_exe_state = EXE_PUSH1;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = R1;
        end
      else if (reg_push_flag[2])
        begin
          next_exe_state = EXE_PUSH2;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = R2;
        end
      else if (reg_push_flag[3])
        begin
          next_exe_state = EXE_PUSH3;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = R3;
        end
      else if (reg_push_flag[4])
        begin
          next_exe_state = EXE_PUSH4;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = R4;
        end
      else if (reg_push_flag[5])
        begin
          next_exe_state = EXE_PUSH5;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = R5;
        end
      else if (reg_push_flag[6])
        begin
          next_exe_state = EXE_PUSH6;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = R6;
        end
      else if (reg_push_flag[7])
        begin
          next_exe_state = EXE_PUSH7;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = R7;
        end
      else if (reg_push_flag[8])
        begin
          next_exe_state = EXE_PUSH8;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = LR;
        end
      else//PUSH is done. end the data phase on PUSH9 state
        begin
          next_exe_state =  EXE_PUSH9;
          nxt_mem_wr_data = 32'b0;
          nxt_mem_req = 1'b0;
          nxt_reg_push_flag = 9'b0;
        end
      end
    end
    
    else if (current_exe_state == EXE_PUSH1)
    begin
      if (mem_rdy == 1'b0)
      begin
        next_exe_state = EXE_PUSH1;
      end
      else
      begin
      if (reg_push_flag[2])
        begin
          next_exe_state = EXE_PUSH2;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = R2;
        end
      else if (reg_push_flag[3])
        begin
          next_exe_state = EXE_PUSH3;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = R3;
        end
      else if (reg_push_flag[4])
        begin
          next_exe_state = EXE_PUSH4;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = R4;
        end
      else if (reg_push_flag[5])
        begin
          next_exe_state = EXE_PUSH5;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = R5;
        end
      else if (reg_push_flag[6])
        begin
          next_exe_state = EXE_PUSH6;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = R6;
        end
      else if (reg_push_flag[7])
        begin
          next_exe_state = EXE_PUSH7;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = R7;
        end
      else if (reg_push_flag[8])
        begin
          next_exe_state = EXE_PUSH8;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = LR;
        end
      else
        begin
          next_exe_state =  EXE_PUSH9;
          nxt_mem_wr_data = 32'b0;
          nxt_mem_req = 1'b0;
          nxt_reg_push_flag = 9'b0;
        end
      end
    end   
    
    else if (current_exe_state == EXE_PUSH2)
    begin
      if (mem_rdy == 1'b0)
      begin
        next_exe_state = EXE_PUSH2;
      end
      else
      begin
      if (reg_push_flag[3])
        begin
          next_exe_state = EXE_PUSH3;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = R3;
        end
      else if (reg_push_flag[4])
        begin
          next_exe_state = EXE_PUSH4;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = R4;
        end
      else if (reg_push_flag[5])
        begin
          next_exe_state = EXE_PUSH5;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = R5;
        end
      else if (reg_push_flag[6])
        begin
          next_exe_state = EXE_PUSH6;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = R6;
        end
      else if (reg_push_flag[7])
        begin
          next_exe_state = EXE_PUSH7;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = R7;
        end
      else if (reg_push_flag[8])
        begin
          next_exe_state = EXE_PUSH8;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = LR;
        end
      else
        begin
          next_exe_state =  EXE_PUSH9;
          nxt_mem_wr_data = 32'b0;
          nxt_mem_req = 1'b0;
          nxt_reg_push_flag = 9'b0;
        end
      end
    end
    
    else if (current_exe_state == EXE_PUSH3)
    begin
      if (mem_rdy == 1'b0)
      begin
        next_exe_state = EXE_PUSH3;
      end
      else
      begin
      if (reg_push_flag[4])
        begin
          next_exe_state = EXE_PUSH4;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = exception_entry ? R12 : R4;
        end
      else if (reg_push_flag[5])
        begin
          next_exe_state = EXE_PUSH5;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = R5;
        end
      else if (reg_push_flag[6])
        begin
          next_exe_state = EXE_PUSH6;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = R6;
        end
      else if (reg_push_flag[7])
        begin
          next_exe_state = EXE_PUSH7;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = R7;
        end
      else if (reg_push_flag[8])
        begin
          next_exe_state = EXE_PUSH8;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = LR;
        end
      else
        begin
          next_exe_state =  EXE_PUSH9;
          nxt_mem_wr_data = 32'b0;
          nxt_mem_req = 1'b0;
          nxt_reg_push_flag = 9'b0;
        end
      end
    end    
    
    else if (current_exe_state == EXE_PUSH4)
    begin
      if (mem_rdy == 1'b0)
      begin
        next_exe_state = EXE_PUSH4;
      end
      else
      begin
      if (reg_push_flag[5])
        begin
          next_exe_state = EXE_PUSH5;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = exception_entry ? LR : R5;
        end
      else if (reg_push_flag[6])
        begin
          next_exe_state = EXE_PUSH6;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = R6;
        end
      else if (reg_push_flag[7])
        begin
          next_exe_state = EXE_PUSH7;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = R7;
        end
      else if (reg_push_flag[8])
        begin
          next_exe_state = EXE_PUSH8;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = LR;
        end
      else
        begin
          next_exe_state =  EXE_PUSH9;
          nxt_mem_wr_data = 32'b0;
          nxt_mem_req = 1'b0;
          nxt_reg_push_flag = 9'b0;
        end
      end
    end
    
    else if (current_exe_state == EXE_PUSH5)
    begin
      if (mem_rdy == 1'b0)
      begin
        next_exe_state = EXE_PUSH5;
      end
      else
      begin
      if (reg_push_flag[6])
        begin
          next_exe_state = EXE_PUSH6;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = exception_entry ? canceled_pc : R6;  //ReturnAddress == canceled_pc. 
        end
      else if (reg_push_flag[7])
        begin
          next_exe_state = EXE_PUSH7;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = R7;
        end
      else if (reg_push_flag[8])
        begin
          next_exe_state = EXE_PUSH8;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = LR;
        end
      else
        begin
          next_exe_state =  EXE_PUSH9;
          nxt_mem_wr_data = 32'b0;
          nxt_mem_req = 1'b0;
          nxt_reg_push_flag = 9'b0;
        end
      end
    end
    
    else if (current_exe_state == EXE_PUSH6)
    begin
      if (mem_rdy == 1'b0)
      begin
        next_exe_state = EXE_PUSH6;
      end
      else
      begin
      if (reg_push_flag[7])
        begin
          next_exe_state = EXE_PUSH7;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = exception_entry ? {xPSR[31:13], nested_pri_num, frameptralign, xPSR[8:0]} : R7;
        end   
      else if (reg_push_flag[8])
        begin
          next_exe_state = EXE_PUSH8;
          nxt_mem_addr = mem_addr + 4;
          nxt_mem_wr_data = LR;
        end
      else
        begin
          next_exe_state =  EXE_PUSH9;
          nxt_mem_wr_data = 32'b0;
          nxt_mem_req = 1'b0;
          nxt_reg_push_flag = 9'b0;
        end
      end
    end
    
    else if (current_exe_state == EXE_PUSH7)
    begin
      if (mem_rdy == 1'b0)
      begin
        next_exe_state = EXE_PUSH7;
      end
      else
      begin
        if (reg_push_flag[8])
        begin
          next_exe_state = EXE_PUSH8;
          nxt_mem_addr = exception_entry ? {24'b0, exception_req_vector} : (mem_addr + 4);
          nxt_mem_wr = exception_entry ? 1'b0 : 1'b1; //Read Vector.
          nxt_mem_wr_data = exception_entry ? 32'b0: LR;
          
          if(exception_entry) //ExceptionTaken() 
          begin
            nxt_LR = (inst_mode == HANDLER_MODE) ? 32'hfffffff1 : (act_SP ? 32'hfffffffd : 32'hfffffff9);
            nxt_inst_mode = HANDLER_MODE;
            nxt_nested_pri_num = IPSR8_0[8:6];
            nxt_IPSR8_0 = exception_req_num;
            nxt_act_SP = 1'b0;
            nxt_exception_ack = 1'b1;        
          end
        end
        else
        begin
          next_exe_state =  EXE_PUSH9;
          nxt_mem_wr_data = 32'b0;
          nxt_mem_req = 1'b0;
          nxt_reg_push_flag = 9'b0;
        end
      end
    end
    
    else if (current_exe_state == EXE_PUSH8) 
    begin
      if (mem_rdy == 1'b0)
      begin
        next_exe_state = EXE_PUSH8;
      end
      else
      begin
          next_exe_state =  EXE_PUSH9;
          nxt_mem_wr_data = 32'b0;
          nxt_mem_wr = 1'b0;
          nxt_mem_req = 1'b0;
          nxt_reg_push_flag = 9'b0;
      end
    end
    
    else if (current_exe_state == EXE_PUSH9) //wait for the end of data phase.
    begin
      if (mem_rdy == 1'b0)
      begin
        next_exe_state = EXE_PUSH9;
      end
      else
      begin
        next_exe_state =  EXE_STP0;
        nxt_exception_entry = 1'b0; //exception entry done.  
          
        if(exception_entry)
        begin
          nxt_branch_addr = {mem_rd_data[31:1], 1'b0}; //get Handler entry address.
          nxt_branch_valid = 1'b1;            
          nxt_EPSR_T = mem_rd_data[0];  //set Tbit here
        end      
        
        if (!exception_entry)//update base address.
        begin
        case (opand3_kpt[3:0])
            4'b0000: nxt_R0 = alu_result_kpt;
            4'b0001: nxt_R1 = alu_result_kpt;
            4'b0010: nxt_R2 = alu_result_kpt;
            4'b0011: nxt_R3 = alu_result_kpt;
            4'b0100: nxt_R4 = alu_result_kpt;
            4'b0101: nxt_R5 = alu_result_kpt;
            4'b0110: nxt_R6 = alu_result_kpt;
            4'b0111: nxt_R7 = alu_result_kpt; 
            4'b1101: begin
                       if (act_SP) nxt_PSP = alu_result_kpt; 
                       else nxt_MSP = alu_result_kpt;
                     end
            default: ; //nothing to do.
        endcase  
        end   
      end
    end
    

    else if (current_exe_state == EXE_POP0)  //control phase
    begin
      if (mem_rdy == 1'b0)//Wait until control phase is finished.
        next_exe_state = EXE_POP0;
      else //generate control signals for next memory access
      begin
      nxt_reg_num = 4'h0;
      if (reg_pop_flag[1])
        begin
          next_exe_state = EXE_POP1;
          nxt_mem_addr = mem_addr + 4;
        end
      else if (reg_pop_flag[2])
        begin
          next_exe_state = EXE_POP2;
          nxt_mem_addr = mem_addr + 4;
        end
      else if (reg_pop_flag[3])
        begin
          next_exe_state = EXE_POP3;
          nxt_mem_addr = mem_addr + 4;
        end
      else if (reg_pop_flag[4])
        begin
          next_exe_state = EXE_POP4;
          nxt_mem_addr = mem_addr + 4;
        end
      else if (reg_pop_flag[5])
        begin
          next_exe_state = EXE_POP5;
          nxt_mem_addr = mem_addr + 4;
        end
      else if (reg_pop_flag[6])
        begin
          next_exe_state = EXE_POP6;
          nxt_mem_addr = mem_addr + 4;
        end
      else if (reg_pop_flag[7])
        begin
          next_exe_state = EXE_POP7;
          nxt_mem_addr = mem_addr + 4;
        end
      else if (reg_pop_flag[8])
        begin
          next_exe_state = EXE_POP8;
          nxt_mem_addr = mem_addr + 4;
        end
      else//pop is done.
        begin
          next_exe_state =  EXE_POP9;
          nxt_mem_req = 1'b0;
          nxt_reg_pop_flag = 9'b0;
        end
      end
    end
        
    else if (current_exe_state == EXE_POP1)
    begin
      if (mem_rdy == 1'b0)//Wait until the read operation is finished.
        next_exe_state = EXE_POP1;
      else //If the first register is popped, assign the value and find out the next one.
      begin
      case (reg_num)
          4'h0: nxt_R0 = mem_rd_data;
          default: ; 
      endcase
      nxt_reg_num  = 4'h1;
      if (reg_pop_flag[2])
        begin
          next_exe_state = EXE_POP2;
          nxt_mem_addr = mem_addr + 4;
        end
      else if (reg_pop_flag[3])
        begin
          next_exe_state = EXE_POP3;
          nxt_mem_addr = mem_addr + 4;
        end
      else if (reg_pop_flag[4])
        begin
          next_exe_state = EXE_POP4;
          nxt_mem_addr = mem_addr + 4;
        end
      else if (reg_pop_flag[5])
        begin
          next_exe_state = EXE_POP5;
          nxt_mem_addr = mem_addr + 4;
        end
      else if (reg_pop_flag[6])
        begin
          next_exe_state = EXE_POP6;
          nxt_mem_addr = mem_addr + 4;
        end
      else if (reg_pop_flag[7])
        begin
          next_exe_state = EXE_POP7;
          nxt_mem_addr = mem_addr + 4;
        end
      else if (reg_pop_flag[8])
        begin
          next_exe_state = EXE_POP8;
          nxt_mem_addr = mem_addr + 4;
        end
      else//pop is done.
        begin
          next_exe_state =  EXE_POP9;
          nxt_mem_req = 1'b0;
          nxt_reg_pop_flag = 9'b0;
        end
      end
    end
        
    else if (current_exe_state == EXE_POP2)
    begin
      if (mem_rdy == 1'b0)//Wait until the read operation is finished.
        next_exe_state = EXE_POP2;
      else //If the first register is popped, assign the value and find out the next one.
      begin
      nxt_reg_num  = 4'h2;
      case (reg_num)
          4'h0: nxt_R0 = mem_rd_data;
          4'h1: nxt_R1 = mem_rd_data;
          default: ; 
      endcase
      if (reg_pop_flag[3])
        begin
          next_exe_state = EXE_POP3;
          nxt_mem_addr = mem_addr + 4;
        end
      else if (reg_pop_flag[4])
        begin
          next_exe_state = EXE_POP4;
          nxt_mem_addr = mem_addr + 4;
        end
      else if (reg_pop_flag[5])
        begin
          next_exe_state = EXE_POP5;
          nxt_mem_addr = mem_addr + 4;
        end
      else if (reg_pop_flag[6])
        begin
          next_exe_state = EXE_POP6;
          nxt_mem_addr = mem_addr + 4;
        end
      else if (reg_pop_flag[7])
        begin
          next_exe_state = EXE_POP7;
          nxt_mem_addr = mem_addr + 4;
        end
      else if (reg_pop_flag[8])
        begin
          next_exe_state = EXE_POP8;
          nxt_mem_addr = mem_addr + 4;
        end
      else//pop is done.
        begin
          next_exe_state =  EXE_POP9;
          nxt_mem_req = 1'b0;
          nxt_reg_pop_flag = 9'b0;
        end
      end
    end
        
    else if (current_exe_state == EXE_POP3)
    begin
      if (mem_rdy == 1'b0)//Wait until the read operation is finished.
        next_exe_state = EXE_POP3;
      else //If the first register is popped, assign the value and find out the next one.
      begin
      nxt_reg_num  = 4'h3;
      case (reg_num)
          4'h0: nxt_R0 = mem_rd_data;
          4'h1: nxt_R1 = mem_rd_data;
          4'h2: nxt_R2 = mem_rd_data;
          default: ; 
      endcase
      if (reg_pop_flag[4])
        begin
          next_exe_state = EXE_POP4;
          nxt_mem_addr = mem_addr + 4;
        end
      else if (reg_pop_flag[5])
        begin
          next_exe_state = EXE_POP5;
          nxt_mem_addr = mem_addr + 4;
        end
      else if (reg_pop_flag[6])
        begin
          next_exe_state = EXE_POP6;
          nxt_mem_addr = mem_addr + 4;
        end
      else if (reg_pop_flag[7])
        begin
          next_exe_state = EXE_POP7;
          nxt_mem_addr = mem_addr + 4;
        end
      else if (reg_pop_flag[8])
        begin
          next_exe_state = EXE_POP8;
          nxt_mem_addr = mem_addr + 4;
        end
      else//pop is done.
        begin
          next_exe_state =  EXE_POP9;
          nxt_mem_req = 1'b0;
          nxt_reg_pop_flag = 9'b0;
        end
      end
    end
        
    else if (current_exe_state == EXE_POP4)
    begin
      if (mem_rdy == 1'b0)//Wait until the read operation is finished.
        next_exe_state = EXE_POP4;
      else //If the first register is popped, assign the value and find out the next one.
      begin
      nxt_reg_num  = 4'h4;
      case (reg_num)
          4'h0: nxt_R0 = mem_rd_data;
          4'h1: nxt_R1 = mem_rd_data;
          4'h2: nxt_R2 = mem_rd_data;
          4'h3: nxt_R3 = mem_rd_data;
          default: ; 
      endcase
      if (reg_pop_flag[5])
        begin
          next_exe_state = EXE_POP5;
          nxt_mem_addr = mem_addr + 4;
        end
      else if (reg_pop_flag[6])
        begin
          next_exe_state = EXE_POP6;
          nxt_mem_addr = mem_addr + 4;
        end
      else if (reg_pop_flag[7])
        begin
          next_exe_state = EXE_POP7;
          nxt_mem_addr = mem_addr + 4;
        end
      else if (reg_pop_flag[8])
        begin
          next_exe_state = EXE_POP8;
          nxt_mem_addr = mem_addr + 4;
        end
      else//pop is done.
        begin
          next_exe_state =  EXE_POP9;
          nxt_mem_req = 1'b0;
          nxt_reg_pop_flag = 9'b0;
        end
      end
    end
        
    else if (current_exe_state == EXE_POP5)
    begin
      if (mem_rdy == 1'b0)//Wait until the read operation is finished.
        next_exe_state = EXE_POP5;
      else //If the first register is popped, assign the value and find out the next one.
      begin
      nxt_reg_num  = 4'h5;
      if (exception_return) 
        nxt_R12 = mem_rd_data;
      else
        case (reg_num)
            4'h0: nxt_R0 = mem_rd_data;
            4'h1: nxt_R1 = mem_rd_data;
            4'h2: nxt_R2 = mem_rd_data;
            4'h3: nxt_R3 = mem_rd_data;
            4'h4: nxt_R4 = mem_rd_data;
            default: ; 
        endcase
      if (reg_pop_flag[6])
        begin
          next_exe_state = EXE_POP6;
          nxt_mem_addr = mem_addr + 4;
        end
      else if (reg_pop_flag[7])
        begin
          next_exe_state = EXE_POP7;
          nxt_mem_addr = mem_addr + 4;
        end
      else if (reg_pop_flag[8])
        begin
          next_exe_state = EXE_POP8;
          nxt_mem_addr = mem_addr + 4;
        end
      else//pop is done.
        begin
          next_exe_state =  EXE_POP9;
          nxt_mem_req = 1'b0;
          nxt_reg_pop_flag = 9'b0;
        end
      end
    end
        
    else if (current_exe_state == EXE_POP6)
    begin
      if (mem_rdy == 1'b0)//Wait until the read operation is finished.
        next_exe_state = EXE_POP6;
      else //If the first register is popped, assign the value and find out the next one.
      begin
      nxt_reg_num  = 4'h6;
      case (reg_num)
          4'h0: nxt_R0 = mem_rd_data;
          4'h1: nxt_R1 = mem_rd_data;
          4'h2: nxt_R2 = mem_rd_data;
          4'h3: nxt_R3 = mem_rd_data;
          4'h4: nxt_R4 = mem_rd_data;
          4'h5: nxt_R5 = mem_rd_data;
          default: ; 
      endcase
      if (reg_pop_flag[7])
        begin
          next_exe_state = EXE_POP7;
          nxt_mem_addr = mem_addr + 4;
        end
      else if (reg_pop_flag[8])
        begin
          next_exe_state = EXE_POP8;
          nxt_mem_addr = mem_addr + 4;
        end
      else//pop is done.
        begin
          next_exe_state =  EXE_POP9;
          nxt_mem_req = 1'b0;
          nxt_reg_pop_flag = 9'b0;
        end
      end
    end
        
    else if (current_exe_state == EXE_POP7)
    begin
      if (mem_rdy == 1'b0)//Wait until the read operation is finished.
        next_exe_state = EXE_POP7;
      else //If the first register is popped, assign the value and find out the next one.
      begin
      nxt_reg_num  = 4'h7;
      if (exception_return) 
        nxt_LR = mem_rd_data;
      else
        case (reg_num)
          4'h0: nxt_R0 = mem_rd_data;
          4'h1: nxt_R1 = mem_rd_data;
          4'h2: nxt_R2 = mem_rd_data;
          4'h3: nxt_R3 = mem_rd_data;
          4'h4: nxt_R4 = mem_rd_data;
          4'h5: nxt_R5 = mem_rd_data;
          4'h6: nxt_R6 = mem_rd_data;
          default: ; 
        endcase
      if (reg_pop_flag[8])
        begin
          next_exe_state = EXE_POP8;
          nxt_mem_addr = mem_addr + 4;
        end
      else//pop is done.
        begin
          next_exe_state =  EXE_POP9;
          nxt_mem_req = 1'b0;
          nxt_reg_pop_flag = 9'b0;
        end
      end
    end
        
    else if (current_exe_state == EXE_POP8)
    begin
      if (mem_rdy == 1'b0)//Wait until the read operation is finished.
        next_exe_state = EXE_POP8;
      else //The last one is updated, end of pop operation.
      begin
      nxt_reg_num  = 4'h8;
      if (exception_return) 
        nxt_branch_addr = {mem_rd_data[31:1],1'b0}; //branch_valid will be asserted after POP done.
      else
        case (reg_num)
            4'h0: nxt_R0 = mem_rd_data;
            4'h1: nxt_R1 = mem_rd_data;
            4'h2: nxt_R2 = mem_rd_data;
            4'h3: nxt_R3 = mem_rd_data;
            4'h4: nxt_R4 = mem_rd_data;
            4'h5: nxt_R5 = mem_rd_data;
            4'h6: nxt_R6 = mem_rd_data;
            4'h7: nxt_R7 = mem_rd_data;
            default: ; 
        endcase
      next_exe_state =  EXE_POP9;//end of pop operation
      nxt_mem_req = 1'b0;
      nxt_reg_pop_flag = 9'b0;
      end
    end
    
    else if (current_exe_state == EXE_POP9)
    begin
      if (mem_rdy == 1'b0)//Wait until the read operation is finished.
        next_exe_state = EXE_POP9;
      else //The last one is updated, end of pop operation.
      begin
        next_exe_state =  EXE_STP0;//end of pop operation
        if (exception_return) //last pop of exception return.
        begin
          nxt_exception_return = 1'b0;
          nxt_exc_return = 4'b0;
          nxt_branch_valid = 1'b1;//Branch_addr was generated in previous cycle.   
          case (exc_return)
          4'b0001,
          4'b1001: 
            begin
              tmp_nxt_MSP = (MSP + 32'h0000_0020);
              tmp_psr9 = mem_rd_data[9] | tmp_nxt_MSP[2];
              nxt_MSP = {tmp_nxt_MSP[31:3], tmp_psr9, tmp_nxt_MSP[1:0]};
            end
          4'b1101: 
            begin
              tmp_nxt_PSP = (PSP + 32'h0000_0020);
              tmp_psr9 = mem_rd_data[9] | tmp_nxt_PSP[2];
              nxt_PSP = {tmp_nxt_PSP[31:3], tmp_psr9, tmp_nxt_PSP[1:0]};
            end
          default: ;
          endcase                           
          {nxt_N_flag, nxt_Z_flag, nxt_C_flag, nxt_V_flag} = mem_rd_data[31:28];  //this cycle is xPSR.
          nxt_IPSR8_0 = mem_rd_data[8:0];
          nxt_nested_pri_num = mem_rd_data[12:10];
          nxt_EPSR_T = mem_rd_data[24];   
        end        
        else  //a normal Rx pop or an exception return start or a normal branch.
        begin       
        //store base address at last stage.
           case (opand3_kpt)//synopsys parallel_case
               5'b00000: nxt_R0 = alu_result_kpt;
               5'b00001: nxt_R1 = alu_result_kpt;
               5'b00010: nxt_R2 = alu_result_kpt;
               5'b00011: nxt_R3 = alu_result_kpt;
               5'b00100: nxt_R4 = alu_result_kpt;
               5'b00101: nxt_R5 = alu_result_kpt;
               5'b00110: nxt_R6 = alu_result_kpt;
               5'b00111: nxt_R7 = alu_result_kpt; 
               5'b01101: begin
                          if (act_SP) nxt_PSP = alu_result_kpt; 
                          else nxt_MSP = alu_result_kpt;
                        end
               default: ; //nothing to do.
           endcase      
           case (reg_num)
             4'h0: nxt_R0 = mem_rd_data;
             4'h1: nxt_R1 = mem_rd_data;
             4'h2: nxt_R2 = mem_rd_data;
             4'h3: nxt_R3 = mem_rd_data;
             4'h4: nxt_R4 = mem_rd_data;
             4'h5: nxt_R5 = mem_rd_data;
             4'h6: nxt_R6 = mem_rd_data;
             4'h7: nxt_R7 = mem_rd_data;
             4'h8:begin //an exception return start or a normal branch.
                    if ((mem_rd_data[31:28] == 4'b1111) && (inst_mode == HANDLER_MODE)) 
                    begin                      	
                        if (exception_req_num[8:6] < nested_pri_num) //tail_chaining.
                        begin //ExceptionTaken
                           nxt_tail_chaining = 1'b1;
                           next_exe_state = EXE_MRD1; //Need read back the handler address from vector table.
                           nxt_mem_addr = {24'b0, exception_req_vector};
                           nxt_mem_byte_en  = 2'b10;
                           nxt_mem_wr   = 1'b0; //Read
                           nxt_mem_req  = 1'b1;  
                           
                           nxt_exception_ack = 1'b1;  
                           nxt_inst_mode = HANDLER_MODE;
                           nxt_IPSR8_0 = exception_req_num;
                           nxt_LR = {28'hf000000, mem_rd_data[3:0]}; //keep the EXC_RETURN value.
                           nxt_act_SP = 1'b0;                    
                        end
                        else //normal exception return.
                        begin
                           next_exe_state =  EXE_POP0;
                           nxt_exception_return = 1'b1;
                           nxt_exc_return = mem_rd_data[3:0]; 
                           nxt_reg_pop_flag = 9'b110111111; //PSR,PC,0,LR,R12,R3,R2,R1,R0;
                           nxt_reg_num = 4'hf;
                           nxt_mem_byte_en  = 2'b10; //word access
                           nxt_mem_wr   = 1'b0;
                           nxt_mem_req  = 1'b1;       
                           case (mem_rd_data[3:0])
                             4'b0001 :
                               begin
                                   nxt_mem_addr  = (opand3_kpt == 5'b01101) ? alu_result_kpt:MSP;
                                   nxt_inst_mode = HANDLER_MODE;
                                   nxt_act_SP    = 1'b0;
                               end
                             4'b1001 :
                               begin
                                   nxt_mem_addr  = (opand3_kpt == 5'b01101) ? alu_result_kpt:MSP;
                                   nxt_inst_mode = THREAD_MODE;
                                   nxt_act_SP    = 1'b0;
                               end
                             4'b1101 :
                               begin
                                   nxt_mem_addr  = (opand3_kpt == 5'b01101) ? alu_result_kpt:PSP;
                                   nxt_inst_mode = THREAD_MODE;
                                   nxt_act_SP    = 1'b1;
                               end
                             default : 
                               begin
                                   nxt_exception_return = 1'b0;
                                   nxt_exc_return = 4'b0;
                                   nxt_reg_pop_flag = 9'b0;
                                   nxt_mem_req = 1'b0;
                                   nxt_ie_hardfault = 1'b1;
                                   next_exe_state = EXE_STP0;
                               end
                           endcase
                           if (nxt_mem_addr[1:0] != 2'b00)
                           begin
                               nxt_exception_return = 1'b0;
                               nxt_exc_return = 4'b0;
                               nxt_reg_pop_flag = 9'b0;
                               nxt_mem_req = 1'b0;
                               nxt_ie_hardfault = 1'b1;
                               next_exe_state = EXE_STP0;
                           end 
                        end                            
                    end
                    else if ((mem_rd_data[31:28] == 4'b1111) && (inst_mode == THREAD_MODE)) //Unexpected exception return
                    begin
                        next_exe_state =  EXE_STP0;
                        nxt_ie_hardfault = 1'b1;  //exception   
                    end
                    else //Normal branch
                    begin
                        nxt_ie_hardfault = mem_rd_data[0] ? 1'b0:1'b1;  //Fault  
                        if (mem_rd_data[0])
                        begin
                           nxt_branch_addr = {mem_rd_data[31:1],1'b0};
                           nxt_branch_valid = 1'b1;
                           nxt_EPSR_T = mem_rd_data[0];
                        end                     
                    end
                  end    
             default: ; 
           endcase
        end
      end
    end   
    
    else  //any other state, force to initial state. ????
    begin
        next_exe_state =  EXE_STP0;
        nxt_mem_req = 1'b0;
    end
    
end  //end of execute FSM.



always@ (posedge clk or negedge rst_n)
begin
  if (!rst_n)
    current_exe_state <= EXE_STP0;
 else 
    current_exe_state <= next_exe_state;
end




//--------------------------------------//
//Pipeline output in execute stage
//--------------------------------------//

//registers
always@ (posedge clk or negedge rst_n)
begin
  if (!rst_n)
  begin
    R0           <= 32'h0;
    R1           <= 32'h0;
    R2           <= 32'h0;
    R3           <= 32'h0;
    R4           <= 32'h0;
    R5           <= 32'h0;
    R6           <= 32'h0;
    R7           <= 32'h0;
    R8           <= 32'h0;
    R9           <= 32'h0;
    R10          <= 32'h0;
    R11          <= 32'h0;
    R12          <= 32'h0;
    PSP          <= 32'h0;   
    act_SP       <= 1'b0;  //default MSP.
    LR           <= 32'h00000084; //for test
    PRIMASK_flag <= 1'b0;
    N_flag       <= 1'b0;
    Z_flag       <= 1'b0;
    C_flag       <= 1'b0;
    V_flag       <= 1'b0;
    IPSR8_0      <= 9'b111_000_000;
  end
  else if (reg_acc_req && reg_wnr)
  begin
      case (reg_sel)
          5'h0:  R0  <= reg_to_cpu;
          5'h1:  R1  <= reg_to_cpu;
          5'h2:  R2  <= reg_to_cpu;
          5'h3:  R3  <= reg_to_cpu;
          5'h4:  R4  <= reg_to_cpu;
          5'h5:  R5  <= reg_to_cpu;
          5'h6:  R6  <= reg_to_cpu;
          5'h7:  R7  <= reg_to_cpu;
          5'h8:  R8  <= reg_to_cpu;
          5'h9:  R9  <= reg_to_cpu;
          5'ha:  R10 <= reg_to_cpu;
          5'hb:  R11 <= reg_to_cpu;
          5'hc:  R12 <= reg_to_cpu;
          5'hd:  begin 
          	    if (act_SP) PSP <= reg_to_cpu; 
          	 end
          5'he:  LR <= reg_to_cpu;
          5'h10: begin
          	   {N_flag, Z_flag, C_flag, V_flag, IPSR8_0[5:0]} <= {reg_to_cpu[31:28], reg_to_cpu[5:0]};
          	 end 
          5'h12: PSP <= reg_to_cpu;
          5'h14: begin 
          	    act_SP <= reg_to_cpu[25]; 
          	    PRIMASK_flag <= reg_to_cpu[0]; 
          	 end
          default: ; 
      endcase
  end
  else
  begin
    R0           <= nxt_R0          ;
    R1           <= nxt_R1          ;
    R2           <= nxt_R2          ;
    R3           <= nxt_R3          ;
    R4           <= nxt_R4          ;
    R5           <= nxt_R5          ;
    R6           <= nxt_R6          ;
    R7           <= nxt_R7          ;
    R8           <= nxt_R8          ;
    R9           <= nxt_R9          ;
    R10          <= nxt_R10         ;
    R11          <= nxt_R11         ;
    R12          <= nxt_R12         ;
    PSP          <= nxt_PSP         ;
    act_SP       <= nxt_act_SP      ;
    LR           <= nxt_LR          ;
    PRIMASK_flag <= nxt_PRIMASK_flag;
    N_flag       <= nxt_N_flag      ;
    Z_flag       <= nxt_Z_flag      ;
    C_flag       <= nxt_C_flag      ;
    V_flag       <= nxt_V_flag      ;
    IPSR8_0      <= nxt_IPSR8_0     ;
  end
end


//branch address
always@ (posedge clk or negedge rst_n)
begin
  if (!rst_n)
  begin
    branch_addr  <= 32'h00;
  end
  else if (reg_acc_req && reg_wnr && (reg_sel == 5'h0f))
  begin
      branch_addr  <= {reg_to_cpu[31:1], 1'b0}; 
  end
  else
  begin
      branch_addr  <= nxt_branch_addr; 
  end
end

//Branch_valid
always@ (posedge clk or negedge rst_n)
begin
  if (!rst_n)
  begin
    branch_valid <= 1'b0;
  end
  else 
  begin
      branch_valid <= (reg_acc_req && reg_wnr && (reg_sel == 5'h0f)) |
	                  nxt_branch_valid; 
  end
end


//MSP register
always@ (posedge clk or negedge rst_n)
begin
  if (!rst_n)
  begin
    MSP          <= 32'h2000_03fc;  
  end
  else if (MSP_rst_flg)
  begin    
      MSP          <= MSP_rst_val; 
  end
  else if (reg_acc_req && reg_wnr && ((reg_sel == 5'hd) && (~act_SP) || (reg_sel == 5'h11)))
  begin
      MSP          <= reg_to_cpu; 
  end
  else 
  begin    
      MSP          <= nxt_MSP; 
  end
end

//EPSR_T register
always@ (posedge clk or negedge rst_n)
begin
  if (!rst_n)
  begin
    EPSR_T       <= 1'b1;
  end
  else if (EPSR_T_rst_flg)
  begin    
      EPSR_T       <= EPSR_T_rst_val;  
  end
  else if (reg_acc_req && reg_wnr && (reg_sel == 5'h0))
  begin
      EPSR_T       <= reg_to_cpu[24]; 
  end
  else 
  begin    
      EPSR_T       <= nxt_EPSR_T;  
  end
end

//PC for executed instruction
always@ (posedge clk or negedge rst_n)
begin
  if (!rst_n)
  begin
      ie_pc <= 32'b0;
  end
  else if (!ie_bsy)
  begin
      ie_pc <= id_pc;
  end
end

//PC should be equal to addr of executing INST + 4.
//Here the PC is only used by Debug module.
assign PC = ie_pc + 4; 

//PC cancelled.
always@ (posedge clk or negedge rst_n)
begin
  if (!rst_n)
  begin
      canceled_pc <= 32'b0;
  end
  else if (exe_cancel)
  begin
      canceled_pc <= ie_bsy ? ie_pc : id_pc;
  end
end


//misc signals.
always@ (posedge clk or negedge rst_n)
begin
  if (!rst_n)
  begin
    mem_addr     <= 32'h0;
    mem_wr       <= 1'h0;
    mem_wr_data  <= 32'b0;
    mem_byte_en  <= 2'h0;
    mem_req      <= 1'h0;
    ie_hardfault <= 1'h0;
    reg_num      <= 4'h0;
        
    reg_pop_flag     <= 8'b0;
    reg_push_flag    <= 8'b0;
    exception_entry  <= 1'b0;
    exception_return <= 1'b0;
    inst_mode        <= THREAD_MODE;
    exc_return       <= 4'b0;
    exception_ack    <= 1'b0;
    Rx_for_MR        <= 5'b0;
    
    opand3_kpt     <= 5'b0;
    alu_result_kpt <= 32'b0;
    tail_chaining  <= 1'b0;
    
    frameptralign        <= 1'b0;
    nested_pri_num       <= 3'b111; 
    
    pre_rdata_conv       <= 3'b010;
    rdata_conv           <= 3'b010;
    
  end
  else 
  begin
      mem_addr     <= nxt_mem_addr;      
      mem_wr       <= nxt_mem_wr;   
      mem_wr_data  <= nxt_mem_wr_data;     
      mem_byte_en  <= nxt_mem_byte_en;       
      mem_req      <= nxt_mem_req;       
      ie_hardfault <= nxt_ie_hardfault;  
      reg_num      <= nxt_reg_num; 
      
      reg_pop_flag     <= nxt_reg_pop_flag;
      reg_push_flag    <= nxt_reg_push_flag;
      exception_entry  <= nxt_exception_entry;
      exception_return <= nxt_exception_return;
      inst_mode        <= nxt_inst_mode;
      exc_return       <= nxt_exc_return;
      exception_ack    <= nxt_exception_ack;
      Rx_for_MR        <= nxt_Rx_for_MR;
      
      opand3_kpt      <= nxt_opand3_kpt;
      alu_result_kpt  <= nxt_alu_result_kpt;
      tail_chaining   <= nxt_tail_chaining;
      
      frameptralign        <= nxt_frameptralign;
      nested_pri_num       <= nxt_nested_pri_num; 
      
      pre_rdata_conv       <= nxt_pre_rdata_conv;
      rdata_conv           <= nxt_rdata_conv;
  end
end



//Other registers.
assign APSR = {N_flag, Z_flag, C_flag, V_flag, 28'b0};
assign IPSR = {23'b0,IPSR8_0};  
assign EPSR = {7'b0, EPSR_T, 24'b0};
assign xPSR = {N_flag, Z_flag, C_flag, V_flag, 3'b0, EPSR_T, 15'b0, IPSR8_0};
assign PRIMASK = {31'b0, PRIMASK_flag};
assign CONTROL = {30'b0, act_SP, 1'b0};  
assign SP = (act_SP) ? PSP : MSP;

assign exception_ack_num = IPSR8_0;


//debugger read
reg reg_rdy;
always@ (posedge clk or negedge rst_n)
begin
  if (!rst_n)
  begin
    reg_rdy <= 1'b0;
  end
  else
  begin
      reg_rdy  <= reg_acc_req; 
  end
end


reg [31:0] debug_return_address;
always@ (posedge clk or negedge rst_n)
begin
  if (!rst_n)
  begin
    debug_return_address <= 32'b0;
  end
  else if (ie_stop_req && branch_valid )
  begin
      debug_return_address  <= branch_addr; 
  end
  else
  begin
      debug_return_address  <= id_pc; 
  end
  
end

always@ (posedge clk or negedge rst_n)
begin
  if (!rst_n)
  begin
    reg_from_cpu <= 32'b0;
  end
  else if (reg_acc_req && (!reg_wnr))
  begin
      case (reg_sel)
          5'h0:  reg_from_cpu <= R0 ;
          5'h1:  reg_from_cpu <= R1 ;
          5'h2:  reg_from_cpu <= R2 ;
          5'h3:  reg_from_cpu <= R3 ;
          5'h4:  reg_from_cpu <= R4 ;
          5'h5:  reg_from_cpu <= R5 ;
          5'h6:  reg_from_cpu <= R6 ;
          5'h7:  reg_from_cpu <= R7 ;
          5'h8:  reg_from_cpu <= R8 ;
          5'h9:  reg_from_cpu <= R9 ;
          5'ha:  reg_from_cpu <= R10;
          5'hb:  reg_from_cpu <= R11;
          5'hc:  reg_from_cpu <= R12;
          5'hd:  reg_from_cpu <= SP ;
          5'he:  reg_from_cpu <= LR ;
          5'hf:  reg_from_cpu <= debug_return_address; 
          5'h10: reg_from_cpu <= xPSR;
          5'h11: reg_from_cpu <= MSP;
          5'h12: reg_from_cpu <= PSP;
          5'h14: reg_from_cpu <= {6'b0, act_SP, 1'b0, 23'b0, PRIMASK_flag}; 
          default: reg_from_cpu <= 32'b0;
      endcase
  end
end





//========================
// IE stage status
//========================
//normal busy need IF, ID to hold, but tail_chaining need IF, ID to NOP.
assign ie_bsy =  ie_stop_req | (current_exe_state != EXE_STP0);

always @(posedge clk or negedge rst_n)
begin
  if(!rst_n) 
  begin 
     core_halted   <= 1'b0;
  end
  else 
  begin
     core_halted   <= ie_stop_req & (current_exe_state == EXE_STP0);
  end
end   

endmodule  //end of inst_exe module.

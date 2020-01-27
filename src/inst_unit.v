
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
// File        : inst_unit.v
// Author      : PODES
// Date        : 20200101
// Version     : 1.0
// Description : IU module of PODES_M0O
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

module inst_unit (
             clk,
             rst_n,
             
             //inst unit status
             reset_trap   ,
             hardfault_req,
             svcall_req,
             
             //instruction access I/F
             inst_addr   ,
             inst_req    ,
             inst_rd_data,
             inst_rdy    ,
             
             //memory access I/F
             mem_req     ,
             mem_addr    ,
             mem_rdy     ,
             mem_rd_data ,
             mem_wr_data , 
             mem_wr      ,
             mem_byte_en ,
             
             //exception information
             exception_req       ,
             exception_req_vector, 
             exception_req_num   , 
             exception_ack       , 
             exception_ack_num   ,
                          
             //Register access I/F for Debugger 
             reg_acc_req,
             reg_sel,
             reg_wnr,
             reg_rdy,
             reg_to_cpu,
             reg_from_cpu,     
             
             //debug information
             c_debugen,       
             c_maskints,
			 ie_stop_req,
			 exe_cancel,
             core_reset,
             core_lockup,
             core_sleep,
             core_halted,
             core_hardfault,
             core_id_pc,
             core_bkpt_inst    
             );

             
//-----------------------------------------------------------//
//                      INPUTS/OUTPUTS                       //
//-----------------------------------------------------------//
input             clk;
input             rst_n;

output            reset_trap;
output            hardfault_req; 
output            svcall_req;
output [31:0]     inst_addr;
output            inst_req;
input  [31:0]     inst_rd_data;
input             inst_rdy;

output             mem_req;
output [31:0]      mem_addr;
input              mem_rdy;
input  [31:0]      mem_rd_data;
output [31:0]      mem_wr_data; 
output             mem_wr;
output [1:0]       mem_byte_en;   

input              exception_req;
input [7:0]        exception_req_vector ;
input [8 :0]       exception_req_num;
output             exception_ack;
output[8 :0]       exception_ack_num;
          
input              reg_acc_req;
input [4:0]        reg_sel;
input              reg_wnr;
output             reg_rdy;
input  [31:0]      reg_to_cpu;
output [31:0]      reg_from_cpu;

input              c_debugen;     
input              c_maskints;
input              ie_stop_req;
output             exe_cancel;
output             core_reset;
output             core_lockup;
output             core_sleep;
output             core_halted; 
output             core_hardfault; 
output [31:0]      core_id_pc; 
output             core_bkpt_inst;    

//-----------------------------------------------------------//
//                    REGISTERS & WIRES                      //
//-----------------------------------------------------------//

wire [31:0]     branch_addr;
wire            branch_valid;
wire            fetch_hold;
wire            fetch_nop;
wire            inst_keep;
wire            inst_latch;
wire [31:0]     PC;
wire [15:0]     inst;
wire            if_bsy;

wire            reset_trap;
wire            hardfault_req;
wire            svcall_req;

wire          dec_hold;
wire [31:0]   new_opand1;
wire [31:0]   new_opand2;
wire [31:0]   xPSR;
wire [15:0]   tmp_opand1;
wire [15:0]   tmp_opand2;
wire [4:0]    optype;
wire [31:0]   opand1;
wire [31:0]   opand2;
wire [4:0]    opand3;
wire [15:0]   opand4;
wire          carry_in;
wire [1:0]    nzcv;
wire          sign_ext;   
wire [1:0]    byte_en;
wire          dsb_inst;
wire          dmb_inst;
wire          isb_inst;                
wire          bkpt_inst;             
wire          yield_inst;
wire          wfe_inst;
wire          wfi_inst;
wire          sev_inst;
wire          svcall;


wire [31:0]   R0 ;
wire [31:0]   R1 ;
wire [31:0]   R2 ;
wire [31:0]   R3 ;
wire [31:0]   R4 ;
wire [31:0]   R5 ;
wire [31:0]   R6 ;
wire [31:0]   R7 ;
wire [31:0]   R8 ;
wire [31:0]   R9 ;
wire [31:0]   R10;
wire [31:0]   R11;
wire [31:0]   R12;
wire [31:0]   SP ;
wire [31:0]   LR ;
   
wire [31:0]   PRIMASK;
wire [31:0]   CONTROL;

wire          ie_hardfault;

wire          startup;
wire [31:0]   MSP_rst_val;
wire          MSP_rst_flg;
wire          EPSR_T_rst_val;
wire          EPSR_T_rst_flg;
wire [31:0]   if_pc;
wire [31:0]   id_pc;
wire [31:0]   ie_pc;
wire [31:0]   pc_used_for_dec_opand;

wire          dec_expt_insert;

wire          exe_cancel           ;
wire [7 :0]   exception_req_vector ;
wire [8 :0]   exception_req_num    ;
wire          exception_ack        ;
wire [8 :0]   exception_ack_num    ;
wire          exception_entry      ;
wire          exception_return     ;
wire          tail_chaining        ;


wire         dec_nop        ;
wire         id_bsy         ;
wire         id_is_idle     ;
wire         id_thumb2      ;
wire         id_branch_op   ;
wire         id_data_depend ;
wire         id_hardfault   ;

wire         ie_bsy;

//-----------------------------------------------------------//
//                          PARAMETERS                       //
//-----------------------------------------------------------//
//parameter INV_0  = 1'b0;


//-----------------------------------------------------------//
//                          ARCHITECTURE                     //
//-----------------------------------------------------------//

inst_fetch inst_fetch_u0 (
             .clk               (clk               ),
             .rst_n             (rst_n             ),
                                                  
             .lockup            (core_lockup       ),
             .branch_addr       (branch_addr       ),
             .branch_valid      (branch_valid      ),
             .fetch_hold        (fetch_hold        ),
             .fetch_nop         (fetch_nop         ),
             .inst_keep         (inst_keep         ),
             .inst_latch        (inst_latch        ),
                                                  
             .inst              (inst              ),
             .if_bsy            (if_bsy            ),
             .if_pc             (if_pc             ),
             .startup           (startup           ),
             .reset_trap        (reset_trap        ),
             .MSP_rst_val       (MSP_rst_val       ),
             .MSP_rst_flg       (MSP_rst_flg       ),
             .EPSR_T_rst_val    (EPSR_T_rst_val    ),
             .EPSR_T_rst_flg    (EPSR_T_rst_flg    ),
                        
             .inst_addr         (inst_addr         ),
             .inst_req          (inst_req          ),
             .inst_rd_data      (inst_rd_data      ),
             .inst_rdy          (inst_rdy          )
             );
         
                                     

inst_dec inst_dec_u0 (
                .rst_n           (rst_n          ),
                .clk             (clk            ),
                .inst            (inst           ),
                .if_pc           (if_pc          ),
                .fetch_nop       (fetch_nop      ),
                
                .dec_hold        (dec_hold       ),
                .dec_expt_insert (dec_expt_insert),
                .dec_nop         (dec_nop        ),
                .id_bsy          (id_bsy         ),
                .id_is_idle      (id_is_idle     ),
                .id_thumb2       (id_thumb2      ),
                .id_branch_op    (id_branch_op   ),
                .id_data_depend  (id_data_depend ),
                .id_hardfault    (id_hardfault   ),
                
                .id_pc           (id_pc          ),
                .optype          (optype         ),
                .opand1          (opand1         ),
                .opand2          (opand2         ),
                .opand3          (opand3         ),
                .opand4          (opand4         ),
                .carry_in        (carry_in       ),
                .nzcv            (nzcv           ),
                .sign_ext        (sign_ext       ),
                .byte_en         (byte_en        ),
                .pc_used_for_dec_opand (pc_used_for_dec_opand),
                
                .new_opand1      (new_opand1     ),
                .new_opand2      (new_opand2     ),            
                .xPSR            (xPSR           ),
                .SP              (SP             ),           
                .tmp_opand1      (tmp_opand1     ),
                .tmp_opand2      (tmp_opand2     ),
                                                 
                .dsb_inst        (dsb_inst       ),
                .dmb_inst        (dmb_inst       ),
                .isb_inst        (isb_inst       ),         
                .bkpt_inst       (bkpt_inst      ),        
                .yield_inst      (yield_inst     ),
                .wfe_inst        (wfe_inst       ),
                .wfi_inst        (wfi_inst       ),
                .sev_inst        (sev_inst       ),
                .svcall          (svcall         )
                );


opand_proc opand_proc_u0 (
                .opand_in (tmp_opand1),
                .opand_out(new_opand1),
                .R0       (R0       ),
                .R1       (R1       ),
                .R2       (R2       ),
                .R3       (R3       ),
                .R4       (R4       ),
                .R5       (R5       ),
                .R6       (R6       ),
                .R7       (R7       ),
                .R8       (R8       ),
                .R9       (R9       ),
                .R10      (R10      ),
                .R11      (R11      ),
                .R12      (R12      ),
                .SP       (SP       ),
                .LR       (LR       ),
                .PC       (pc_used_for_dec_opand )
                );

opand_proc opand_proc_u1 (
                .opand_in (tmp_opand2),
                .opand_out(new_opand2),
                .R0       (R0       ),
                .R1       (R1       ),
                .R2       (R2       ),
                .R3       (R3       ),
                .R4       (R4       ),
                .R5       (R5       ),
                .R6       (R6       ),
                .R7       (R7       ),
                .R8       (R8       ),
                .R9       (R9       ),
                .R10      (R10      ),
                .R11      (R11      ),
                .R12      (R12      ),
                .SP       (SP       ),
                .LR       (LR       ),
                .PC       (pc_used_for_dec_opand )                
                );

inst_exe inst_exe_u0 (
                .rst_n        (rst_n        ),
                .clk          (clk          ),                
                 
                .id_pc        (id_pc        ),                
                .id_hardfault (id_hardfault ),
                .optype       (optype       ),   
                .opand1       (opand1       ),
                .opand2       (opand2       ),
                .opand3       (opand3       ),
                .opand4       (opand4       ),
                .carry_in     (carry_in     ),
                .nzcv         (nzcv         ),
                .sign_ext     (sign_ext     ), 
                .byte_en      (byte_en      ),  
          
                .R0           (R0           ),
                .R1           (R1           ),
                .R2           (R2           ),
                .R3           (R3           ),
                .R4           (R4           ),
                .R5           (R5           ),
                .R6           (R6           ),
                .R7           (R7           ),
                .R8           (R8           ),
                .R9           (R9           ),
                .R10          (R10          ),
                .R11          (R11          ),
                .R12          (R12          ),
                .SP           (SP           ),
                .LR           (LR           ),
                .PC           (PC           ),     
                .branch_addr  (branch_addr  ),  
                .branch_valid (branch_valid ),         
                .xPSR         (xPSR         ),         
                .PRIMASK      (PRIMASK      ),         
                .CONTROL      (CONTROL      ),       
            
                .exe_cancel           (exe_cancel          ),
                .exception_req_vector (exception_req_vector),
                .exception_req_num    (exception_req_num   ),
                .exception_ack        (exception_ack       ),
                .exception_ack_num    (exception_ack_num   ),
                .exception_entry      (exception_entry     ),
                .exception_return     (exception_return    ),
                .tail_chaining        (tail_chaining       ),
                             
                .mem_req              (mem_req        ),
                .mem_addr             (mem_addr       ),
                .mem_rdy              (mem_rdy        ),
                .mem_rd_data          (mem_rd_data    ),
                .mem_wr_data          (mem_wr_data    ), 
                .mem_wr               (mem_wr         ),
                .mem_byte_en          (mem_byte_en    ),
                                                      
                .ie_pc                (ie_pc          ),
                .ie_hardfault         (ie_hardfault   ),
                .ie_bsy               (ie_bsy         ),
                .core_halted          (core_halted    ),
                                      
                .EPSR_T_rst_val       (EPSR_T_rst_val ),
                .EPSR_T_rst_flg       (EPSR_T_rst_flg ),
                .MSP_rst_val          (MSP_rst_val    ),
                .MSP_rst_flg          (MSP_rst_flg    ),
                .reset_trap           (reset_trap     ),
                                      
                .ie_stop_req          (ie_stop_req    ),
                .reg_acc_req          (reg_acc_req    ),
                .reg_sel              (reg_sel        ),
                .reg_wnr              (reg_wnr        ),
                .reg_rdy              (reg_rdy        ),
                .reg_to_cpu           (reg_to_cpu     ),
                .reg_from_cpu         (reg_from_cpu   )                
             );


mfsm mfsm_u0 (
                .rst_n            (rst_n        ),
                .clk              (clk          ),
                //fetch           
                .if_pc            (if_pc        ),
                .startup          (startup      ),
                .reset_trap       (reset_trap   ),
                .if_bsy           (if_bsy       ),
                .fetch_hold       (fetch_hold   ),
                .fetch_nop        (fetch_nop    ),
                .inst_keep        (inst_keep    ),
                .inst_latch       (inst_latch   ),
               //decoder          
                .id_pc            (id_pc        ),
                .dec_hold         (dec_hold     ),
                .dec_nop          (dec_nop      ),
                .id_bsy           (id_bsy       ),
                .id_is_idle       (id_is_idle     ),
                .id_thumb2        (id_thumb2      ),
                .id_branch_op     (id_branch_op   ),                              
                .id_data_depend   (id_data_depend ),
                .id_hardfault     (id_hardfault   ), 
                .dec_expt_insert  (dec_expt_insert),
                
                .dsb_inst         (dsb_inst    ),
                .dmb_inst         (dmb_inst    ),
                .isb_inst         (isb_inst    ),         
                .bkpt_inst        (bkpt_inst   ),        
                .yield_inst       (yield_inst  ),
                .wfe_inst         (wfe_inst    ),
                .wfi_inst         (wfi_inst    ),
                .sev_inst         (sev_inst    ),
                .svcall           (svcall       ),
                //execute
                .ie_pc            (ie_pc        ),
                .ie_bsy           (ie_bsy       ),
                .exception_entry  (exception_entry ),
                .exception_return (exception_return),
                .tail_chaining    (tail_chaining   ),
                .ie_hardfault     (ie_hardfault    ),
                .exe_cancel       (exe_cancel      ),
                //exception       
                .PRIMASK          (PRIMASK[0]       ),
                .hardfault_req    (hardfault_req   ),
                .svcall_req       (svcall_req      ),
                .exception_req    (exception_req   ),
                .exception_req_num(exception_req_num),
                .exception_ack    (exception_ack    ),
                .exception_ack_num(exception_ack_num),
                                
                .c_debugen        (c_debugen    ),       
                .c_maskints       (c_maskints   ),
				.ie_stop_req      (ie_stop_req  ),
                .core_reset       (core_reset   ),
                .core_lockup      (core_lockup  ),
                .core_sleep       (core_sleep   ),
                .core_halted      (core_halted  ),
                .core_hardfault   (core_hardfault),
                .core_id_pc       (core_id_pc),
                .core_bkpt_inst   (core_bkpt_inst)   
                
                );

           

//synopsys translate_off    
EMULATOR_M0O EMULATOR_M0O_u0 (
                .rst_n             (rst_n        ),
                .clk               (clk          ),                
                .ie_bsy            (ie_bsy       ), 
				.optype            (optype       ),
                .exception_entry   (exception_entry  ),
                .exception_req_num (exception_req_num),
                .rtl_R0            (R0           ),
                .rtl_R1            (R1           ),
                .rtl_R2            (R2           ),
                .rtl_R3            (R3           ),
                .rtl_R4            (R4           ),
                .rtl_R5            (R5           ),
                .rtl_R6            (R6           ),
                .rtl_R7            (R7           ),
                .rtl_R8            (R8           ),
                .rtl_R9            (R9           ),
                .rtl_R10           (R10          ),
                .rtl_R11           (R11          ),
                .rtl_R12           (R12          ),
                .rtl_SP            (SP           ),
                .rtl_LR            (LR           ),
                .rtl_PC            (PC           ),         
                .rtl_xPSR          (xPSR         ),         
                .rtl_PRIMASK       (PRIMASK      ),          
                .rtl_CONTROL       (CONTROL      )                

				);

//synopsys translate_on
				
endmodule

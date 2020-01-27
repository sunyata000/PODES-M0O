
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
// File        : PODES_M0O.v
// Author      : PODES
// Date        : 20200101
// Version     : 1.0
// Description : PODES_M0O top module.
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
module PODES_M0O (
             clk,             //clock
             rst_n,           //reset, active low.
                              
             sysresetreq,     //request a system reset.
                              
             nmi,             //NMI, one cycle pulse 
             irq,             //IRQ, high level wider than one cycle.
             
             //AMBA Master to external BUS I/F
             ext_mhready,     //HREADY to slave
             ext_mhsel,       //HSEL to slave
             ext_mhaddr,      //AMBA AHBLite I/F. To slave.
             ext_mhtrans,     //AMBA AHBLite I/F. To slave.
             ext_mhwrite,     //AMBA AHBLite I/F. To slave.
             ext_mhwdata,     //AMBA AHBLite I/F. To slave.
             ext_mhsize,      //AMBA AHBLite I/F. To slave.
             ext_mhburst,     //AMBA AHBLite I/F. To slave.
             ext_mhprot,      //AMBA AHBLite I/F. To slave.
             ext_mhrdata,     //AMBA AHBLite I/F. From slave.
             ext_mhready_out, //AMBA AHBLite I/F. From slave.
             ext_mhresp       //AMBA AHBLite I/F. From slave.
             
             );

             
//-----------------------------------------------------------//
//                      INPUTS/OUTPUTS                       //
//-----------------------------------------------------------//
input              clk  ;
input              rst_n;
//system reset request
output             sysresetreq ;
//external interrupt
input              nmi;
input[31:0]        irq;
//AMBA Master to external BUS I/F
output             ext_mhready;
output             ext_mhsel;
output [31:0]      ext_mhaddr;
output [1:0]       ext_mhtrans;
output             ext_mhwrite;
output [31:0]      ext_mhwdata;
output [2:0]       ext_mhsize;
output [2:0]       ext_mhburst;
output [3:0]       ext_mhprot;
input  [31:0]      ext_mhrdata;
input              ext_mhready_out;
input              ext_mhresp; 


//-----------------------------------------------------------//
//                    REGISTERS & WIRES                      //
//-----------------------------------------------------------//
wire            sysresetreq;

wire            reset_trap;
wire            hardfault_req; 
wire            svcall_req;

wire            exe_cancel  ; 
wire            core_reset  ;
wire            core_lockup ;
wire            core_sleep  ;
wire            core_halted ;
wire            core_hardfault;
wire [31:0]     core_id_pc;
wire            core_mwr_mrd;
wire [31:0]     core_mem_addr;
wire            core_mem_addr_vld;
wire            core_bkpt_inst;
             
wire            reg_rdy;
wire [31:0]     reg_from_cpu;

wire [31:0]     inst_addr   ;
wire            inst_req    ;
wire [31:0]     inst_rd_data;
wire            inst_rdy    ;

wire            mem_req  ;
wire [31:0]     mem_addr ;
wire            mem_wr   ;
wire [1 :0]     mem_byte_en;
wire [31:0]     mem_wr_data;
wire [31:0]     mem_rd_data;
wire            mem_rdy    ;
           
wire            exception_req;
wire [7 :0]     exception_req_vector ;
wire [8 :0]     exception_req_num    ;
wire            exception_ack        ;
wire [8 :0]     exception_ack_num    ;

wire [31:0]     actlr;
wire            sevonpend;
wire            sleepdeep;
wire            sleeponexit;


wire             ext_mhready;
wire             ext_mhsel;
wire [31:0]      ext_mhaddr;
wire [1 :0]      ext_mhtrans;
wire             ext_mhwrite;
wire [31:0]      ext_mhwdata;
wire [2 :0]      ext_mhsize;
wire [2 :0]      ext_mhburst;
wire [3 :0]      ext_mhprot;

wire             sys_shsel        ;
wire             sys_shready_in   ; 
wire [31:0]      sys_shaddr       ;
wire [1 :0]      sys_shtrans      ;
wire             sys_shwrite      ;
wire [31:0]      sys_shwdata      ;
wire [2 :0]      sys_shsize       ; 
wire [2 :0]      sys_shburst      ;
wire [3 :0]      sys_shprot       ;  
wire [31:0]      sys_shrdata      ;
wire             sys_shready_out  ;
wire             sys_shresp       ;
//-----------------------------------------------------------//
//                          PARAMETERS                       //
//-----------------------------------------------------------//
//parameter INV_0  = 1'b0;


//-----------------------------------------------------------//
//                          ARCHITECTURE                     //
//-----------------------------------------------------------//

//instruction unit
inst_unit inst_unit_u0 (
             .clk                 (clk                 ),
             .rst_n               (rst_n               ),
                                                       
             .reset_trap          (reset_trap          ),
             .hardfault_req       (hardfault_req       ),
             .svcall_req          (svcall_req          ),
                                                       
             .inst_addr           (inst_addr           ),
             .inst_req            (inst_req            ),
             .inst_rd_data        (inst_rd_data        ),
             .inst_rdy            (inst_rdy            ),
                                                       
             .mem_req             (mem_req             ),
             .mem_addr            (mem_addr            ),
             .mem_rdy             (mem_rdy             ),
             .mem_rd_data         (mem_rd_data         ),
             .mem_wr_data         (mem_wr_data         ), 
             .mem_wr              (mem_wr              ),
             .mem_byte_en         (mem_byte_en         ),
           
             .exception_req       (exception_req       ),
             .exception_req_vector(exception_req_vector), 
             .exception_req_num   (exception_req_num   ), 
             .exception_ack       (exception_ack       ), 
             .exception_ack_num   (exception_ack_num   ),
             
             .reg_acc_req         (1'b0                ),
             .reg_sel             (5'b0                ),
             .reg_wnr             (1'b0                ),
             .reg_rdy             (reg_rdy             ),
             .reg_to_cpu          (32'b0               ),
             .reg_from_cpu        (reg_from_cpu        ),      
                                                       
             .c_debugen           (1'b0                ),       
             .c_maskints          (1'b0                ),
			 .ie_stop_req         (1'b0                ),
			 .exe_cancel          (exe_cancel          ),
             .core_reset          (core_reset          ),
             .core_lockup         (core_lockup         ),
             .core_sleep          (core_sleep          ),
             .core_halted         (core_halted         ),
             .core_hardfault      (core_hardfault      ),
             .core_id_pc          (core_id_pc          ),
             .core_bkpt_inst      (core_bkpt_inst      )
             );

//system support module (interrupt controller, timer, system control)
//sys_suppt
system_ctrl	system_ctrl_u0 (
             .clk                 (clk                 ),
             .rst_n               (rst_n               ), 
                                 
             .hsel                (sys_shsel           ),
             .hready_in           (sys_shready_in      ), 
             .haddr               (sys_shaddr          ),
             .htrans              (sys_shtrans         ),
             .hwrite              (sys_shwrite         ),
             .hwdata              (sys_shwdata         ),
             .hsize               (sys_shsize          ), 
             .hburst              (sys_shburst         ),
             .hprot               (sys_shprot          ),  
             .hrdata              (sys_shrdata         ),
             .hready_out          (sys_shready_out     ),
             .hresp               (sys_shresp          ),
                                 
             .reset_trap          (reset_trap          ),
             .nmi_req             (nmi                 ),
             .hardfault_req       (hardfault_req       ),  
             .svcall_req          (svcall_req          ),   
             .exception_req       (exception_req       ),
             .exception_req_vector(exception_req_vector),
             .exception_req_num   (exception_req_num   ),
             .exception_ack       (exception_ack       ),
             .exception_ack_num   (exception_ack_num   ),        
                                  
             .sysresetreq         (sysresetreq         ),   
             .irq                 (irq                 ),           
                                  
             .core_halted         (core_halted         ),
                                 
             .actlr               (actlr               ),
                                
             .sevonpend           (sevonpend           ),
             .sleepdeep           (sleepdeep           ),
             .sleeponexit         (sleeponexit         )
             );


//Internal Bus Controller
bus_ctrl bus_ctrl_u0 (
             .clk              (clk            ),        
             .rst_n            (rst_n          ),
                               
		     //inst access I/F 
             .inst_addr        (inst_addr      ),
             .inst_req         (inst_req       ),
             .inst_rd_data     (inst_rd_data   ),
             .inst_rdy         (inst_rdy       ),
                               
		     //data access I/F 
             .mem_addr         (mem_addr       ),
             .mem_wr           (mem_wr         ),
             .mem_byte_en      (mem_byte_en    ),
             .mem_req          (mem_req        ),
             .mem_wr_data      (mem_wr_data    ),
             .mem_rd_data      (mem_rd_data    ),
             .mem_rdy          (mem_rdy        ),
		                    
             //System Slave IF 
             .sys_shready_in   (sys_shready_in ),
             .sys_shsel        (sys_shsel      ),
             .sys_shaddr       (sys_shaddr     ),
             .sys_shtrans      (sys_shtrans    ),
             .sys_shwrite      (sys_shwrite    ),
             .sys_shwdata      (sys_shwdata    ),
             .sys_shsize       (sys_shsize     ),
             .sys_shburst      (sys_shburst    ),
             .sys_shprot       (sys_shprot     ),     
             .sys_shrdata      (sys_shrdata    ),
             .sys_shready_out  (sys_shready_out),
             .sys_shresp       (sys_shresp     ),
                               
             //external Slave IF
             .ext_shready_in   (ext_mhready    ),
             .ext_shsel        (ext_mhsel      ),
             .ext_shaddr       (ext_mhaddr     ),
             .ext_shtrans      (ext_mhtrans    ),
             .ext_shwrite      (ext_mhwrite    ),
             .ext_shwdata      (ext_mhwdata    ),
             .ext_shsize       (ext_mhsize     ),
             .ext_shburst      (ext_mhburst    ),
             .ext_shprot       (ext_mhprot     ),
             .ext_shrdata      (ext_mhrdata    ),
             .ext_shready_out  (ext_mhready_out),
             .ext_shresp       (ext_mhresp     )              
            );

endmodule

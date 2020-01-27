
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
// File        : bus_ctrl.v
// Author      : PODES
// Date        : 20200101
// Version     : 1.0
// Description : Internal bus controller for PODES.
//               Masterlock signal is ignored since the access will never be broken.
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

module bus_ctrl
         (
          clk,
          rst_n,
          
		  //inst access I/F
          inst_addr,
          inst_req,
          inst_rd_data,
          inst_rdy,
          
		  //data access I/F
          mem_addr,
          mem_wr,
          mem_byte_en,
          mem_req,
          mem_wr_data,
          mem_rd_data,
          mem_rdy,
			                
          //System Slave IF
          sys_shready_in,
          sys_shsel,
          sys_shaddr,
          sys_shtrans,
          sys_shwrite,
          sys_shwdata,
          sys_shsize,
          sys_shburst,
          sys_shprot,         
          sys_shrdata,
          sys_shready_out,
          sys_shresp,
          
          //external Slave IF
          ext_shready_in,
          ext_shsel,
          ext_shaddr,
          ext_shtrans,
          ext_shwrite,
          ext_shwdata,
          ext_shsize,
          ext_shburst,
          ext_shprot,         
          ext_shrdata,
          ext_shready_out,
          ext_shresp
          
        );


//-----------------------------------------------------------//
//                          PARAMETERS                       //
//-----------------------------------------------------------//
parameter SYS_ADDRESS_START    = 32'he000_0000;
parameter SYS_ADDRESS_MASK     = 32'he000_0000;


//-----------------------------------------------------------//
//                      INPUTS/OUTPUTS                       //
//-----------------------------------------------------------//  
input        clk;
input        rst_n;

//INST ACCESS IF
input [31:0]      inst_addr ;
input             inst_req  ;
output[31:0]      inst_rd_data;
output            inst_rdy    ;
          
//DATA ACCESS IF
input [31:0]      mem_addr ;
input             mem_wr;
input [1:0]       mem_byte_en  ;
input             mem_req  ;
input [31:0]      mem_wr_data;
output[31:0]      mem_rd_data;
output            mem_rdy    ;

//Debug Master IF
//removed


//System Slave IF
output           sys_shready_in;
output           sys_shsel;
output  [31:0]   sys_shaddr;
output  [1:0]    sys_shtrans;
output           sys_shwrite;
output  [31:0]   sys_shwdata;
output  [2:0]    sys_shsize;  
output  [2:0]    sys_shburst;   
output  [3:0]    sys_shprot;  
input  [31:0]    sys_shrdata;           
input            sys_shready_out;
input            sys_shresp;


//External Slave IF
output           ext_shready_in;
output           ext_shsel;
output  [31:0]   ext_shaddr;
output  [1:0]    ext_shtrans;
output           ext_shwrite;
output  [31:0]   ext_shwdata;
output  [2:0]    ext_shsize;  
output  [2:0]    ext_shburst;   
output  [3:0]    ext_shprot;  
input  [31:0]    ext_shrdata;           
input            ext_shready_out;
input            ext_shresp;

//-----------------------------------------------------------//
//                    REGISTERS & WIRES                      //
//-----------------------------------------------------------//

wire [31:0]      inst_rd_data;
wire             inst_rdy    ;

wire [31:0]      mem_rd_data;
wire             mem_rdy    ;

wire           sys_shready_in;
wire           sys_shsel;
wire  [31:0]   sys_shaddr;
wire  [1:0]    sys_shtrans;
wire           sys_shwrite;
wire  [31:0]   sys_shwdata;
wire  [2:0]    sys_shsize;  
wire  [2:0]    sys_shburst;   
wire  [3:0]    sys_shprot;  

wire           ext_shready_in;
wire           ext_shsel;
wire  [31:0]   ext_shaddr;
wire  [1:0]    ext_shtrans;
wire           ext_shwrite;
wire  [31:0]   ext_shwdata;
wire  [2:0]    ext_shsize;  
wire  [2:0]    ext_shburst;   
wire  [3:0]    ext_shprot;  

wire           ts01_hready_in; 
wire           ts01_hready ;
wire           ts01_hsel   ;
wire  [31:0]   ts01_haddr  ;
wire  [1:0]    ts01_htrans ;
wire           ts01_hwrite ;
wire  [31:0]   ts01_hwdata ;
wire  [2:0]    ts01_hsize  ;
wire  [2:0]    ts01_hburst ;
wire  [3:0]    ts01_hprot  ;
wire  [31:0]   fs01_hrdata ;
wire           fs01_hready ;
wire           fs01_hresp  ;
wire           fs01_hready_in;

wire  [31:0]   inst_mhaddr  ;
wire  [1:0]    inst_mhtrans ;
wire           inst_mhwrite ;
wire  [31:0]   inst_mhwdata ;
wire  [2:0]    inst_mhsize  ;
wire  [2:0]    inst_mhburst ;
wire  [3:0]    inst_mhprot  ;
wire           inst_mhmasterlock ;
wire  [31:0]   inst_mhrdata ;
wire           inst_mhready ;
wire           inst_mhresp  ;


wire           data_mhsel   ;
wire  [31:0]   data_mhaddr  ;
wire  [1:0]    data_mhtrans ;
wire           data_mhwrite ;
wire  [31:0]   data_mhwdata ;
wire  [2:0]    data_mhsize  ;
wire  [2:0]    data_mhburst ;
wire  [3:0]    data_mhprot  ;
wire           data_mhmasterlock ;
wire  [31:0]   data_mhrdata ;
wire           data_mhready ;
wire           data_mhresp  ;


wire [31:0]     core_mem_addr;
wire            core_mem_addr_vld;
wire            core_mwr_mrd;

//-----------------------------------------------------------//
//                          ARCHITECTURE                     //
//-----------------------------------------------------------//

//instruction access: convert to AMBA bus
inst_access inst_access_u0 (
             .clk           (clk              ),
             .rst_n         (rst_n            ),
        
             .inst_addr     (inst_addr        ),
             .inst_req      (inst_req         ),
             .inst_rd_data  (inst_rd_data     ),
             .inst_rdy      (inst_rdy         ),
         
             .i_mhaddr      (inst_mhaddr      ),
             .i_mhtrans     (inst_mhtrans     ),
             .i_mhwrite     (inst_mhwrite     ),
             .i_mhwdata     (inst_mhwdata     ),
             .i_mhsize      (inst_mhsize      ),
             .i_mhburst     (inst_mhburst     ),
             .i_mhprot      (inst_mhprot      ),
             .i_mhmasterlock(inst_mhmasterlock),
             .i_mhrdata     (inst_mhrdata     ),
             .i_mhready     (inst_mhready     ),
             .i_mhresp      (inst_mhresp      )
             );

//data access: convert to AMBA bus.
data_access data_access_u0 (
             .clk               (clk              ),
             .rst_n             (rst_n            ),
        
             .mem_addr          (mem_addr         ),
             .mem_wr            (mem_wr           ),
             .mem_byte_en       (mem_byte_en      ),
             .mem_req           (mem_req          ),
             .mem_wr_data       (mem_wr_data      ),
             .mem_rd_data       (mem_rd_data      ),
             .mem_rdy           (mem_rdy          ),
             .core_mem_addr     (core_mem_addr    ),
             .core_mem_addr_vld (core_mem_addr_vld),
             .core_mwr_mrd      (core_mwr_mrd     ),
         
             .d_mhaddr          (data_mhaddr      ),
             .d_mhtrans         (data_mhtrans     ),
             .d_mhwrite         (data_mhwrite     ),
             .d_mhwdata         (data_mhwdata     ),
             .d_mhsize          (data_mhsize      ),
             .d_mhburst         (data_mhburst     ),
             .d_mhprot          (data_mhprot      ),
             .d_mhmasterlock    (data_mhmasterlock),
             .d_mhrdata         (data_mhrdata     ),
             .d_mhready         (data_mhready     ),
             .d_mhresp          (data_mhresp      )
             );

//--------------------------------------------
//S0(system Control: e000_0000 ~ ffff_ffff)
//Data Master: System control space and others
//--------------------------------------------
ahblite1to2  #(
              .S0_ADDRESS_START (SYS_ADDRESS_START),
              .S0_ADDRESS_MASK  (SYS_ADDRESS_MASK )  
              ) 
         ahblite1to2_u0 (
          .clk        (clk             ),
          .rst_n      (rst_n           ),
          
          //Master IF
          .fm_hready  (data_mhready    ),
          .fm_hsel    (1'b1            ),
          .fm_haddr   (data_mhaddr     ),
          .fm_htrans  (data_mhtrans    ),
          .fm_hwrite  (data_mhwrite    ),
          .fm_hwdata  (data_mhwdata    ),
          .fm_hsize   (data_mhsize     ),
          .fm_hburst  (data_mhburst    ),
          .fm_hprot   (data_mhprot     ), 
          .tm_hrdata  (data_mhrdata    ),         
          .tm_hready  (data_mhready    ),
          .tm_hresp   (data_mhresp     ),
          
          //Slv IF 0
          .ts0_hready  (sys_shready_in ),
          .ts0_hsel    (sys_shsel      ),
          .ts0_haddr   (sys_shaddr     ),
          .ts0_htrans  (sys_shtrans    ),
          .ts0_hwrite  (sys_shwrite    ),
          .ts0_hwdata  (sys_shwdata    ),
          .ts0_hsize   (sys_shsize     ),
          .ts0_hburst  (sys_shburst    ),
          .ts0_hprot   (sys_shprot     ),
          .fs0_hrdata  (sys_shrdata    ),
          .fs0_hready  (sys_shready_out),
          .fs0_hresp   (sys_shresp     ),
          
          //Slv IF 1
          .ts1_hready  (ts01_hready_in ),
          .ts1_hsel    (ts01_hsel      ),
          .ts1_haddr   (ts01_haddr     ),
          .ts1_htrans  (ts01_htrans    ),
          .ts1_hwrite  (ts01_hwrite    ),
          .ts1_hwdata  (ts01_hwdata    ),
          .ts1_hsize   (ts01_hsize     ),
          .ts1_hburst  (ts01_hburst    ),
          .ts1_hprot   (ts01_hprot     ),
          .fs1_hrdata  (fs01_hrdata    ),
          .fs1_hready  (fs01_hready_out),
          .fs1_hresp   (fs01_hresp     )
          
        );


//--------------------------------------------
//BUS Mux
//combine inst_Master and data_master
//--------------------------------------------
ahblite2to1 ahblite2to1_u0(
          .clk        (clk            ),
          .rst_n      (rst_n          ),
         
          .fm0_hready (inst_mhready   ),
          .fm0_hsel   (1'b1           ),
          .fm0_haddr  (inst_mhaddr    ),
          .fm0_htrans (inst_mhtrans   ),
          .fm0_hwrite (inst_mhwrite   ),
          .fm0_hwdata (inst_mhwdata   ),
          .fm0_hsize  (inst_mhsize    ),
          .fm0_hburst (inst_mhburst   ),
          .fm0_hprot  (inst_mhprot    ),
          .tm0_hrdata (inst_mhrdata   ),
          .tm0_hready (inst_mhready   ),
          .tm0_hresp  (inst_mhresp    ),
                                
          .fm1_hready (ts01_hready_in ),
          .fm1_hsel   (ts01_hsel      ),
          .fm1_haddr  (ts01_haddr     ),
          .fm1_htrans (ts01_htrans    ),
          .fm1_hwrite (ts01_hwrite    ),
          .fm1_hwdata (ts01_hwdata    ),
          .fm1_hsize  (ts01_hsize     ),
          .fm1_hburst (ts01_hburst    ),
          .fm1_hprot  (ts01_hprot     ),
          .tm1_hrdata (fs01_hrdata    ),
          .tm1_hready (fs01_hready_out),
          .tm1_hresp  (fs01_hresp     ),
                                
          .ts_hready (ext_shready_in  ), 
          .ts_hsel   (ext_shsel       ),    
          .ts_haddr  (ext_shaddr      ),    
          .ts_htrans (ext_shtrans     ),    
          .ts_hwrite (ext_shwrite     ),    
          .ts_hwdata (ext_shwdata     ),    
          .ts_hsize  (ext_shsize      ),    
          .ts_hburst (ext_shburst     ),    
          .ts_hprot  (ext_shprot      ),    
          .fs_hrdata (ext_shrdata     ),    
          .fs_hready (ext_shready_out ),
          .fs_hresp  (ext_shresp      )     
        );
			 
endmodule


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
// File        : data_access.v
// Author      : PODES
// Date        : 20200101
// Version     : 1.0
// Description : Internal memory access signals to AMBA master bus.
//               
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

module data_access (
             clk,
             rst_n,
             
             mem_addr,
             mem_wr,
             mem_byte_en,
             mem_req,
             mem_wr_data,
             mem_rd_data,
             mem_rdy,
             core_mem_addr ,
             core_mem_addr_vld ,
             core_mwr_mrd ,
             
             d_mhaddr,
             d_mhtrans,
             d_mhwrite,
             d_mhwdata,
             d_mhsize,
             d_mhburst,
             d_mhprot,
             d_mhmasterlock,
             d_mhrdata,
             d_mhready,
             d_mhresp
             );

             
//-----------------------------------------------------------//
//                      INPUTS, OUTPUTS                      //
//-----------------------------------------------------------//
input             clk  ;
input             rst_n;
         
input [31:0]      mem_addr ;
input             mem_wr;
input [1:0]       mem_byte_en  ;
input             mem_req  ;
input [31:0]      mem_wr_data;
output[31:0]      mem_rd_data;
output            mem_rdy    ;
output [31:0]     core_mem_addr;
output            core_mem_addr_vld;
output            core_mwr_mrd;
           
output [31:0]      d_mhaddr ;
output [1:0]       d_mhtrans;
output             d_mhwrite;
output [31:0]      d_mhwdata;
output [2:0]       d_mhsize ;
output [2:0]       d_mhburst;
output [3:0]       d_mhprot ;
output             d_mhmasterlock;
input  [31:0]      d_mhrdata;
input              d_mhready;
input              d_mhresp ;


//-----------------------------------------------------------//
//                    REGISTERS & WIRES                      //
//-----------------------------------------------------------//

wire[31:0]      mem_rd_data;
wire            mem_rdy    ;
   
wire [31:0]      d_mhaddr ;
wire [2:0]       d_mhburst;
wire             d_mhmasterlock;
wire [3:0]       d_mhprot ;
wire [2:0]       d_mhsize ;
wire [1:0]       d_mhtrans;
reg [31:0]       d_mhwdata;
wire             d_mhwrite;

wire [1:0]      tmp_byte_en;

//-----------------------------------------------------------//
//                          PARAMETERS                       //
//-----------------------------------------------------------//
parameter NOSEQ  = 2'b10;
parameter IDLE   = 2'b00;


//-----------------------------------------------------------//
//                          ARCHITECTURE                     //
//-----------------------------------------------------------//

//---------------
//For debugger
//---------------
assign   core_mem_addr = (mem_byte_en == 2'b00)? {mem_addr} :
                         ((mem_byte_en == 2'b01)? {mem_addr[31:1], 1'b0} : {mem_addr[31:2], 2'b0});  
assign   core_mem_addr_vld = mem_req;
assign   core_mwr_mrd = mem_wr;

//---------------
//To BUS
//---------------
assign d_mhaddr       = mem_addr;

assign d_mhburst      = 3'b000;

assign d_mhmasterlock = 1'b0;

assign d_mhprot       = 4'b0001;

assign d_mhsize       = {1'b0, mem_byte_en};

assign d_mhtrans      = (mem_req == 1'b1) ? NOSEQ : IDLE;


always@ (posedge clk or negedge rst_n)
begin
  if (!rst_n)
    d_mhwdata <= 32'b0;
  else if (d_mhready && mem_req) 
    d_mhwdata <=  mem_wr_data;
end

assign d_mhwrite      = mem_wr;

assign mem_rdy      = d_mhready;

assign mem_rd_data  = d_mhrdata;


endmodule


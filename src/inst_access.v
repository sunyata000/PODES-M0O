
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
// File        : inst_access.v
// Author      : PODES
// Date        : 20200101
// Version     : 1.0
// Description : Internal instruction access signals to AMBA master bus.
//               Keep the REQ till INST_RDY is asserted, then latch DATA
//                 on next cycle if INST_RDY is asserted.
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

module inst_access (
             clk,
             rst_n,
             
             inst_addr,
             inst_req,
             inst_rd_data,
             inst_rdy,
                          
             i_mhaddr,
             i_mhtrans,
             i_mhwrite,
             i_mhwdata,
             i_mhsize,
             i_mhburst,
             i_mhprot,
             i_mhmasterlock,
             i_mhrdata,
             i_mhready,
             i_mhresp
             );

             
//-----------------------------------------------------------//
//                      INPUTS, OUTPUTS                      //
//-----------------------------------------------------------//
input             clk  ;
input             rst_n;
        
input [31:0]      inst_addr ;
input             inst_req  ;
output[31:0]      inst_rd_data;
output            inst_rdy    ;
           
output [31:0]      i_mhaddr ;
output [1:0]       i_mhtrans;
output             i_mhwrite;
output [31:0]      i_mhwdata;
output [2:0]       i_mhsize ;
output [2:0]       i_mhburst;
output [3:0]       i_mhprot ;
output             i_mhmasterlock;
input  [31:0]      i_mhrdata;
input              i_mhready;
input              i_mhresp ;


//-----------------------------------------------------------//
//                    REGISTERS & WIRES                      //
//-----------------------------------------------------------//

wire [31:0]     inst_rd_data;
wire            inst_rdy    ;
   
wire [31:0]     i_mhaddr ;
reg  [1:0]      i_mhtrans;
wire            i_mhwrite;
wire [31:0]     i_mhwdata;
wire [2:0]      i_mhsize ;
wire [2:0]      i_mhburst;
wire [3:0]      i_mhprot ;
wire            i_mhmasterlock;

reg             ahb_acc_dly;
reg [31:0]      data_keep;
wire            data_rdy;


//-----------------------------------------------------------//
//                          PARAMETERS                       //
//-----------------------------------------------------------//
parameter NOSEQ  = 2'b10;
parameter IDLE   = 2'b00;


//-----------------------------------------------------------//
//                          ARCHITECTURE                     //
//-----------------------------------------------------------//
 
//=======================================
//Generate control signals for BUS access.
//=======================================
always @*
begin //(a branch_addr or (not branch_addr but word align addr)
    if (inst_req && ((inst_addr[0]) | (inst_addr[1:0] == 2'b00)))
	    i_mhtrans = NOSEQ;
	else
	    i_mhtrans = IDLE;
	
end

assign i_mhaddr       = {inst_addr[31:2], 2'b00}; //always 32bit word alignment.
assign i_mhsize       = 3'b010; //32bits word access. 

assign i_mhwdata      = 32'b0;
assign i_mhwrite      = 1'b0;  //only read
assign i_mhburst      = 3'b000; //single burst
assign i_mhmasterlock = 1'b0;
assign i_mhprot       = 4'b0011;



//=======================================
//Generate inst and status.
//=======================================
always@ (posedge clk or negedge rst_n)
begin
  if (!rst_n)
  begin
    ahb_acc_dly  <= 1'b0;
  end
  else if (i_mhready)
  begin
   ahb_acc_dly  <= i_mhtrans[1]; 
  end
end

assign data_rdy = ahb_acc_dly & i_mhready;

always@ (posedge clk or negedge rst_n)
begin
  if (!rst_n)
  begin
    data_keep <= 32'b0;
  end
  else if (data_rdy)
  begin
    data_keep <= i_mhrdata;
  end
end

assign inst_rd_data = data_rdy ?  i_mhrdata  : data_keep;
assign inst_rdy     = data_rdy | (~ahb_acc_dly); //access ready or doesnt access.


endmodule



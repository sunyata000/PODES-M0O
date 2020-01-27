
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
// File        : ahblite1to2.v
// Author      : PODES
// Date        : 20200101
// Version     : 1.0
// Description : AHBLite bus. Divide one port into two ports.
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

module ahblite1to2
        #(
          parameter S0_ADDRESS_START = 32'he000_0000,
          parameter S0_ADDRESS_MASK  = 32'he000_0000  
         ) 
        (
          clk,
          rst_n,
          
          //Master IF
          fm_hready,
          fm_hsel,
          fm_haddr,
          fm_htrans,
          fm_hwrite,
          fm_hwdata,
          fm_hsize,
          fm_hburst,
          fm_hprot, 
          tm_hrdata,         
          tm_hready,
          tm_hresp,
          
          //Slv IF 0
          ts0_hready,
          ts0_hsel,
          ts0_haddr,
          ts0_htrans,
          ts0_hwrite,
          ts0_hwdata,
          ts0_hsize,
          ts0_hburst,
          ts0_hprot,
          fs0_hrdata,
          fs0_hready,
          fs0_hresp,
          
          //Slv IF 1
          ts1_hready,
          ts1_hsel,
          ts1_haddr,
          ts1_htrans,
          ts1_hwrite,
          ts1_hwdata,
          ts1_hsize,
          ts1_hburst,
          ts1_hprot,
          fs1_hrdata,
          fs1_hready,
          fs1_hresp
          
        );

//-----------------------------------------------------------//
//                          PARAMETERS                       //
//-----------------------------------------------------------//


//-----------------------------------------------------------//
//                      INPUTS/OUTPUTS                       //
//-----------------------------------------------------------//  
input        clk;
input        rst_n;

//Master IF
input           fm_hready;
input           fm_hsel;
input  [31:0]   fm_haddr;
input  [1:0]    fm_htrans;
input           fm_hwrite;
input  [31:0]   fm_hwdata;
input  [2:0]    fm_hsize;
input  [2:0]    fm_hburst;
input  [3:0]    fm_hprot;

output          tm_hready;
output          tm_hresp;
output [31:0]   tm_hrdata;
          
//Slv IF 0
output             ts0_hready;
output             ts0_hsel;
output  [31:0]     ts0_haddr;
output  [1:0]      ts0_htrans;
output             ts0_hwrite;
output  [31:0]     ts0_hwdata;
output  [2:0]      ts0_hsize;
output  [2:0]      ts0_hburst;
output  [3:0]      ts0_hprot;
input              fs0_hready;
input              fs0_hresp;
input  [31:0]      fs0_hrdata;
          
//Slv IF 1
output             ts1_hready;
output             ts1_hsel;
output  [31:0]     ts1_haddr;
output  [1:0]      ts1_htrans;
output             ts1_hwrite;
output  [31:0]     ts1_hwdata;
output  [2:0]      ts1_hsize;
output  [2:0]      ts1_hburst;
output  [3:0]      ts1_hprot;
input              fs1_hready;
input              fs1_hresp;
input  [31:0]      fs1_hrdata;
          

//-----------------------------------------------------------//
//                    REGISTERS & WIRES                      //
//-----------------------------------------------------------//

reg          tm_hresp;
reg [31:0]   tm_hrdata;
reg          hready_grant;
        
        
//-----------------------------------------------------------//
//                          ARCHITECTURE                     //
//-----------------------------------------------------------//
//Slave IF
assign      ts0_haddr   =  fm_haddr ;
assign      ts0_htrans  =  fm_htrans;
assign      ts0_hwrite  =  fm_hwrite;
assign      ts0_hwdata  =  fm_hwdata;
assign      ts0_hsize   =  fm_hsize ;
assign      ts0_hburst  =  fm_hburst;
assign      ts0_hprot   =  fm_hprot;
assign      ts0_hready  =  hready_grant;

assign      ts1_haddr   =  fm_haddr ;
assign      ts1_htrans  =  fm_htrans;
assign      ts1_hwrite  =  fm_hwrite;
assign      ts1_hwdata  =  fm_hwdata;
assign      ts1_hsize   =  fm_hsize ;
assign      ts1_hburst  =  fm_hburst;
assign      ts1_hprot   =  fm_hprot;
assign      ts1_hready  =  hready_grant;

assign      tm_hready  =  hready_grant;

//===========
//Decoder
//===========
wire s0_hit = (((fm_haddr ^ S0_ADDRESS_START) & S0_ADDRESS_MASK) == 0) & fm_hsel;
wire s1_hit = (~s0_hit) & fm_hsel;

wire s0_access = s0_hit & fm_htrans[1];
wire s1_access = s1_hit & fm_htrans[1];

assign      ts0_hsel  =  s0_hit;
assign      ts1_hsel  =  s1_hit;


//==========
//Mux
//==========
reg s0_access_reg;
reg s1_access_reg;
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        s0_access_reg <= 1'b0;
        s1_access_reg <= 1'b0;
    end
    else if(fm_hready)
    begin
        s0_access_reg <= s0_access;
        s1_access_reg <= s1_access;
    end
end

always @ *
begin
    case ({s1_access_reg,s0_access_reg})
    2'b01:     //S0 is selected.
      begin
        hready_grant   = fs0_hready;
        tm_hrdata      = fs0_hrdata;
        tm_hresp       = fs0_hresp;      
      end
    2'b10:     //S1 is selected.
      begin
        hready_grant   = fs1_hready;
        tm_hrdata      = fs1_hrdata;
        tm_hresp       = fs1_hresp;    
      end
    2'b00:    //None is selected.
      begin
          hready_grant    = 1'b1;
          tm_hrdata      = 32'h00000000;
          tm_hresp       = 1'b0;
      end
    default:  //Both are selected. Never occurs.
      begin
          hready_grant    = 1'b1;
          tm_hrdata      = 32'h00000000;
          tm_hresp       = 1'b0;
      end
    endcase
end    
    
endmodule

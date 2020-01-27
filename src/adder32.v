
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
// File        : adder32.v
// Author      : PODES
// Date        : 20200101
// Version     : 1.0
// Description : 32bit adder with carry and overflow bit module.
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

module adder32 (
                  opand1,
                  opand2,
                  cin,
                  cout,
                  ov,
                  sum 
                   ); 


//-----------------------------------------------------------//
//                      INPUTS / OUTPUTS                     //
//-----------------------------------------------------------//
input [31:0]      opand1;
input [31:0]      opand2;
input             cin;
             
output             cout;
output             ov;
output [31:0]      sum;


//-----------------------------------------------------------//
//                    REGISTERS & WIRES                      //
//-----------------------------------------------------------//
wire             cout;
wire             ov;
wire [31:0]      sum;

wire [32:0]      tmp_result;



//-----------------------------------------------------------//
//                          PARAMETERS                       //
//-----------------------------------------------------------//
//parameter INV_0  = 1'b0;


//-----------------------------------------------------------//
//                          ARCHITECTURE                     //
//-----------------------------------------------------------//

//adder32
assign tmp_result = {1'b0, opand1} + {1'b0, opand2} + {32'b0, cin};

assign sum  = tmp_result[31:0];
assign cout = tmp_result[32];
assign ov   = ((opand1[31] == opand2[31]) && (tmp_result[31] != opand2[31])) ? 1'b1 : 1'b0;


endmodule

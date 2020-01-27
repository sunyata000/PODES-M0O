
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
// File        : log_shft.v
// Author      : PODES
// Date        : 20200101
// Version     : 1.0
// Description : Logic shifter. 
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

module log_shft (
                 optype,
                 opand1,
                 opand2,
                 result,
                 cin ,
                 cout
                 ) ;

//-----------------------------------------------------------//
//                      INPUTS / OUTPUTS                     //
//-----------------------------------------------------------//
input [4:0]       optype;
input [31:0]      opand1;
input [31:0]      opand2;
input             cin;
             
output [31:0]     result;
output             cout;

//-----------------------------------------------------------//
//                    REGISTERS & WIRES                      //
//-----------------------------------------------------------//

wire [31:0]     result;
wire            cout;

reg [31:0]      tmp_result;
reg             tmp_cout;


//-----------------------------------------------------------//
//                          PARAMETERS                       //
//-----------------------------------------------------------//
//parameter INV_0  = 1'b0;

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


//-----------------------------------------------------------//
//                          ARCHITECTURE                     //
//-----------------------------------------------------------//

//logic and shift operations
wire [7:0] shift_n = ((optype == OP_RSR) && (opand2[7:0] > 8'h20))? {3'b000, opand2[4:0]} : opand2[7:0];
//LSL
always @ *
begin
case (optype) 
      OP_OR:
          begin
            tmp_result = opand1 | opand2;
            tmp_cout   = cin;
          end
      
      OP_XOR:
          begin
            tmp_result = opand1 ^ opand2;
            tmp_cout   = cin;
          end
                  
      OP_AND:
          begin
            tmp_result = opand1 & opand2;
            tmp_cout   = cin;
          end
      
      OP_LSL,
      OP_LSR,
      OP_ASR,
      OP_RSR:
          begin      
            case (shift_n) 
                8'd0:
                    begin
                      tmp_result = opand1;
                      tmp_cout   = cin;
                    end
                8'd1:
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = {opand1[30:0], 1'b0};
                          tmp_cout   = opand1[31];
                        end      
                      else
                        begin
                          tmp_cout = opand1[0];
                          tmp_result[30:0] = opand1[31:1];
                          tmp_result[31] = (optype == OP_LSR)? 1'b0 : ((optype == OP_ASR) ? opand1[31] : opand1[0]);
                        end                         
                    end
                8'd2:
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = {opand1[29:0], 2'b0};
                          tmp_cout   = opand1[30];
                        end      
                      else
                        begin
                          tmp_cout = opand1[1];
                          tmp_result[29:0] = opand1[31:2];
                          tmp_result[31:30] = (optype == OP_LSR)? 2'b0 : ((optype == OP_ASR) ? {2{opand1[31]}} : opand1[1:0]);
                        end                         
                    end
                8'd3:
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = {opand1[28:0], 3'b0};
                          tmp_cout   = opand1[29];
                        end      
                      else
                        begin
                          tmp_cout = opand1[2];
                          tmp_result[28:0] = opand1[31:3];
                          tmp_result[31:29] = (optype == OP_LSR)? 3'b0 : ((optype == OP_ASR) ? {3{opand1[31]}} : opand1[2:0]);
                        end                         
                    end
                8'd4:
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = {opand1[27:0], 4'b0};
                          tmp_cout   = opand1[28];
                        end      
                      else
                        begin
                          tmp_cout = opand1[3];
                          tmp_result[27:0] = opand1[31:4];
                          tmp_result[31:28] = (optype == OP_LSR)? 4'b0 : ((optype == OP_ASR) ? {4{opand1[31]}} : opand1[3:0]);
                        end                         
                    end
                8'd5:
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = {opand1[26:0], 5'b0};
                          tmp_cout   = opand1[27];
                        end      
                      else
                        begin
                          tmp_cout = opand1[4];
                          tmp_result[26:0] = opand1[31:5];
                          tmp_result[31:27] = (optype == OP_LSR)? 5'b0 : ((optype == OP_ASR) ? {5{opand1[31]}} : opand1[4:0]);
                        end                         
                    end
                8'd6:
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = {opand1[25:0], 6'b0};
                          tmp_cout   = opand1[26];
                        end      
                      else
                        begin
                          tmp_cout = opand1[5];
                          tmp_result[25:0] = opand1[31:6];
                          tmp_result[31:26] = (optype == OP_LSR)? 6'b0 : ((optype == OP_ASR) ? {6{opand1[31]}} : opand1[5:0]);
                        end                         
                    end
                8'd7:
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = {opand1[24:0], 7'b0};
                          tmp_cout   = opand1[25];
                        end      
                      else
                        begin
                          tmp_cout = opand1[6];
                          tmp_result[24:0] = opand1[31:7];
                          tmp_result[31:25] = (optype == OP_LSR)? 7'b0 : ((optype == OP_ASR) ? {7{opand1[31]}} : opand1[6:0]);
                        end                         
                    end
                8'd8:
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = {opand1[23:0], 8'b0};
                          tmp_cout   = opand1[24];
                        end      
                      else
                        begin
                          tmp_cout = opand1[7];
                          tmp_result[23:0] = opand1[31:8];
                          tmp_result[31:24] = (optype == OP_LSR)? 8'b0 : ((optype == OP_ASR) ? {8{opand1[31]}} : opand1[7:0]);
                        end                         
                    end
                8'd9:
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = {opand1[22:0], 9'b0};
                          tmp_cout   = opand1[23];
                        end      
                      else
                        begin
                          tmp_cout = opand1[8];
                          tmp_result[22:0] = opand1[31:9];
                          tmp_result[31:23] = (optype == OP_LSR)? 9'b0 : ((optype == OP_ASR) ? {9{opand1[31]}} : opand1[8:0]);
                        end                         
                    end
                8'd10:
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = {opand1[21:0], 10'b0};
                          tmp_cout   = opand1[22];
                        end      
                      else
                        begin
                          tmp_cout = opand1[9];
                          tmp_result[21:0] = opand1[31:10];
                          tmp_result[31:22] = (optype == OP_LSR)? 10'b0 : ((optype == OP_ASR) ? {10{opand1[31]}} : opand1[9:0]);
                        end                         
                    end
                8'd11:
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = {opand1[20:0], 11'b0};
                          tmp_cout   = opand1[21];
                        end      
                      else
                        begin
                          tmp_cout = opand1[10];
                          tmp_result[20:0] = opand1[31:11];
                          tmp_result[31:21] = (optype == OP_LSR)? 11'b0 : ((optype == OP_ASR) ? {11{opand1[31]}} : opand1[10:0]);
                        end                         
                    end
                8'd12:
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = {opand1[19:0], 12'b0};
                          tmp_cout   = opand1[20];
                        end      
                      else
                        begin
                          tmp_cout = opand1[11];
                          tmp_result[19:0] = opand1[31:12];
                          tmp_result[31:20] = (optype == OP_LSR)? 12'b0 : ((optype == OP_ASR) ? {12{opand1[31]}} : opand1[11:0]);
                        end                         
                    end
                8'd13:
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = {opand1[18:0], 13'b0};
                          tmp_cout   = opand1[19];
                        end      
                      else
                        begin
                          tmp_cout = opand1[12];
                          tmp_result[18:0] = opand1[31:13];
                          tmp_result[31:19] = (optype == OP_LSR)? 13'b0 : ((optype == OP_ASR) ? {13{opand1[31]}} : opand1[12:0]);
                        end                         
                    end
                8'd14:
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = {opand1[17:0], 14'b0};
                          tmp_cout   = opand1[18];
                        end      
                      else
                        begin
                          tmp_cout = opand1[13];
                          tmp_result[17:0] = opand1[31:14];
                          tmp_result[31:18] = (optype == OP_LSR)? 14'b0 : ((optype == OP_ASR) ? {14{opand1[31]}} : opand1[13:0]);
                        end                         
                    end
                8'd15:
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = {opand1[16:0], 15'b0};
                          tmp_cout   = opand1[17];
                        end      
                      else
                        begin
                          tmp_cout = opand1[14];
                          tmp_result[16:0] = opand1[31:15];
                          tmp_result[31:17] = (optype == OP_LSR)? 15'b0 : ((optype == OP_ASR) ? {15{opand1[31]}} : opand1[14:0]);
                        end                         
                    end
                8'd16:
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = {opand1[15:0], 16'b0};
                          tmp_cout   = opand1[16];
                        end      
                      else
                        begin
                          tmp_cout = opand1[15];
                          tmp_result[15:0] = opand1[31:16];
                          tmp_result[31:16] = (optype == OP_LSR)? 16'b0 : ((optype == OP_ASR) ? {16{opand1[31]}} : opand1[15:0]);
                        end                         
                    end
                8'd17:
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = {opand1[14:0], 17'b0};
                          tmp_cout   = opand1[15];
                        end      
                      else
                        begin
                          tmp_cout = opand1[16];
                          tmp_result[14:0] = opand1[31:17];
                          tmp_result[31:15] = (optype == OP_LSR)? 17'b0 : ((optype == OP_ASR) ? {17{opand1[31]}} : opand1[16:0]);
                        end                         
                    end
                8'd18:
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = {opand1[13:0], 18'b0};
                          tmp_cout   = opand1[14];
                        end      
                      else
                        begin
                          tmp_cout = opand1[17];
                          tmp_result[13:0] = opand1[31:18];
                          tmp_result[31:14] = (optype == OP_LSR)? 18'b0 : ((optype == OP_ASR) ? {18{opand1[31]}} : opand1[17:0]);
                        end                         
                    end
                8'd19:
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = {opand1[12:0], 19'b0};
                          tmp_cout   = opand1[13];
                        end      
                      else
                        begin
                          tmp_cout = opand1[18];
                          tmp_result[12:0] = opand1[31:19];
                          tmp_result[31:13] = (optype == OP_LSR)? 19'b0 : ((optype == OP_ASR) ? {19{opand1[31]}} : opand1[18:0]);
                        end                         
                    end
                8'd20:
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = {opand1[11:0], 20'b0};
                          tmp_cout   = opand1[12];
                        end      
                      else
                        begin
                          tmp_cout = opand1[19];
                          tmp_result[11:0] = opand1[31:20];
                          tmp_result[31:12] = (optype == OP_LSR)? 20'b0 : ((optype == OP_ASR) ? {20{opand1[31]}} : opand1[19:0]);
                        end                         
                    end
                8'd21:
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = {opand1[10:0], 21'b0};
                          tmp_cout   = opand1[11];
                        end      
                      else
                        begin
                          tmp_cout = opand1[20];
                          tmp_result[10:0] = opand1[31:21];
                          tmp_result[31:11] = (optype == OP_LSR)? 21'b0 : ((optype == OP_ASR) ? {21{opand1[31]}} : opand1[20:0]);
                        end                         
                    end
                8'd22:
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = {opand1[9:0], 22'b0};
                          tmp_cout   = opand1[10];
                        end      
                      else
                        begin
                          tmp_cout = opand1[21];
                          tmp_result[9:0] = opand1[31:22];
                          tmp_result[31:10] = (optype == OP_LSR)? 22'b0 : ((optype == OP_ASR) ? {22{opand1[31]}} : opand1[21:0]);
                        end                         
                    end
                8'd23:
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = {opand1[8:0], 23'b0};
                          tmp_cout   = opand1[9];
                        end      
                      else
                        begin
                          tmp_cout = opand1[22];
                          tmp_result[8:0] = opand1[31:23];
                          tmp_result[31:9] = (optype == OP_LSR)? 23'b0 : ((optype == OP_ASR) ? {23{opand1[31]}} : opand1[22:0]);
                        end                         
                    end
                8'd24:
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = {opand1[7:0], 24'b0};
                          tmp_cout   = opand1[8];
                        end      
                      else
                        begin
                          tmp_cout = opand1[23];
                          tmp_result[7:0] = opand1[31:24];
                          tmp_result[31:8] = (optype == OP_LSR)? 24'b0 : ((optype == OP_ASR) ? {24{opand1[31]}} : opand1[23:0]);
                        end                         
                    end
                8'd25:
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = {opand1[6:0], 25'b0};
                          tmp_cout   = opand1[7];
                        end      
                      else
                        begin
                          tmp_cout = opand1[24];
                          tmp_result[6:0] = opand1[31:25];
                          tmp_result[31:7] = (optype == OP_LSR)? 25'b0 : ((optype == OP_ASR) ? {25{opand1[31]}} : opand1[24:0]);
                        end                         
                    end
                8'd26:
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = {opand1[5:0], 26'b0};
                          tmp_cout   = opand1[6];
                        end      
                      else
                        begin
                          tmp_cout = opand1[25];
                          tmp_result[5:0] = opand1[31:26];
                          tmp_result[31:6] = (optype == OP_LSR)? 26'b0 : ((optype == OP_ASR) ? {26{opand1[31]}} : opand1[25:0]);
                        end                         
                    end
                8'd27:
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = {opand1[4:0], 27'b0};
                          tmp_cout   = opand1[5];
                        end      
                      else
                        begin
                          tmp_cout = opand1[26];
                          tmp_result[4:0] = opand1[31:27];
                          tmp_result[31:5] = (optype == OP_LSR)? 27'b0 : ((optype == OP_ASR) ? {27{opand1[31]}} : opand1[26:0]);
                        end                         
                    end
                8'd28:
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = {opand1[3:0], 28'b0};
                          tmp_cout   = opand1[4];
                        end      
                      else
                        begin
                          tmp_cout = opand1[27];
                          tmp_result[3:0] = opand1[31:28];
                          tmp_result[31:4] = (optype == OP_LSR)? 28'b0 : ((optype == OP_ASR) ? {28{opand1[31]}} : opand1[27:0]);
                        end                         
                    end
                8'd29: 
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = {opand1[2:0], 29'b0};
                          tmp_cout   = opand1[3];
                        end      
                      else
                        begin
                          tmp_cout = opand1[28];
                          tmp_result[2:0] = opand1[31:29];
                          tmp_result[31:3] = (optype == OP_LSR)? 29'b0 : ((optype == OP_ASR) ? {29{opand1[31]}} : opand1[28:0]);
                        end                         
                    end
                8'd30:
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = {opand1[1:0], 30'b0};
                          tmp_cout   = opand1[2];
                        end      
                      else
                        begin
                          tmp_cout = opand1[29];
                          tmp_result[1:0] = opand1[31:30];
                          tmp_result[31:2] = (optype == OP_LSR)? 30'b0 : ((optype == OP_ASR) ? {30{opand1[31]}} : opand1[29:0]);
                        end                         
                    end
                8'd31:
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = {opand1[0], 31'b0};
                          tmp_cout   = opand1[1];
                        end      
                      else
                        begin
                          tmp_cout = opand1[30];
                          tmp_result[0] = opand1[31];
                          tmp_result[31:1] = (optype == OP_LSR)? 31'b0 : ((optype == OP_ASR) ? {31{opand1[31]}} : opand1[30:0]);
                        end                         
                    end
                8'd32:
                    begin
                      if (optype == OP_LSL)
                        begin
                          tmp_result = 32'b0;
                          tmp_cout   = opand1[0];
                        end      
                      else
                        begin
                          tmp_cout = opand1[31];
                          tmp_result[31:0] = (optype == OP_LSR)? 32'b0 : ((optype == OP_ASR) ? {32{opand1[31]}} : opand1[31:0]);
                        end                         
                    end
                default:
                    begin
                      if ((optype == OP_LSL) | (optype == OP_LSR))
                        begin
                          tmp_result = 32'b0;
                          tmp_cout   = 1'b0;
                        end      
                      else
                        begin //????
                          tmp_cout = opand1[31];
                          tmp_result[31:0] = (optype == OP_ASR) ? {32{opand1[31]}} : opand1[31:0];
                        end                         
                    end
        endcase
      end
    default: 
        begin
          tmp_cout = cin;
          tmp_result = opand1;
        end 
endcase
end

assign result = tmp_result;
assign cout   = tmp_cout;

endmodule



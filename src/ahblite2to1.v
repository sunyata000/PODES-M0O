
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
// File        : ahblite2to1.v
// Author      : PODES
// Date        : 20200101
// Version     : 1.0
// Description : AHBLite bus. Two masters access one port.
//               If both asserted simultaneously, grand port0.
//               ts_hready is always high in control phase, and may be low in data phase.
//               Access to another port can be granted only when the previous one is finished. 
//               Access cannot be broken(insert wait state).
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

module ahblite2to1(
          clk,
          rst_n,
          
          fm0_hready,
          fm0_hsel,
          fm0_haddr,
          fm0_htrans,
          fm0_hwrite,
          fm0_hwdata,
          fm0_hsize,
          fm0_hburst,
          fm0_hprot,
          tm0_hrdata,
          tm0_hready,
          tm0_hresp,
          
          fm1_hready,
          fm1_hsel,
          fm1_haddr,
          fm1_htrans,
          fm1_hwrite,
          fm1_hwdata,
          fm1_hsize,
          fm1_hburst,
          fm1_hprot,
          tm1_hrdata,
          tm1_hready,
          tm1_hresp,
          
          ts_hready,
          ts_hsel,
          ts_haddr,
          ts_htrans,
          ts_hwrite,
          ts_hwdata,
          ts_hsize,
          ts_hburst,
          ts_hprot,
          fs_hrdata,
          fs_hready,
          fs_hresp
        );
        
//-----------------------------------------------------------//
//                          PARAMETERS                       //
//-----------------------------------------------------------//
parameter IDLE   = 2'b00;
parameter NONSEQ = 2'b01;
parameter SEQ    = 2'b10;

//-----------------------------------------------------------//
//                      INPUTS/OUTPUTS                       //
//-----------------------------------------------------------//  
input             clk;
input             rst_n;

input             fm0_hready ;
input             fm0_hsel   ;
input   [31:0]    fm0_haddr  ;
input   [1 :0]    fm0_htrans ;
input             fm0_hwrite ;
input   [31:0]    fm0_hwdata ;
input   [2 :0]    fm0_hsize  ;
input   [2 :0]    fm0_hburst ;
input   [3 :0]    fm0_hprot  ;
output  [31:0]    tm0_hrdata ;
output            tm0_hready ;
output            tm0_hresp  ;
          
input             fm1_hready ;
input             fm1_hsel   ;
input   [31:0]    fm1_haddr  ;
input   [1 :0]    fm1_htrans ;
input             fm1_hwrite ;
input   [31:0]    fm1_hwdata ;
input   [2 :0]    fm1_hsize  ;
input   [2 :0]    fm1_hburst ;
input   [3 :0]    fm1_hprot  ;
output  [31:0]    tm1_hrdata ;
output            tm1_hready ;
output            tm1_hresp  ;
           
output            ts_hready  ;  
output            ts_hsel    ;   
output  [31:0]    ts_haddr   ; 
output  [1 :0]    ts_htrans  ;  
output            ts_hwrite  ;  
output  [31:0]    ts_hwdata  ;  
output  [2 :0]    ts_hsize   ; 
output  [2 :0]    ts_hburst  ; 
output  [3 :0]    ts_hprot   ; 
input   [31:0]    fs_hrdata  ; 
input             fs_hready  ;
input             fs_hresp   ;

//-----------------------------------------------------------//
//                    REGISTERS & WIRES                      //
//-----------------------------------------------------------//
wire               tm0_hready;
wire               tm0_hresp     ;
wire  [31:0]       tm0_hrdata    ;
                   
wire               tm1_hready;
wire               tm1_hresp     ;
wire  [31:0]       tm1_hrdata    ;
                   
reg                ts_hsel    ;  
reg                ts_hwrite  ;  
reg   [1 :0]       ts_htrans  ;  
reg   [2 :0]       ts_hburst  ;   
reg   [3 :0]       ts_hprot  ;  
reg   [31:0]       ts_haddr   ;  
wire  [31:0]       ts_hwdata  ;  
reg   [2 :0]       ts_hsize   ;  
reg                ts_hready  ;  

wire               req_slv0;
wire               req_slv1;
                   
reg                pending_slv0;
reg                pending_slv1;

reg               grant_cmd_slv0;
reg               grant_cmd_slv1;
reg               grant_pending_slv0;
reg               grant_pending_slv1;
reg               grant_cmd_slv0_r;
reg               grant_cmd_slv1_r;
                  
reg               grant_data_slv0;
reg               grant_data_slv1;

reg            hwrite_pd_0 ;
reg  [1 :0]    htrans_pd_0 ;
reg  [2 :0]    hburst_pd_0 ;
reg  [3 :0]    hprot_pd_0 ;
reg  [31:0]    haddr_pd_0  ;
reg  [2 :0]    hsize_pd_0  ;

reg            hwrite_pd_1 ;
reg  [1 :0]    htrans_pd_1 ;
reg  [2 :0]    hburst_pd_1 ;
reg  [3 :0]    hprot_pd_1 ;
reg  [31:0]    haddr_pd_1  ;
reg  [2 :0]    hsize_pd_1  ;

reg  [1 :0]    state;        
reg  [1 :0]    nxt_state;


//-----------------------------------------------------------//
//                          ARCHITECTURE                     //
//-----------------------------------------------------------//
assign req_slv0 = fm0_hsel && (fm0_htrans==2'b10) && fm0_hready;
assign req_slv1 = fm1_hsel && (fm1_htrans==2'b10) && fm1_hready;

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        pending_slv0 <= 1'b0;
    end
    else if( req_slv0 && ~grant_cmd_slv0)
    begin
        pending_slv0 <= 1'b1;
    end
    else if(grant_pending_slv0)
    begin
        pending_slv0 <= 1'b0;
    end
end

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        pending_slv1 <= 1'b0;
    end
    else if( req_slv1 && ~grant_cmd_slv1)
    begin
        pending_slv1 <= 1'b1;
    end
    else if(grant_pending_slv1)
    begin
        pending_slv1 <= 1'b0;
    end
end

//pending the command
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        hwrite_pd_0 <=  1'h0;
        htrans_pd_0 <=  2'h0;
        hburst_pd_0 <=  3'h0;
        hprot_pd_0  <=  4'h0;
        haddr_pd_0  <= 32'h0;
        hsize_pd_0  <=  3'h0;
    end
    else if( req_slv0 && ~grant_cmd_slv0)
    begin
        hwrite_pd_0 <=  fm0_hwrite;
        htrans_pd_0 <=  fm0_htrans;
        hburst_pd_0 <=  fm0_hburst;
        hprot_pd_0  <=  fm0_hprot;
        haddr_pd_0  <=  fm0_haddr ;
        hsize_pd_0  <=  fm0_hsize ;
    end
    else if(grant_pending_slv0)
    begin
        hwrite_pd_0 <=  1'h0;
        htrans_pd_0 <=  2'h0;
        hburst_pd_0 <=  3'h0;
        hprot_pd_0  <=  4'h0;
        haddr_pd_0  <= 32'h0;
        hsize_pd_0  <=  3'h0;
    end
end

//pending the command
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        hwrite_pd_1 <=  1'h0;
        htrans_pd_1 <=  2'h0;
        hburst_pd_1 <=  3'h0;
        hprot_pd_1  <=  4'h0;
        haddr_pd_1  <= 32'h0;
        hsize_pd_1  <=  3'h0;
    end
    else if( req_slv1 && ~grant_cmd_slv1)
    begin
        hwrite_pd_1 <=  fm1_hwrite;
        htrans_pd_1 <=  fm1_htrans;
        hburst_pd_1 <=  fm1_hburst;
        hprot_pd_1  <=  fm1_hprot;
        haddr_pd_1  <=  fm1_haddr ;
        hsize_pd_1  <=  fm1_hsize ;
    end
    else if(grant_pending_slv1)
    begin
        hwrite_pd_1 <=  1'h0;
        htrans_pd_1 <=  2'h0;
        hburst_pd_1 <=  3'h0;
        hprot_pd_1  <=  4'h0;
        haddr_pd_1  <= 32'h0;
        hsize_pd_1  <=  3'h0;
    end
end

//command MUX
always @ *
begin
    case({grant_pending_slv1, grant_pending_slv0, grant_cmd_slv1, grant_cmd_slv0})
    4'b0001:
    begin
        ts_hsel   =  fm0_hsel  ;
        ts_hwrite =  fm0_hwrite;
        ts_htrans =  fm0_htrans;
        ts_hburst =  fm0_hburst;
        ts_hprot  =  fm0_hprot;
        ts_haddr  =  fm0_haddr ;
        ts_hsize  =  fm0_hsize ;
        ts_hready =  fm0_hready;
    end
    4'b0010:
    begin
        ts_hsel   =  fm1_hsel  ;
        ts_hwrite =  fm1_hwrite;
        ts_htrans =  fm1_htrans;
        ts_hburst =  fm1_hburst;
        ts_hprot  =  fm1_hprot;
        ts_haddr  =  fm1_haddr ;
        ts_hsize  =  fm1_hsize ;
        ts_hready =  fm1_hready;
    end
    4'b0100:
    begin
        ts_hsel   =  1'b1    ;
        ts_hwrite =  hwrite_pd_0;
        ts_htrans =  htrans_pd_0;
        ts_hburst =  hburst_pd_0;
        ts_hprot  =  hprot_pd_0;
        ts_haddr  =  haddr_pd_0 ;
        ts_hsize  =  hsize_pd_0 ;
        ts_hready =  1'b1    ;
    end
    4'b1000:
    begin
        ts_hsel   =  1'b1    ;
        ts_hwrite =  hwrite_pd_1;
        ts_htrans =  htrans_pd_1;
        ts_hburst =  hburst_pd_1;
        ts_hprot  =  hprot_pd_1;
        ts_haddr  =  haddr_pd_1 ;
        ts_hsize  =  hsize_pd_1 ;
        ts_hready =  1'b1    ;
    end
    4'b0000:  // grant slv1, when no request
    begin
        ts_hsel   =  fm1_hsel   ; //1'b0  ;
        ts_hwrite =  fm1_hwrite ; //1'b0;
        ts_htrans =  fm1_htrans ; //2'b00;
        ts_hburst =  fm1_hburst ; //3'b000;
        ts_hprot  =  fm1_hprot ; //4'b000;
        ts_haddr  =  fm1_haddr  ; //fm0_haddr ;
        ts_hsize  =  fm1_hsize  ; //3'b000 ;
        ts_hready =  grant_data_slv0 ? fm0_hready : fm1_hready; //1'b1;
    end
    default:// grant slv0, when no request
    begin
        ts_hsel   =  fm0_hsel  ;
        ts_hwrite =  fm0_hwrite;
        ts_htrans =  fm0_htrans;
        ts_hburst =  fm0_hburst;
        ts_hprot  =  fm0_hprot;
        ts_haddr  =  fm0_haddr ;
        ts_hsize  =  fm0_hsize ;
        ts_hready =  fm0_hready;
    end
    endcase
end

//data MUX
assign ts_hwdata = grant_data_slv1 ? fm1_hwdata : grant_data_slv0 ? fm0_hwdata : fm1_hwdata;

assign tm0_hrdata = fs_hrdata;
assign tm1_hrdata = fs_hrdata;

assign tm0_hresp = fs_hresp;
assign tm1_hresp = fs_hresp;

assign tm0_hready = grant_data_slv0 ? fs_hready : 
                      pending_slv0 ? 1'b0 : 1'b1;
                      
assign tm1_hready = grant_data_slv1 ? fs_hready : 
                      pending_slv1 ? 1'b0 : 1'b1;                      

//======================================================
//  ARB
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        grant_data_slv0 <= 1'b0;
    end
    else if(grant_cmd_slv0 || grant_pending_slv0)
    begin
        grant_data_slv0 <= 1'b1;
    end
    else if(grant_data_slv0 && fs_hready)
    begin
        grant_data_slv0 <= 1'b0;
    end
end

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        grant_data_slv1 <= 1'b0;
    end
    else if(grant_cmd_slv1 || grant_pending_slv1)
    begin
        grant_data_slv1 <= 1'b1;
    end
    else if(grant_data_slv1 && fs_hready)
    begin
        grant_data_slv1 <= 1'b0;
    end
end




always @ *
begin
    nxt_state = IDLE;
    grant_pending_slv1  = 1'b0;
    grant_pending_slv0  = 1'b0;
    grant_cmd_slv1      = 1'b0;
    grant_cmd_slv0      = 1'b0;
    case (state)
    IDLE:
    begin
        if(pending_slv1) //1st priority
        begin
            grant_pending_slv1 = 1'b1;
            nxt_state = NONSEQ;
        end
        else if(pending_slv0) //2nd priority
        begin
            grant_pending_slv0 = 1'b1;
            nxt_state = NONSEQ;
        end
        else if(req_slv1) //3rd priority
        begin
            grant_cmd_slv1 = 1'b1;
            nxt_state = NONSEQ;
        end
        else if(req_slv0) //4th priority
        begin
            grant_cmd_slv0 = 1'b1;
            nxt_state = NONSEQ;
        end
        else 
            nxt_state = IDLE;
    end
    NONSEQ:
    begin
        if(fm1_hsel && fm1_htrans == 2'b11 && grant_data_slv1)   //dont break seq operation
        begin
            nxt_state = SEQ;
            grant_cmd_slv1     =  1'b1;
        end
        else if(fm0_hsel && fm0_htrans == 2'b11 && grant_data_slv0)   //dont break seq operation
        begin
            nxt_state = SEQ;
            grant_cmd_slv0     = 1'b1;
        end
        else if( (grant_data_slv0 || grant_data_slv1) && ~fs_hready) 
        begin
            nxt_state = NONSEQ;
        end
        
        else
        begin 
        
            if(pending_slv1) //1st priority
            begin
                grant_pending_slv1 = 1'b1;
                nxt_state = NONSEQ;
            end
            else if(pending_slv0) //2nd priority
            begin
                grant_pending_slv0 = 1'b1;
                nxt_state = NONSEQ;
            end
            else if(req_slv1) //3rd priority
            begin
                grant_cmd_slv1 = 1'b1;
                nxt_state = NONSEQ;
            end
            else if(req_slv0) //4th priority
            begin
                grant_cmd_slv0 = 1'b1;
                nxt_state = NONSEQ;
            end
            else
                nxt_state = IDLE;
            
        end
    
    end
    SEQ:
    begin
        
        //if(fm1_hsel && fm1_htrans == 2'b11 && grant_cmd_slv1_r)   //dont break seq operation
        if(fm1_hsel && fm1_htrans == 2'b11 && grant_data_slv1)   //dont break seq operation
        begin
            nxt_state = SEQ;
            grant_cmd_slv1     =  1'b1;
        end
        //else if(fm0_hsel && fm0_htrans == 2'b11 && grant_cmd_slv0_r)   //dont break seq operation
        else if(fm0_hsel && fm0_htrans == 2'b11 && grant_data_slv0)   //dont break seq operation
        begin
            nxt_state = SEQ;
            grant_cmd_slv0     = 1'b1;
        end
        else if( (grant_data_slv0 || grant_data_slv1) && ~fs_hready) 
        begin
            nxt_state = SEQ;
        end
        else
        begin
           if(pending_slv1) //1st priority
            begin
                grant_pending_slv1 = 1'b1;
                nxt_state = NONSEQ;
            end
            else if(pending_slv0) //2nd priority
            begin
                grant_pending_slv0 = 1'b1;
                nxt_state = NONSEQ;
            end
            else if(req_slv1) //3rd priority
            begin
                grant_cmd_slv1 = 1'b1;
                nxt_state = NONSEQ;
            end
            else if(req_slv0) //4th priority
            begin
                grant_cmd_slv0 = 1'b1;
                nxt_state = NONSEQ;
            end
            else
                nxt_state = IDLE;
        end
    end
    endcase
end




always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        state  <= IDLE;
    end
    else
    begin
        state <= nxt_state;
    end
end

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        grant_cmd_slv0_r  <= 1'b0;
    end
    else
    begin
        grant_cmd_slv0_r <= grant_cmd_slv0;
    end
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        grant_cmd_slv1_r  <= 1'b0;
    end
    else
    begin
        grant_cmd_slv1_r <= grant_cmd_slv1;
    end
end

endmodule

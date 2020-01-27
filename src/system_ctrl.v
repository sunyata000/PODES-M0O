
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
// File        : system_ctrl.v
// Author      : PODES
// Date        : 20200101
// Version     : 1.0
// Description : system control space.
//              The PPB space are divided into two portions, one can  be 
//              accessed by DAP only, the other can be accessed by both DAP 
//              and CORE.
//              This module manages all registers which can be accessed by 
//              both DAP and CORE.
//              It includes: SystemControl/ID, SysTick, NVIC, SCS:SCB excluding DFSR.
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

module	system_ctrl 
       (
        //Ahb clock & reset
        clk,
        rst_n,
        
        //Ahb slave interface
        //input
        hsel,
        hready_in,
        haddr,
        htrans,
        hwrite,
        hwdata,
        hsize, 
        hburst,
        hprot,         
        hrdata,
        hready_out,
        hresp,
        
                
        //exceptions
        reset_trap,
        nmi_req,
        hardfault_req,  //hardfault high level
        svcall_req,     //svcall high level
        exception_req,
        exception_req_vector,
        exception_req_num,
        exception_ack,
        exception_ack_num,        
                
        sysresetreq,    //to external module.
        irq,            //external interrupts.
        
        core_halted,
        
        //Control signals from/to registers        
        //offset_e008 //TBD.
        actlr,
        //offset_ed10  //TBD.
        sevonpend,
        sleepdeep,
        sleeponexit
        
        );


//-----------------------------------------------------------//
//                          PARAMETERS                       //
//-----------------------------------------------------------//

parameter CPUID = 32'h410c_c200; //{8'h41, 4'h0, 4'hc, 12'hc20, 4'h0}; //ARM, ARMv6-M, Cortex-M0.
parameter CALIB_10MS_50MHZ = 24'h7a120;  //Calibration value for timer. 10ms if using 50Mhz system clock.
parameter ENDIANESS = 1'b0; //0: LE; 1: BE.

parameter RSV6_0 = 6'b0;

//-----------------------------------------------------------//
//                      INPUTS/OUTPUTS                       //
//-----------------------------------------------------------//  

input          clk;
input          rst_n;

input          hsel;
input          hready_in;
input [31:0]   haddr ;
input [1:0]    htrans;
input          hwrite;
input [31:0]   hwdata;
input [2:0]    hsize ; 
input [2:0]    hburst;   
input [3:0]    hprot;  
output[31:0]   hrdata;
output         hready_out;
output         hresp;



                
//exceptions
input           reset_trap;
input           nmi_req;      
input           hardfault_req    ;  //hardfault high level
input           svcall_req       ;  //svcall high level
output          exception_req    ;
output [7:0]    exception_req_vector;
output [8:0]    exception_req_num;
input           exception_ack    ;
input  [8:0]    exception_ack_num;        
        
output          sysresetreq  ;  //to external module.
input  [31:0]   irq          ;  //external interrupts.
        
input           core_halted;
        
//Control signals from/to registers.
output [31:0]   actlr;
//offset_ed10  //TBD.
output          sevonpend  ;
output          sleepdeep  ;
output          sleeponexit;


//-----------------------------------------------------------//
//                    REGISTERS & WIRES                      //
//-----------------------------------------------------------//

wire          hready_out;
wire          hresp;
reg   [31:0]  hrdata;

reg           exception_req;
reg  [7:0]    exception_req_vector;
reg  [8:0]    exception_req_num;
reg           sysresetreq  ;  

wire [31:0]   actlr;
wire          sevonpend  ;
wire          sleepdeep  ;
wire          sleeponexit;


reg [8:0]     tmp_exception_req_num ;

reg           vectclractive;

wire          ahb_wr;
wire          ahb_rd;

reg [31:0]    ahb_wr_addr_tmp;
reg           ahb_wr_flg;
              
wire [15:0]   ahb_wr_addr;
wire [15:0]   ahb_rd_addr;
wire          ahb_rd_flg;


reg [31: 0]   rege008;
reg [31: 0]   reged00; //RO
reg [31:16]   reged0c;
reg [4:1]     reged10;
reg [23:0]    rege014;
              
reg           tickint;
reg           enable;
              
reg [1:0]     pri_15;
reg [1:0]     pri_14;
reg [1:0]     pri_11;
              
reg           countflag;
reg [23:0]    timer_cnt_dly;
reg [23:0]    timer_cnt;
              
reg [63:0]    irq_pri;
reg [31:0]    irq_enab;
reg [31:0]    irq_pend;

reg           nmi_pend;
reg           hardfault_pend;
reg           svcall_pend;
reg           pendsv_pend;
wire          syst_int;
reg           systick_pend;

//-----------------------------------------------------------//
//                          ARCHITECTURE                     //
//-----------------------------------------------------------//

//---------
//read/write address and flag. Only use low 16bit.
//---------
assign ahb_wr  = hsel & htrans[1] & hready_in & hwrite;  //control phase
assign ahb_rd  = hsel & htrans[1] & hready_in & ~hwrite; //control phase

assign hready_out = 1'b1;
assign hresp  = 1'b0;


always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
       ahb_wr_flg      <= 1'b0;
       ahb_wr_addr_tmp <= 32'h0;
    end
    else 
    begin 
       ahb_wr_flg      <= ahb_wr;
       ahb_wr_addr_tmp <= haddr;
    end                                 
end
assign ahb_wr_addr = (ahb_wr_addr_tmp[31:16] == 16'he000) ? ahb_wr_addr_tmp[15:0] : 16'hffff;

assign ahb_rd_flg  = ahb_rd;
assign ahb_rd_addr = (haddr[31:16] == 16'he000) ? haddr[15:0] : 16'hffff;


//========================
//Write operation to registers
//========================

always @(posedge clk or negedge rst_n)
begin
  if(!rst_n) 
  begin 
     rege008   <= 32'h0;
     reged00   <= CPUID;
     reged0c   <= 16'h0;
     reged10   <= 4'b0;
     
     pri_11    <= 2'b0;
     pri_15    <= 2'b0;
     pri_14    <= 2'b0;
     
     tickint   <= 1'b0;
     enable    <= 1'b0;
     
     rege014   <= 24'b0;
//NVIC     
     irq_pri   <= 64'b0; 
     irq_enab  <= 32'b0;

  end 
  
  else if(ahb_wr_flg) 
    case(ahb_wr_addr) 
    16'he008:  rege008 <= hwdata;
    16'hed00:  reged00 <= hwdata; //RO. But writable in this implmentation.
    16'hed0c:  reged0c <= hwdata[31:16];
    16'hed10:  reged10 <= hwdata[4:1];
    
    16'hed1c:  pri_11  <= hwdata[31:30]; //SVCall
    16'hed20:  begin 
               pri_15  <= hwdata[31:30]; //SysTick
               pri_14  <= hwdata[23:22]; //PendSV
               end
    //SysTic
    16'he010:  begin 
               tickint  <= hwdata[1];
               enable   <= hwdata[0];
               end
    16'he014:  rege014 <= hwdata[23:0];           
    //NVIC    
    16'he100:  irq_enab <= irq_enab | hwdata;
    16'he180:  irq_enab <= irq_enab & ~hwdata;
    16'he400:  irq_pri[7:0]    <= {hwdata[31:30], hwdata[23:22], hwdata[15:14], hwdata[7:6]}; 
    16'he404:  irq_pri[15:8]   <= {hwdata[31:30], hwdata[23:22], hwdata[15:14], hwdata[7:6]}; 
    16'he408:  irq_pri[23:16]  <= {hwdata[31:30], hwdata[23:22], hwdata[15:14], hwdata[7:6]}; 
    16'he40c:  irq_pri[31:24]  <= {hwdata[31:30], hwdata[23:22], hwdata[15:14], hwdata[7:6]}; 
    16'he410:  irq_pri[39:32]  <= {hwdata[31:30], hwdata[23:22], hwdata[15:14], hwdata[7:6]}; 
    16'he414:  irq_pri[47:40]  <= {hwdata[31:30], hwdata[23:22], hwdata[15:14], hwdata[7:6]}; 
    16'he418:  irq_pri[55:48]  <= {hwdata[31:30], hwdata[23:22], hwdata[15:14], hwdata[7:6]}; 
    16'he41c:  irq_pri[63:56]  <= {hwdata[31:30], hwdata[23:22], hwdata[15:14], hwdata[7:6]};    
        
     default: ;
    endcase
     
end



//------------------------
//NMI pend
//------------------------
wire nmi_ack = exception_ack & (exception_ack_num[5:0] == 6'd2);
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        nmi_pend <= 1'b0;
    else if (nmi_req)
        nmi_pend <= 1'b1;
    else if (nmi_ack)
        nmi_pend <= 1'b0;   
    else if (ahb_wr_flg && (ahb_wr_addr == 16'hed04) )
        nmi_pend <= hwdata[31];
    else if (vectclractive)  //vector clear
        nmi_pend  <= 1'b0;
end

//------------------------
//HardFault pend
//------------------------
wire hardfault_ack = exception_ack & (exception_ack_num[5:0] == 6'd3);
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        hardfault_pend <= 1'b0;
    else if (hardfault_req)
        hardfault_pend <= 1'b1;
    else if (hardfault_ack)
        hardfault_pend <= 1'b0;     
    else if (vectclractive)  //vector clear
        hardfault_pend  <= 1'b0;
end


//------------------------
//SVCall pend
//------------------------
wire svcall_ack = exception_ack & (exception_ack_num[5:0] == 6'd11);
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        svcall_pend <= 1'b0;
    else if (svcall_req)
        svcall_pend <= 1'b1;
    else if (svcall_ack)
        svcall_pend <= 1'b0;     
    else if (vectclractive)  //vector clear
        svcall_pend  <= 1'b0;
end


//------------------------
//PendSV pend
//------------------------
wire pendsv_ack = exception_ack & (exception_ack_num[5:0] == 6'd14);
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        pendsv_pend <= 1'b0;
    else if (ahb_wr_flg && (ahb_wr_addr == 16'hed04) && hwdata[28])
        pendsv_pend <= 1'b1;
    else if (ahb_wr_flg && (ahb_wr_addr == 16'hed04) && hwdata[27])
        pendsv_pend <= 1'b0;    
    else if (pendsv_ack)
        pendsv_pend <= 1'b0;     
    else if (vectclractive)  //vector clear
        pendsv_pend  <= 1'b0;
end


//------------------------
//SysTick pend
//------------------------
wire systick_ack = exception_ack & (exception_ack_num[5:0] == 6'd15);
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        systick_pend <= 1'b0;
    else if (ahb_wr_flg && (ahb_wr_addr == 16'hed04) && hwdata[26])
        systick_pend <= 1'b1;
    else if (ahb_wr_flg && (ahb_wr_addr == 16'hed04) && hwdata[25])
        systick_pend <= 1'b0;       
    else if (systick_ack)
        systick_pend <= 1'b0;       
    else if (vectclractive)  //vector clear
        systick_pend  <= 1'b0;
    else
        systick_pend <= systick_pend | syst_int;
end



//------------------------
//Sysresetreq and vectclractive
//------------------------
wire  vectkey       = (hwdata[31:16] == 16'h05fa);
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        sysresetreq <= 1'b0;
    else if (ahb_wr_flg && (ahb_wr_addr == 16'hed0c) && hwdata[2] && vectkey)
        sysresetreq <= 1'b1;
end
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        vectclractive <= 1'b0;
    else
        vectclractive <= core_halted & ahb_wr_flg & (ahb_wr_addr == 16'hed0c) & hwdata[1] & vectkey;
end

//---------
//ACTLR 0xe000e008
//---------


//---------
//SYST_CSR 0xe000e010
//---------        
wire [31:0] syst_csr =  {
                     15'b0,
                     countflag,
                     13'b0,
                     1'b1,
                     tickint,
                     enable
                    };            
     
//---------
//SYST_RVR 0xe000e014
//---------
wire [31:0] syst_rvr =  {
                     8'b0,
                     rege014[23:0]
                    };                                
                    

//---------
//SYST_CVR 0xe000e018
//---------
wire [31:0] syst_cvr =  {
                     8'b0,
                     timer_cnt
                    };              
                    
//---------
//SYST_CALIB 0xe000e01c
//---------
wire [31:0] syst_calib =  {
                     1'b1,
                     1'b1,
                     6'b0,
                     CALIB_10MS_50MHZ
                    };           

//---------
//CPUID 0xe000ed00
//---------

//---------
//ICSR 0xe000ed04
//---------
wire isrpreempt = nmi_pend | hardfault_pend | svcall_pend | pendsv_pend | systick_pend | (|irq_pend);
wire isrpending = (|irq_pend);
wire [8:0] vectpending = {3'b0, exception_req_num[5:0]};
wire [8:0] vectactive  = {3'b0, exception_ack_num[5:0]};
wire [31:0] icsr = {
                    nmi_pend,
                    2'b00,
                    pendsv_pend,
                    1'b0, //pendsvclr,
                    systick_pend,
                    1'b0, //pendstclr,
                    1'b0,
                    isrpreempt,
                    isrpending,
                    vectpending,
                    3'b0,
                    vectactive
                    };

//---------
//AICSR 0xe000ed0c
//---------
wire [31:0] aircr = {
                     reged0c[31:16],
                     ENDIANESS,
                     15'b0
                    };


//---------
//SCR 0xe000ed10
//---------
wire [31:0] scr =  {
                     27'b0,
                     reged10[4],
                     1'b0,
                     reged10[2],
                     reged10[1],
                     1'b0
                    };

//---------
//CCR 0xe000ed14
//---------
wire [31:0] ccr =  {
                     22'b0,
                     1'b1,
                     5'b0,
                     1'b1,
                     3'b0
                    };
                    
//---------
//SHPR2 0xe000ed1c
//---------
wire [31:0] shpr2 =  {
                     pri_11,
                     30'b0
                    };

//---------
//SHPR3 0xe000ed20
//---------
wire [31:0] shpr3 =  {
                     pri_15,
                     6'b0,
                     pri_14,
                     22'b0
                    };
                    
//---------
//SHCSR 0xe000ed24
//---------
wire [31:0] shcsr =  {
                     16'b0,
                     svcall_pend,
                     15'b0
                    };
              
                    
                    
                                        
//----------
//Read operation to registers
//---------
always @(posedge clk or negedge rst_n)
begin
  if(!rst_n) 
  begin 
     hrdata <= 32'b0;
  end 
  //AHB BUS read register
  else if(ahb_rd_flg)
  begin 
    case(ahb_rd_addr) 
       //SysControl
        16'he008: hrdata <=  rege008;
        16'hed00: hrdata <=  reged00;
        16'hed04: hrdata <=  icsr;
        16'hed0c: hrdata <=  aircr;
        16'hed10: hrdata <=  scr;
        16'hed14: hrdata <=  ccr;
        16'hed1c: hrdata <=  shpr2;
        16'hed20: hrdata <=  shpr3;
        16'hed24: hrdata <=  shcsr;
        //SysTic
        16'he010: hrdata <=  syst_csr;
        16'he014: hrdata <=  syst_rvr;
        16'he018: hrdata <=  syst_cvr;
        16'he01c: hrdata <=  syst_calib;            
        //NVIC  
        16'he100:  hrdata <= irq_enab ;
        16'he180:  hrdata <= irq_enab ;
        16'he200:  hrdata <= irq_pend ;
        16'he280:  hrdata <= irq_pend ;
        16'he400:  hrdata <=  {irq_pri[7:6],   RSV6_0, irq_pri[5:4],   RSV6_0, irq_pri[3:2],   RSV6_0, irq_pri[1:0],   RSV6_0};
        16'he404:  hrdata <=  {irq_pri[15:14], RSV6_0, irq_pri[13:12], RSV6_0, irq_pri[11:10], RSV6_0, irq_pri[9:8],   RSV6_0};
        16'he408:  hrdata <=  {irq_pri[23:22], RSV6_0, irq_pri[21:20], RSV6_0, irq_pri[19:18], RSV6_0, irq_pri[17:16], RSV6_0};
        16'he40c:  hrdata <=  {irq_pri[31:30], RSV6_0, irq_pri[29:28], RSV6_0, irq_pri[27:26], RSV6_0, irq_pri[25:24], RSV6_0};
        16'he410:  hrdata <=  {irq_pri[39:38], RSV6_0, irq_pri[37:36], RSV6_0, irq_pri[35:34], RSV6_0, irq_pri[33:32], RSV6_0};
        16'he414:  hrdata <=  {irq_pri[47:46], RSV6_0, irq_pri[45:44], RSV6_0, irq_pri[43:42], RSV6_0, irq_pri[41:40], RSV6_0};
        16'he418:  hrdata <=  {irq_pri[55:54], RSV6_0, irq_pri[53:52], RSV6_0, irq_pri[51:50], RSV6_0, irq_pri[49:48], RSV6_0};
        16'he41c:  hrdata <=  {irq_pri[63:62], RSV6_0, irq_pri[61:60], RSV6_0, irq_pri[59:58], RSV6_0, irq_pri[57:56], RSV6_0};
                
        default: hrdata <= 32'b0;
    endcase
  end
end



//--------
//Control signals output. TBD.
//--------
assign  actlr = rege008;

//ofset_ed10
assign  sevonpend   = reged10[4];
assign  sleepdeep   = reged10[2];
assign  sleeponexit = reged10[1];








//============================================================
//
//System Tick function
//
//============================================================
                   
wire [23:0] reload_val  = rege014[23:0];

//timer counter
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
       timer_cnt  <= 24'b0;
    end
    else if (ahb_wr_flg && (ahb_wr_addr == 16'he018))
    begin 
       timer_cnt  <= 24'b0;
    end           
    else if (timer_cnt == 24'b0)
    begin 
       timer_cnt  <= reload_val;
    end                        
    else if (enable && ~core_halted)  //counter will be stopped when CPU is halted.
    begin
       timer_cnt <= timer_cnt - 1;
    end             
end


//interrupt. pulse of one cycle.    
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
       timer_cnt_dly  <= 24'b0;
    end
    else
    begin
       timer_cnt_dly  <= timer_cnt;
    end
end

assign syst_int = tickint & (timer_cnt_dly == 24'b1) & (timer_cnt == 24'b0);


//generate the countflag.
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
       countflag  <= 1'b0;
    end
    else if ((timer_cnt_dly == 24'b1) && (timer_cnt == 24'b0))
    begin
       countflag  <= 1'b1;
    end
    else if ((ahb_rd_flg && (ahb_rd_addr == 16'he010)) | (ahb_wr_flg && (ahb_wr_addr == 16'he018)))
    begin
       countflag  <= 1'b0;
    end
end    



//============================================================
//
//NVIC and exception_priority function
//
//============================================================

//decode the acknowledged irq.    
wire [31:0] tmp_irq_ack = irq_decode (exception_ack_num[5:0]);
//generate irq_pend register
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        irq_pend  <= 32'b0;
    end
    else if (ahb_wr_flg && (ahb_wr_addr == 16'he200)) //set pend
    begin 
        irq_pend <= irq_pend | hwdata;
    end  
    else if (ahb_wr_flg && (ahb_wr_addr == 16'he280))  //clr pend
    begin 
        irq_pend <= irq_pend & ~hwdata;
    end                    
    else if (exception_ack)  //IRQ acknowledged from CPU. clear the pend
    begin 
       irq_pend  <= irq_pend & (~tmp_irq_ack);
    end                     
    else if (vectclractive)  //vector clear
    begin 
       irq_pend  <= 32'b0;
    end                     
    else    //latch the input IRQ.
    begin
       irq_pend <= irq_pend | irq;
    end             
end



//=========================================
//Generate exception_req and exception_req_num.
//1. find out the highest priority exception for configurable exceptions.
//rule: pri_reg == 2'b00, highest level; 2'b11, lowest level. 
//rule: exception[0], highest priority; exception[34], lowest priority.
//2. code the exception to 6bit.
//==========================================
wire [69:0] exception_pri = {irq_pri, pri_15, pri_14, pri_11};
wire [34:0] exception_pri_level0 = {
                                              (exception_pri[69:68] == 2'b00), (exception_pri[67:66] == 2'b00),  (exception_pri[65:64] == 2'b00),
             (exception_pri[63:62] == 2'b00), (exception_pri[61:60] == 2'b00), (exception_pri[59:58] == 2'b00),  (exception_pri[57:56] == 2'b00),
             (exception_pri[55:54] == 2'b00), (exception_pri[53:52] == 2'b00), (exception_pri[51:50] == 2'b00),  (exception_pri[49:48] == 2'b00),
             (exception_pri[47:46] == 2'b00), (exception_pri[45:44] == 2'b00), (exception_pri[43:42] == 2'b00),  (exception_pri[41:40] == 2'b00),
             (exception_pri[39:38] == 2'b00), (exception_pri[37:36] == 2'b00), (exception_pri[35:34] == 2'b00),  (exception_pri[33:32] == 2'b00),
             (exception_pri[31:30] == 2'b00), (exception_pri[29:28] == 2'b00), (exception_pri[27:26] == 2'b00),  (exception_pri[25:24] == 2'b00),
             (exception_pri[23:22] == 2'b00), (exception_pri[21:20] == 2'b00), (exception_pri[19:18] == 2'b00),  (exception_pri[17:16] == 2'b00),
             (exception_pri[15:14] == 2'b00), (exception_pri[13:12] == 2'b00), (exception_pri[11:10] == 2'b00),  (exception_pri[9:8]   == 2'b00),
             (exception_pri[7:6]   == 2'b00), (exception_pri[5:4]   == 2'b00), (exception_pri[3:2]   == 2'b00),  (exception_pri[1:0]   == 2'b00)   
             };

wire [34:0] exception_pri_level1 = {
                                              (exception_pri[69:68] == 2'b01), (exception_pri[67:66] == 2'b01),  (exception_pri[65:64] == 2'b01),
             (exception_pri[63:62] == 2'b01), (exception_pri[61:60] == 2'b01), (exception_pri[59:58] == 2'b01),  (exception_pri[57:56] == 2'b01),
             (exception_pri[55:54] == 2'b01), (exception_pri[53:52] == 2'b01), (exception_pri[51:50] == 2'b01),  (exception_pri[49:48] == 2'b01),
             (exception_pri[47:46] == 2'b01), (exception_pri[45:44] == 2'b01), (exception_pri[43:42] == 2'b01),  (exception_pri[41:40] == 2'b01),
             (exception_pri[39:38] == 2'b01), (exception_pri[37:36] == 2'b01), (exception_pri[35:34] == 2'b01),  (exception_pri[33:32] == 2'b01),
             (exception_pri[31:30] == 2'b01), (exception_pri[29:28] == 2'b01), (exception_pri[27:26] == 2'b01),  (exception_pri[25:24] == 2'b01),
             (exception_pri[23:22] == 2'b01), (exception_pri[21:20] == 2'b01), (exception_pri[19:18] == 2'b01),  (exception_pri[17:16] == 2'b01),
             (exception_pri[15:14] == 2'b01), (exception_pri[13:12] == 2'b01), (exception_pri[11:10] == 2'b01),  (exception_pri[9:8]   == 2'b01),
             (exception_pri[7:6]   == 2'b01), (exception_pri[5:4]   == 2'b01), (exception_pri[3:2]   == 2'b01),  (exception_pri[1:0]   == 2'b01)   
             };

wire [34:0] exception_pri_level2 = {
                                              (exception_pri[69:68] == 2'b10), (exception_pri[67:66] == 2'b10),  (exception_pri[65:64] == 2'b10),
             (exception_pri[63:62] == 2'b10), (exception_pri[61:60] == 2'b10), (exception_pri[59:58] == 2'b10),  (exception_pri[57:56] == 2'b10),
             (exception_pri[55:54] == 2'b10), (exception_pri[53:52] == 2'b10), (exception_pri[51:50] == 2'b10),  (exception_pri[49:48] == 2'b10),
             (exception_pri[47:46] == 2'b10), (exception_pri[45:44] == 2'b10), (exception_pri[43:42] == 2'b10),  (exception_pri[41:40] == 2'b10),
             (exception_pri[39:38] == 2'b10), (exception_pri[37:36] == 2'b10), (exception_pri[35:34] == 2'b10),  (exception_pri[33:32] == 2'b10),
             (exception_pri[31:30] == 2'b10), (exception_pri[29:28] == 2'b10), (exception_pri[27:26] == 2'b10),  (exception_pri[25:24] == 2'b10),
             (exception_pri[23:22] == 2'b10), (exception_pri[21:20] == 2'b10), (exception_pri[19:18] == 2'b10),  (exception_pri[17:16] == 2'b10),
             (exception_pri[15:14] == 2'b10), (exception_pri[13:12] == 2'b10), (exception_pri[11:10] == 2'b10),  (exception_pri[9:8]   == 2'b10),
             (exception_pri[7:6]   == 2'b10), (exception_pri[5:4]   == 2'b10), (exception_pri[3:2]   == 2'b10),  (exception_pri[1:0]   == 2'b10)   
             };

wire [34:0] exception_pri_level3 = {
                                              (exception_pri[69:68] == 2'b11), (exception_pri[67:66] == 2'b11),  (exception_pri[65:64] == 2'b11),
             (exception_pri[63:62] == 2'b11), (exception_pri[61:60] == 2'b11), (exception_pri[59:58] == 2'b11),  (exception_pri[57:56] == 2'b11),
             (exception_pri[55:54] == 2'b11), (exception_pri[53:52] == 2'b11), (exception_pri[51:50] == 2'b11),  (exception_pri[49:48] == 2'b11),
             (exception_pri[47:46] == 2'b11), (exception_pri[45:44] == 2'b11), (exception_pri[43:42] == 2'b11),  (exception_pri[41:40] == 2'b11),
             (exception_pri[39:38] == 2'b11), (exception_pri[37:36] == 2'b11), (exception_pri[35:34] == 2'b11),  (exception_pri[33:32] == 2'b11),
             (exception_pri[31:30] == 2'b11), (exception_pri[29:28] == 2'b11), (exception_pri[27:26] == 2'b11),  (exception_pri[25:24] == 2'b11),
             (exception_pri[23:22] == 2'b11), (exception_pri[21:20] == 2'b11), (exception_pri[19:18] == 2'b11),  (exception_pri[17:16] == 2'b11),
             (exception_pri[15:14] == 2'b11), (exception_pri[13:12] == 2'b11), (exception_pri[11:10] == 2'b11),  (exception_pri[9:8]   == 2'b11),
             (exception_pri[7:6]   == 2'b11), (exception_pri[5:4]   == 2'b11), (exception_pri[3:2]   == 2'b11),  (exception_pri[1:0]   == 2'b11)   
             };

wire [34:0] exception_pend = {irq_pend, systick_pend, pendsv_pend, svcall_pend};
wire [34:0] exception_enab = {irq_enab, 1'b1, 1'b1, 1'b1};
wire [34:0] tmp_exception_irq_level0 = exception_pend & exception_enab & exception_pri_level0;
wire [34:0] tmp_exception_irq_level1 = exception_pend & exception_enab & exception_pri_level1;
wire [34:0] tmp_exception_irq_level2 = exception_pend & exception_enab & exception_pri_level2;
wire [34:0] tmp_exception_irq_level3 = exception_pend & exception_enab & exception_pri_level3;

//During reset, all exceptions are blocked.
always @ *
begin    
    if (reset_trap)                      //fixed level -3
        tmp_exception_req_num = {3'b111, 6'h00}; //{3'b000, 6'h01};
    else if (nmi_pend)                   //fixed level -2
        tmp_exception_req_num = {3'b001, 6'h02};
    else if (hardfault_pend)             //fixed level -1 
        tmp_exception_req_num = {3'b010, 6'h03}; 
    else if (|tmp_exception_irq_level0)  //configurable level0
        tmp_exception_req_num = {3'b011, exception_priority (tmp_exception_irq_level0)}; 
    else if (|tmp_exception_irq_level1)  //configurable level1
        tmp_exception_req_num = {3'b100, exception_priority (tmp_exception_irq_level1)};
    else if (|tmp_exception_irq_level2)  //configurable level2
        tmp_exception_req_num = {3'b101, exception_priority (tmp_exception_irq_level2)};
    else if (|tmp_exception_irq_level3)  //configurable level3
        tmp_exception_req_num = {3'b110, exception_priority (tmp_exception_irq_level3)};
    else                                //no exception.
        tmp_exception_req_num = 9'b111_000_000;
end

//output req_num and req_vector
// always @(posedge clk or negedge rst_n)
// begin
//     if (!rst_n)
//     begin
//         exception_req_num    <= 9'b111_000_000;
//         exception_req_vector <= 8'h0;
//         exception_req        <= 1'b0;
//     end
//     else
//     begin 
//         exception_req_num    <= tmp_exception_req_num;  
//         exception_req_vector <= {tmp_exception_req_num[5:0], 2'b00};
//         exception_req        <= (tmp_exception_req_num != exception_req_num);
//  //       exception_req        <= (tmp_exception_req_num != exception_req_num) & (tmp_exception_req_num != 9'b111_000_000);
//     end
// end  
//--------------
//change exception req 20150602
//during the period of core_halted, the exception should be held on.
//-------------- 
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        exception_req_num    <= 9'b111_000_000;
        exception_req_vector <= 8'h0;
        exception_req        <= 1'b0;
    end
    else
    begin 
        exception_req_num    <= core_halted ? exception_req_num : 
		                                      tmp_exception_req_num;  
        exception_req_vector <= core_halted ? exception_req_vector : 
		                                     {tmp_exception_req_num[5:0], 2'b00};
        exception_req        <= core_halted ? 1'b0 : 
		                                     (tmp_exception_req_num != exception_req_num);
    end
end


//=======================
//Functions and utilities
//=======================
function [5:0] exception_priority;
input [34:0] exception;
begin
       if       (exception[0] )  exception_priority = 6'd11;   //SVCall  
       else if  (exception[1] )  exception_priority = 6'd14;   //pendSV  
       else if  (exception[2] )  exception_priority = 6'd15;   //SysTick 
       else if  (exception[3] )  exception_priority = 6'd16;   //IRQ0    
       else if  (exception[4] )  exception_priority = 6'd17;   //IRQ1    
       else if  (exception[5] )  exception_priority = 6'd18;   //IRQ2    
       else if  (exception[6] )  exception_priority = 6'd19;   //IRQ3    
       else if  (exception[7] )  exception_priority = 6'd20;   //IRQ4    
       else if  (exception[8] )  exception_priority = 6'd21;   //IRQ5    
       else if  (exception[9] )  exception_priority = 6'd22;   //IRQ6    
       else if  (exception[10])  exception_priority = 6'd23;   //IRQ7    
       else if  (exception[11])  exception_priority = 6'd24;   //IRQ8    
       else if  (exception[12])  exception_priority = 6'd25;   //IRQ9    
       else if  (exception[13])  exception_priority = 6'd26;   //IRQ10   
       else if  (exception[14])  exception_priority = 6'd27;   //IRQ11   
       else if  (exception[15])  exception_priority = 6'd28;   //IRQ12   
       else if  (exception[16])  exception_priority = 6'd29;   //IRQ13   
       else if  (exception[17])  exception_priority = 6'd30;   //IRQ14   
       else if  (exception[18])  exception_priority = 6'd31;   //IRQ15   
       else if  (exception[19])  exception_priority = 6'd32;   //IRQ16   
       else if  (exception[20])  exception_priority = 6'd33;   //IRQ17   
       else if  (exception[21])  exception_priority = 6'd34;   //IRQ18   
       else if  (exception[22])  exception_priority = 6'd35;   //IRQ19   
       else if  (exception[23])  exception_priority = 6'd36;   //IRQ20   
       else if  (exception[24])  exception_priority = 6'd37;   //IRQ21   
       else if  (exception[25])  exception_priority = 6'd38;   //IRQ22   
       else if  (exception[26])  exception_priority = 6'd39;   //IRQ23   
       else if  (exception[27])  exception_priority = 6'd40;   //IRQ24   
       else if  (exception[28])  exception_priority = 6'd41;   //IRQ25   
       else if  (exception[29])  exception_priority = 6'd42;   //IRQ26   
       else if  (exception[30])  exception_priority = 6'd43;   //IRQ27   
       else if  (exception[31])  exception_priority = 6'd44;   //IRQ28   
       else if  (exception[32])  exception_priority = 6'd45;   //IRQ29   
       else if  (exception[33])  exception_priority = 6'd46;   //IRQ30   
       else if  (exception[34])  exception_priority = 6'd47;   //IRQ31   
       else                      exception_priority = 6'd0;    //No exception
end

endfunction



function [31:0] irq_decode ;
input [5:0] irq_irl;
begin
    if      (irq_irl == 6'd0)   irq_decode = 32'h0000_0000;
    else if (irq_irl == 6'd16)  irq_decode = 32'h0000_0001;
    else if (irq_irl == 6'd17)  irq_decode = 32'h0000_0002;
    else if (irq_irl == 6'd18)  irq_decode = 32'h0000_0004;
    else if (irq_irl == 6'd19)  irq_decode = 32'h0000_0008;
    else if (irq_irl == 6'd20)  irq_decode = 32'h0000_0010;
    else if (irq_irl == 6'd21)  irq_decode = 32'h0000_0020;
    else if (irq_irl == 6'd22)  irq_decode = 32'h0000_0040;
    else if (irq_irl == 6'd23)  irq_decode = 32'h0000_0080;
    else if (irq_irl == 6'd24)  irq_decode = 32'h0000_0100;
    else if (irq_irl == 6'd25)  irq_decode = 32'h0000_0200;
    else if (irq_irl == 6'd26)  irq_decode = 32'h0000_0400;
    else if (irq_irl == 6'd27)  irq_decode = 32'h0000_0800;
    else if (irq_irl == 6'd28)  irq_decode = 32'h0000_1000;
    else if (irq_irl == 6'd29)  irq_decode = 32'h0000_2000;
    else if (irq_irl == 6'd30)  irq_decode = 32'h0000_4000;
    else if (irq_irl == 6'd31)  irq_decode = 32'h0000_8000;
    else if (irq_irl == 6'd32)  irq_decode = 32'h0001_0000;
    else if (irq_irl == 6'd33)  irq_decode = 32'h0002_0000;
    else if (irq_irl == 6'd34)  irq_decode = 32'h0004_0000;
    else if (irq_irl == 6'd35)  irq_decode = 32'h0008_0000;
    else if (irq_irl == 6'd36)  irq_decode = 32'h0010_0000;
    else if (irq_irl == 6'd37)  irq_decode = 32'h0020_0000;
    else if (irq_irl == 6'd38)  irq_decode = 32'h0040_0000;
    else if (irq_irl == 6'd39)  irq_decode = 32'h0080_0000;
    else if (irq_irl == 6'd40)  irq_decode = 32'h0100_0000;
    else if (irq_irl == 6'd41)  irq_decode = 32'h0200_0000;
    else if (irq_irl == 6'd42)  irq_decode = 32'h0400_0000;
    else if (irq_irl == 6'd43)  irq_decode = 32'h0800_0000;
    else if (irq_irl == 6'd44)  irq_decode = 32'h1000_0000;
    else if (irq_irl == 6'd45)  irq_decode = 32'h2000_0000;
    else if (irq_irl == 6'd46)  irq_decode = 32'h4000_0000;
    else if (irq_irl == 6'd47)  irq_decode = 32'h8000_0000;
    else                        irq_decode = 32'h0000_0000;
end                          

endfunction

    

endmodule

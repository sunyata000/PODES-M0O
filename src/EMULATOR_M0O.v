
//************************************************************************//
//PODES:    Processor Optimization for Deeply Embedded System                                                                 
//Web:      www.mcucore.club                          
//Bug:      sunyata.peng@foxmail.com                                                                          
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
// File        : EMULATOR_M0O.v
// Author      : PODES
// Date        : 20200101
// Version     : 1.0
// Description : PODES emulator.
//               Disassembly the instructions.
// -----------------------------History-----------------------------------//
// Date      BY   Version  Change Description
//
// 20200101  PODES   1.0      Initial Release. 
// 20200110  PODES   1.1      Remove some unnecessary registers.
//                                                                        
//************************************************************************//
// --- CVS information:
// ---    $Author: $
// ---    $Revision: $
// ---    $Id: $
// ---    $Log$ 
//
//************************************************************************//

`timescale 1ps/1ps

module EMULATOR_M0O  (
                clk,
                rst_n,
                ie_bsy,
				optype,
                exception_entry,
                exception_req_num,
                
                
                rtl_R0 ,
                rtl_R1 ,
                rtl_R2 ,
                rtl_R3 ,
                rtl_R4 ,
                rtl_R5 ,
                rtl_R6 ,
                rtl_R7 ,
                rtl_R8 ,
                rtl_R9 ,
                rtl_R10,
                rtl_R11,
                rtl_R12,
                rtl_SP ,
                rtl_LR ,
                rtl_PC ,
                rtl_xPSR,
                rtl_PRIMASK,
                rtl_CONTROL
                
                );
				
parameter ROM_SIZE = 4096;
parameter RAM_SIZE = 4096;
parameter PERI_SIZE = 4096;
//-----------------------------------------------------------//
//                      INPUTS, OUTPUT                       //
//-----------------------------------------------------------//                                 
input        clk;
input        rst_n;  
input        ie_bsy;
input [4:0]  optype;
input       exception_entry;
input [8:0] exception_req_num;

input [31:0] rtl_R0 ;
input [31:0] rtl_R1 ;
input [31:0] rtl_R2 ;
input [31:0] rtl_R3 ;
input [31:0] rtl_R4 ;
input [31:0] rtl_R5 ;
input [31:0] rtl_R6 ;
input [31:0] rtl_R7 ;
input [31:0] rtl_R8 ;
input [31:0] rtl_R9 ;
input [31:0] rtl_R10;
input [31:0] rtl_R11;
input [31:0] rtl_R12;
input [31:0] rtl_SP ;
input [31:0] rtl_LR ;
input [31:0] rtl_PC ;
input [31:0] rtl_xPSR;
input [31:0] rtl_PRIMASK;
input [31:0] rtl_CONTROL;
        

//synopsys translate_off
 parameter STEP_DLY = 1ns;   
        
      
wire        APSR_N  = rtl_xPSR[31];
wire        APSR_Z  = rtl_xPSR[30];
wire        APSR_C  = rtl_xPSR[29];
wire        APSR_V  = rtl_xPSR[28];
wire        EPSR_T  = rtl_xPSR[24];
wire [8:0]  IPSR    = rtl_xPSR[8:0];

wire        PRIMASK_flag  = rtl_PRIMASK[0];
wire        act_SP = rtl_CONTROL[1];  
        
//============================================================
// Build up runtime environment for  emulator.
// The size of ROM, RAM, Registers should be same as that of real CPU
//============================================================

//--------------------------------------------------
// Open ROM memory and copy the instructions.
//--------------------------------------------------
reg [31:0] rom_mem [0: ROM_SIZE-1]; 
integer inst_f;
initial
begin 
    #STEP_DLY;
    inst_f = $fopen("program.txt", "r");
    $readmemh("program.txt", rom_mem);
end




//============================================================
//                  Emulator Architecture                   //
//                                                          //
//============================================================



//These signals are internal variables for  lator.
integer    d, n, m, t;
integer    index;
integer i;
reg        setflags;
reg [2:0]  shift_t; 
integer    shift_n;
reg [31:0] shifted;
reg [31:0] offset;
reg [31:0] result;
reg        carry;
reg        overflow;
integer    add;

parameter SRType_LSL = 3'b000;
parameter SRType_LSR = 3'b001;
parameter SRType_ASR = 3'b010;
parameter SRType_ROR = 3'b011;
parameter SRType_RRX = 3'b100;

reg [31:0] tmp_PC = 32'b0;
reg [31:0] read_addr = 32'b0;
reg [31:0] inst32 = 32'b0;
reg [15:0] inst = 16'b0;
reg [31:0] imm32 = 32'b0;
reg [31:0] branch_pc = 32'b0;
reg        branch_pc_flag = 1'b0;
reg [31:0] tmpR = 32'b0;
reg [31:0] branchwritepc = 32'b0;
reg        I1 = 1'b0;
reg        I2 = 1'b0;
reg [31:0] next_inst_addr = 32'b0;


reg [15:0] registers = 16'b0;
integer    wback = 0;
string     sub_str = "rx, ";
string     str ="";
string     stri = "";
integer    address = 0;
integer    registers_cnt = 0;
integer    offset_addr = 0;
integer    base = 0;

reg [31:0] tmp_data32 = 32'b0;
reg [7:0]  SYSm = 8'b0;

integer    rotation = 0;
reg [31:0] rotated = 32'b0;

reg [31:0] inst32s = 32'b0;
reg [31:0] inst_data = 32'b0;
reg        inst_calc_done = 0;
reg        peri_space_r = 1'b0 ;
reg        peri_space_w  = 1'b0;

//============================================================
// Open a logfile to store the disassembly code.
//============================================================
integer disasm_f;
initial
begin 
    #STEP_DLY;
    disasm_f = $fopen("disassembly.log", "w");
    $fdisplay(disasm_f, "[PC Value:]  [inst code:]  [ASM inst]");
end

//==================================================================================
//run the  lator, disassembly the instruction, compare the executing result.
//
//whenever PC changes, an instruction at address of (rtl_PC-4) is executed in RTL module. 
//At this time point,  lator will read out that instruction and calculate it, then 
//compare the result between RTL and Emulator. 
//==================================================================================
always @(rtl_PC)  
begin
    //Read out instruction from ROM file.
  #STEP_DLY;
	
  tmp_PC = rtl_PC -4; //inst_address.
  if(tmp_PC == 32'b0) 
    $fdisplay(disasm_f, "System Reset. DISASM starts from here."); 
  else
  begin  
    inst_data = Read_MemU(tmp_PC, 4);
    inst = (tmp_PC[1] ==1'b1)? inst_data[31:16] : inst_data[15:0];
    
	
    //parse the instruction
    if (inst[15:11] != 5'b11110) //16bit instruction.
    begin
//---------------------------------------------------------------------------------    
        if (inst[15:6] == 10'b010000_0101) //ADC(register)
        begin       
            d = inst[2:0]; n = inst[2:0]; m = inst[5:3]; setflags = 1;
            shift_t = SRType_LSL; shift_n = 0; 
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    ADCS        r%1d, r%1d, r%1d", (rtl_PC-4), inst, d, n, m);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:9] ==7'b000_11_1_0) //ADD(immediate) T1
        begin       
            d = inst[2:0]; n = inst[5:3]; setflags = 1; imm32 = {29'b0, inst[8:6]};
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    ADDS        r%1d, r%1d, #%1d", (rtl_PC-4), inst, d, n, imm32); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:11] ==5'b001_10) //ADD(immediate) T2
        begin       
            d = inst[10:8]; n = inst[10:8]; setflags = 1; imm32 = {24'b0, inst[7:0]};
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    ADDS        r%1d, r%1d, #%1d", (rtl_PC-4), inst, d, n, imm32);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:9] ==7'b000_11_0_0) //ADD(register) T1
        begin       
            d = inst[2:0]; n = inst[5:3]; m= inst[8:6]; setflags = 1; 
            shift_t = SRType_LSL; shift_n = 0; 
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    ADDS        r%1d, r%1d, #%1d", (rtl_PC-4), inst, d, n, m);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:8] ==8'b010001_00) //ADD(register) T2
        begin       
            d = {inst[7], inst[2:0]}; n = d; m= inst[6:3]; setflags = 0; 
            shift_t = SRType_LSL; shift_n = 0; 
            if((d == 15)&&(m == 15)) $display ("[DISASM_COMP] WARNING: UNPREDICTABLE. PC=%h.", tmp_PC);
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    ADDS        r%1d, r%1d, r%1d", (rtl_PC-4), inst, d, n, m); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:11] ==5'b1010_1) //ADD(SP plus immediate) T1
        begin       
            d = inst[10:8]; setflags = 0; imm32 = {22'b0, inst[7:0], 2'b00};
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    ADD         r%1d, SP, #%1d", (rtl_PC-4), inst, d, imm32);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:7] ==9'b1011_0000_0) //ADD(SP plus immediate) T2
        begin       
            d = 13; setflags = 0; imm32 = {23'b0, inst[6:0], 2'b00};
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    ADD         r%1d, SP, #%1d", (rtl_PC-4), inst, d, imm32);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if ({inst[15:8], inst[6:3]} == {8'b01000100, 4'b1101}) //ADD(SP plus register) T1
        begin       
            d = {inst[7], inst[2:0]}; m = {inst[7], inst[2:0]}; setflags = 0;
            shift_t = SRType_LSL; shift_n = 0; 
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    ADD         r%1d, SP, r%1d", (rtl_PC-4), inst, d, m); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if ({inst[15:7], inst[2:0]} == {9'b01000100_1, 3'b10_1}) //ADD(SP plus register) T2
        begin       
            d = 13; m = inst[6:3]; setflags = 0;
            shift_t = SRType_LSL; shift_n = 0; 
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    ADD         r%1d, SP, r%1d", (rtl_PC-4), inst, d, m);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:11] == 5'b1010_0) //ADR
        begin       
            d = inst[10:8]; imm32 = {22'b0, inst[7:0], 2'b00}; add = 1;
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    ADR         r%1d, PC, #%1d", (rtl_PC-4), inst, d, imm32);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:6]== 10'b010000_0000) //AND(register) 
        begin       
            d = inst[2:0]; n = inst[2:0]; m = inst[5:3]; setflags = 1;
            shift_t = SRType_LSL; shift_n = 0; 
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    ANDS        r%1d, r%1d, r%1d", (rtl_PC-4), inst, d, n, m); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:11]== 5'b000_10) //ASR(immediate) 
        begin       
            d = inst[2:0]; m = inst[5:3]; setflags = 1;
            {shift_t, shift_n[5:0]} = DecodeImmShift(2'b10, inst[10:6]); 
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    ASRS        r%1d, r%1d, #%1d", (rtl_PC-4), inst, d, m, inst[10:6]);
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:6]== 10'b010000_0100) //ASR(register) 
        begin       
            d = inst[2:0]; n = inst[2:0]; m = inst[5:3]; setflags = 1;
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    ASRS        r%1d, r%1d, r%1d", (rtl_PC-4), inst, d, n, m);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:12]== 4'b1101) //B T1
        begin       
            imm32 = {{23{inst[7]}}, inst[7:0], 1'b0}; 
    //Output dis-assembly instruction.
            if((inst[11:8] == 4'b0000) && APSR_Z )
            begin
                $fdisplay(disasm_f, "%8h:  %8h    BEQ         #0x%1h ", (rtl_PC-4), inst, (rtl_PC+imm32));  
            end
            if((inst[11:8] == 4'b0001) && !APSR_Z )
            begin
                $fdisplay(disasm_f, "%8h:  %8h    BNE         #0x%1h ", (rtl_PC-4), inst, (rtl_PC+imm32)); 
            end
            if((inst[11:8] == 4'b0010) && APSR_C )
            begin
                $fdisplay(disasm_f, "%8h:  %8h    BCS         #0x%1h ", (rtl_PC-4), inst, (rtl_PC+imm32));  
            end
            if((inst[11:8] == 4'b0011) && !APSR_C )
            begin
                $fdisplay(disasm_f, "%8h:  %8h    BCC         #0x%1h ", (rtl_PC-4), inst, (rtl_PC+imm32));  
            end
            if((inst[11:8] == 4'b0100) && APSR_N )
            begin
                $fdisplay(disasm_f, "%8h:  %8h    BMI         #0x%1h ", (rtl_PC-4), inst, (rtl_PC+imm32));  
            end
            if((inst[11:8] == 4'b0101) && !APSR_N )
            begin
                $fdisplay(disasm_f, "%8h:  %8h    BPL         #0x%1h ", (rtl_PC-4), inst, (rtl_PC+imm32)); 
            end
            if((inst[11:8] == 4'b0110) && APSR_V )
            begin
                $fdisplay(disasm_f, "%8h:  %8h    BVS         #0x%1h ", (rtl_PC-4), inst, (rtl_PC+imm32)); 
            end
            if((inst[11:8] == 4'b0111) && !APSR_V )
            begin
                $fdisplay(disasm_f, "%8h:  %8h    BVC         #0x%1h ", (rtl_PC-4), inst, (rtl_PC+imm32));
            end
            if((inst[11:8] == 4'b1000) && (APSR_C  && !APSR_Z ))
            begin
                $fdisplay(disasm_f, "%8h:  %8h    BHI         #0x%1h ", (rtl_PC-4), inst, (rtl_PC+imm32)); 
            end
            if((inst[11:8] == 4'b1001) && (!APSR_C  || APSR_Z ))
            begin
                $fdisplay(disasm_f, "%8h:  %8h    BLS         #0x%1h ", (rtl_PC-4), inst, (rtl_PC+imm32)); 
            end
            if((inst[11:8] == 4'b1010) && (APSR_N  == APSR_V ))
            begin
                $fdisplay(disasm_f, "%8h:  %8h    BGE         #0x%1h ", (rtl_PC-4), inst, (rtl_PC+imm32)); 
            end
            if((inst[11:8] == 4'b1011) && (APSR_N  != APSR_V ))
            begin
                $fdisplay(disasm_f, "%8h:  %8h    BLT         #0x%1h ", (rtl_PC-4), inst, (rtl_PC+imm32)); 
            end
            if((inst[11:8] == 4'b1100) && (!APSR_Z  && (APSR_N  == APSR_V )))
            begin
                $fdisplay(disasm_f, "%8h:  %8h    BGT         #0x%1h ", (rtl_PC-4), inst, (rtl_PC+imm32));  
            end
            if((inst[11:8] == 4'b1101) && (APSR_Z  || (APSR_N  != APSR_V )))
            begin
                $fdisplay(disasm_f, "%8h:  %8h    BLE         #0x%1h ", (rtl_PC-4), inst, (rtl_PC+imm32));  
            end
            if(inst[11:8] == 4'b1110)
            begin
                $fdisplay(disasm_f, "%8h:  %8h    BLE         #0x%1h ", (rtl_PC-4), inst, (rtl_PC+imm32)); 
            end
        
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:11]== 5'b11100) //B T2
        begin       
            imm32 = {{20{inst[10]}}, inst[10:0], 1'b0}; 
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    B           #0x%1h ", (rtl_PC-4), inst, (rtl_PC+imm32));  
        end
//---------------------------------------------------------------------------------------    
    
//---------------------------------------------------------------------------------------    
        else if (inst[15:6]== 10'b010000_1110) //BIC(register) 
        begin       
            d = inst[2:0]; n = inst[2:0]; m = inst[5:3]; setflags = 1;
            shift_t = SRType_LSL; shift_n = 0;
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    BIC         r%1d, r%1d, r%1d", (rtl_PC-4), inst, d, n, m);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:8]== 8'b1011_1110) //BKPT 
        begin       
            imm32 = {24'b0, inst[7:0]};
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    BKPT        #%1d", (rtl_PC-4), inst, imm32);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:7]== 9'b010001_11_1) //BLX (register) 
        begin       
            m = inst[6:3];
            if((m == 15)) $display ("[DISASM_COMP] WARNING: UNPREDICTABLE. PC=%h.", tmp_PC);
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    BLX         r%1d", (rtl_PC-4), inst, m);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:7]== 9'b010001_11_0) //BX 
        begin       
            m = inst[6:3];
            if((m == 15)) $display ("[DISASM_COMP] WARNING: UNPREDICTABLE. PC=%h.", tmp_PC);
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    BX          r%1d", (rtl_PC-4), inst, m);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:6]== 10'b010000_1011) //CMN(register) 
        begin       
            n = inst[2:0]; m = inst[5:3]; 
            shift_t = SRType_LSL; shift_n = 0; 
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    CMN         r%1d, r%1d", (rtl_PC-4), inst, n, m);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:11]== 5'b001_01) //CMP(immediate) 
        begin       
            n = inst[10:8]; imm32 = {24'b0, inst[7:0]}; 
            shift_t = SRType_LSL; shift_n = 0; 
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    CMP         r%1d, #%1d", (rtl_PC-4), inst, n, imm32); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:6]== 10'b010000_1010) //CMP(register) T1
        begin       
            n = inst[2:0]; m = inst[5:3]; 
            shift_t = SRType_LSL; shift_n = 0; 
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    CMP         r%1d, r%1d", (rtl_PC-4), inst, n, m); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:8]== 8'b010001_01) //CMP(register) T2
        begin       
            n = {inst[7],inst[2:0]}; m = inst[6:3]; 
            shift_t = SRType_LSL; shift_n = 0; 
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    CMP         r%1d, r%1d", (rtl_PC-4), inst, n, m);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:5]== 11'b1011_0110_011) //CPS
        begin       
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    CPS         #%1d", (rtl_PC-4), inst, inst[1]);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:6]== 10'b010000_0001) //EOR(register) 
        begin       
            d = inst[2:0]; n = inst[2:0]; m = inst[5:3]; setflags = 1;
            shift_t = SRType_LSL; shift_n = 0; 
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    EORS        r%1d, r%1d, r%1d", (rtl_PC-4), inst, d, n, m); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:11]== 5'b1100_1) //LDM/LDMIA/LDMFD 
        begin       
            n = inst[10:8]; registers = {8'b0, inst[7:0]}; wback = (registers[n] == 1'b0);
    //Output dis-assembly instruction.
            str = "";
            for (i = 0; i<8; i=i+1) 
            begin
              if (registers[i]) begin
                 stri.itoa(i);
                 sub_str = {"r", stri}; //
                 if (str.len()) str = {str, ", ", sub_str}; else str = {str, sub_str};
              end
            end
            if (wback) str = {"!, {", str, "}"}; else str = {", {", str, "}"};
            $fdisplay(disasm_f, "%8h:  %8h    LDM         r%1d%s", (rtl_PC-4), inst, n, str);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:11]== 5'b011_0_1) //LDR (immediate) T1
        begin       
            t = inst[2:0]; n = inst[5:3]; imm32 = {25'b0, inst[10:6], 2'b00}; 
            index = 1; add = 1; wback = 0;
    //Output dis-assembly instruction.
            if ((index) && (add))
              $fdisplay(disasm_f, "%8h:  %8h    LDR         r%1d, [r%1d, #+%1d]", (rtl_PC-4), inst, t, n, imm32); 
            else if ((index) && (!add))
              $fdisplay(disasm_f, "%8h:  %8h    LDR         r%1d, [r%1d, #-%1d]", (rtl_PC-4), inst, t, n, imm32);
            else 
              $fdisplay(disasm_f, "%8h:  %8h    LDR         r%1d, [r%1d]", (rtl_PC-4), inst, t, n);   
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:11]== 5'b1001_1) //LDR (immediate) T2
        begin       
            t = inst[10:8]; n = 13; imm32 = {22'b0, inst[7:0], 2'b00}; 
            index = 1; add = 1; wback = 0;
    //Output dis-assembly instruction.
            if ((index) && (add))
              $fdisplay(disasm_f, "%8h:  %8h    LDR         r%1d, [r%1d, #+%1d]", (rtl_PC-4), inst, t, n, imm32); 
            else if ((index) && (!add))
              $fdisplay(disasm_f, "%8h:  %8h    LDR         r%1d, [r%1d, #-%1d]", (rtl_PC-4), inst, t, n, imm32);
            else  
              $fdisplay(disasm_f, "%8h:  %8h    LDR         r%1d, [r%1d]", (rtl_PC-4), inst, t, n); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:11]== 5'b01001) //LDR (literal)  
        begin       
            t = inst[10:8]; imm32 = {22'b0, inst[7:0], 2'b00}; add = 1; 
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    LDR         r%1d, [PC, #%1d]", (rtl_PC-4), inst, t, imm32); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:9]== 7'b0101_100) //LDR (register)  
        begin       
            t = inst[2:0]; n = inst[5:3]; m = inst[8:6]; 
            index = 1; add = 1; wback = 0;
            shift_t = SRType_LSL; shift_n = 0;
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    LDR         r%1d, [r%1d, r%1d]", (rtl_PC-4), inst, t, n, m);
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:11]== 5'b011_1_1) //LDRB (immediate)  
        begin       
            t = inst[2:0]; n = inst[5:3]; imm32 = {27'b0, inst[10:6]}; 
            index = 1; add = 1; wback = 0;
    //Output dis-assembly instruction.
            if ((index) && (add))
              $fdisplay(disasm_f, "%8h:  %8h    LDRB        r%1d, [r%1d, #+%1d]", (rtl_PC-4), inst, t, n, imm32); 
            else if ((index) && (!add))
              $fdisplay(disasm_f, "%8h:  %8h    LDRB        r%1d, [r%1d, #-%1d]", (rtl_PC-4), inst, t, n, imm32);
            else  
              $fdisplay(disasm_f, "%8h:  %8h    LDRB        r%1d, [r%1d]", (rtl_PC-4), inst, t, n);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:9]== 7'b0101_110) //LDRB (register)  
        begin       
            t = inst[2:0];  n = inst[5:3]; m = inst[8:6]; 
            index = 1; add = 1; wback = 0;
            shift_t = SRType_LSL; shift_n = 0;
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    LDRB        r%1d, [r%1d, r%1d]", (rtl_PC-4), inst, t, n, m);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:11]== 5'b1000_1) //LDRH (immediate)  
        begin       
            t = inst[2:0]; n = inst[5:3]; imm32 = {26'b0, inst[10:6], 1'b0}; 
            index = 1; add = 1; wback = 0;
    //Output dis-assembly instruction.
            if ((index) && (add))
              $fdisplay(disasm_f, "%8h:  %8h    LDRH        r%1d, [r%1d, #+%1h]", (rtl_PC-4), inst, t, n, imm32); 
            else if ((index) && (!add))
              $fdisplay(disasm_f, "%8h:  %8h    LDRH        r%1d, [r%1d, #-%1h]", (rtl_PC-4), inst, t, n, imm32);
            else 
              $fdisplay(disasm_f, "%8h:  %8h    LDRH        r%1d, [r%1d]", (rtl_PC-4), inst, t, n);      
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:9]== 7'b0101_101) //LDRH (register)  
        begin       
            t = inst[2:0]; n = inst[5:3]; m = inst[8:6]; 
            index = 1; add = 1; wback = 0;
            shift_t = SRType_LSL; shift_n = 0;
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    LDRH        r%1d, [r%1d, r%1d]", (rtl_PC-4), inst, t, n, m); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:9]== 7'b0101_011) //LDRSB (register)  
        begin       
            t = inst[2:0]; n = inst[5:3]; m = inst[8:6]; 
            index = 1; add = 1; wback = 0;
            shift_t = SRType_LSL; shift_n = 0;
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    LDRSB       r%1d, [r%1d, r%1d]", (rtl_PC-4), inst, t, n, m); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:9]== 7'b0101_111) //LDRSH (register)  
        begin       
            t = inst[2:0]; n = inst[5:3]; m = inst[8:6]; 
            index = 1; add = 1; wback = 0;
            shift_t = SRType_LSL; shift_n = 0;
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    LDRSH       r%1d, [r%1d, r%1d]", (rtl_PC-4), inst, t, n, m); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:11]== 5'b000_00) //LSL (immediate)  
        begin       
            d = inst[2:0];  m = inst[5:3]; setflags = 1; 
            {shift_t, shift_n[5:0]} = DecodeImmShift(2'b00, inst[10:6]);
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    LSLS        r%1d, r%1d, #%1d", (rtl_PC-4), inst, d, m, inst[10:6]); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:6]== 10'b010000_0010) //LSL (register)  
        begin       
            d = inst[2:0];  n = inst[2:0]; m = inst[5:3]; setflags = 1; 
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    LSLS        r%1d, r%1d, r%1d", (rtl_PC-4), inst, d, n, m);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:11]== 5'b000_01) //LSR (immediate)  
        begin       
            d = inst[2:0];  m = inst[5:3]; setflags = 1; 
            {shift_t, shift_n[5:0]} = DecodeImmShift(2'b01, inst[10:6]);
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    LSRS        r%1d, r%1d, #%1d", (rtl_PC-4), inst, d, m, inst[10:6]); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:6]== 10'b010000_0011) //LSR (register)  
        begin       
            d = inst[2:0];  n = inst[2:0]; m = inst[5:3]; setflags = 1; 
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    LSRS        r%1d, r%1d, r%1d", (rtl_PC-4), inst, d, n, m);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:11]== 5'b001_00) //MOV (immediate)  
        begin       
            d = inst[10:8];  setflags = 1; imm32 = {24'b0, inst[7:0]}; carry = APSR_C ;
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    MOVS        r%1d, #%1d", (rtl_PC-4), inst, d, imm32);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:8]== 8'b010001_10) //MOV (register) T1
        begin       
            d = {inst[7],inst[2:0]};  m = inst[6:3]; setflags = 0; 
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    MOV         r%1d, r%1d", (rtl_PC-4), inst, d, m);   
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:6]== 10'b000_00_00000) //MOV (register) T2
        begin       
            d = inst[2:0];  m = inst[5:3]; setflags = 1; 
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    MOVS        r%1d, r%1d", (rtl_PC-4), inst, d, m);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:6]== 10'b010000_1101) //MUL
        begin       
            d = inst[2:0];  m = inst[2:0]; n = inst[5:3]; setflags = 1; 
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    MULS        r%1d, r%1d, r%1d", (rtl_PC-4), inst, d, n, m); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:6]== 10'b010000_1111) //MVN (register)  
        begin       
            d = inst[2:0];  m = inst[5:3]; setflags = 1; 
            shift_t = SRType_LSL; shift_n = 0;
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    MNVS        r%1d, r%1d", (rtl_PC-4), inst, d, m);   
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst== 16'b1011_1111_0000_0000) //NOP 
        begin       
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    NOP         ", (rtl_PC-4), inst);    
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:6]== 10'b010000_1100) //ORR (register)  
        begin       
            d = inst[2:0]; n = inst[2:0]; m = inst[5:3]; setflags = 1; 
            shift_t = SRType_LSL; shift_n = 0;
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    ORRS        r%1d, r%1d, r%1d", (rtl_PC-4), inst, d, n, m);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:9]== 7'b1011_1_10) //POP  
        begin       
            registers = {inst[8], 7'b000_0000, inst[7:0]}; 
    //Output dis-assembly instruction.
            str = "";
            for (i = 0; i<8; i=i+1) 
            begin
              if (registers[i]) begin
                 stri.itoa(i);
                 sub_str = {"r", stri}; //
                 if (str.len()) str = {str, ", ", sub_str}; else str = {str, sub_str};
              end
            end
			if (registers[15]) str = {str, ", PC"};
            $fdisplay(disasm_f, "%8h:  %8h    POP         {%s}", (rtl_PC-4), inst, str);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:9]== 7'b1011_0_10) //PUSH  
        begin       
            registers = {1'b0, inst[8], 6'b00_0000, inst[7:0]}; 
    //Output dis-assembly instruction.
            str = "";
            for (i = 0; i<8; i=i+1) 
            begin
              if (registers[i]) begin
                 stri.itoa(i);
                 sub_str = {"r", stri}; //
                 if (str.len()) str = {str, ", ", sub_str}; else str = {str, sub_str};
              end
            end
			if (registers[14]) str = {str, ", LR"};
            $fdisplay(disasm_f, "%8h:  %8h    PUSH        {%s}", (rtl_PC-4), inst, str);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:6]== 10'b1011_101000) //REV  
        begin       
            d = inst[2:0]; m = inst[5:3];
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    REV         r%1d, r%1d", (rtl_PC-4), inst, d, m); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:6]== 10'b1011_1010_01) //REV16  
        begin       
            d = inst[2:0]; m = inst[5:3];
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    REV16       r%1d, r%1d", (rtl_PC-4), inst, d, m);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:6]== 10'b1011_1010_11) //REVSH  
        begin       
            d = inst[2:0]; m = inst[5:3];
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    REVSH       r%1d, r%1d", (rtl_PC-4), inst, d, m);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:6]== 10'b010000_0111) //ROR (register)  
        begin       
            d = inst[2:0]; n = inst[2:0]; m = inst[5:3]; setflags = 1; 
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    RORS        r%1d, r%1d, r%1d", (rtl_PC-4), inst, d, n, m); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:6]== 10'b010000_1001) //RSB (immediate)  
        begin       
            d = inst[2:0]; n = inst[5:3]; setflags = 1; imm32 = 32'b0; 
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    RSBS        r%1d, r%1d, #%1d", (rtl_PC-4), inst, d, n, imm32); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:6]== 10'b010000_0110) //SBC (register)  
        begin       
            d = inst[2:0]; n = inst[2:0]; m = inst[5:3]; setflags = 1;
            shift_t = SRType_LSL; shift_n = 0;			
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    SBCS        r%1d, r%1d, r%1d", (rtl_PC-4), inst, d, n, m);   
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst== 16'b1011_1111_0100_0000) //SEV 
        begin       
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    SEV         ", (rtl_PC-4), inst);    
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:11]== 5'b1100_0) //STM/STMIA/STMEA  
        begin       
            n = inst[10:8]; registers = {8'b0000_0000, inst[7:0]}; wback = 1;
    //Output dis-assembly instruction.
            str = "";
            for (i = 0; i<8; i=i+1) 
            begin
              if (registers[i]) begin
                 stri.itoa(i);
                 sub_str = {"r", stri}; //
                 if (str.len()) str = {str, ", ", sub_str}; else str = {str, sub_str};
              end
            end
            if (wback) str = {"!, {", str, "}"}; else str = {", {", str, "}"};
            $fdisplay(disasm_f, "%8h:  %8h    STM         r%1d%s", (rtl_PC-4), inst, n, str);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:11]== 5'b011_0_0) //STR (immediate) T1 
        begin       
            t = inst[2:0]; n = inst[5:3]; imm32 = {25'b0, inst[10:6], 2'b00};
			index = 1; add = 1; wback = 0;
    //Output dis-assembly instruction.
            if ((index) && (add))
              $fdisplay(disasm_f, "%8h:  %8h    STR         r%1d, [r%1d, #+%1d]", (rtl_PC-4), inst, t, n, imm32); 
            else if ((index) && (!add))
              $fdisplay(disasm_f, "%8h:  %8h    STR         r%1d, [r%1d, #-%1d]", (rtl_PC-4), inst, t, n, imm32);
            else   
              $fdisplay(disasm_f, "%8h:  %8h    STR         r%1d, [r%1d]", (rtl_PC-4), inst, t, n);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:11]== 5'b1001_0) //STR (immediate) T2 
        begin       
            t = inst[10:8]; n = 13; imm32 = {22'b0, inst[7:0], 2'b00};
			index = 1; add = 1; wback = 0;
    //Output dis-assembly instruction.
            if ((index) && (add))
              $fdisplay(disasm_f, "%8h:  %8h    STR         r%1d, [r%1d, #+%1d]", (rtl_PC-4), inst, t, n, imm32); 
            else if ((index) && (!add))
              $fdisplay(disasm_f, "%8h:  %8h    STR         r%1d, [r%1d, #-%1d]", (rtl_PC-4), inst, t, n, imm32);
            else  
              $fdisplay(disasm_f, "%8h:  %8h    STR         r%1d, [r%1d]", (rtl_PC-4), inst, t, n); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:9]== 7'b0101_000) //STR (register)   
        begin       
            t = inst[2:0]; n = inst[5:3]; m = inst[8:6];
			index = 1; add = 1; wback = 0;
			shift_t = SRType_LSL; shift_n = 0;
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    STR         r%1d, [r%1d, r%1d]", (rtl_PC-4), inst, t, n, m); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:11]== 5'b011_1_0) //STRB (immediate) 
        begin       
            t = inst[2:0]; n = inst[5:3]; imm32 = {27'b0, inst[10:6]};
			index = 1; add = 1; wback = 0;
    //Output dis-assembly instruction.
            if ((index) && (add))
              $fdisplay(disasm_f, "%8h:  %8h    STRB        r%1d, [r%1d, #+%1d]", (rtl_PC-4), inst, t, n, imm32); 
            else if ((index) && (!add))
              $fdisplay(disasm_f, "%8h:  %8h    STRB        r%1d, [r%1d, #-%1d]", (rtl_PC-4), inst, t, n, imm32);
            else  
              $fdisplay(disasm_f, "%8h:  %8h    STRB        r%1d, [r%1d]", (rtl_PC-4), inst, t, n); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:9]== 7'b0101_010) //STRB (register)   
        begin       
            t = inst[2:0]; n = inst[5:3]; m = inst[8:6];
			index = 1; add = 1; wback = 0;
			shift_t = SRType_LSL; shift_n = 0;
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    STRB        r%1d, [r%1d, r%1d]", (rtl_PC-4), inst, t, n, m);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:11]== 5'b1000_0) //STRH (immediate)   
        begin       
            t = inst[2:0]; n = inst[5:3]; imm32 = {26'b0, inst[10:6], 1'b0};
			index = 1; add = 1; wback = 0;
    //Output dis-assembly instruction.
            if ((index) && (add))
              $fdisplay(disasm_f, "%8h:  %8h    STRH        r%1d, [r%1d, #+%1d]", (rtl_PC-4), inst, t, n, imm32); 
            else if ((index) && (!add))
              $fdisplay(disasm_f, "%8h:  %8h    STRH        r%1d, [r%1d, #-%1d]", (rtl_PC-4), inst, t, n, imm32);
            else 
              $fdisplay(disasm_f, "%8h:  %8h    STRH        r%1d, [r%1d]", (rtl_PC-4), inst, t, n); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:9]== 7'b0101_001) //STRH (register)   
        begin       
            t = inst[2:0]; n = inst[5:3]; m = inst[8:6];
			index = 1; add = 1; wback = 0;
			shift_t = SRType_LSL; shift_n = 0;
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    STRH        r%1d, [r%1d, r%1d]", (rtl_PC-4), inst, t, n, m); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:9] ==7'b000_11_1_1) //SUB(immediate) T1
        begin       
            d = inst[2:0]; n = inst[5:3]; setflags = 1; imm32 = {29'b0, inst[8:6]};
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    SUBS        r%1d, r%1d, #%1d", (rtl_PC-4), inst, d, n, imm32); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:11] ==5'b001_11) //SUB(immediate) T2
        begin       
            d = inst[10:8]; n = inst[10:8]; setflags = 1; imm32 = {24'b0, inst[7:0]};
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    SUBS        r%1d, r%1d, #%1d", (rtl_PC-4), inst, d, n, imm32); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:9] ==7'b000_11_0_1) //SUB(register) 
        begin       
            d = inst[2:0]; n = inst[5:3]; m= inst[8:6]; setflags = 1; 
            shift_t = SRType_LSL; shift_n = 0; 
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    SUBS        r%1d, r%1d, r%1d", (rtl_PC-4), inst, d, n, m);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:7] ==9'b1011_0000_1) //SUB(SP minus immediate)
        begin       
            d = 13; setflags = 0; imm32 = {23'b0, inst[6:0], 2'b00};
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    SUB         r%1d, SP, #%1d", (rtl_PC-4), inst, d, imm32); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:8] ==8'b1101_1111) //SVC
        begin       
            imm32 = {24'b0, inst[7:0]};
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    SVC         #%1d", (rtl_PC-4), inst, imm32);      
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:6] ==10'b1011_0010_01) //SXTB
        begin       
            d = inst[2:0]; m = inst[5:3]; rotation = 0;
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    SXTB        r%1d, r%1d", (rtl_PC-4), inst, d, m);
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:6] ==10'b1011_0010_00) //SXTH
        begin       
            d = inst[2:0]; m = inst[5:3]; rotation = 0;
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    SXTH        r%1d, r%1d", (rtl_PC-4), inst, d, m); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:6] ==10'b010000_1000) //TST(register) 
        begin       
            n = inst[2:0]; m = inst[5:3];
            shift_t = SRType_LSL; shift_n = 0; 
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    TST        r%1d, r%1d", (rtl_PC-4), inst, n, m); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:6] ==10'b1011_0010_11) //UXTB
        begin       
            d = inst[2:0]; m = inst[5:3]; rotation = 0;
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    UXTB        r%1d, r%1d", (rtl_PC-4), inst, d, m);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst[15:6] ==10'b1011_0010_10) //UXTH
        begin       
            d = inst[2:0]; m = inst[5:3]; rotation = 0;
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    UXTH        r%1d, r%1d", (rtl_PC-4), inst, d, m);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst ==16'b1011_1111_0010_0000) //WFE
        begin       
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    WFE         ", (rtl_PC-4), inst);         
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst ==16'b1011_1111_0011_0000) //WFI
        begin       
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    WFI         ", (rtl_PC-4), inst);        
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if (inst ==16'b1011_1111_0001_0000) //YIELD
        begin       
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    YIELD        ", (rtl_PC-4), inst);       
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else  //UnImplemented
        begin       
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    Un-Implemented Inst16.", (rtl_PC-4), inst); 
        end
//---------------------------------------------------------------------------------------    
    end
	
    else //32bit instruction
    begin
	if (tmp_PC[1] == 1'b0) 
	    inst32s = {inst_data[15:0], inst_data[31:16]};
	else begin
	    read_addr = tmp_PC +2;
	    tmp_data32 = Read_MemU(read_addr, 4);
	    inst32s = {inst_data[31:16], tmp_data32[15:0]};
	 end
//--------------------------------------------------------------------------------------- 
		if ({inst32s[15:14], inst32s[12]} == 3'b11_1) //BL 
        begin       
            I1 = ~(inst32s[13] ^ inst32s[26]); I2 = ~(inst32s[11] ^ inst32s[26]);
            imm32 = { {7{inst32s[26]}},inst32s[26], I1, I2, inst32s[25:16], inst32s[10:0], 1'b0};
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    BL          #0x%1h", (rtl_PC-4), inst32s, (rtl_PC +imm32)); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if ({inst32s[31:20], inst32s[15:14], inst32s[12], inst32s[7:4]} == 19'b11110_0_111_01_1_10_0_0101) //DMB 
        begin     
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    DMB         {#%1d}", (rtl_PC-4), inst32s, inst32s[3:0]); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if ({inst32s[31:20], inst32s[15:14], inst32s[12], inst32s[7:4]} == 19'b11110_0_111_01_1_10_0_0100) //DSB 
        begin     
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    DSB         {#%1d}", (rtl_PC-4), inst32s, inst32s[3:0]); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if ({inst32s[31:20], inst32s[15:14], inst32s[12], inst32s[7:4]} == 19'b11110_0_111_01_1_10_0_0110) //ISB 
        begin     
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    ISB         {#%1d}", (rtl_PC-4), inst32s, inst32s[3:0]); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if ({inst32s[31:21], inst32s[15:14], inst32s[12]} == 19'b11110_0_1111_1_10_0) //MRS 
        begin
            d = inst32s[11:8]; SYSm = inst32s[7:0];       
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    MRS          r%1d, <SYSm=%1d>", (rtl_PC-4), inst32s, d, SYSm);  
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else if ({inst32s[31:21], inst32s[15:14], inst32s[12]} == 19'b11110_0_1110_0_10_0) //MSR 
        begin
            n = inst32s[19:16]; SYSm = inst32s[7:0];      
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    MSR          <SYSm=%1d>, r%1d", (rtl_PC-4), inst32s, SYSm, d); 
        end
//---------------------------------------------------------------------------------------       

//---------------------------------------------------------------------------------------    
        else  //UnImplemented
        begin       
    //Output dis-assembly instruction.
            $fdisplay(disasm_f, "%8h:  %8h    Un-Implemented Inst32.", (rtl_PC-4), inst32s);     
        end
//---------------------------------------------------------------------------------------   
    end
  end
end




//-------------
//Function: Read_MemU
//-------------
function[31:0] Read_MemU;
  input [31:0] address;
  input integer bits;
  reg [31:0] mem_addr;
  begin
     if (address[31:29] == 3'b000) begin 
	     mem_addr = (address/4) % (ROM_SIZE);
		 Read_MemU = rom_mem[mem_addr];
	 end
     else
     begin
         $display("[DISASM]: Read_MemU is wrong.");
     end
  end
endfunction
  

//-------------
//Function: DecodeImmShift
//-------------
function[8:0] DecodeImmShift;
  input [1:0] value;
  input [4:0] imm5;
 //output ={shift_t, shift_n)
  reg [2:0] shift_t;
  reg [5:0] shift_n;
  
  parameter SRType_LSL = 3'b000;
  parameter SRType_LSR = 3'b001;
  parameter SRType_ASR = 3'b010;
  parameter SRType_ROR = 3'b011;
  parameter SRType_RRX = 3'b100;

  
  begin
    case (value)
    2'b00: begin shift_t = SRType_LSL; shift_n = imm5; end
    2'b01: begin shift_t = SRType_LSR; shift_n = (imm5==0)? 32 : imm5; end
    2'b10: begin shift_t = SRType_ASR; shift_n = (imm5==0)? 32 : imm5; end
    2'b11: begin shift_t = (imm5==0)? SRType_RRX : SRType_ROR;  shift_n = (imm5==0)? 1 : imm5; end
    endcase
    DecodeImmShift = {shift_t, shift_n};
  end
endfunction


//synopsys translate_on

endmodule


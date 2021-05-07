*************************************************************************
   ____  ____ 
  /   /\/   / 
 /___/  \  /   
 \   \   \/    © Copyright 2009—2013 Xilinx, Inc. All rights reserved.
  \   \        This file contains confidential and proprietary 
  /   /        information of Xilinx, Inc. and is protected under U.S. 
 /___/   /\    and international copyright and other intellectual 
 \   \  /  \   property laws. 
  \___\/\___\ 
 
*************************************************************************

Vendor: Xilinx 
Current readme.txt Version: 1.2
Date Last Modified:  01/9/2013
Date Created: 12/02/2009

Associated Filename: xapp879.zip
Associated Document: XAPP879, PLL Dynamic Reconfiguration

Supported Device(s): Spartan-6 LX/LXT FPGAs
   
*************************************************************************

Disclaimer: 

      This disclaimer is not a license and does not grant any rights to 
      the materials distributed herewith. Except as otherwise provided in 
      a valid license issued to you by Xilinx, and to the maximum extent 
      permitted by applicable law: (1) THESE MATERIALS ARE MADE AVAILABLE 
      "AS IS" AND WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL 
      WARRANTIES AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, 
      INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, 
      NON-INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and 
      (2) Xilinx shall not be liable (whether in contract or tort, 
      including negligence, or under any other theory of liability) for 
      any loss or damage of any kind or nature related to, arising under 
      or in connection with these materials, including for any direct, or 
      any indirect, special, incidental, or consequential loss or damage 
      (including loss of data, profits, goodwill, or any type of loss or 
      damage suffered as a result of any action brought by a third party) 
      even if such damage or loss was reasonably foreseeable or Xilinx 
      had been advised of the possibility of the same.

Critical Applications:

      Xilinx products are not designed or intended to be fail-safe, or 
      for use in any application requiring fail-safe performance, such as 
      life-support or safety devices or systems, Class III medical 
      devices, nuclear facilities, applications related to the deployment 
      of airbags, or any other applications that could lead to death, 
      personal injury, or severe property or environmental damage 
      (individually and collectively, "Critical Applications"). Customer 
      assumes the sole risk and liability of any use of Xilinx products 
      in Critical Applications, subject only to applicable laws and 
      regulations governing limitations on product liability.

THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS PART OF THIS 
FILE AT ALL TIMES.

*************************************************************************

THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS PART OF THIS 
FILE AT ALL TIMES.

*************************************************************************

This readme file contains these sections:

1. REVISION HISTORY
2. OVERVIEW
3. SOFTWARE TOOLS AND SYSTEM REQUIREMENTS
4. DESIGN FILE HIERARCHY
5. INSTALLATION AND OPERATING INSTRUCTIONS
6. SUPPORT


1. REVISION HISTORY 

            Readme  
Date        Version      Revision Description
=========================================================================
12/02/2009  1.0         Initial Xilinx release.
09/15/2011  1.1         Mask and signal assignment for rom[15] and rom[38] were incorrect
						in the pll_drp.v source file and have been fixed
01/09/2013  1.2         Fixed duty_cycle error message (cr623274 - JT)
=========================================================================


2. OVERVIEW

This readme describes how to use the files that come with XAPP879

The XAPP879 application note comes with reference design source files that you can use 
to implement a design using a dynamically reconfigurable PLL.  

3. SOFTWARE TOOLS AND SYSTEM REQUIREMENTS

* Xilinx ISE 11.1 or higher (Includes XST, ISIM, and PlanAhead).


4. DESIGN FILE HIERARCHY

The directory structure underneath this top-level folder is described 
below:

The zip file contains 5 files:
	-pll_drp.v (This is the source code for the pll_drp reference design)
	-pll_drp_func.h  (This is the source file that contains all functions that pll_drp.v calls)
	-top.v  (this is an example top level setup which includes the pll_drp.v source file)
	-top_tb.v  (this is an example testbench file that can be used to simulate the pll_drp.v design)
	-readme.txt

	
5. INSTALLATION AND OPERATING INSTRUCTIONS 

This design comes with and example setup.  To use this setup include top.v,
tob_tb.v, and pll_drp.v in an ISE design.  pll_drp_func.h must be included
in the project directory.

To incorporate the pll_drp module into an ISE design project:

Verilog flow:

1) Add pll_drp.v to the design
2) Place pll_drp_func.h in the project directory
3) Instantiate the pll_drp module and the PLL_ADV module and connect the
   associated DRP ports.  top.v may be referred to as a reference for the needed
   connections.
4) Set the desired attributes for each reconfiguration state.


6. SUPPORT

To obtain technical support for this reference design, go to 
www.xilinx.com/support to locate answers to known issues in the Xilinx
Answers Database or to create a WebCase.  
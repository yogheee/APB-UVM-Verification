//---------------------------------------------
// APB UVM Testbench Top
//---------------------------------------------

import uvm_pkg::*;

`include "uvm_macros.svh"


// --------------------------------------------
// Interface
// --------------------------------------------
`include "apb_if.sv"


// --------------------------------------------
// APB slave BFM
// --------------------------------------------
`include "apb_slave_bfm.sv"


// --------------------------------------------
// Transaction + UVM components
// --------------------------------------------
`include "apb_rw.sv"

`include "apb_driver_seq_mon.sv"

`include "apb_scoreboard.sv"

`include "apb_coverage.sv"

`include "apb_agent_env_config.sv"

`include "apb_sequences.sv"

`include "apb_test.sv"



module test;

   import uvm_pkg::*;


   // -----------------------------------------
   // Clock
   // -----------------------------------------
   logic pclk;


   initial begin

      pclk = 1'b0;

   end


   always begin

      #10 pclk = ~pclk;

   end


   // -----------------------------------------
   // Physical APB interface
   // -----------------------------------------
   apb_if apb_vif(
      pclk
   );


   // -----------------------------------------
   // APB slave BFM
   // -----------------------------------------
   apb_slave_bfm #(
      .MAX_WAIT_STATES(2)
   ) slave (
      apb_vif
   );


   // -----------------------------------------
   // Start UVM
   // -----------------------------------------
   initial begin


      // Pass physical interface to UVM
      uvm_config_db#(virtual apb_if)::set(
         null,
         "uvm_test_top",
         "vif",
         apb_vif
      );


      // Start test
      run_test(
         "apb_base_test"
      );


   end


endmodule : test

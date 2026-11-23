//---------------------------------------------
// APB Interface
//
// Master : Driver
// Slave  : APB Slave BFM
// Passive: Monitor
//---------------------------------------------

`ifndef APB_IF_SV
`define APB_IF_SV

interface apb_if(input bit pclk);

   // -----------------------------------------
   // APB signals
   // -----------------------------------------
   logic [31:0] paddr;
   logic        psel;
   logic        penable;
   logic        pwrite;
   logic [31:0] pwdata;

   logic [31:0] prdata;
   logic        pready;
   logic        pslverr;


   // -----------------------------------------
   // Master clocking block
   // -----------------------------------------
   clocking master_cb @(posedge pclk);

      output paddr;
      output psel;
      output penable;
      output pwrite;
      output pwdata;

      input  prdata;
      input  pready;
      input  pslverr;

   endclocking : master_cb


   // -----------------------------------------
   // Slave clocking block
   // -----------------------------------------
   clocking slave_cb @(posedge pclk);

      input  paddr;
      input  psel;
      input  penable;
      input  pwrite;
      input  pwdata;

      output prdata;
      output pready;
      output pslverr;

   endclocking : slave_cb


   // -----------------------------------------
   // Monitor clocking block
   // -----------------------------------------
   clocking monitor_cb @(posedge pclk);

      input paddr;
      input psel;
      input penable;
      input pwrite;
      input pwdata;

      input prdata;
      input pready;
      input pslverr;

   endclocking : monitor_cb


   // -----------------------------------------
   // Modports
   // -----------------------------------------
   modport master  (clocking master_cb);
   modport slave   (clocking slave_cb);
   modport passive (clocking monitor_cb);


   // =========================================================
   // APB protocol assertions
   // =========================================================

   // PENABLE can only be high when PSEL is high.
   property p_penable_requires_psel;
      @(posedge pclk)
      penable |-> psel;
   endproperty

   ap_penable_requires_psel:
      assert property(p_penable_requires_psel)
      else $error("[APB_ASSERT] PENABLE asserted without PSEL");


   // SETUP phase must be followed by ACCESS phase.
   property p_setup_to_access;
      @(posedge pclk)
      (psel && !penable) |=> (psel && penable);
   endproperty

   ap_setup_to_access:
      assert property(p_setup_to_access)
      else $error("[APB_ASSERT] SETUP phase not followed by ACCESS");


   // Address/control must remain stable while waiting.
   property p_control_stable_during_wait;
      @(posedge pclk)
      (psel && penable && !pready)
      |=> (
            psel &&
            penable &&
            $stable(paddr) &&
            $stable(pwrite) &&
            $stable(pwdata)
          );
   endproperty

   ap_control_stable_during_wait:
      assert property(p_control_stable_during_wait)
      else $error(
         "[APB_ASSERT] APB control changed during wait state"
      );

endinterface : apb_if

`endif

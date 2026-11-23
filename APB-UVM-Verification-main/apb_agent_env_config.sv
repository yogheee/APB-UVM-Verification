//---------------------------------------------
// APB Configuration / Agent / Environment
//---------------------------------------------

`ifndef APB_AGENT_ENV_CONFIG_SV
`define APB_AGENT_ENV_CONFIG_SV


//================================================
// APB CONFIG
//================================================

class apb_config extends uvm_object;

   `uvm_object_utils(apb_config)

   virtual apb_if vif;

   bit is_active = 1'b1;


   function new(
      string name = "apb_config"
   );

      super.new(name);

   endfunction

endclass



//================================================
// APB AGENT
//================================================

class apb_agent extends uvm_agent;

   `uvm_component_utils(apb_agent)


   apb_sequencer  sqr;
   apb_master_drv drv;
   apb_monitor    mon;


   virtual apb_if vif;


   function new(
      string name,
      uvm_component parent = null
   );

      super.new(name, parent);

   endfunction


   // -----------------------------------------
   // Build
   // -----------------------------------------
   virtual function void build_phase(
      uvm_phase phase
   );

      super.build_phase(phase);


      if (!uvm_config_db#(virtual apb_if)::get(
            this,
            "",
            "vif",
            vif
         )) begin

         `uvm_fatal(
            "NOVIF",
            "APB agent virtual interface not found"
         )

      end


      sqr = apb_sequencer::type_id::create(
         "sqr",
         this
      );


      drv = apb_master_drv::type_id::create(
         "drv",
         this
      );


      mon = apb_monitor::type_id::create(
         "mon",
         this
      );


      // Pass VIF to driver
      uvm_config_db#(virtual apb_if)::set(
         this,
         "drv",
         "vif",
         vif
      );


      // Pass VIF to monitor
      uvm_config_db#(virtual apb_if)::set(
         this,
         "mon",
         "vif",
         vif
      );

   endfunction


   // -----------------------------------------
   // Connect
   // -----------------------------------------
   virtual function void connect_phase(
      uvm_phase phase
   );

      super.connect_phase(phase);


      drv.seq_item_port.connect(
         sqr.seq_item_export
      );


      `uvm_info(
         "APB_AGENT",
         "Driver connected to sequencer",
         UVM_MEDIUM
      )

   endfunction

endclass : apb_agent



//================================================
// APB ENVIRONMENT
//================================================

class apb_env extends uvm_env;

   `uvm_component_utils(apb_env)


   apb_agent      agt;
   apb_scoreboard sb;
   apb_coverage   cov;


   virtual apb_if vif;


   function new(
      string name,
      uvm_component parent = null
   );

      super.new(name, parent);

   endfunction


   // -----------------------------------------
   // Build
   // -----------------------------------------
   function void build_phase(
      uvm_phase phase
   );

      super.build_phase(phase);


      if (!uvm_config_db#(virtual apb_if)::get(
            this,
            "",
            "vif",
            vif
         )) begin

         `uvm_fatal(
            "NOVIF",
            "APB environment virtual interface not found"
         )

      end


      agt = apb_agent::type_id::create(
         "agt",
         this
      );


      sb = apb_scoreboard::type_id::create(
         "sb",
         this
      );


      cov = apb_coverage::type_id::create(
         "cov",
         this
      );


      uvm_config_db#(virtual apb_if)::set(
         this,
         "agt",
         "vif",
         vif
      );

   endfunction


   // -----------------------------------------
   // Connect
   // -----------------------------------------
   function void connect_phase(
      uvm_phase phase
   );

      super.connect_phase(phase);


      // Monitor -> scoreboard
      agt.mon.ap.connect(
         sb.analysis_export
      );


      // Monitor -> coverage
      agt.mon.ap.connect(
         cov.analysis_export
      );


   endfunction

endclass : apb_env


`endif

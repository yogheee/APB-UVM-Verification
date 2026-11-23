`ifndef APB_BASE_TEST_SV
`define APB_BASE_TEST_SV


class apb_base_test extends uvm_test;

   `uvm_component_utils(apb_base_test)


   apb_env    env;
   apb_config cfg;

   virtual apb_if vif;


   function new(
      string name = "apb_base_test",
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


      env = apb_env::type_id::create(
         "env",
         this
      );


      cfg = apb_config::type_id::create(
         "cfg"
      );


      if (!uvm_config_db#(virtual apb_if)::get(
            this,
            "",
            "vif",
            vif
         )) begin

         `uvm_fatal(
            "NOVIF",
            "APB test virtual interface not found"
         )

      end


      cfg.vif = vif;


      uvm_config_db#(virtual apb_if)::set(
         this,
         "env",
         "vif",
         vif
      );

   endfunction


   // -----------------------------------------
   // Run
   // -----------------------------------------
   task run_phase(
      uvm_phase phase
   );

      apb_smoke_seq  smoke_seq;
      apb_random_seq random_seq;
      apb_error_seq  error_seq;


      phase.raise_objection(this);


      // ======================================
      // 1. Directed smoke
      // ======================================

      smoke_seq =
         apb_smoke_seq::type_id::create(
            "smoke_seq"
         );


      smoke_seq.start(
         env.agt.sqr
      );


      // ======================================
      // 2. Constrained random
      // ======================================

      random_seq =
         apb_random_seq::type_id::create(
            "random_seq"
         );


      random_seq.num_transactions = 50;


      random_seq.start(
         env.agt.sqr
      );


      // ======================================
      // 3. Error response
      // ======================================

      error_seq =
         apb_error_seq::type_id::create(
            "error_seq"
         );


      error_seq.start(
         env.agt.sqr
      );


      `uvm_info(
         "APB_TEST",
         "All APB sequences completed",
         UVM_LOW
      )


      phase.drop_objection(this);

   endtask


endclass : apb_base_test


`endif

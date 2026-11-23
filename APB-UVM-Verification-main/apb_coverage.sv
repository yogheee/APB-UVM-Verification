//---------------------------------------------
// APB Functional Coverage
//---------------------------------------------

`ifndef APB_COVERAGE_SV
`define APB_COVERAGE_SV


class apb_coverage extends uvm_subscriber #(apb_rw);

   `uvm_component_utils(apb_coverage)


   int unsigned cmd_cov;
   bit [31:0]   addr_cov;
   bit          err_cov;


   covergroup apb_cg;

      option.per_instance = 1;


      // --------------------------------------
      // READ / WRITE
      // --------------------------------------
      cp_command:
         coverpoint cmd_cov {

            bins READ  = {0};
            bins WRITE = {1};

         }


      // --------------------------------------
      // Register addresses
      // --------------------------------------
      cp_address:
         coverpoint addr_cov {

            bins REG_0  = {32'h00000000};
            bins REG_1  = {32'h00000004};
            bins REG_2  = {32'h00000008};
            bins REG_3  = {32'h0000000C};

            bins REG_4  = {32'h00000010};
            bins REG_5  = {32'h00000014};
            bins REG_6  = {32'h00000018};
            bins REG_7  = {32'h0000001C};

            bins REG_8  = {32'h00000020};
            bins REG_9  = {32'h00000024};
            bins REG_10 = {32'h00000028};
            bins REG_11 = {32'h0000002C};

            bins REG_12 = {32'h00000030};
            bins REG_13 = {32'h00000034};
            bins REG_14 = {32'h00000038};
            bins REG_15 = {32'h0000003C};

            bins INVALID = default;

         }


      // --------------------------------------
      // Error response
      // --------------------------------------
      cp_error:
         coverpoint err_cov {

            bins NO_ERROR = {0};
            bins ERROR    = {1};

         }


      // --------------------------------------
      // Command / error cross
      // --------------------------------------
      command_x_error:
         cross cp_command, cp_error;

   endgroup


   function new(
      string name,
      uvm_component parent = null
   );

      super.new(name, parent);

      apb_cg = new();

   endfunction


   virtual function void write(
      apb_rw t
   );

      if (t.apb_cmd == apb_rw::READ)
         cmd_cov = 0;
      else
         cmd_cov = 1;


      addr_cov = t.addr;
      err_cov  = t.slverr;


      apb_cg.sample();

   endfunction


   function void report_phase(
      uvm_phase phase
   );

      `uvm_info(
         "APB_COV",
         $sformatf(
            "APB Functional Coverage = %0.2f%%",
            apb_cg.get_inst_coverage()
         ),
         UVM_NONE
      )

   endfunction

endclass : apb_coverage


`endif

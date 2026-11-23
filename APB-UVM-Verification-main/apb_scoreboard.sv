//---------------------------------------------
// APB Scoreboard
//
// Reference model + automatic checking
//---------------------------------------------

`ifndef APB_SCOREBOARD_SV
`define APB_SCOREBOARD_SV


class apb_scoreboard extends uvm_scoreboard;

   `uvm_component_utils(apb_scoreboard)


   uvm_analysis_imp #(apb_rw, apb_scoreboard)
      analysis_export;


   // Reference memory
   bit [31:0] model_mem [bit [31:0]];


   int unsigned total_checks;
   int unsigned passed_checks;
   int unsigned failed_checks;


   function new(
      string name,
      uvm_component parent = null
   );

      super.new(name, parent);

      analysis_export = new(
         "analysis_export",
         this
      );

   endfunction


   // -----------------------------------------
   // Valid register address
   // -----------------------------------------
   function bit valid_addr(
      bit [31:0] addr
   );

      return (
         (addr <= 32'h0000003C) &&
         (addr[1:0] == 2'b00)
      );

   endfunction


   // -----------------------------------------
   // Analysis implementation
   // -----------------------------------------
   virtual function void write(
      apb_rw tr
   );

      bit [31:0] expected;


      total_checks++;


      // ======================================
      // Invalid address
      // ======================================
      if (!valid_addr(tr.addr)) begin

         if (tr.slverr) begin

            passed_checks++;

            `uvm_info(
               "APB_SCB",
               $sformatf(
                  "PASS: Invalid address correctly returned PSLVERR: 0x%08h",
                  tr.addr
               ),
               UVM_MEDIUM
            )

         end
         else begin

            failed_checks++;

            `uvm_error(
               "APB_SCB",
               $sformatf(
                  "FAIL: Invalid address did not return PSLVERR: 0x%08h",
                  tr.addr
               )
            )

         end

         return;

      end


      // ======================================
      // Valid transfer must not error
      // ======================================
      if (tr.slverr) begin

         failed_checks++;

         `uvm_error(
            "APB_SCB",
            $sformatf(
               "FAIL: Unexpected PSLVERR at address 0x%08h",
               tr.addr
            )
         )

         return;

      end


      // ======================================
      // WRITE
      // ======================================
      if (tr.apb_cmd == apb_rw::WRITE) begin

         model_mem[tr.addr] = tr.data;

         passed_checks++;


         `uvm_info(
            "APB_SCB",
            $sformatf(
               "WRITE CHECK PASS: ADDR=0x%08h DATA=0x%08h",
               tr.addr,
               tr.data
            ),
            UVM_HIGH
         )

      end


      // ======================================
      // READ
      // ======================================
      else begin

         if (model_mem.exists(tr.addr))
            expected = model_mem[tr.addr];

         else
            expected = 32'h00000000;


         if (tr.rdata == expected) begin

            passed_checks++;


            `uvm_info(
               "APB_SCB",
               $sformatf(
                  "READ CHECK PASS: ADDR=0x%08h EXPECTED=0x%08h ACTUAL=0x%08h",
                  tr.addr,
                  expected,
                  tr.rdata
               ),
               UVM_MEDIUM
            )

         end
         else begin

            failed_checks++;


            `uvm_error(
               "APB_SCB",
               $sformatf(
                  "READ CHECK FAIL: ADDR=0x%08h EXPECTED=0x%08h ACTUAL=0x%08h",
                  tr.addr,
                  expected,
                  tr.rdata
               )
            )

         end

      end

   endfunction


   // -----------------------------------------
   // Final report
   // -----------------------------------------
   function void report_phase(
      uvm_phase phase
   );

      `uvm_info(
         "APB_SCB",
         $sformatf(
            "Scoreboard Summary: Total=%0d PASS=%0d FAIL=%0d",
            total_checks,
            passed_checks,
            failed_checks
         ),
         UVM_NONE
      )


      if (failed_checks == 0) begin

         `uvm_info(
            "APB_SCB",
            "==========================================",
            UVM_NONE
         )

         `uvm_info(
            "APB_SCB",
            "      APB SCOREBOARD : PASS",
            UVM_NONE
         )

         `uvm_info(
            "APB_SCB",
            "==========================================",
            UVM_NONE
         )

      end
      else begin

         `uvm_error(
            "APB_SCB",
            "APB SCOREBOARD : FAIL"
         )

      end

   endfunction

endclass : apb_scoreboard


`endif

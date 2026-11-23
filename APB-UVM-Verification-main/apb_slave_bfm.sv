//---------------------------------------------
// APB Slave BFM
//
// Behavioral APB peripheral model
//---------------------------------------------

`ifndef APB_SLAVE_BFM_SVH
`define APB_SLAVE_BFM_SVH


module apb_slave_bfm #(

   parameter int MAX_WAIT_STATES = 2

) (
   apb_if vif
);


   // -----------------------------------------
   // Register memory
   // -----------------------------------------
   logic [31:0] mem [logic [31:0]];


   // -----------------------------------------
   // Latched transaction
   // -----------------------------------------
   logic [31:0] addr_q;
   logic [31:0] wdata_q;

   logic        write_q;
   logic        active;
   logic        responded;

   integer wait_count;


   // -----------------------------------------
   // Address validation
   // -----------------------------------------
   function automatic bit valid_addr(
      input logic [31:0] addr
   );

      return (
         (addr <= 32'h0000003C) &&
         (addr[1:0] == 2'b00)
      );

   endfunction


   // -----------------------------------------
   // Initial state
   // -----------------------------------------
   initial begin

      vif.prdata  = 32'h00000000;
      vif.pready  = 1'b0;
      vif.pslverr = 1'b0;

      addr_q      = '0;
      wdata_q     = '0;
      write_q     = 1'b0;

      active      = 1'b0;
      responded   = 1'b0;

      wait_count  = 0;

   end


   // -----------------------------------------
   // APB slave process
   // -----------------------------------------
   always @(posedge vif.pclk) begin


      // ======================================
      // IDLE
      // ======================================
      if (!vif.psel) begin

         vif.pready  <= 1'b0;
         vif.pslverr <= 1'b0;
         vif.prdata  <= 32'h00000000;

         active      <= 1'b0;
         responded   <= 1'b0;

         wait_count  = 0;

      end


      // ======================================
      // SETUP
      // ======================================
      else if (
         vif.psel &&
         !vif.penable
      ) begin

         addr_q  <= vif.paddr;
         wdata_q <= vif.pwdata;
         write_q <= vif.pwrite;

         wait_count = $urandom_range(
            0,
            MAX_WAIT_STATES
         );

         active    <= 1'b1;
         responded <= 1'b0;

         vif.pready  <= 1'b0;
         vif.pslverr <= 1'b0;
         vif.prdata  <= 32'h00000000;

      end


      // ======================================
      // ACCESS
      // ======================================
      else if (
         vif.psel &&
         vif.penable
      ) begin


         // -----------------------------------
         // Already responded
         // -----------------------------------
         if (responded) begin

            vif.pready <= 1'b0;

         end


         // -----------------------------------
         // Wait state
         // -----------------------------------
         else if (wait_count > 0) begin

            wait_count = wait_count - 1;

            vif.pready <= 1'b0;


            $display(
               "[APB_SLAVE] WAIT STATE: remaining=%0d ADDR=0x%08h",
               wait_count,
               addr_q
            );

         end


         // -----------------------------------
         // Complete transfer
         // -----------------------------------
         else begin

            vif.pready  <= 1'b1;
            vif.pslverr <= !valid_addr(addr_q);


            // =================================
            // WRITE
            // =================================
            if (write_q) begin

               if (valid_addr(addr_q)) begin

                  mem[addr_q] = wdata_q;


                  $display(
                     "[APB_SLAVE] WRITE: ADDR=0x%08h DATA=0x%08h",
                     addr_q,
                     wdata_q
                  );

               end
               else begin

                  $display(
                     "[APB_SLAVE] WRITE ERROR: INVALID ADDR=0x%08h",
                     addr_q
                  );

               end

            end


            // =================================
            // READ
            // =================================
            else begin

               if (valid_addr(addr_q)) begin

                  if (mem.exists(addr_q))
                     vif.prdata <= mem[addr_q];

                  else
                     vif.prdata <= 32'h00000000;


                  $display(
                     "[APB_SLAVE] READ : ADDR=0x%08h DATA=0x%08h",
                     addr_q,
                     mem.exists(addr_q) ?
                     mem[addr_q] :
                     32'h00000000
                  );

               end
               else begin

                  vif.prdata <= 32'hDEAD_BEEF;


                  $display(
                     "[APB_SLAVE] READ ERROR: INVALID ADDR=0x%08h",
                     addr_q
                  );

               end

            end


            responded <= 1'b1;

         end

      end

   end

endmodule : apb_slave_bfm


`endif

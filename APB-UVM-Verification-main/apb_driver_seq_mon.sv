//---------------------------------------------
// APB Driver / Sequencer / Monitor
//---------------------------------------------

`ifndef APB_DRIVER_SEQ_MON_SV
`define APB_DRIVER_SEQ_MON_SV


//================================================
// APB MASTER DRIVER
//================================================

class apb_master_drv extends uvm_driver #(apb_rw);

   `uvm_component_utils(apb_master_drv)

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
   function void build_phase(uvm_phase phase);

      super.build_phase(phase);

      if (!uvm_config_db#(virtual apb_if)::get(
            this,
            "",
            "vif",
            vif
         )) begin

         `uvm_fatal(
            "NOVIF",
            "APB virtual interface not found"
         )

      end

   endfunction


   // -----------------------------------------
   // Run
   // -----------------------------------------
   virtual task run_phase(uvm_phase phase);

      apb_rw req;

      // Initial bus state
      vif.master_cb.psel    <= 1'b0;
      vif.master_cb.penable <= 1'b0;
      vif.master_cb.pwrite  <= 1'b0;
      vif.master_cb.paddr   <= '0;
      vif.master_cb.pwdata  <= '0;


      forever begin

         seq_item_port.get_next_item(req);


         `uvm_info(
            "APB_DRIVER",
            {"Driving: ", req.convert2string()},
            UVM_MEDIUM
         )


         case (req.apb_cmd)

            apb_rw::WRITE:
               drive_write(
                  req.addr,
                  req.data,
                  req.slverr
               );


            apb_rw::READ:
               drive_read(
                  req.addr,
                  req.rdata,
                  req.slverr
               );


            default:
               `uvm_error(
                  "APB_DRIVER",
                  "Unknown APB command"
               )

         endcase


         seq_item_port.item_done();

      end

   endtask


   //================================================
   // WRITE TRANSFER
   //================================================

   virtual protected task drive_write(
      input  bit [31:0] addr,
      input  bit [31:0] data,
      output bit        slverr
   );

      slverr = 1'b0;


      // -----------------------------------------
      // SETUP phase
      // -----------------------------------------
      @(vif.master_cb);

      vif.master_cb.paddr   <= addr;
      vif.master_cb.pwrite  <= 1'b1;
      vif.master_cb.pwdata  <= data;
      vif.master_cb.psel    <= 1'b1;
      vif.master_cb.penable <= 1'b0;


      // -----------------------------------------
      // ACCESS phase
      // -----------------------------------------
      @(vif.master_cb);

      vif.master_cb.penable <= 1'b1;


      // -----------------------------------------
      // Wait for slave
      // -----------------------------------------
      do begin

         @(vif.master_cb);

      end
      while (!vif.master_cb.pready);


      slverr = vif.master_cb.pslverr;


      if (slverr) begin

         `uvm_warning(
            "APB_DRIVER",
            $sformatf(
               "WRITE received PSLVERR: ADDR=0x%08h",
               addr
            )
         )

      end


      // -----------------------------------------
      // Return to IDLE
      // -----------------------------------------
      vif.master_cb.psel    <= 1'b0;
      vif.master_cb.penable <= 1'b0;
      vif.master_cb.pwrite  <= 1'b0;
      vif.master_cb.paddr   <= '0;
      vif.master_cb.pwdata  <= '0;

   endtask


   //================================================
   // READ TRANSFER
   //================================================

   virtual protected task drive_read(
      input  bit [31:0] addr,
      output bit [31:0] data,
      output bit        slverr
   );

      data   = '0;
      slverr = 1'b0;


      // -----------------------------------------
      // SETUP phase
      // -----------------------------------------
      @(vif.master_cb);

      vif.master_cb.paddr   <= addr;
      vif.master_cb.pwrite  <= 1'b0;
      vif.master_cb.pwdata  <= '0;
      vif.master_cb.psel    <= 1'b1;
      vif.master_cb.penable <= 1'b0;


      // -----------------------------------------
      // ACCESS phase
      // -----------------------------------------
      @(vif.master_cb);

      vif.master_cb.penable <= 1'b1;


      // -----------------------------------------
      // Wait for slave response
      // -----------------------------------------
      do begin

         @(vif.master_cb);

      end
      while (!vif.master_cb.pready);


      data   = vif.master_cb.prdata;
      slverr = vif.master_cb.pslverr;


      `uvm_info(
         "APB_DRIVER",
         $sformatf(
            "READ RESPONSE: ADDR=0x%08h DATA=0x%08h ERR=%0b",
            addr,
            data,
            slverr
         ),
         UVM_HIGH
      )


      // -----------------------------------------
      // Return to IDLE
      // -----------------------------------------
      vif.master_cb.psel    <= 1'b0;
      vif.master_cb.penable <= 1'b0;
      vif.master_cb.pwrite  <= 1'b0;
      vif.master_cb.paddr   <= '0;
      vif.master_cb.pwdata  <= '0;

   endtask

endclass : apb_master_drv



//================================================
// APB SEQUENCER
//================================================

class apb_sequencer extends uvm_sequencer #(apb_rw);

   `uvm_component_utils(apb_sequencer)


   function new(
      string name,
      uvm_component parent = null
   );

      super.new(name, parent);

   endfunction

endclass : apb_sequencer



//================================================
// APB MONITOR
//================================================

class apb_monitor extends uvm_monitor;

   `uvm_component_utils(apb_monitor)


   virtual apb_if vif;


   uvm_analysis_port #(apb_rw) ap;


   function new(
      string name,
      uvm_component parent = null
   );

      super.new(name, parent);

      ap = new("ap", this);

   endfunction


   // -----------------------------------------
   // Build
   // -----------------------------------------
   function void build_phase(uvm_phase phase);

      super.build_phase(phase);


      if (!uvm_config_db#(virtual apb_if)::get(
            this,
            "",
            "vif",
            vif
         )) begin

         `uvm_fatal(
            "NOVIF",
            "APB monitor virtual interface not found"
         )

      end

   endfunction


   // -----------------------------------------
   // Monitor
   // -----------------------------------------
   virtual task run_phase(uvm_phase phase);

      apb_rw tr;


      forever begin

         @(vif.monitor_cb);


         // Only sample completed ACCESS transfers.
         // This prevents duplicate transactions during
         // wait states.
         if (
            vif.monitor_cb.psel &&
            vif.monitor_cb.penable &&
            vif.monitor_cb.pready
         ) begin

            tr = apb_rw::type_id::create(
               "tr"
            );


            tr.addr   = vif.monitor_cb.paddr;
            tr.slverr = vif.monitor_cb.pslverr;


            if (vif.monitor_cb.pwrite) begin

               tr.apb_cmd = apb_rw::WRITE;
               tr.data    = vif.monitor_cb.pwdata;

            end
            else begin

               tr.apb_cmd = apb_rw::READ;
               tr.rdata   = vif.monitor_cb.prdata;
               tr.data    = vif.monitor_cb.prdata;

            end


            `uvm_info(
               "APB_MONITOR",
               {"Observed: ", tr.convert2string()},
               UVM_MEDIUM
            )


            ap.write(tr);

         end

      end

   endtask

endclass : apb_monitor


`endif

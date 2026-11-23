//---------------------------------------------
// APB Sequences
//---------------------------------------------

`ifndef APB_SEQUENCES_SV
`define APB_SEQUENCES_SV


//================================================
// BASE SEQUENCE
//================================================

class apb_base_seq extends uvm_sequence #(apb_rw);

   `uvm_object_utils(apb_base_seq)


   function new(
      string name = "apb_base_seq"
   );

      super.new(name);

   endfunction


   task body();

   endtask

endclass



//================================================
// DIRECTED SMOKE SEQUENCE
//================================================

class apb_smoke_seq extends apb_base_seq;

   `uvm_object_utils(apb_smoke_seq)


   function new(
      string name = "apb_smoke_seq"
   );

      super.new(name);

   endfunction


   task send_write(
      input bit [31:0] addr,
      input bit [31:0] data
   );

      apb_rw req;

      req = apb_rw::type_id::create(
         "write_req"
      );

      start_item(req);

      req.apb_cmd = apb_rw::WRITE;
      req.addr    = addr;
      req.data    = data;

      finish_item(req);

   endtask


   task send_read(
      input bit [31:0] addr
   );

      apb_rw req;

      req = apb_rw::type_id::create(
         "read_req"
      );

      start_item(req);

      req.apb_cmd = apb_rw::READ;
      req.addr    = addr;

      finish_item(req);

   endtask


   task body();

      `uvm_info(
         "APB_SMOKE",
         "Starting directed APB smoke sequence",
         UVM_LOW
      )


      // --------------------------------------
      // Write known values
      // --------------------------------------

      send_write(
         32'h00000000,
         32'hAAAA1111
      );


      send_write(
         32'h00000004,
         32'hBBBB2222
      );


      send_write(
         32'h00000008,
         32'hCCCC3333
      );


      send_write(
         32'h0000000C,
         32'hDDDD4444
      );


      // --------------------------------------
      // Read them back
      // --------------------------------------

      send_read(
         32'h00000000
      );


      send_read(
         32'h00000004
      );


      send_read(
         32'h00000008
      );


      send_read(
         32'h0000000C
      );


      `uvm_info(
         "APB_SMOKE",
         "Directed APB smoke sequence completed",
         UVM_LOW
      )

   endtask

endclass



//================================================
// CONSTRAINED RANDOM SEQUENCE
//================================================

class apb_random_seq extends apb_base_seq;

   `uvm_object_utils(apb_random_seq)


   int unsigned num_transactions = 50;


   function new(
      string name = "apb_random_seq"
   );

      super.new(name);

   endfunction


   task body();

      apb_rw req;


      `uvm_info(
         "APB_RANDOM",
         $sformatf(
            "Starting %0d constrained-random transactions",
            num_transactions
         ),
         UVM_LOW
      )


      repeat (num_transactions) begin

         req = apb_rw::type_id::create(
            "req"
         );


         start_item(req);


         if (!req.randomize()) begin

            `uvm_fatal(
               "APB_RANDOM",
               "APB transaction randomization failed"
            )

         end


         finish_item(req);

      end


      `uvm_info(
         "APB_RANDOM",
         "Constrained-random sequence completed",
         UVM_LOW
      )

   endtask

endclass



//================================================
// ERROR RESPONSE SEQUENCE
//================================================

class apb_error_seq extends apb_base_seq;

   `uvm_object_utils(apb_error_seq)


   function new(
      string name = "apb_error_seq"
   );

      super.new(name);

   endfunction


   task send_invalid_write();

      apb_rw req;

      req = apb_rw::type_id::create(
         "invalid_write"
      );


      start_item(req);

      req.apb_cmd = apb_rw::WRITE;

      // Outside valid register space
      req.addr = 32'h00000100;

      req.data = 32'h12345678;


      finish_item(req);

   endtask


   task send_invalid_read();

      apb_rw req;

      req = apb_rw::type_id::create(
         "invalid_read"
      );


      start_item(req);

      req.apb_cmd = apb_rw::READ;

      // Outside valid register space
      req.addr = 32'h00000104;


      finish_item(req);

   endtask


   task body();

      `uvm_info(
         "APB_ERROR",
         "Starting APB error-response sequence",
         UVM_LOW
      )


      send_invalid_write();

      send_invalid_read();


      `uvm_info(
         "APB_ERROR",
         "APB error-response sequence completed",
         UVM_LOW
      )

   endtask

endclass


`endif

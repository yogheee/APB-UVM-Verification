//---------------------------------------------
// APB Read / Write Transaction
//---------------------------------------------

`ifndef APB_RW_SV
`define APB_RW_SV


class apb_rw extends uvm_sequence_item;

   typedef enum {
      READ,
      WRITE
   } kind_e;


   // -----------------------------------------
   // Stimulus fields
   // -----------------------------------------
   rand bit [31:0] addr;
   rand bit [31:0] data;
   rand kind_e     apb_cmd;


   // -----------------------------------------
   // Response fields
   // -----------------------------------------
   bit [31:0] rdata;
   bit        slverr;


   // -----------------------------------------
   // Factory registration
   // -----------------------------------------
   `uvm_object_utils_begin(apb_rw)

      `uvm_field_int(addr, UVM_ALL_ON)
      `uvm_field_int(data, UVM_ALL_ON)
      `uvm_field_enum(kind_e, apb_cmd, UVM_ALL_ON)
      `uvm_field_int(rdata, UVM_ALL_ON)
      `uvm_field_int(slverr, UVM_ALL_ON)

   `uvm_object_utils_end


   // -----------------------------------------
   // Address constraint
   //
   // Peripheral register space:
   // 0x00 - 0x3C
   // 4-byte aligned
   // -----------------------------------------
   constraint c_addr {

      addr inside {[32'h00000000 : 32'h0000003C]};

      addr[1:0] == 2'b00;

   }


   // -----------------------------------------
   // Command distribution
   // -----------------------------------------
   constraint c_cmd {

      apb_cmd dist {
         WRITE := 60,
         READ  := 40
      };

   }


   function new(string name = "apb_rw");

      super.new(name);

   endfunction


   // -----------------------------------------
   // String conversion
   // -----------------------------------------
   function string convert2string();

      if (apb_cmd == WRITE) begin

         return $sformatf(
            "APB WRITE: ADDR=0x%08h DATA=0x%08h ERR=%0b",
            addr,
            data,
            slverr
         );

      end
      else begin

         return $sformatf(
            "APB READ : ADDR=0x%08h DATA=0x%08h ERR=%0b",
            addr,
            rdata,
            slverr
         );

      end

   endfunction


   // -----------------------------------------
   // Copy
   // -----------------------------------------
   function void do_copy(uvm_object rhs);

      apb_rw rhs_;

      if (!$cast(rhs_, rhs)) begin

         `uvm_fatal(
            "APB_COPY",
            "Failed to cast RHS to apb_rw"
         )

      end

      super.do_copy(rhs);

      addr    = rhs_.addr;
      data    = rhs_.data;
      apb_cmd = rhs_.apb_cmd;
      rdata   = rhs_.rdata;
      slverr  = rhs_.slverr;

   endfunction


   // -----------------------------------------
   // Compare
   // -----------------------------------------
   function bit do_compare(
      uvm_object rhs,
      uvm_comparer comparer
   );

      apb_rw rhs_;

      if (!$cast(rhs_, rhs))
         return 0;

      return (
         super.do_compare(rhs, comparer) &&
         addr    == rhs_.addr &&
         apb_cmd == rhs_.apb_cmd &&
         data    == rhs_.data &&
         rdata   == rhs_.rdata &&
         slverr  == rhs_.slverr
      );

   endfunction


   // -----------------------------------------
   // Print
   // -----------------------------------------
   function void do_print(uvm_printer printer);

      super.do_print(printer);

      printer.print_string(
         "Command",
         apb_cmd.name()
      );

      printer.print_field(
         "Address",
         addr,
         32,
         UVM_HEX
      );

      printer.print_field(
         "Data",
         data,
         32,
         UVM_HEX
      );

      printer.print_field(
         "ReadData",
         rdata,
         32,
         UVM_HEX
      );

      printer.print_field(
         "SlaveError",
         slverr,
         1,
         UVM_BIN
      );

   endfunction

endclass : apb_rw


`endif

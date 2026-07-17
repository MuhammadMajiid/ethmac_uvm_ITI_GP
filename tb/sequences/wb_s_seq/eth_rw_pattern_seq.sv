//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_rw_pattern_seq.sv
// Author   : Nada
// Date     :2026-07-15
//------------------------------------------------------------------------------
// Description:
//   Writes alternating patterns (0xAAAAAAAA and 0x55555555) to every RW
//   register and verifies the readback.
//==============================================================================

class eth_rw_pattern_seq extends uvm_reg_sequence;

  `uvm_object_utils(eth_rw_pattern_seq)

  eth_reg_block model;

  function new(string name="eth_rw_pattern_seq");
    super.new(name);
  endfunction

  virtual task body();

    uvm_status_e      status;
    uvm_reg_data_t    rd_data;
    uvm_reg_data_t    wr_data;
    uvm_reg_data_t    rw_mask;

    uvm_reg           regs[$];
    uvm_reg_field     fields[$];

uvm_reg_data_t patterns[2];

patterns[0] = 32'hAAAA_AAAA;
patterns[1] = 32'h5555_5555;

    if(model == null)
      `uvm_fatal(get_type_name(),"Register model handle is NULL")

    //--------------------------------------------------------
    // Get all registers
    //--------------------------------------------------------
    model.get_registers(regs);

    foreach(regs[i]) begin

    if (regs[i] == model.TX_BD_NUM) begin
    patterns[0] = 8'h2A;
    patterns[1] = 8'h15;
    end
    else begin
    patterns[0] = 32'hAAAA_AAAA;
    patterns[1] = 32'h5555_5555;
    end

      rw_mask = '0;

      fields.delete();
      regs[i].get_fields(fields);

      //------------------------------------------------------
      // Build writable-bit mask
      //------------------------------------------------------
      foreach(fields[j]) begin

        string access;
        int    lsb;
        int    n_bits;

        access = fields[j].get_access();
        lsb    = fields[j].get_lsb_pos();
        n_bits = fields[j].get_n_bits();

        if(access == "RW") begin
          rw_mask |= (((32'h1 << n_bits) - 1) << lsb);
        end
      end

      //------------------------------------------------------
      // Skip registers with no RW fields
      //------------------------------------------------------
      if(rw_mask == 0)
        continue;

      //------------------------------------------------------
      // Test both alternating patterns
      //------------------------------------------------------


foreach (patterns[k]) begin

    wr_data = patterns[k] & rw_mask;

    regs[i].write(status, wr_data, UVM_FRONTDOOR);
     if(status != UVM_IS_OK)
          `uvm_error(get_type_name(),
            $sformatf("%s write failed", regs[i].get_name()))

        regs[i].read(status, rd_data, UVM_FRONTDOOR);

        if(status != UVM_IS_OK)
          `uvm_error(get_type_name(),
            $sformatf("%s read failed", regs[i].get_name()))
    if ((rd_data & rw_mask) !== wr_data) begin

          `uvm_error(get_type_name(),
            $sformatf("Mismatch in %s\nExpected = 0x%08h\nActual   = 0x%08h\nMask     = 0x%08h",
                      regs[i].get_name(),
                      wr_data,
                      rd_data & rw_mask,
                      rw_mask))
        end
        else begin

          `uvm_info(get_type_name(),
            $sformatf("%s PASSED Pattern 0x%08h",
                      regs[i].get_name(),
                      patterns[k]),
            UVM_MEDIUM)

        end

      end

    end

endtask
       

endclass
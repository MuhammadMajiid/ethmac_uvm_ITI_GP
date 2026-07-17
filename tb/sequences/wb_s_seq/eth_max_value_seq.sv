//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_max_value_seq.sv
// Author   : Nada
// Date     : 2026-07-14
//------------------------------------------------------------------------------
// Description:
//  Writes maximum legal value to every RW register.
//  Verifies:
//   - Correct write/read
//   - No truncation/masking
//   - No side effects
//==============================================================================

class eth_max_value_seq extends uvm_reg_sequence;

  `uvm_object_utils(eth_max_value_seq)

  eth_reg_block rgm;

  uvm_status_e   status;
  uvm_reg_data_t data;


  function new(string name="eth_max_value_seq");
    super.new(name);
  endfunction


  virtual task body();

    //------------------------------------------------------------
    // Test all RW registers
    //------------------------------------------------------------

    test_reg(rgm.MODER      ,32'h0001_F7FF);
    test_reg(rgm.INT_MASK   ,32'h0000_007F);
    test_reg(rgm.IPGT       ,32'h0000_007F);
    test_reg(rgm.IPGR1      ,32'h0000_007F);
    test_reg(rgm.IPGR2      ,32'h0000_007F);
    test_reg(rgm.PACKETLEN  ,32'hFFFF_FFFF);
    test_reg(rgm.COLLCONF   ,32'h000F_003F);
    test_reg(rgm.TX_BD_NUM  ,32'h0000_0080);
    test_reg(rgm.CTRLMODER  ,32'h0000_0007);
    test_reg(rgm.MIIMODER   ,32'h0000_01FF);
    test_reg(rgm.MIICOMMAND ,32'h0000_0007);
    test_reg(rgm.MIIADDRESS ,32'h0000_1F1F);
    test_reg(rgm.MIITX_DATA ,32'h0000_FFFF);
    test_reg(rgm.MAC_ADDR0  ,32'hFFFF_FFFF);
    test_reg(rgm.MAC_ADDR1  ,32'h0000_FFFF);
    test_reg(rgm.HASH0      ,32'hFFFF_FFFF);
    test_reg(rgm.HASH1      ,32'hFFFF_FFFF);
    test_reg(rgm.TXCTRL     ,32'h0001_FFFF);


  endtask
  
  function bit is_read_only(uvm_reg rg);

  uvm_reg_field fields[$];

  rg.get_fields(fields);

  foreach(fields[i]) begin

    if(fields[i].get_access() != "RO")
      return 0;

  end

  return 1;

endfunction

  //------------------------------------------------------------
  // Test one register
  //------------------------------------------------------------

  task test_reg(uvm_reg rg,
              uvm_reg_data_t max_val);

  uvm_reg regs[$];
 uvm_reg_data_t saved_value[string];


  rgm.get_registers(regs);


  // Save current state of all other RW registers
  foreach(regs[i]) begin

    if(regs[i].get_full_name() == rg.get_full_name())
      continue;

    if(is_read_only(regs[i]))
      continue;

    regs[i].read(status,data);

    saved_value[regs[i].get_full_name()] = data;

  end


  // Write tested register
  rg.write(status,max_val);


  // Readback check
  rg.read(status,data);

  if(data !== max_val)
    `uvm_error(get_name(),
      $sformatf("%s readback mismatch Expected=%08h Actual=%08h",
                rg.get_name(),
                max_val,
                data))


  // Check side effects
  foreach(regs[i]) begin

    if(regs[i].get_full_name() == rg.get_full_name())
      continue;

    if(is_read_only(regs[i]))
      continue;


    regs[i].read(status,data);


    if(data !== saved_value[regs[i].get_full_name()])

      `uvm_error(get_name(),
        $sformatf("Side effect detected on %s Before=%08h Actual=%08h",
                  regs[i].get_name(),
                  saved_value[regs[i].get_full_name()],
                  data))

  end

endtask


endclass
//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_s_driver_base.sv
// Author   : Nada
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
// Wishbone driver responsible for converting sequence items into bus
// transactions on the Wishbone interface.
//
// The driver receives wb_s_seq_item_base transactions from the sequencer,
// drives the corresponding request signals to the DUT, waits for the DUT
// response, and stores the response information back into the transaction.
//==============================================================================

`ifndef WB_S_DRIVER_BASE_SV
`define WB_S_DRIVER_BASE_SV

class wb_s_driver_base extends uvm_driver #(wb_s_seq_item_base);

  `uvm_component_utils(wb_s_driver_base)

  //--------------------------------------------------------------------------
  // Members
  //--------------------------------------------------------------------------
  virtual wb_s_if vif;
  wb_s_config_obj   m_config;

  //--------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  //--------------------------------------------------------------------------
  // Build Phase
  //--------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db #(wb_s_config_obj)::get(this, "", "config", m_config))
      `uvm_fatal(get_type_name(), "wb_s_config not found in config_db")

    vif = m_config.vif;

    if (vif == null)
      `uvm_fatal(get_type_name(),
                 "wb_s driver virtual interface not set")
  endfunction

  //--------------------------------------------------------------------------
  // Run Phase
  //--------------------------------------------------------------------------
  task run_phase(uvm_phase phase);

    wb_s_seq_item_base req;

    wait(!vif.rst);

    forever begin

      seq_item_port.get_next_item(req);

     `uvm_info(get_type_name(),
          $sformatf("Driving transaction:%s",
                    req.convert2string()),
          UVM_MEDIUM)

      drive_transfer(req);

      seq_item_port.item_done();

    end

  endtask

  //--------------------------------------------------------------------------
  // Drive One Wishbone Transfer
  //--------------------------------------------------------------------------
  task drive_transfer(wb_s_seq_item_base req);

    int timeout;

  

    // Drive request
    vif.addr  <= req.m_addr;
    vif.wdata <= req.m_wdata;
    vif.we    <= req.m_we;
    vif.sel   <= req.m_sel;

    vif.cyc   <= 1'b1;
    vif.stb   <= 1'b1;


    @(posedge vif.clk);
     // Return interface to idle
    vif.cyc <= 1'b0;
    vif.stb <= 1'b0;
    vif.we  <= 1'b0;
   // Wait for ACK or ERR
    timeout = 1000;

    while (!(vif.ack || vif.err) && (timeout > 0))
    begin
      @(posedge vif.clk);
      timeout--;
    end

    if (timeout == 0)
    begin
      `uvm_error(get_type_name(),
                 "Wishbone transaction timeout")

      req.m_ack   = 1'b0;
      req.m_err   = 1'b1;
      req.m_inta  = 1'b0;
      req.m_rdata = '0;
    end
    else
    begin
      req.m_ack  = vif.ack;
      req.m_err  = vif.err;
      req.m_inta = vif.inta;


      if (!req.m_we)
        req.m_rdata = vif.rdata;
    end
`uvm_info(get_type_name(),
$sformatf("ACK=%0b DATA=%08h ADDR=%08h",
vif.ack,
vif.rdata,
req.m_addr),
UVM_LOW)

  @(posedge vif.clk);

  endtask

endclass

`endif // WB_S_DRIVER_BASE_SV

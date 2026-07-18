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

class wb_s_driver_base extends uvm_driver #(wb_s_seq_item_base#(WB_S_ADDR_WIDTH, WB_DATA_WIDTH,WB_SEL_WIDTH));

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

    super.run_phase(phase);
     reset_item();

    forever begin
      
      seq_item_port.get_next_item(req);
     

     `uvm_info(get_type_name(),
          $sformatf("Driving transaction:%s",
                    req.convert2string()),UVM_DEBUG)

      drive_transfer(req);

      seq_item_port.item_done();

    end

  endtask

 task reset_item();
  vif.cb.addr_i  <= '0;
  vif.cb.wdata_i <= '0;
  vif.cb.we_i    <= 1'b0;
  vif.cb.sel_i   <= '0;
  vif.cb.cyc_i   <= 1'b0;
  vif.cb.stb_i   <= 1'b0;
  @(vif.cb);
 endtask

  //--------------------------------------------------------------------------
  // Drive One Wishbone Transfer
  //--------------------------------------------------------------------------
 task drive_transfer(wb_s_seq_item_base req);

  //----------------------------------------------------------------------
  // Drive request
  //----------------------------------------------------------------------
  @(vif.cb);

  vif.cb.addr_i  <= req.m_addr;
  vif.cb.wdata_i <= req.m_wdata;
  vif.cb.we_i    <= req.m_dir;
  vif.cb.sel_i   <= req.m_sel;

  vif.cb.cyc_i   <= 1'b1;
  vif.cb.stb_i   <= 1'b1;

 
  @(vif.cb);


  //----------------------------------------------------------------------
  // Wait for ACK/ERR
  //----------------------------------------------------------------------
  @(vif.cb);

  while (!(vif.cb.ack_o || vif.cb.err_o))
    @(vif.cb);

  //----------------------------------------------------------------------
  // Capture response
  //----------------------------------------------------------------------
  req.m_ack  = vif.cb.ack_o;
  req.m_err  = vif.cb.err_o;
  req.m_inta = vif.cb.inta_o;

  if (req.m_dir==WB_READ) begin
    req.m_rdata = vif.cb.rdata_o;

    `uvm_info(get_type_name(),
      $sformatf("ACK=%0b DATA=%08h ADDR=%08h",
                vif.cb.ack_o,
                vif.cb.rdata_o,
                req.m_addr),
      UVM_LOW)
  end

  @(vif.cb);
  if(req.m_addr!='h00B)
  @(vif.cb);
  //----------------------------------------------------------------------
  // Return bus to idle
  //----------------------------------------------------------------------
  vif.cb.cyc_i <= 1'b0;
  vif.cb.stb_i <= 1'b0;

 endtask
endclass

`endif // WB_S_DRIVER_BASE_SV

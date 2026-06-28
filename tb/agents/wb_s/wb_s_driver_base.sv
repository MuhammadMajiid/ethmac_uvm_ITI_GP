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

    super.run_phase(phase);
     reset_item();

    forever begin
      
      seq_item_port.get_next_item(req);
     

     `uvm_info(get_type_name(),
          $sformatf("Driving transaction:%s",
                    req.convert2string()),UVM_MEDIUM)

      drive_transfer(req);

      seq_item_port.item_done();

    end

  endtask

 task reset_item();
  vif.cb.addr  <=0 ;
  vif.cb.wdata <=0;
  vif.cb.we    <=0;
  vif.cb.sel   <=0;
  vif.cb.cyc   <=0;
  vif.cb.stb   <=0;
 @(posedge vif.clk);
 endtask

  //--------------------------------------------------------------------------
  // Drive One Wishbone Transfer
  //--------------------------------------------------------------------------
 task drive_transfer(wb_s_seq_item_base req);
    int timeout;
 @(posedge vif.clk);

  //--------------------------------------------------------------------------
  // Drive request
  //--------------------------------------------------------------------------
  vif.cb.addr  <= req.m_addr;
  vif.cb.wdata <= req.m_wdata;
  vif.cb.we    <= req.m_we;
  vif.cb.sel   <= req.m_sel;

  vif.cb.cyc   <= 1'b1;
  vif.cb.stb   <= 1'b1;

  // Keep request asserted for one cycle
  @(posedge vif.clk);

  //--------------------------------------------------------------------------
  // Return bus to idle
  //--------------------------------------------------------------------------
  vif.cb.cyc <= 1'b0;
  vif.cb.stb <= 1'b0;
  vif.cb.we  <=1'b0; 

  //--------------------------------------------------------------------------
  // Wait for ACK/ERR
  //--------------------------------------------------------------------------

   timeout = 1000;
 @(posedge vif.clk);
  while (!(vif.cb.ack || vif.cb.err) && (timeout > 0)) begin
    @(posedge vif.cb);
    timeout--;
  end

  if (timeout == 0) begin
    `uvm_error(get_type_name(), "Wishbone transaction timeout")

    req.m_ack   = 0;
    req.m_err   = 1;
    req.m_inta  = 0;
    req.m_rdata = '0;
  end
  else begin
    req.m_ack  = vif.cb.ack;
    req.m_err  = vif.cb.err;
    req.m_inta = vif.cb.inta;

    if (!req.m_we)
    begin
      req.m_rdata = vif.cb.rdata;
      
  `uvm_info(get_type_name(),
            $sformatf("ACK=%0b DATA=%08h ADDR=%08h",
                      vif.cb.ack,
                      vif.cb.rdata,
                      req.m_addr),
            UVM_LOW)
    end
  end

 @(posedge vif.clk);

endtask

endclass

`endif // WB_S_DRIVER_BASE_SV

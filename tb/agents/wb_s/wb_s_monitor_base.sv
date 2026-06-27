//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_s_monitor_base.sv
// Author   : Nada
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
// 
//==============================================================================
`ifndef WB_S_MONITOR_BASE_SV
`define WB_S_MONITOR_BASE_SV
class wb_s_monitor_base extends uvm_monitor;
  `uvm_component_utils(wb_s_monitor_base)

  virtual wb_s_if vif;
  uvm_analysis_port #(wb_s_seq_item_base) a_port;

  wb_s_config_obj m_config;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    if (!uvm_config_db #(wb_s_config_obj)::get(this, "", "config", m_config))
      `uvm_fatal(get_type_name(), "wb_s_config not found in config_db")
    vif = m_config.vif;
    if (vif == null)
      `uvm_fatal(get_type_name(), "wb_s monitor virtual interface not set")
    a_port = new("a_port", this);
  endfunction

  task run_phase(uvm_phase phase);
    wb_s_seq_item_base tr;

    forever
    begin
      @(posedge vif.clk);
        // Wait for start of a WISHBONE transfer
        // Transfer starts when both CYC_I and STB_I are asserted
      if (vif.cyc && vif.stb)
      begin
        tr =  wb_s_seq_item_base::type_id::create("tr");
       // Capture the transaction inputs
         tr.m_addr  = vif.addr;
         tr.m_wdata = vif.wdata;
         tr.m_we    = vif.we;
         tr.m_sel   = vif.sel;

        // Wait for response
       while (!(vif.ack || vif.err)) 
       begin
        @(posedge vif.clk);
        end

        // Capture response
         tr.m_rdata = vif.rdata;
         tr.m_ack   = vif.ack;
         tr.m_err   = vif.err;
         tr.m_inta  = vif.inta;

      // Broadcast to scoreboard and coverage collectors      
        a_port.write(tr);
      end
    end
  endtask

endclass
`endif // WB_S_MONITOR_BASE_SV

//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_s_monitor_base.sv
// Author   : Nada
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
// Passive monitor for the WISHBONE slave interface. Samples completed
// transfers through the interface's clocking block and publishes each one as a
// wb_s_seq_item_base on its analysis port for the RAL predictor,
// scoreboard, and coverage collectors.
//==============================================================================

`ifndef WB_S_MONITOR_BASE_SV
`define WB_S_MONITOR_BASE_SV

class wb_s_monitor_base extends uvm_monitor;

  `uvm_component_utils(wb_s_monitor_base)

  virtual wb_s_if vif;
  uvm_analysis_port #(wb_s_seq_item_base #(WB_S_ADDR_WIDTH, WB_DATA_WIDTH, WB_SEL_WIDTH)) a_port;
  uvm_analysis_port #(wb_s_seq_item_base #(WB_S_ADDR_WIDTH, WB_DATA_WIDTH, WB_SEL_WIDTH)) bd_status_ap;
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
    bd_status_ap = new("bd_status_ap", this);

  endfunction


  task run_phase(uvm_phase phase);

    wb_s_seq_item_base tr;

    wait (!vif.rst);

    forever begin

      @(vif.cb);

      // Detect beginning of a Wishbone transfer
      if (vif.cyc_i && vif.stb_i) begin

        tr = wb_s_seq_item_base#(
        WB_S_ADDR_WIDTH,
        WB_DATA_WIDTH,
        WB_SEL_WIDTH
      )::type_id::create("tr");

        //-----------------------------
        // Capture request
        //-----------------------------
        tr.m_addr  = vif.addr_i;
        tr.m_wdata = vif.wdata_i;
        tr.m_sel   = vif.sel_i;
        tr.m_dir   = wb_dir_t'(vif.we_i);

        //-----------------------------
        // Wait for completion
        //-----------------------------
        while (!(vif.cb.ack_o || vif.cb.err_o))
          @(vif.cb);

        //-----------------------------
        // Capture response
        //-----------------------------
        tr.m_rdata = vif.cb.rdata_o;
        tr.m_ack   = vif.cb.ack_o;
        tr.m_err   = vif.cb.err_o;
        tr.m_inta  = vif.cb.inta_o;

        //-----------------------------
        // Publish transaction
        //-----------------------------
        a_port.write(tr);

        begin : bd_done_filter
            localparam bit [31:0] BD_BASE = 32'h0000_0400;
            localparam bit [31:0] BD_END  = 32'h0000_0800;
            int unsigned word_offset;
        
            if ((tr.m_dir     == WB_READ)      &&   // host reading
                (tr.m_addr    >= BD_BASE)      &&   // within BD RAM
                (tr.m_addr    <  BD_END)       &&   // within BD RAM
                (tr.m_ack     == 1'b1)         &&   // successful cycle
                (tr.m_rdata[15] == 1'b0))           // E=0: DUT has written BD
            begin
                word_offset = (tr.m_addr - BD_BASE) >> 2;
                
                if (word_offset % 2 == 0) begin     // status word only (not RXPNT)
                  bd_status_ap.write(tr);
                end            
                    
            end
        end : bd_done_filter
      `uvm_info(get_full_name(),tr.convert2string(), UVM_MEDIUM)
      
      end

    end

  endtask

endclass

`endif // WB_S_MONITOR_BASE_SV

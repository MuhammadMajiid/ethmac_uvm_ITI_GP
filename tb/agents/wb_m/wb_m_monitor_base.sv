
`ifndef WB_M_MONITOR_BASE_SV
`define WB_M_MONITOR_BASE_SV

class wb_m_monitor_base extends uvm_monitor;

    `uvm_component_utils(wb_m_monitor_base)

    //--------------------------------------------------------------------------
    // TLM analysis port — broadcasts observed transactions to subscribers
    //--------------------------------------------------------------------------
    uvm_analysis_port #(wb_master_tx) ap;

    //--------------------------------------------------------------------------
    // Virtual interface and config
    //--------------------------------------------------------------------------
    virtual wb_master_if vif;
    wb_master_config     m_config;

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    //--------------------------------------------------------------------------
    // build_phase
    //--------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        ap = new("ap", this);
        if (!uvm_config_db #(wb_master_config)::get(this, "", "config", m_config))
            `uvm_fatal(get_type_name(), "wb_master_config not found in config_db")
        if (m_config.vif == null)
            `uvm_fatal(get_type_name(), "wb_master_if virtual interface not set")
        vif = m_config.vif;
    endfunction

    //--------------------------------------------------------------------------
    // run_phase — observe and broadcast transactions
    //--------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        wb_master_tx tx;
        forever begin
            // Wait for start of a Wishbone cycle
            @(vif.monitor_cb);
            if (vif.monitor_cb.cyc && vif.monitor_cb.stb) begin
                tx = wb_master_tx::type_id::create("tx");
                tx.m_addr = vif.monitor_cb.adr;
                tx.m_sel  = vif.monitor_cb.sel;
                tx.m_dir  = (vif.monitor_cb.we) ? wb_master_tx::WB_WRITE
                                                 : wb_master_tx::WB_READ;
                tx.m_data = vif.monitor_cb.dat_o;

                // Wait for ACK
                while (!vif.monitor_cb.ack) @(vif.monitor_cb);

                if (tx.m_dir == wb_master_tx::WB_READ)
                    tx.m_rdata = vif.monitor_cb.dat_i;

                `uvm_info(get_type_name(),
                          $sformatf("WB Master Monitor observed: %s", tx.convert2string()),
                          UVM_HIGH)

                ap.write(tx);
            end
        end
    endtask

endclass : wb_m_monitor_base

`endif // WB_M_MONITOR_BASE_SV

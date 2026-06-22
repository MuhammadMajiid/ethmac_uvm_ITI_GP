
`ifndef WB_M_DRIVER_BASE_SV
`define WB_M_DRIVER_BASE_SV

class wb_m_driver_base extends uvm_driver #(wb_master_tx);

    `uvm_component_utils(wb_m_driver_base)

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
    // build_phase — retrieve config object
    //--------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        if (!uvm_config_db #(wb_master_config)::get(this, "", "config", m_config))
            `uvm_fatal(get_type_name(), "wb_master_config not found in config_db")
        if (m_config.vif == null)
            `uvm_fatal(get_type_name(), "wb_master_if virtual interface not set")
        vif = m_config.vif;
    endfunction

    //--------------------------------------------------------------------------
    // run_phase — drive transactions using try_next_item (non-blocking pull)
    //--------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        // Drive bus to idle defaults
        vif.master_cb.cyc  <= 1'b0;
        vif.master_cb.stb  <= 1'b0;
        vif.master_cb.we   <= 1'b0;
        vif.master_cb.adr  <= '0;
        vif.master_cb.dat_o <= '0;
        vif.master_cb.sel  <= '0;

        forever begin
            wb_master_tx req;

            // Non-blocking pull — insert idle cycles when no item available
            seq_item_port.try_next_item(req);

            if (req != null) begin
                drive_transaction(req);
                seq_item_port.item_done();
            end else begin
                // Idle cycle
                @(vif.master_cb);
                vif.master_cb.cyc <= 1'b0;
                vif.master_cb.stb <= 1'b0;
            end
        end
    endtask

    //--------------------------------------------------------------------------
    // drive_transaction — perform a single Wishbone transfer
    //--------------------------------------------------------------------------
    task drive_transaction(wb_master_tx req);
        // Assert CYC and STB
        @(vif.master_cb);
        vif.master_cb.cyc   <= 1'b1;
        vif.master_cb.stb   <= 1'b1;
        vif.master_cb.we    <= (req.m_dir == wb_master_tx::WB_WRITE) ? 1'b1 : 1'b0;
        vif.master_cb.adr   <= req.m_addr;
        vif.master_cb.dat_o <= (req.m_dir == wb_master_tx::WB_WRITE) ? req.m_data : '0;
        vif.master_cb.sel   <= req.m_sel;

        // Wait for ACK
        @(vif.master_cb);
        while (!vif.master_cb.ack) @(vif.master_cb);

        // Capture read data
        if (req.m_dir == wb_master_tx::WB_READ)
            req.m_rdata = vif.master_cb.dat_i;

        // Deassert
        vif.master_cb.cyc <= 1'b0;
        vif.master_cb.stb <= 1'b0;
        vif.master_cb.we  <= 1'b0;

        `uvm_info(get_type_name(),
                  $sformatf("WB Master: %s addr=0x%08h data=0x%08h rdata=0x%08h",
                             req.m_dir.name(), req.m_addr, req.m_data, req.m_rdata),
                  UVM_HIGH)
    endtask

endclass : wb_m_driver_base

`endif // WB_M_DRIVER_BASE_SV

//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_cov_mdio.sv
// Author   : Muhammad Majid
// Date     : 2026-07-23
//------------------------------------------------------------------------------
// Description:
//   Functional coverage collector for the MDIO/MIIM interface.
//   Captures configurations written/read via the Wishbone Slave interface.
//==============================================================================

`ifndef ETH_COV_MDIO_SV
`define ETH_COV_MDIO_SV

class eth_cov_mdio extends uvm_component;
    `uvm_component_utils(eth_cov_mdio)

    // =========================================================================
    // Register model & TLM Fifos
    // =========================================================================
    eth_reg_block                               m_regmodel;
    uvm_tlm_analysis_fifo #(wb_s_seq_item_base) wb_s_fifo;
    uvm_analysis_export   #(wb_s_seq_item_base) wb_s_a_export;
    wb_s_seq_item_base                          m_wb_s_seq_item;

    // =========================================================================
    // Tracked Fields for Coverage
    // =========================================================================
    logic [WB_S_ADDR_WIDTH-1:0] m_addr;
    logic [WB_DATA_WIDTH-1:0]   m_wdata;
    logic [WB_DATA_WIDTH-1:0]   m_rdata;

    bit [7:0] m_clk_div;
    bit       m_miinopre;
    bit       m_wctrldata;
    bit       m_rstat;
    bit       m_scanstat;
    bit [4:0] m_rgad;
    bit [4:0] m_fiad;
    bit [15:0] m_ctrldata;

    // =========================================================================
    // Covergroups
    // =========================================================================
    // NOTE: bins below are sampled from RAL-mapped wishbone-slave writes.
    // m_addr equals the uvm_reg_map OFFSET passed to add_reg() in
    // eth_reg_block.sv (confirmed via eth_wb_adapter::reg2bus, which does
    // tr.m_addr = rw.addr with no scaling) -- NOT the byte address quoted in
    // the per-register header comments. MIIM map offsets are:
    //   MIIMODER='h00A  MIICOMMAND='h00B  MIIADDRESS='h00C
    //   MIITX_DATA='h00D  MIIRX_DATA='h00E(RO)  MIISTATUS='h00F(RO)
    covergroup m_mdio_cfg_cov;
        // Clock Divider (MIIMODER, map offset 0x00A)
        cp_clk_div: coverpoint m_clk_div {
            bins div_min = {8'h02}; // Assuming min reasonable div
            bins div_mid = {[8'h03:8'h7E]};
            bins div_max = {8'hFE}; // Assuming max even div
        }

        // Preamble Suppression (MIIMODER, map offset 0x00A)
        cp_miinopre: coverpoint m_miinopre {
            bins preamble_enabled  = {0};
            bins preamble_disabled = {1};
        }

        // Command Operations (MIICOMMAND, map offset 0x00B)
        cp_command: coverpoint {m_wctrldata, m_rstat, m_scanstat} {
            bins write_op = {3'b100};
            bins read_op  = {3'b010};
            bins scan_op  = {3'b001};
            illegal_bins ill_cmd = {3'b110, 3'b111, 3'b101, 3'b011};
        }

        // PHY Address (MIIADDRESS, map offset 0x00C)
        cp_phy_addr: coverpoint m_fiad {
            bins addr_0   = {5'h00};
            bins addr_max = {5'h1F};
            bins others   = {[5'h01:5'h1E]};
        }

        // Register Address (MIIADDRESS, map offset 0x00C)
        cp_reg_addr: coverpoint m_rgad {
            bins ctrl_reg   = {5'h00}; // Basic Mode Control Register
            bins status_reg = {5'h01}; // Basic Mode Status Register
            bins id1_reg    = {5'h02}; // PHY ID 1
            bins others     = {[5'h03:5'h1F]};
        }

        // Cross Commands with Register Addresses
        cross_cmd_reg: cross cp_command, cp_reg_addr {
            bins scan_op_ctrl_reg = binsof(cp_command.scan_op) && binsof(cp_reg_addr.ctrl_reg);
            bins scan_op_id1_reg  = binsof(cp_command.scan_op) && binsof(cp_reg_addr.id1_reg);
            bins scan_op_others   = binsof(cp_command.scan_op) && binsof(cp_reg_addr.others);
            bins read_op_others   = binsof(cp_command.read_op) && binsof(cp_reg_addr.others);

            // E.g., Writing to a read-only status register is generally invalid/ignored
            ignore_bins write_to_status = binsof(cp_command.write_op) && binsof(cp_reg_addr.status_reg);
        }
    endgroup

    // Separate covergroup for MIITX_DATA (map offset 0x00D) since it is
    // sampled on a different write than MIIMODER/MIICOMMAND/MIIADDRESS and
    // was previously never instrumented at all.
    covergroup m_mdio_txdata_cov;
        cp_ctrldata: coverpoint m_ctrldata {
            bins zero    = {16'h0000};
            bins all_one = {16'hFFFF};
            bins others  = {[16'h0001:16'hFFFE]};
        }
    endgroup

    // =========================================================================
    // Methods
    // =========================================================================
    extern function new(string name, uvm_component parent);
    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
    extern task run_phase(uvm_phase phase);
    extern task sample_wb_s_item();
endclass

function eth_cov_mdio::new(string name, uvm_component parent);
    super.new(name, parent);
    m_mdio_cfg_cov    = new();
    m_mdio_txdata_cov = new();
endfunction

function void eth_cov_mdio::build_phase(uvm_phase phase);
    super.build_phase(phase);
    wb_s_fifo     = new("wb_s_fifo", this);
    wb_s_a_export = new("wb_s_a_export", this);
endfunction

function void eth_cov_mdio::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    wb_s_a_export.connect(wb_s_fifo.analysis_export);
endfunction

task eth_cov_mdio::run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever sample_wb_s_item();
endtask

task eth_cov_mdio::sample_wb_s_item();
    wb_s_fifo.get(m_wb_s_seq_item);

    m_addr  = m_wb_s_seq_item.m_addr;
    m_wdata = m_wb_s_seq_item.m_wdata;
    m_rdata = m_wb_s_seq_item.m_rdata;

    // m_addr is the uvm_reg_map OFFSET (see eth_wb_adapter::reg2bus), which
    // matches the add_reg() calls in eth_reg_block.sv, NOT the register's
    // byte address from its header comment. MIIM registers sit at map
    // offsets 0x00A (MIIMODER) through 0x00F (MIISTATUS).
    if(m_addr == 'h00A) begin // MIIMODER
        m_clk_div  = m_wdata[7:0];
        m_miinopre = m_wdata[8];
    end
    if(m_addr == 'h00B) begin // MIICOMMAND
        m_scanstat  = m_wdata[0];
        m_rstat     = m_wdata[1];
        m_wctrldata = m_wdata[2];
    end
    if(m_addr == 'h00C) begin // MIIADDRESS
        m_fiad = m_wdata[4:0];
        m_rgad = m_wdata[12:8];
    end
    if(m_addr == 'h00D) begin // MIITX_DATA
        m_ctrldata = m_wdata[15:0];
    end

    if(!(&m_wb_s_seq_item.m_sel)) return;

    if(m_wb_s_seq_item.m_dir == WB_WRITE) begin
        `uvm_info("MDIO_COV", $sformatf("sample addr=0x%0h wdata=0x%0h rgad=0x%0h scan=%0d read=%0d write=%0d",
                    m_addr, m_wdata, m_rgad, m_scanstat, m_rstat, m_wctrldata), UVM_MEDIUM)

        if(m_addr == 'h00D)
            m_mdio_txdata_cov.sample();
        else
            m_mdio_cfg_cov.sample();

        // Reset volatile command bits after sampling
        if(m_addr == 'h00B) begin
            m_scanstat  = 0;
            m_rstat     = 0;
            m_wctrldata = 0;
        end
    end
endtask

`endif // ETH_COV_MDIO_SV

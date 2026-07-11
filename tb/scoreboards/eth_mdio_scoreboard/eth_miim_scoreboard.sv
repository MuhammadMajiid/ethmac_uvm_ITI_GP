`ifndef ETH_MIIM_SCOREBOARD_SV
`define ETH_MIIM_SCOREBOARD_SV

typedef struct {
    mdio_seq_item_base::op_code_e op_code;
    bit        mii_no_pre;
    bit [7:0]  clk_div;
    bit        w_ctrl_data;
    bit        r_stat;
    bit        scan_stat;
    bit [4:0]  reg_addr;
    bit [4:0]  phy_addr;
    bit [15:0] ctrl_data;
    bit [15:0] prsd_data;
    bit [1:0]  invalid;
    bit        busy; 
    bit        link_fail;
} mdio_cfg_reg_s;

class eth_miim_scoreboard extends uvm_scoreboard ;
    `uvm_component_utils(eth_miim_scoreboard)

    
    uvm_analysis_imp #(mdio_seq_item_base, eth_miim_scoreboard) mdio_export;

    eth_reg_block m_regmodel;
    
    miim_exp_cfg_regs m_cfg_reg_s;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        mdio_export = new("mdio_export", this);

        if (!uvm_config_db#(eth_reg_block)::get(this, "", "m_regmodel", m_regmodel))
            `uvm_fatal(get_type_name(), "eth_reg_block (m_regmodel) not found in config_db")
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

    endfunction
    
    function void run_phase(uvm_phase phase);
        super.run_phase(phase);
    endfunction

    extern task read_cfg_regs();
    extern function write_predictor();

endclass


task eth_miim_scoreboard::read_cfg_regs();

    uvm_status_e status;
    m_regmodel.MIIMODER.mirror(status, UVM_CHECK, UVM_BACKDOOR);
    m_exp_reg.mii_no_pre = m_regmodel.MIIMODER.MIINOPRE.get_mirrored_value();
    m_exp_reg.clk_div    = m_regmodel.MIIMODER.CLKDIV.get_mirrored_value();
    
    m_regmodel.MIICOMMAND.mirror(status, UVM_CHECK, UVM_BACKDOOR);
    m_exp_reg.w_ctrl_data = m_regmodel.MIICOMMAND.WCTRLDATA.get_mirrored_value();
    m_exp_reg.r_stat      = m_regmodel.MIICOMMAND.RSTAT.get_mirrored_value();
    m_exp_reg.scan_stat   = m_regmodel.MIICOMMAND.SCANSTAT.get_mirrored_value();
    

    m_regmodel.MIIADDRESS.mirror(status, UVM_CHECK, UVM_BACKDOOR);
    m_exp_reg.reg_addr = m_regmodel.MIIADDRESS.RGAD.get_mirrored_value();
    m_exp_reg.phy_addr = m_regmodel.MIIADDRESS.FIAD.get_mirrored_value();
   
    m_regmodel.MIITX_DATA.mirror(status, UVM_CHECK, UVM_BACKDOOR);
    m_exp_reg.ctrl_data = m_regmodel.MIITX_DATA.CTRLDATA.get_mirrored_value();

    m_regmodel.MIIRX_DATA.mirror(status, UVM_CHECK, UVM_BACKDOOR);
    

    m_regmodel.MIISTATUS.mirror(status, UVM_CHECK, UVM_BACKDOOR);
    m_exp_reg.invalid = m_regmodel.MIISTATUS.NVALID.get_mirrored_value();
    m_exp_reg.busy = m_regmodel.MIISTATUS.BUSY.get_mirrored_value();
    m_exp_reg.link_fail = m_regmodel.MIISTATUS.LINKFAIL.get_mirrored_value();

endtask

function eth_mii_scoreboard::write_predictor();


endfunction


`endif 


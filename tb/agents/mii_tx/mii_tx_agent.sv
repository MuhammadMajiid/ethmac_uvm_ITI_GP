//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mii_tx_agent.sv
// Author   : Mounir
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
// UVM agent for the MII Transmit interface.
// Instantiates and connects the three sub-components:
//       - mii_tx_driver       : drives MColl/MCrS stimulus
//       - mii_tx_monitor      : observes MTxD/MTxEN output
//       - mii_tx_sequencer    : arbitrates sequence items
// Reads mii_tx_config_obj from uvm_config_db during
// build_phase to determine active/passive mode 
//       - UVM_ACTIVE  : driver + sequencer + monitor all created
//       - UVM_PASSIVE : only monitor created (no stimulus driven)
//==============================================================================

`ifndef MII_TX_AGENT_SV
`define MII_TX_AGENT_SV

class mii_tx_agent extends uvm_agent;

    `uvm_component_utils(mii_tx_agent)

    uvm_analysis_port #(mii_tx_seq_item_base) agent_a_port;  

    mii_tx_driver_base m_driver;
    mii_tx_monitor_base m_monitor;
    mii_tx_sequencer_base m_sequencer;

    mii_tx_config_obj m_config;

    function new(string name = "mii_tx_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Get config object from database
        if(!uvm_config_db #(mii_tx_config_obj)::get(this, "", "config", m_config)) begin
            `uvm_fatal("build_phase" ,"Unable to get configuration object mii_tx_config_obj")
        end

        // Instantiate driver & monitor if the agent is active
        if(m_config.is_active == UVM_ACTIVE) begin
            m_driver    = mii_tx_driver_base::type_id::create("m_driver", this);
            m_sequencer = mii_tx_sequencer_base::type_id::create("m_sequencer", this);
        end else begin
            `uvm_info("build_phase", "agent passive", UVM_MEDIUM);
        end

        // Instantiate monitor
        m_monitor    = mii_tx_monitor_base::type_id::create("m_monitor", this);
        // Instantiate analysis port of agent
        agent_a_port = new("agent_a_port", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if(m_config.is_active == UVM_ACTIVE) begin
            // Assign driver vif handle to that in config object
            m_driver.vif = m_config.vif;
            // Connect driver port to sequencer Export
            m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
        end else begin
            `uvm_info("connect_phase" , "agent passive" ,UVM_MEDIUM);
        end

        // Assign monitor vif handle to that in config object
        m_monitor.vif = m_config.vif;
       m_sequencer.vif = m_config.vif;
        // Connect transaction analysis port of monitor to analysis port of agent
        m_monitor.monitor_tr_a_port.connect(agent_a_port);
    endfunction

endclass : mii_tx_agent

`endif 
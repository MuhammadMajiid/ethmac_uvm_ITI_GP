//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mii_tx_monitor_base.sv
// Author   : Mounir
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
// Base UVM monitor for the MII Transmit Agent.
// Passively observes all signals on mii_tx_if and converts
// them into mii_tx_seq_item transactions broadcast to the
// scoreboard and coverage collector via an analysis port.
//==============================================================================

`ifndef MII_TX_MONITOR_BASE_SV
`define MII_TX_MONITOR_BASE_SV

class mii_tx_monitor_base extends uvm_monitor;

    `uvm_component_utils(mii_tx_monitor_base)

    uvm_analysis_port #(mii_tx_seq_item_base) monitor_tr_a_port;

    virtual mii_tx_if vif;

    mii_tx_seq_item_base m_seq_item;
	
   
    
    function new(string name = "mii_tx_monitor_base", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor_tr_a_port = new("monitor_tr_a_port", this);	
    endfunction

    task run_phase(uvm_phase phase);

    super.run_phase(phase);

    mon_reset();

    forever begin

        m_seq_item = mii_tx_seq_item_base::type_id::create("m_seq_item");

        mon_items(m_seq_item);

    end

    endtask

    // Task: mon_reset
    task mon_reset();
        // Reset deassertion 
        @(negedge vif.rst);
        `uvm_info(get_type_name(),"Begin monitoring after reset deassertion", UVM_LOW)
    endtask 
	


    // Task: mon_items
    task mon_items(mii_tx_seq_item_base m_seq_item);
        // Wait until clocking block triggers at positive edge
        @(vif.cb_mii_tx);

        // DUT input signals -> output from testbench
        m_seq_item.MColl  = vif.MColl;
        m_seq_item.MCrS   = vif.MCrS;

        // DUT output signals -> input to testbench
        m_seq_item.MTxD   = vif.cb_mii_tx.MTxD;
        m_seq_item.MTxEN  = vif.cb_mii_tx.MTxEN;
        m_seq_item.MTxERR = vif.cb_mii_tx.MTxERR;
		


        // Send transaction to agent analysis port
        monitor_tr_a_port.write(m_seq_item);

        `uvm_info(get_name(), m_seq_item.convert2string(), UVM_HIGH);
    endtask

	


endclass : mii_tx_monitor_base

`endif
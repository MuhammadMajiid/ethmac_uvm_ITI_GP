//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : reset_agent.sv
// Author   : Nada
// Date     : 2026-07-16
//------------------------------------------------------------------------------
// Description:
// UVM reset agent responsible for driving DUT hardware reset.
// Instantiates and connects the reset sequencer and reset driver.
//==============================================================================

`ifndef RESET_AGENT_SV
`define RESET_AGENT_SV

class reset_agent extends uvm_agent;

  `uvm_component_utils(reset_agent)

  //------------------------------------------------------------
  // Components
  //------------------------------------------------------------
  reset_driver    m_driver;
  reset_sequencer m_sequencer;

  //------------------------------------------------------------
  // Configuration
  //------------------------------------------------------------
  reset_config_obj m_config;

  //------------------------------------------------------------
  // Constructor
  //------------------------------------------------------------
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  //------------------------------------------------------------
  // Build Phase
  //------------------------------------------------------------
  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    if(!uvm_config_db#(reset_config_obj)::get(
          this,
          "",
          "config",
          m_config))
      `uvm_fatal(get_type_name(),
                 "reset_config_obj not found")
				 
	 if (m_config.vif == null)
      `uvm_fatal(get_type_name(), "reset virtual interface not set")			 

    if(m_config.is_active == UVM_ACTIVE) begin

      m_driver =
        reset_driver::type_id::create("m_driver", this);

      m_sequencer =
        reset_sequencer::type_id::create("m_sequencer", this);

    end

  endfunction

  //------------------------------------------------------------
  // Connect Phase
  //------------------------------------------------------------
  function void connect_phase(uvm_phase phase);

    super.connect_phase(phase);
	
   

    if(m_config.is_active == UVM_ACTIVE)begin
		m_driver.vif = m_config.vif;
      m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
	  end

  endfunction

endclass

`endif
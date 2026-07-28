//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_env_mdio.sv
//------------------------------------------------------------------------------
// Description:
//   Extended from base environment, used for creating the MDIO/MIIM agent,
//   MDIO scoreboard, and MDIO coverage. Structure mirrors eth_env_tx.sv.
//==============================================================================

`ifndef ETH_ENV_MDIO_SV
`define ETH_ENV_MDIO_SV
class eth_env_mdio extends eth_env_base;
  `uvm_component_utils(eth_env_mdio)

  // declare MDIO agent handle
  mdio_agent            m_mdio_agent;

  // declare MDIO scoreboard handle
  eth_mdio_scoreboard    m_mdio_sb;

  // declare MDIO coverage handle
  eth_cov_mdio           m_cov_mdio;

  // Always-on PHY responder: answers m_mdio_agent's driver so PHY-read
  // frames (RSTAT/SCANSTAT) never block forever waiting on a sequence.
  // Kept alive for the whole test in run_phase(); exposed on the virtual
  // sequencer (m_v_sqr.m_mdio_phy_rsp) so virtual sequences can update its
  // phy_data live (e.g. for a link-fail test case).
  mdio_seq_phy_responder m_mdio_phy_rsp;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Distribute MDIO config down to its agent
    uvm_config_db #(mdio_config_obj) ::set(this, "m_mdio_agent", "config", m_config.m_mdio_config);

    // build MDIO agent
    m_mdio_agent = mdio_agent::type_id::create("m_mdio_agent", this);

    // build MDIO scoreboard
    uvm_config_db #(mdio_config_obj) ::set(this, "m_mdio_sb", "config", m_config.m_mdio_config);
    m_mdio_sb = eth_mdio_scoreboard::type_id::create("m_mdio_sb", this);

    // build MDIO coverage
    m_cov_mdio = eth_cov_mdio::type_id::create("m_cov_mdio", this);

    // build the always-on PHY responder sequence object (started in run_phase)
    m_mdio_phy_rsp = mdio_seq_phy_responder::type_id::create("m_mdio_phy_rsp");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Assign ral handle to MDIO agent config so the driver/monitor/scoreboard
    // can each see the shared register model where needed.
    m_config.m_mdio_config.m_regmodel = m_regmodel;

    m_cov_mdio.m_regmodel = m_config.m_regmodel;

    // Connect the MDIO sequencer + PHY responder handle into the virtual
    // sequencer so eth_v_seq_mdio_lib.sv sequences can reach them.
    m_v_sqr.m_mdio_sqr     = m_mdio_agent.m_sequencer;
    m_v_sqr.m_mdio_phy_rsp = m_mdio_phy_rsp;

    // Connect MDIO agent's monitor analysis port to the scoreboard's
    // analysis export (bus-level MDIO frames observed on the wire)
    m_mdio_agent.a_port.connect(m_mdio_sb.a_export);

    // Connect wishbone-slave agent's analysis port to the MDIO coverage's
    // analysis export (RAL-level register writes drive the covergroups)
    m_wb_s_agent.a_port.connect(m_cov_mdio.wb_s_a_export);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    // Keep the PHY responder running for the entire test. Not forked: this
    // is the standard "background sequence lives as long as run_phase does"
    // pattern -- the phase itself only ends once test-level objections are
    // dropped, at which point this task is killed along with everything
    // else in the phase.
    if (m_config.m_mdio_config.is_active == UVM_ACTIVE)
      m_mdio_phy_rsp.start(m_mdio_agent.m_sequencer);
  endtask

endclass
`endif // ETH_ENV_MDIO_SV

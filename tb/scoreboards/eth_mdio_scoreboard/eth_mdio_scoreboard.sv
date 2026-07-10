//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_mdio_scoreboard.sv
// Author   : Muhammad Majid
// Date     : 2026-07-03
//------------------------------------------------------------------------------
// Description:
//   Scoreboard for the MIIM (MDIO) module. Compares Host/Wishbone commands
//   against the actual physical MDIO transactions observed on the bus.
//==============================================================================

`ifndef ETH_MDIO_SCOREBOARD_SV
`define ETH_MDIO_SCOREBOARD_SV

typedef struct {
    
    // ------------------------------------------------------------------
    // From the TX BD status word (wb_slave_monitor observed DATA_I)
    // ------------------------------------------------------------------
    bit [7:0]  clk_div;           // BD[31:16] – payload byte count
    bit        no_pre;            // BD[15]    – ready / armed flag
    bit        wr_ctrl_data;           // BD[14]    – per-BD interrupt enable
    bit        r_stat;            // BD[13]    – wrap bit (last BD in ring)
    bit        s_stat;        // BD[12]    – per-packet pad enable
    bit [4:0]  rgad;        // BD[11]    – per-packet CRC enable
    bit [4:0]  fiad;         // Pointer word – DMA source address
}m_cfg_s;

class eth_mdio_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(eth_mdio_scoreboard)

  parameter SEM_NO_KEYS = 1;


  // =========================================================================
  // Analysis fifo
  // =========================================================================
  uvm_tlm_analysis_fifo  #(mdio_seq_item_base)      a_fifo;
  // =========================================================================
  // Analysis export
  // =========================================================================
  uvm_analysis_export  #(mdio_seq_item_base)        a_export;
  // =========================================================================
  // Transaction for storing last item pulled from tlm fifo
  // =========================================================================
  mdio_seq_item_base                                m_wb_m_seq_item;
  // =========================================================================
  //  Configuration object 
  // =========================================================================
  mdio_scoreboard_config_obj                        m_config;
  // =========================================================================
  // Register block
  // =========================================================================
  eth_reg_block                                     m_regmodel;   
  // =========================================================================
  // Semaphore for getting mii tx transaction from fifo
  // =========================================================================
  semaphore                                         m_sem; 


  // =========================================================================
  // Constructor
  // =========================================================================
  extern function new(string name,uvm_component parent);
  
  function new(string name = "eth_mdio_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction


  extern task run_phase(uvm_phase phase);
    wb_tx   host_cmd;
    mdio_tx actual_mdio;
    mdio_tx expected_mdio;

    forever begin
      // 1. Wait for a command to be sent to the MAC via the Wishbone bus
      wb_fifo.get(host_cmd);

      // Note: In a real environment, you would filter Wishbone transactions here
      // to ONLY process writes made to the MIIM Command/Address registers.
      // We will assume 'host_cmd' is already confirmed to be an MDIO trigger.

      // 2. Predict what the MAC should do on the MDIO pins
      expected_mdio = predict_mdio_traffic(host_cmd);

      // 3. Wait for the MAC to actually drive the MDIO pins
      // (This pulls the transaction your mdio_monitor_base broadcasted)
      mdio_fifo.get(actual_mdio);

      // 4. Compare Expected vs Actual
      if (actual_mdio.compare(expected_mdio)) begin
        `uvm_info("SCB_MATCH", $sformatf("MDIO Frame Matched! \nExpected: %s\nActual: %s",
                                         expected_mdio.sprint(), actual_mdio.sprint()), UVM_HIGH)
        match_count++;
      end else begin
        `uvm_error("SCB_MISMATCH", $sformatf("MDIO Frame Mismatch! \nExpected: %s\nActual: %s",
                                             expected_mdio.sprint(), actual_mdio.sprint()))
        mismatch_count++;
      end
    end
  endtask

  // -------------------------------------------------------------------------
  // Function: predict_mdio_traffic
  // Description: Translates a Wishbone register write into an expected MDIO frame
  // -------------------------------------------------------------------------
  virtual function mdio_tx predict_mdio_traffic(wb_tx host_cmd);
    mdio_tx exp_tx = mdio_tx::type_id::create("exp_tx");

    // Example Mapping Logic:
    // You will need to map your specific Wishbone register addresses to the MDIO fields.
    // If CPU wrote to MIIADDRESS register (e.g., containing PHY and REG addresses):
    exp_tx.phy_addr = host_cmd.data[12:8]; // Assuming PHY address is at bits 12-8
    exp_tx.reg_addr = host_cmd.data[4:0];  // Assuming REG address is at bits 4-0

    // If CPU wrote to MIICOMMAND register to trigger a Read (op = 10):
    exp_tx.op = mdio_tx::READ;

    // If it was a write command, the expected data is what the CPU wrote to MIITX_DATA
    // exp_tx.data = host_cmd.data[15:0];

    return exp_tx;
  endfunction

  // -------------------------------------------------------------------------
  // Report Phase
  // -------------------------------------------------------------------------
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SCB_REPORT", $sformatf("Simulation Complete. Matches: %0d, Mismatches: %0d",
                                      match_count, mismatch_count), UVM_NONE)
  endfunction

endclass


// =============================================================================
//  IMPLEMENTATION
// =============================================================================

function eth_mdio_scoreboard::new(string name = "eth_mdio_scoreboard", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void eth_mdio_scoreboard::build_phase(uvm_phase phase);
    super.build_phase(phase);
    a_fifo = new("a_fifo", this);
    m_sem  =new(SEM_NO_KEYS);
    // get config object from database
    if (!uvm_config_db #(eth_tx_scoreboard_config_obj)::get(this, "", "config", m_config))
      `uvm_error(get_type_name(), "eth_tx_scoreboard_config not found in config_db")
endfunction

function void eth_mdio_scoreboard::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // assign ral handle to it's corresponding in config
    m_regmodel=m_config.m_regmodel;
    
    // Connect each export with it's corrosponding fifo
    a_export.connect(a_fifo.analysis_export);
endfunction 

task run_phase(uvm_phase phase);
endtask

`endif // ETH_MDIO_SCOREBOARD_SV

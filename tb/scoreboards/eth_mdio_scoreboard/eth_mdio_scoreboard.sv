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

import mdio_seq_item_pkg::*;

typedef struct {
    op_code_e   op_code;
    bit                             mii_no_pre;
    bit [ETH_CTRL_CLK_DIV_LEN-1:0]  clk_div;
    bit                             w_ctrl_data;
    bit                             r_stat;
    bit                             scan_stat;
    bit [ETH_CTRL_ADDR_LEN-1:0]     reg_addr;
    bit [ETH_CTRL_ADDR_LEN-1:0]     phy_addr;
    bit [ETH_CTRL_ADDR_LEN-1:0]     wr_data;
    bit [ETH_CTRL_DATA_LEN-1:0]     rd_data;
    bit                             invalid;
    bit                             busy;
    bit                             link_fail;
} mdio_cfg_reg_s;

class eth_mdio_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(eth_mdio_scoreboard)



  // Analysis fifo

  uvm_tlm_analysis_fifo  #(mdio_seq_item_base)      a_fifo;

  // Analysis export

  uvm_analysis_export  #(mdio_seq_item_base)        a_export;

  // Transaction for storing last item pulled from tlm fifo

  mdio_seq_item_base                                m_mdio_seq_item;

  //  Configuration object

  mdio_config_obj                    m_config;

  // Register block

  eth_reg_block                                     m_regmodel;



  // Configuration struct

  mdio_cfg_reg_s m_cfg_reg_s;

  bit m_exp_rd_pkt[$];
  bit m_exp_wr_pkt[$];
  bit m_actual_rd_pkt[$];


  // fuctions and tasks

  extern function new(string name,uvm_component parent);
  extern function void build_phase(uvm_phase phase);
  extern function void connect_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);

  extern task get_seq_item();
  extern task read_cfg_regs();
  extern task read_stat_regs();
  extern task pred_write();
  extern task comp_write(input mdio_seq_item_base item);
  extern task pred_read();
  extern task comp_read();
  extern task comp_linkfail();
  extern task comp_clk_period();

endclass



//  IMPLEMENTATION

function eth_mdio_scoreboard::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction

function void eth_mdio_scoreboard::build_phase(uvm_phase phase);
    super.build_phase(phase);
    a_fifo = new("a_fifo", this);
    a_export = new("a_export", this);
    // get config object from database
    if (!uvm_config_db #(mdio_config_obj)::get(this, "", "config", m_config))
      `uvm_error(get_type_name(), "mdio_config_obj not found in config_db")

    if (m_config != null && m_config.m_regmodel != null)
      m_regmodel = m_config.m_regmodel;
endfunction

function void eth_mdio_scoreboard::connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Re-sync the RAL handle from the shared config object; the environment
    // may populate it during connect_phase after the scoreboard is built.
    if (m_config != null && m_config.m_regmodel != null)
      m_regmodel = m_config.m_regmodel;

    // Connect each export with it's corrosponding fifo
    a_export.connect(a_fifo.analysis_export);
endfunction

task eth_mdio_scoreboard::run_phase(uvm_phase phase);

  forever
  begin
      get_seq_item();
      read_cfg_regs();
      if(m_cfg_reg_s.w_ctrl_data) begin
          do begin
            @(posedge m_config.vif.mdc); // Replaced #1 with clock edge
            read_stat_regs();
          end
          while(m_cfg_reg_s.busy);
          pred_write();
          comp_write(m_mdio_seq_item);
      end
      else if(m_cfg_reg_s.scan_stat) begin
          do begin
            @(posedge m_config.vif.mdc); // Replaced #1 with clock edge
            read_stat_regs();
        end
          while(m_cfg_reg_s.invalid);
          pred_read();
          comp_read();
          comp_linkfail();
      end
      else if(m_cfg_reg_s.r_stat) begin
          do begin
            @(posedge m_config.vif.mdc); // Replaced #1 with clock edge
            read_stat_regs();
          end
          while(m_cfg_reg_s.busy);
          pred_read();
          comp_read();
          comp_linkfail();
        end

      comp_clk_period();
  end


endtask

task eth_mdio_scoreboard::get_seq_item();
        // Get transaction item from fifo
        a_fifo.get(m_mdio_seq_item);
        `uvm_info(get_type_name(),m_mdio_seq_item.convert2string(),UVM_HIGH)

endtask

task eth_mdio_scoreboard::read_cfg_regs();

  uvm_status_e status;

  if (m_regmodel == null) begin
    if (m_config != null && m_config.m_regmodel != null)
      m_regmodel = m_config.m_regmodel;

    if (m_regmodel == null) begin
      `uvm_warning(get_type_name(), "MDIO register model unavailable; skipping scoreboard cfg read")
      return;
    end
  end

  m_regmodel.MIIMODER.mirror(status, UVM_CHECK, UVM_BACKDOOR);
  m_cfg_reg_s.mii_no_pre = m_regmodel.MIIMODER.MIINOPRE.get_mirrored_value();
  m_cfg_reg_s.clk_div    = m_regmodel.MIIMODER.CLKDIV.get_mirrored_value();

  m_regmodel.MIICOMMAND.mirror(status, UVM_CHECK, UVM_BACKDOOR);
  m_cfg_reg_s.w_ctrl_data = m_regmodel.MIICOMMAND.WCTRLDATA.get_mirrored_value();
  m_cfg_reg_s.r_stat      = m_regmodel.MIICOMMAND.RSTAT.get_mirrored_value();
  m_cfg_reg_s.scan_stat   = m_regmodel.MIICOMMAND.SCANSTAT.get_mirrored_value();


  m_regmodel.MIIADDRESS.mirror(status, UVM_CHECK, UVM_BACKDOOR);
  m_cfg_reg_s.reg_addr = m_regmodel.MIIADDRESS.RGAD.get_mirrored_value();
  m_cfg_reg_s.phy_addr = m_regmodel.MIIADDRESS.FIAD.get_mirrored_value();

  m_regmodel.MIITX_DATA.mirror(status, UVM_CHECK, UVM_BACKDOOR);
  m_cfg_reg_s.wr_data = m_regmodel.MIITX_DATA.CTRLDATA.get_mirrored_value();

endtask

task eth_mdio_scoreboard::read_stat_regs();
  uvm_status_e status;
  m_regmodel.MIIRX_DATA.mirror(status, UVM_CHECK, UVM_BACKDOOR);
  m_cfg_reg_s.rd_data = m_regmodel.MIIRX_DATA.PRSD.get_mirrored_value();

  m_regmodel.MIISTATUS.mirror(status, UVM_CHECK, UVM_BACKDOOR);
  m_cfg_reg_s.invalid   = m_regmodel.MIISTATUS.NVALID.get_mirrored_value();
  m_cfg_reg_s.busy      = m_regmodel.MIISTATUS.BUSY.get_mirrored_value();
  m_cfg_reg_s.link_fail = m_regmodel.MIISTATUS.LINKFAIL.get_mirrored_value();
endtask

task eth_mdio_scoreboard::pred_write();

m_exp_wr_pkt.delete();


  // Check if no preamble is disabled then push preamble
  if(!m_cfg_reg_s.mii_no_pre) begin
    for (int i=ETH_CTRL_PREAMBLE_LEN-1; i>=0; i--)
    m_exp_wr_pkt.push_back(1);
  end

  // push start of frame
  m_exp_wr_pkt.push_back(0);
  m_exp_wr_pkt.push_back(1);

  // push opcode
  m_exp_wr_pkt.push_back(0);
  m_exp_wr_pkt.push_back(1);

  // push fiad
  for (int i=ETH_CTRL_ADDR_LEN-1; i>=0; i--)
      m_exp_wr_pkt.push_back(m_cfg_reg_s.phy_addr[i]);

  // push rgad
  for (int i=ETH_CTRL_ADDR_LEN-1; i>=0; i--)
      m_exp_wr_pkt.push_back(m_cfg_reg_s.reg_addr[i]);

  //push turn around (TA = 10 for write per spec)
  m_exp_wr_pkt.push_back(1);
  m_exp_wr_pkt.push_back(0);

  // push data
  for (int i=ETH_CTRL_DATA_LEN-1; i>=0; i--)
      m_exp_wr_pkt.push_back(m_cfg_reg_s.wr_data[i]);

endtask

task eth_mdio_scoreboard::pred_read();

m_exp_rd_pkt.delete();

  // Check if no preamble is disabled then push preamble
  if(!m_cfg_reg_s.mii_no_pre) begin
    for (int i=ETH_CTRL_PREAMBLE_LEN-1; i>=0; i--)
    m_exp_rd_pkt.push_back(1);
  end

  // push start of frame
  m_exp_rd_pkt.push_back(0);
  m_exp_rd_pkt.push_back(1);

  // push opcode
  m_exp_rd_pkt.push_back(1);
  m_exp_rd_pkt.push_back(0);

  // push fiad
  for (int i=ETH_CTRL_ADDR_LEN-1; i>=0; i--)
      m_exp_rd_pkt.push_back(m_cfg_reg_s.phy_addr[i]);

  // push rgad
  for (int i=ETH_CTRL_ADDR_LEN-1; i>=0; i--)
      m_exp_rd_pkt.push_back(m_cfg_reg_s.reg_addr[i]);

  //push turn around
  m_exp_rd_pkt.push_back(1);
  m_exp_rd_pkt.push_back(0);

  // push data
  for (int i=ETH_CTRL_DATA_LEN-1; i>=0; i--)
      m_exp_rd_pkt.push_back(m_cfg_reg_s.rd_data[i]);

endtask


task eth_mdio_scoreboard::comp_write(input mdio_seq_item_base item);
  int idx =0;
  bit err =0;
  bit temp[$];

    // Compare preamble
    if(!m_cfg_reg_s.mii_no_pre) begin
      temp=m_exp_wr_pkt[idx +: ETH_CTRL_PREAMBLE_LEN];
      if({>>{temp}}!=item.preamble) begin
        `uvm_error(get_type_name(),
          $sformatf("Preamble mismatch  Field Offset: %0d\n Expected: %0p\n Actual: %0p", idx,temp,item.preamble))
          err =1;
      end
      idx+=ETH_CTRL_PREAMBLE_LEN;
    end
    // Compare start of frame
    temp=m_exp_wr_pkt[idx +: ETH_CTRL_ST_LEN];
    if({>>{temp}}!=item.st) begin
        `uvm_error(get_type_name(),
        $sformatf("Start of frame mismatch  Field Offset: %0d\n Expected: %0p\n Actual: %0p", idx,temp,item.st))
        err =1;
    end
    // Compare opcode
    idx+=ETH_CTRL_ST_LEN;
    temp=m_exp_wr_pkt[idx +: ETH_CTRL_OPCODE_LEN];
    if({temp[0],temp[1]} != item.op) begin
        `uvm_error(get_type_name(),
          $sformatf("Opcode mismatch  Field Offset: %0d\n Expected: %0p\n Actual: %0d", idx,temp,bit'(item.op)))
        err =1;
    end

    // Compare phy address
    idx+=ETH_CTRL_OPCODE_LEN;
    temp=m_exp_wr_pkt[idx +: ETH_CTRL_ADDR_LEN];
    if({>>{temp}}!= item.phy_addr) begin
        `uvm_error(get_type_name(),
        $sformatf("Phy address mismatch  Field Offset: %0d\n Expected: %0p\n Actual: %0p", idx,temp,item.phy_addr))
        err =1;
    end
    // Compare register address
    idx+=ETH_CTRL_ADDR_LEN;
    temp=m_exp_wr_pkt[idx +: ETH_CTRL_ADDR_LEN];
    if({>>{temp}}!= item.reg_addr) begin
        `uvm_error(get_type_name(),
        $sformatf("Register address mismatch  Field Offset: %0d\n Expected: %0p\n Actual: %0p", idx,temp,item.reg_addr))
        err =1;
    end
    // Compare turnaround
    idx+=ETH_CTRL_ADDR_LEN;
    temp=m_exp_wr_pkt[idx +: ETH_CTRL_TA_LEN]; // Changed to wr_pkt
    if({>>{temp}}!= item.turn_around) begin // Changed m_mdio_seq_item to item
        `uvm_error(get_type_name(),
        $sformatf("Turnaround mismatch  Field Offset: %0d\n Expected: %0p\n Actual: %0p", idx,temp,item.turn_around))
        err =1;
    end
    // Compare data
    idx+=ETH_CTRL_TA_LEN;
    temp=m_exp_wr_pkt[idx +: ETH_CTRL_DATA_LEN]; // Changed to wr_pkt
    if({>>{temp}}!= item.data) begin // Changed m_mdio_seq_item to item
        `uvm_error(get_type_name(),
        $sformatf("Data mismatch  Field Offset: %0d\n Expected: %0p\n Actual: %0p", idx,temp,item.data))
        err =1;
    end
    if(!err)
        `uvm_info(get_type_name(),"Management Write Packet comparison PASSED",UVM_LOW)
endtask


task eth_mdio_scoreboard::comp_read();
    int idx =0;
    bit err =0;
    bit temp[$];

    // Removed forever begin and continue logic, this runs once per transaction
    // Compare preamble
    if(!m_cfg_reg_s.mii_no_pre) begin
      temp=m_exp_rd_pkt[idx +: ETH_CTRL_PREAMBLE_LEN];
      if({>>{temp}}!=m_mdio_seq_item.preamble) begin
          `uvm_error(get_type_name(),
          $sformatf("Preamble mismatch  Field Offset: %0d\n Expected: %0p\n Actual: %0p", idx,temp,m_mdio_seq_item.preamble))
          err =1;
      end
      idx+=ETH_CTRL_PREAMBLE_LEN;
    end
    // Compare start of frame
    temp=m_exp_rd_pkt[idx +: ETH_CTRL_ST_LEN];
    if({>>{temp}}!=m_mdio_seq_item.st) begin
        `uvm_error(get_type_name(),
        $sformatf("Start of frame mismatch  Field Offset: %0d\n Expected: %0p\n Actual: %0p", idx,temp,m_mdio_seq_item.st))
        err =1;
    end
    // Compare opcode
    idx+=ETH_CTRL_ST_LEN;
    temp=m_exp_rd_pkt[idx +: ETH_CTRL_OPCODE_LEN];
    if({temp[1],temp[0]} != m_mdio_seq_item.op) begin
        `uvm_error(get_type_name(),
        $sformatf("Opcode mismatch  Field Offset: %0d\n Expected: %0p\n Actual: %0d", idx,temp,bit'(m_mdio_seq_item.op)))
        err =1;
    end
    // Compare phy address
    idx+=ETH_CTRL_OPCODE_LEN;
    temp=m_exp_rd_pkt[idx +: ETH_CTRL_ADDR_LEN];
    if({>>{temp}}!= m_mdio_seq_item.phy_addr) begin
        `uvm_error(get_type_name(),
        $sformatf("Phy address mismatch  Field Offset: %0d\n Expected: %0p\n Actual: %0p", idx,temp,m_mdio_seq_item.phy_addr))
        err =1;
    end
    // Compare register address
    idx+=ETH_CTRL_ADDR_LEN;
    temp=m_exp_rd_pkt[idx +: ETH_CTRL_ADDR_LEN];
    if({>>{temp}}!= m_mdio_seq_item.reg_addr) begin
        `uvm_error(get_type_name(),
        $sformatf("Register address mismatch  Field Offset: %0d\n Expected: %0p\n Actual: %0p", idx,temp,m_mdio_seq_item.reg_addr))
        err =1;
    end
    // Compare turnaround
    idx+=ETH_CTRL_ADDR_LEN;
    temp=m_exp_rd_pkt[idx +: ETH_CTRL_TA_LEN];
    if({>>{temp}}!= m_mdio_seq_item.turn_around) begin
        `uvm_error(get_type_name(),
        $sformatf("Turnaround mismatch  Field Offset: %0d\n Expected: %0p\n Actual: %0p", idx,temp,m_mdio_seq_item.turn_around))
        err =1;
    end
    // Compare data
    idx+=ETH_CTRL_TA_LEN;
    temp=m_exp_rd_pkt[idx +: ETH_CTRL_DATA_LEN];
    if({>>{temp}}!= m_mdio_seq_item.data) begin
        `uvm_error(get_type_name(),
        $sformatf("Data mismatch  Field Offset: %0d\n Expected: %0p\n Actual: %0p", idx,temp,m_mdio_seq_item.data))
        err =1;
    end
    if(!err)
        `uvm_info(get_type_name(),"Management Read Packet comparison PASSED",UVM_LOW)

endtask

task eth_mdio_scoreboard::comp_linkfail();
    bit exp_link_fail;

    // Only evaluate link fail if the MAC is actively reading the PHY Status Register (Reg 0x01)
    if (m_cfg_reg_s.reg_addr == 5'h01 && (m_cfg_reg_s.r_stat || m_cfg_reg_s.scan_stat)) begin

        // PHY status bit[2] is 1 for Link OK, 0 for Link Fail.
        // MIISTATUS.LINKFAIL goes high (1) when link fails.
        exp_link_fail = ~m_mdio_seq_item.data[2];

        if(m_cfg_reg_s.link_fail != exp_link_fail) begin
            `uvm_error(get_type_name(),
                $sformatf("Linkfail mismatch. Expected: %0b, Actual: %0b",
                exp_link_fail, m_cfg_reg_s.link_fail))
        end else begin
            `uvm_info(get_type_name(), "Linkfail comparison PASSED", UVM_LOW)
        end
    end else begin
        // If not reading reg 0x01, the LINKFAIL bit should hold its previous state.
        // (Optional: add a check here to ensure it didn't toggle unexpectedly).
    end
endtask

task eth_mdio_scoreboard::comp_clk_period();
    real exp_period_ns;

      // check if the division value is 0
      if(m_cfg_reg_s.clk_div==0) begin
          `uvm_error(get_type_name(),"Clock frequency divider = 0")
          return;
      end

      // Calculate expected period , check if it's even or odd as the calculation differs
      // exp_period_ns=(m_cfg_reg_s.clk_div%2==0)?(WB_CLK_PERIOD_NS*m_cfg_reg_s.clk_div):(WB_CLK_PERIOD_NS*(m_cfg_reg_s.clk_div-1));
      exp_period_ns = 2.0 * m_cfg_reg_s.clk_div * WB_CLK_PERIOD_NS;
      if(exp_period_ns!=m_mdio_seq_item.clk_period_ns)
      begin
          `uvm_error(get_type_name(),
          $sformatf("clock period mismatch, Divisor value = %0d, clk periods in ns:\n Wishbone = %0f \n Expexcted Management = %0f \n Actual Management = %0f",
          m_cfg_reg_s.clk_div,WB_CLK_PERIOD_NS,exp_period_ns,m_mdio_seq_item.clk_period_ns))
      end

endtask

`endif // ETH_MDIO_SCOREBOARD_SV
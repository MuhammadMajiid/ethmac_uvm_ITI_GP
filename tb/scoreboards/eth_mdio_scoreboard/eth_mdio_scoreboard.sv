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
    mdio_seq_item_base::op_code_e op_code;
    bit        mii_no_pre;
    bit [7:0]  clk_div;
    bit        w_ctrl_data;
    bit        r_stat;
    bit        scan_stat;
    bit [4:0]  reg_addr;
    bit [4:0]  phy_addr;
    bit [15:0] wr_data;
    bit [15:0] rd_data;
    bit [1:0]  invalid;
    bit        busy; 
    bit        link_fail;
} mdio_cfg_reg_s;

class eth_mdio_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(eth_mdio_scoreboard)

  parameter SEM_NO_KEYS = 3;


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
  mdio_seq_item_base                                m_mdio_seq_item;
  // =========================================================================
  //  Configuration object 
  // =========================================================================
  eth_mdio_scoreboard_config_obj                    m_config;
  // =========================================================================
  // Register block
  // =========================================================================
  eth_reg_block                                     m_regmodel;   
  // =========================================================================
  // Semaphore for getting mii tx transaction from fifo
  // =========================================================================
  semaphore                                         m_sem; 
  // =========================================================================
  // Event for ending packet comparison
  // =========================================================================
  event                                             m_ev_end_comp;  
  // =========================================================================
  // Configuration struct
  // =========================================================================
  mdio_cfg_reg_s m_cfg_reg_s;

  bit m_exp_rd_pkt[$];
  bit m_exp_wr_pkt[$];
  bit m_actual_rd_pkt[$];

  // =========================================================================
  // 
  // =========================================================================
  extern function new(string name,uvm_component parent);
  extern function void build_phase(uvm_phase phase);
  extern function void eth_mdio_scoreboard::connect_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
  
  extern task get_seq_item();
  extern task read_cfg_regs();
  extern task pred_write(input mdio_seq_item_base item);
  extern task comp_write(input mdio_seq_item_base item);


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
    if (!uvm_config_db #(eth_mdio_scoreboard_config)::get(this, "", "config", m_config))
      `uvm_error(get_type_name(), "eth_mdio_scoreboard_config not found in config_db")
endfunction

function void eth_mdio_scoreboard::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // assign ral handle to it's corresponding in config
    m_regmodel=m_config.m_regmodel;
    
    // Connect each export with it's corrosponding fifo
    a_export.connect(a_fifo.analysis_export);
endfunction 

task run_phase(uvm_phase phase);
  
      phase.raise_objection(this);
      fork
      get_seq_item();
      #0 comp_read();
      #0 comp_clk_period();

      begin
        forever
          begin
            // Read cfgs
            // Write data
            if(m_cfg_reg_s.wr_data) 
              wait(m_ev_end_comp.triggered);
            pred_scan();  

          end  
        end
      join;
      
      phase.drop_objection(this);
      
   
endtask

task eth_mdio_scoreboard::get_seq_item();
    forever begin
        // Get all keys from semaphore
        repeat(SEM_NO_KEYS)
        m_sem.get(1);
        // Get transaction item from fifo
        a_fifo.get(m_mdio_seq_item);
        `uvm_info(get_type_name(),m_mdio_seq_item.convert2string(),UVM_HIGH)
        // Put all Keys in semaphore
        m_sem.put(SEM_NO_KEYS);
    end
endtask 

task eth_mdio_scoreboard::read_cfg_regs();

  uvm_status_e status;
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

  m_regmodel.MIIRX_DATA.mirror(status, UVM_CHECK, UVM_BACKDOOR);
  m_cfg_reg_s.rd_data = m_regmodel.MIIRX_DATA.PRSD.get_mirrored_value();

  m_regmodel.MIISTATUS.mirror(status, UVM_CHECK, UVM_BACKDOOR);
  m_cfg_reg_s.invalid   = m_regmodel.MIISTATUS.NVALID.get_mirrored_value();
  m_cfg_reg_s.busy      = m_regmodel.MIISTATUS.BUSY.get_mirrored_value();
  m_cfg_reg_s.link_fail = m_regmodel.MIISTATUS.LINKFAIL.get_mirrored_value();

endtask

task eth_mdio_scoreboard::pred_write();
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

  //push turn around
  m_exp_wr_pkt.push_back(0);
  m_exp_wr_pkt.push_back(1); 

  // push data
  for (int i=ETH_CTRL_DATA_LEN-1; i>=0; i--)
      m_exp_wr_pkt.push_back(m_cfg_reg_s.wr_data[i]);

endtask

task pred_read();
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

task pred_scan();

  if(m_cfg_reg_s.scan_stat) begin
    do begin 
      pred_read();
      wait(m_ev_end_comp.triggered);
    end
    while(m_cfg_reg_s.scan_stat);
  end
  else if(m_cfg_reg_s.r_stat) begin
      pred_read();
      wait(m_ev_end_comp.triggered);
  end  
endtask

task eth_mdio_scoreboard::comp_write(input mdio_seq_item_base item);
  int idx =0;
  bit err =0;
  bit temp[$];
  forever begin
    if(!m_cfg_reg_s.w_ctrl_data) begin
      #1;
      continue;
    end  
    // Compare preamble
    if(!m_cfg_reg_s.mii_no_pre) begin
      temp=m_exp_wr_pkt[idx:ETH_CTRL_PREAMBLE_LEN-1];
      if(temp!=item.preamble) begin
        `uvm_error(get_type_name(),
          $sformatf("Preamble mismatch  Field Offset: %0d\n Expected: %0p\n Actual: %0p",
          idx,temp,item.preamble))
          err =1;
      end            
      idx+=ETH_CTRL_PREAMBLE_LEN;
    end
    // Compare start of frame
    temp=m_exp_wr_pkt[idx:ETH_CTRL_ST_LEN-1];
    if(temp!=item.st) begin
        `uvm_error(get_type_name(),
        $sformatf(
        "Start of frame mismatch  Field Offset: %0d\n Expected: %0p\n Actual: %0p",
        idx,temp,item.st))
        err =1;
      end
    // Compare opcode
    idx+=ETH_CTRL_OPCODE_LEN;
    temp=m_exp_wr_pkt[idx:ETH_CTRL_OPCODE_LEN-1];
    if({temp[0],temp[1]} != bit'(item.op)) begin
        `uvm_error(get_type_name(),
          $sformatf("Opcode mismatch  Field Offset: %0d\n Expected: %0p\n Actual: %0d",
          idx,temp,bit'(item.op))
        err =1;
    end 
    // Compare phy address   
    idx+=ETH_CTRL_ADDR_LEN;
    temp=m_exp_wr_pkt[idx:ETH_CTRL_ADDR_LEN-1];
    if(temp!= item.phy_addr) begin
        `uvm_error(get_type_name(),
        $sformatf(
        "Phy address mismatch  Field Offset: %0d\n Expected: %0p\n Actual: %0p",
        idx,temp,item.phy_addr))
        err =1;
    end 
    // Compare register address   
    idx+=ETH_CTRL_ADDR_LEN;
    temp=m_exp_wr_pkt[idx:ETH_CTRL_ADDR_LEN-1];
    if(temp!= item.reg_addr) begin
        `uvm_error(get_type_name(),
        $sformatf(
        "Register address mismatch  Field Offset: %0d\n Expected: %0p\n Actual: %0p",
        idx,temp,item.reg_addr))
        err =1;
      end 
    // Compare turnaround   
    idx+=ETH_CTRL_TA_LEN;
    temp=m_exp_rd_pkt[idx:ETH_CTRL_TA_LEN-1];
    if(temp!= m_mdio_seq_item.turn_around) begin
        `uvm_error(get_type_name(),
        $sformatf(
        "Turnaround mismatch  Field Offset: %0d\n Expected: %0p\n Actual: %0p",
        idx,temp,m_mdio_seq_item.turn_around))
        err =1;
      end
    // Compare data   
    idx+=ETH_CTRL_DATA_LEN;
    temp=m_exp_rd_pkt[idx:ETH_CTRL_DATA_LEN-1];
    if(temp!= m_mdio_seq_item.data) begin
        `uvm_error(get_type_name(),
        $sformatf(
        "Data mismatch  Field Offset: %0d\n Expected: %0p\n Actual: %0p",
        idx,temp,m_mdio_seq_item.data))
        err =1;
    end
    if(!err)
        `uvm_info(get_type_name(),"Management Packet comparison PASSED",UVM_LOW)

    -> m_ev_end_comp;
      #1ns;
    end

endtask


task comp_read();
    int idx =0;
    bit err =0;
    bit temp[$];
    forever begin
      if(!(m_cfg_reg_s.scan_stat || m_cfg_reg_s.r_stat)) begin
        #1;
        continue;
      end  
      m_sem.get(1);
      // Compare preamble
      if(!m_cfg_reg_s.mii_no_pre) begin
        temp=m_exp_rd_pkt[idx:ETH_CTRL_PREAMBLE_LEN-1];
        if(temp!=m_mdio_seq_item.preamble) begin
            `uvm_error(get_type_name(),
            $sformatf(
            "Preamble mismatch  Field Offset: %0d\n Expected: %0p\n Actual: %0p",
            idx,temp,m_mdio_seq_item.preamble))
            err =1;
        end            
        idx+=ETH_CTRL_PREAMBLE_LEN;
      end
      // Compare start of frame
      temp=m_exp_rd_pkt[idx:ETH_CTRL_ST_LEN-1];
      if(temp!=m_mdio_seq_item.st) begin
          `uvm_error(get_type_name(),
          $sformatf(
          "Start of frame mismatch  Field Offset: %0d\n Expected: %0p\n Actual: %0p",
          idx,temp,m_mdio_seq_item.st))
          err =1;
        end
      // Compare opcode
      idx+=ETH_CTRL_OPCODE_LEN;
      temp=m_exp_rd_pkt[idx:ETH_CTRL_OPCODE_LEN-1];
      if({temp[1],temp[0]} != bit'(m_mdio_seq_item.op)) begin
          `uvm_error(get_type_name(),
          $sformatf(
          "Opcode mismatch  Field Offset: %0d\n Expected: %0p\n Actual: %0d",
          idx,temp,bit'(m_mdio_seq_item.op))
          err =1;
      end 
      // Compare phy address   
      idx+=ETH_CTRL_ADDR_LEN;
      temp=m_exp_rd_pkt[idx:ETH_CTRL_ADDR_LEN-1];
      if(temp!= m_mdio_seq_item.phy_addr) begin
          `uvm_error(get_type_name(),
          $sformatf(
          "Phy address mismatch  Field Offset: %0d\n Expected: %0p\n Actual: %0p",
          idx,temp,m_mdio_seq_item.phy_addr))
          err =1;
      end 
      // Compare register address   
      idx+=ETH_CTRL_ADDR_LEN;
      temp=m_exp_rd_pkt[idx:ETH_CTRL_ADDR_LEN-1];
      if(temp!= m_mdio_seq_item.reg_addr) begin
          `uvm_error(get_type_name(),
          $sformatf(
          "Register address mismatch  Field Offset: %0d\n Expected: %0p\n Actual: %0p",
          idx,temp,m_mdio_seq_item.reg_addr))
          err =1;
        end 
      // Compare turnaround   
      idx+=ETH_CTRL_TA_LEN;
      temp=m_exp_rd_pkt[idx:ETH_CTRL_TA_LEN-1];
      if(temp!= m_mdio_seq_item.turn_around) begin
          `uvm_error(get_type_name(),
          $sformatf(
          "Turnaround mismatch  Field Offset: %0d\n Expected: %0p\n Actual: %0p",
          idx,temp,m_mdio_seq_item.turn_around))
          err =1;
        end
      // Compare data   
      idx+=ETH_CTRL_DATA_LEN;
      temp=m_exp_rd_pkt[idx:ETH_CTRL_DATA_LEN-1];
      if(temp!= m_mdio_seq_item.data) begin
          `uvm_error(get_type_name(),
          $sformatf(
          "Data mismatch  Field Offset: %0d\n Expected: %0p\n Actual: %0p",
          idx,temp,m_mdio_seq_item.data))
          err =1;
      end
      if(!err)
          `uvm_info(get_type_name(),"Management Packet comparison PASSED",UVM_LOW)
      
      m_sem.put(1); 
      -> m_ev_end_comp;
      #1ns;
    end
endtask

task comp_clk_period();
    real exp_period_ns;
    forever begin
      // check if the division value is 0
      if(m_cfg_reg_s.clk_div==0) begin
          `uvm_error(get_type_name(),"Clock frequency divider = 0",UVM_LOW)
          #1;
          return;
      end  
      m_sem.get(1);
      // Calculate expected period , check if it's even or odd as the calculation differs
      exp_period_ns=(m_cfg_reg_s.clk_div%2==0)?(WB_CLK_PERIOD_NS*m_cfg_reg_s.clk_div):(WB_CLK_PERIOD_NS*(m_cfg_reg_s.clk_div-1)):
      if(exp_period_ns!=m_mdio_seq_item.clk_period_ns) 
      begin
          `uvm_error(get_type_name(),
          $sformatf("clock period mismatch, Divisor value = %0d, clk periods in ns:\n Wishbone = %0f \n Expexcted Management = %0f \n Actual Management = %0f",
          m_cfg_reg_s.clk_div,WB_CLK_PERIOD_NS,exp_period_ns,m_mdio_seq_item.clk_period_ns))
      end
      
      m_sem.put(1); 
      #1ns;
    end
endtask

`endif // ETH_MDIO_SCOREBOARD_SV

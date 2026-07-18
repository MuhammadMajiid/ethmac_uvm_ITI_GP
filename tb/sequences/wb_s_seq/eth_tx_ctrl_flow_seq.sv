//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_tx_ctrl_flow_seq.sv
// Author   : Mounir
// Date     : 2026-07-18
//------------------------------------------------------------------------------
// Description:
//   All Control Flow / PAUSE sequences mapped to Planning_control_flow.xlsx.
//   In the TX we have the Control Frame Generation
//   and in the RX we have the Control Frame Detection.
//   So we will write sequences for Control Frame Generation (FD-CFG-01..08)
//
//   All sequences extend wb_s_basic_tx_seq 
//==============================================================================

`ifndef ETH_TX_CTRL_FLOW_SEQ_SV
`define ETH_TX_CTRL_FLOW_SEQ_SV


    // TXFLOW=1 enables PAUSE frame transmission and the TXC interrupt source.
class eth_fd_ctr01_txflow_set_seq extends wb_s_basic_tx_seq;
    `uvm_object_utils(eth_fd_ctr01_txflow_set_seq)

    function new(string name = "eth_fd_ctr01_txflow_set_seq");
        super.new(name);
    endfunction

    task body();
        configure_tx_registers(.tx_bd_num(1),.mac_addr0($random),.mac_addr1($random),.txen(1),.fulld(1),
        .pause_req(1),.pause_timer($random),.tx_flow(1));
    endtask
endclass : eth_fd_ctr01_txflow_set_seq

//  FD-CFG-01  TXFLOW=0, request PAUSE TX → blocked ─
// Writing TXPAUSERQ=1 when TXFLOW=0 must NOT transmit a PAUSE frame.
class eth_fd_cfg01_txflow0_pause_request_seq extends wb_s_basic_tx_seq;
    `uvm_object_utils(eth_fd_cfg01_txflow0_pause_request_seq)

    function new(string name = "eth_fd_cfg01_txflow0_pause_request_seq");
        super.new(name);
    endfunction

    task body();
        // Write TXPAUSERQ=1 with timer value random 0x0010
        // TXFLOW=0 means this should be blocked
        configure_tx_registers(.tx_bd_num(1),.txen(1),.fulld(1),
        .pause_req(1),.pause_timer($random),.tx_flow(0));
    endtask

endclass : eth_fd_cfg01_txflow0_pause_request_seq

//  FD-CFG-02  TXFLOW=1, request PAUSE TX → frame sent 
// After current TX completes, MAC sends PAUSE frame.
class eth_fd_cfg02_txflow1_pause_request_seq extends wb_s_basic_tx_seq;
    `uvm_object_utils(eth_fd_cfg02_txflow1_pause_request_seq)

    function new(string name = "eth_fd_cfg02_txflow1_pause_request_seq");
        super.new(name);
    endfunction

    task body();
        
        // Write TXCTRL: TXPAUSERQ=1, TPAUSETV=0x0050
        configure_tx_registers(.tx_bd_num(1),.txen(1),.fulld(1),
        .pause_req(1),.pause_timer(16'h0050),.tx_flow(1));
    
    endtask

endclass : eth_fd_cfg02_txflow1_pause_request_seq

//  FD-CFG-03  Verify PAUSE frame structure 
// DA=multicast/own, L/T=0x8808, Opcode=0x0001, Timer=TPAUSETV, CRC appended.
class eth_fd_cfg03_pause_frame_structure_seq extends wb_s_basic_tx_seq;
    `uvm_object_utils(eth_fd_cfg03_pause_frame_structure_seq)

    function new(string name = "eth_fd_cfg03_pause_frame_structure_seq");
        super.new(name);
    endfunction

    task body();
        uvm_status_e   status;
        uvm_reg_data_t txctrl_val;
        bit [15:0]     pause_tv = 16'hABCD;  // distinctive value for easy checking

        configure_tx_registers(.tx_bd_num(1),.mac_addr1($random),.mac_addr0($random),
        .txen(1),.fulld(1),.pause_req(1),.pause_timer(16'hABCD),.tx_flow(1));
        // MAC_ADDR1 holds bytes 0-1 (bits [15:8]=byte0, [7:0]=byte1)
        // MAC_ADDR0 holds bytes 2-5

        // TX scoreboard verifies exact PAUSE frame structure:
        //   DA = 01:80:C2:00:00:01 or own MAC
        //   Length/Type = 0x8808
        //   Opcode = 0x0001
        //   Timer Value = 0xABCD
        //   Frame padded to 64 bytes
        //   Valid CRC appended
    endtask

endclass : eth_fd_cfg03_pause_frame_structure_seq

//  FD-CFG-04  TXPAUSERQ auto-clear ──
// After writing 1 to TXPAUSERQ, bit must auto-clear to 0 after frame sent.
//  FD-CFG-05  TXC interrupt on PAUSE TX completion ─
class eth_fd_cfg04_txpauserq_autoclear_seq extends wb_s_basic_tx_seq;
    `uvm_object_utils(eth_fd_cfg04_txpauserq_autoclear_seq)

    function new(string name = "eth_fd_cfg04_txpauserq_autoclear_seq");
        super.new(name);
    endfunction

    task body();
        uvm_status_e   status;
        uvm_reg_data_t int_val;

        bit [15:0] pause_timer = 16'h0011;
        bit [6:0] bits_to_clear = 7'b010_0000;

        configure_tx_registers(.tx_bd_num(1),.txen(1),.fulld(1),
        .pause_req(1),.pause_timer(16'hABCD),.tx_flow(1));

        #5000ns;

        // Read back TXCTRL — TXPAUSERQ (bit[16]) must be 0 now
        regmodel.TXCTRL.TXPAUSETV.read(status, pause_timer, UVM_FRONTDOOR);

        `uvm_info(get_name(),
            $sformatf("FD-CFG-04: TXCTRL readback= 16'hABCD TXPAUSERQ=%0b (expect 0)", pause_timer), UVM_LOW)

        // Read INT_SOURCE — TXC (bit[5]) must be set
        regmodel.INT_SOURCE.read(status, int_val, UVM_FRONTDOOR);
        `uvm_info(get_name(),
            $sformatf("FD-CFG-05: INT_SOURCE=0x%08h TXC=%0b (expect 1)",
                int_val, int_val[5]),
            UVM_LOW)

        // Clear TXC
        regmodel.INT_SOURCE.write(status, {25'h0, bits_to_clear}, UVM_FRONTDOOR);

    endtask

endclass : eth_fd_cfg04_txpauserq_autoclear_seq


//  FD-CFG-06  Duplicate PAUSE TX request → second ignored 
// Issue TXPAUSERQ twice rapidly. Second must be ignored while first is pending.
class eth_fd_cfg06_duplicate_pause_request_seq extends wb_s_basic_tx_seq;
    `uvm_object_utils(eth_fd_cfg06_duplicate_pause_request_seq)

    function new(string name = "eth_fd_cfg06_duplicate_pause_request_seq");
        super.new(name);
    endfunction

    task body();
        uvm_status_e   status;
        uvm_reg_data_t txctrl_val;

        // Issue first request
        configure_tx_registers(.tx_bd_num(1),.txen(1),.fulld(1),
        .pause_req(1),.pause_timer(16'h0020),.tx_flow(1));

        // Issue second immediately — internal latch should prevent duplicate
        configure_tx_registers(.tx_bd_num(1),.txen(1),.fulld(1),
        .pause_req(1),.pause_timer(16'h0030),.tx_flow(1));

        #10000ns;

        `uvm_info(get_name(),
            "FD-CFG-06: two rapid TXPAUSERQ — only one PAUSE frame should be sent",
            UVM_LOW)

    endtask

endclass : eth_fd_cfg06_duplicate_pause_request_seq

`endif // ETH_TX_CTRL_FLOW_SEQ_SV
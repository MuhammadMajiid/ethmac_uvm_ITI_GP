//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mii_rx_driver_base.sv
// Author   : Mariam
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
//   Base driver for MII Rx interface.
//==============================================================================

`ifndef MII_RX_DRIVER_BASE_SV
`define MII_RX_DRIVER_BASE_SV

class mii_rx_driver_base extends uvm_driver #(mii_rx_seq_item);
  `uvm_component_utils(mii_rx_driver_base)

  virtual mii_rx_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    reset_items(); 

    forever begin
      mii_rx_seq_item req;

      // Wait for the virtual sequencer to provide a frame 
      seq_item_port.get_next_item(req);

      // Drive the frame onto physical pins
      drive_frame(req);

      // Tell sequencer we're done
      seq_item_port.item_done();

      // Inter-Packet Gap (IPG) minimum wait before next item
      repeat(req.ifg_delay) @(posedge vif.MRxClk); // 960ns = 24 MII clocks at 25MHz --> sequence 
    end
  endtask

  virtual task reset_items();
    vif.MRxDV  = 0;
    vif.MRxD   = 4'h0;
    vif.MRxErr = 0;
  endtask 

  virtual task drive_frame(mii_rx_seq_item txn);
    byte current_byte;

    //----------------------------------------------------------
    // Drive Preamble & SFD
    //---------------------------------------------------------- 
    @(posedge vif.MRxClk);
    vif.MRxDV = 1;           // Assert Data Valid  -> seq

    // Preamble (0x55 repeated)
    for (int i=0 ; i < txn.preamble_len ; i++) begin
      drive_byte(8'h55);
    end

    // SDF (0xD5)
    drive_byte(8'hD5);

    //----------------------------------------------------------
    // Drive Frame Data
    //---------------------------------------------------------- 
    for(int i=0 ; i < txn.frame_data_q.size() ; i++) begin
      current_byte = txn.frame_data_q[i];

      // Drive LSB Nibble first
      @(posedge vif.MRxClk);
      
      // handle if error is injected mid frame 
      if (txn.inject_mrxerr && i == txn.err_pos)
        vif.MRxErr = 1;
      else 
        vif.MRxErr = 0;

      // handle if injected 0xE error code
      if (txn.inject_invalid_symbol && i == txn.err_pos)
        vif.MRxD = 4'hE;
      else
        vif.MRxD = current_byte[3:0]; 

      // Drive MSB Nibble (2nd clk cycle for the byte)
      @(posedge vif.MRxClk);
      vif.MRxD   = current_byte[7:4];
      vif.MRxErr = 0;
    end

    //----------------------------------------------------------
    // Teardown & Dribble Nibble
    //---------------------------------------------------------- 
    
    // Send one extra nibble before dropping MRxDV
    if (txn.dribble_nibble_en) begin
      @(posedge vif.MRxClk);
      vif.MRxD = txn.dribble_data;   // Arbitrary extra nibble
    end

    //----------------------------------------------------------
    // End of Frame: Deassert Data Valid
    //---------------------------------------------------------- 
    @(posedge vif.MRxClk);
    vif.MRxDV  = 0;
    vif.MRxD   = 4'h0;
    vif.MRxErr = 0;

  endtask : drive_frame

  // Drives a single byte over two clock cycles, LSB nibble first
  virtual task drive_byte(byte data);
    @(posedge vif.MRxClk);
    vif.MRxD = data[3:0];   // LSB
        
    @(posedge vif.MRxClk);
    vif.MRxD = data[7:4];   // MSB
  endtask : drive_byte

endclass

`endif // MII_RX_DRIVER_BASE_SV
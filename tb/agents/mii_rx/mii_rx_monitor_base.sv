//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mii_rx_monitor_base.sv
// Author   : Mariam
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
//   Monitor for MII Rx agent.
//==============================================================================
`ifndef MII_RX_MONITOR_BASE_SV
`define MII_RX_MONITOR_BASE_SV

  `include "uvm_macros.svh"
  import uvm_pkg::*;

class mii_rx_monitor_base extends uvm_monitor;
  `uvm_component_utils(mii_rx_monitor_base)

  uvm_analysis_port #(mii_rx_seq_item) a_port;
  virtual mii_rx_if vif;

  //--------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  //--------------------------------------------------------------------------
  // Build Phase
  //--------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    a_port = new("a_port", this);
  endfunction

  //--------------------------------------------------------------------------
  // Run Phase
  //--------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    forever begin
      mii_rx_seq_item item;

      byte frame_bytes[$];
      bit [7:0] current_byte;
      bit [3:0] nibble;

      // timestamp locals 
      realtime t_start_ns = 0.0;
      realtime t_end_ns   = 0.0;

      // Error tracking flags
      bit is_dribble       = 0;
      bit seen_sfd         = 0;
      int preamble_cnt     = 0;
      bit err_flag         = 0;
      bit invalid_sym_flag = 0;

      // Wait for Start of Frame (MRxDV goes high)
      @(posedge vif.MRxClk iff vif.MRxDV === 1'b1);

      // Capture the stream until MRxDV goes low
      while (vif.MRxDV === 1'b1) begin
        // --- Capture LSB Nibble ---
        nibble = vif.MRxD;

        if (vif.MRxErr === 1'b1) begin
          err_flag = 1;
        end 

        if (nibble === 4'hE) begin
          invalid_sym_flag = 1;
        end 

        current_byte[3:0] = nibble;

        @(posedge vif.MRxClk);

        // Check if MRxDV dropped in the middle of a byte (Dribble Nibble)
        if (vif.MRxDV === 1'b0) begin
          is_dribble = 1; 
          break;
        end

        // --- Capture MSB Nibble ---
        nibble = vif.MRxD;

        if (vif.MRxErr === 1'b1) begin
          err_flag = 1;
        end 

        if (nibble === 4'hE) begin
          invalid_sym_flag = 1; 
        end 

        current_byte[7:4] = nibble;

        // --- Preamble and SFD Parsing ---
        if (!seen_sfd) begin
          if (current_byte == 8'hD5) begin
            seen_sfd = 1;
            item.preamble_len = preamble_cnt;
            t_start_ns  = $realtime; // record start time at the moment SFD is confirmed
          end 
          else if (current_byte == 8'h55) begin
            preamble_cnt++;
          end
        end 
        else begin
            // Once SFD is passed, store the actual frame bytes
            frame_bytes.push_back(current_byte);
        end

        @(posedge vif.MRxClk);
      end

      // record end time the moment MRxDV deasserts
      t_end_ns = $realtime;

      // Create the item once the frame is fully received
      item = mii_rx_seq_item::type_id::create("item");

      // populate timestamp fields 
      item.start_time_ns      = t_start_ns;
      item.end_time_ns        = t_end_ns;

      // Record captured errors for the Scoreboard
      item.has_mrxerr         = err_flag;
      item.has_invalid_symbol = invalid_sym_flag;
      item.dribble_nibble_en  = is_dribble;

      // Deserialize the byte queue into the sequence item
      if (frame_bytes.size() >= 14) begin // Ensure minimum MAC header exists
        item.unpack_frame(frame_bytes);
      end

      // Broadcast the assembled item    
      a_port.write(item);
    end
  endtask

endclass

`endif // MII_RX_MONITOR_BASE_SV

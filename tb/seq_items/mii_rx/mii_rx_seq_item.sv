//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mii_rx_seq_item.sv
// Author   : Mariam
// Date     : 2026-06-24
//------------------------------------------------------------------------------
// Description:
//   Transaction contains MII Rxs interface ports.
//==============================================================================

`ifndef MII_RX_SEQ_ITEM_SV
`define MII_RX_SEQ_ITEM_SV
    
    `include "uvm_macros.svh"
    import uvm_pkg::*;

class mii_rx_seq_item extends uvm_sequence_item;
    `uvm_object_utils(mii_rx_seq_item)

    //--------------------------------------------------------------------------
    // Transaction Data Fields (The actual Ethernet Frame)
    //--------------------------------------------------------------------------
    rand bit [47:0] destination_addr; // For address recognition tests
    rand bit [47:0] source_addr;      // SA
    rand bit [15:0] length_type;      // Length/Type field
    rand byte       payload[];        // Dynamic array for randomized payload sizes
         bit [31:0] fcs;              // CRC Checksum

    //--------------------------------------------------------------------------
    // Control knobs
    //--------------------------------------------------------------------------
    rand int preamble_len;            // For tc_rx_short_preamble
    rand bit inject_crc_error;        // For tc_rx_crc_check_fail
    rand bit inject_mrxerr;           // For tc_rx_phy_error (aborts mid-frame)
    rand bit inject_invalid_symbol;   // For tc_rx_invalid_symbol (forces 0xE)
    rand int err_pos;                 // Injected error position
    rand bit dribble_nibble_en;       // For tc_rx_dribble_nibble (adds an odd nibble)
    rand bit [3:0] dribble_data;
    rand int ifg_delay;               // For tc_rx_ifg_minimum & tc_rx_ifg_disable
    rand bit inject_late_collision; 
         bit has_mrxerr;
         bit has_invalid_symbol;

         // Timestamp fields
         realtime start_time_ns;      // $realtime when SFD byte is first detected
         realtime end_time_ns;        // $realtime when MRxDV finally deasserts

    //--------------------------------------------------------------------------
    // Rx Frame
    //--------------------------------------------------------------------------
    // +----------+--------+--------+--------+--------+-----------------+--------+
    // | Preamble |   SDF  |   DA   |   SA   |  L/T   |     Payload     |   FCS  |
    // +----------+--------+--------+--------+--------+-----------------+--------+

    // The fully assembled frame bytes (excluding preamble/SFD)
    byte frame_data_q[$];   // queue to hold the frame as byte by byte 
    byte frame_no_crc[$];   

    //--------------------------------------------------------------------------
    // Constraints
    //--------------------------------------------------------------------------

    constraint payload_size_c {
        payload.size inside {[46 : 1500]}; 
    }

    // inject error in a rand byte between headers/addresses and CRC
    constraint err_pos_c {
        err_pos inside {[14 : 13 + payload.size()]};  
    }

    // Probability Distribution
    constraint err_pos_order_c {
        solve payload.size before err_pos; // if you face an error try: solve payload before err_pos;
    }

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new (string name = "");
        super.new(name);
    endfunction

    //--------------------------------------------------------------------------
    // Post rand func to calc CRC of rand data & addr
    //--------------------------------------------------------------------------
    function void post_randomize();
        frame_data_q.delete(); // Clear queue just in case
        frame_no_crc.delete(); // Clear queue just in case

        for(int i=5 ; i>=0 ; i--) begin 
            frame_no_crc.push_back(destination_addr[i*8 +: 8]);  // part select [start +: width]
        end

        for(int i=5 ; i>=0 ; i--) begin 
            frame_no_crc.push_back(source_addr[i*8 +: 8]);
        end

        frame_no_crc.push_back(length_type[15:8]);
        frame_no_crc.push_back(length_type[7:0]);

        foreach (payload[i]) begin 
            frame_no_crc.push_back(payload[i]);
        end

        // Calculate actual CRC based on the queue so far
        fcs = calc_crc32(frame_no_crc);

        // 5. Inject CRC Error if requested (Driver doesn't need to know!)
        if (inject_crc_error) begin
            fcs = ~fcs; 
        end
        frame_data_q = frame_no_crc; // Copy the frame without CRC first

        frame_data_q.push_back(fcs[31:24]);
        frame_data_q.push_back(fcs[23:16]);
        frame_data_q.push_back(fcs[15:8]);
        frame_data_q.push_back(fcs[7:0]);
    endfunction

    //--------------------------------------------------------------------------
    // calc_crc32
    //--------------------------------------------------------------------------
    function bit [31:0] calc_crc32(const ref byte data_q[$]);

        bit          [31:0] crc;
        byte         current_byte;
        bit          b;
        int len = data_q.size();

        crc = 32'hFFFF_FFFF;

        for (int i = 0; i < len; i++) begin
            current_byte = data_q[i];
            for (int bit_i = 0; bit_i < 8; bit_i++) begin
                b   = crc[0] ^ current_byte[bit_i];
                crc = crc >> 1;
                if (b) crc = crc ^ ETH_CRC_POLY;
            end
        end
        
        return ~crc;

    endfunction   

    //--------------------------------------------------------------------------
    // Un-packing the frame
    //--------------------------------------------------------------------------
    function void unpack_frame(ref byte frame_bytes[$]);
        for (int i=5 ; i>=0 ; i--) begin
            destination_addr[i*8 +: 8] = frame_bytes.pop_front();
        end 
        for (int i=5 ; i>=0 ; i--) begin
            source_addr[i*8 +: 8]      = frame_bytes.pop_front();
        end 

        // Extract Length/Type
        length_type[15:8] = frame_bytes.pop_front();
        length_type[7:0]  = frame_bytes.pop_front();

        // Extract Payload and FCS
        if (frame_bytes.size() >= 4) begin
            int payload_size = frame_bytes.size() - 4;

            payload = new[payload_size];

            for (int i=0 ; i<payload_size ; i++) begin
                payload[i] = frame_bytes.pop_front();
            end 
            
            fcs[31:24] = frame_bytes.pop_front();
            fcs[23:16] = frame_bytes.pop_front();
            fcs[15:8]  = frame_bytes.pop_front();
            fcs[7:0]   = frame_bytes.pop_front();
        end
    endfunction

    //--------------------------------------------------------------------------
    // convert2string
    //--------------------------------------------------------------------------
    virtual function string convert2string();
        string s;
        // Call super.convert2string() to get base class info [1, 4]
        $sformat(s, "%s\n", super.convert2string());
        
        // Format and append the main data fields
        $sformat(s, "%s destination_addr      \t0x%0h\n", s, destination_addr);
        $sformat(s, "%s source_addr           \t0x%0h\n", s, source_addr);
        $sformat(s, "%s length_type           \t0x%0h\n", s, length_type);
        $sformat(s, "%s payload.size()        \t%0d bytes\n", s, payload.size());
        $sformat(s, "%s fcs                   \t0x%0h\n", s, fcs);
        
        // Format and append the control knobs (for debug)
        $sformat(s, "%s inject_crc_error      \t%0b\n", s, inject_crc_error);
        $sformat(s, "%s inject_mrxerr         \t%0b\n", s, inject_mrxerr);
        $sformat(s, "%s inject_invalid_symbol \t%0b\n", s, inject_invalid_symbol);
        $sformat(s, "%s err_pos               \t%0d\n", s, err_pos);
        $sformat(s, "%s dribble_nibble_en     \t%0b\n", s, dribble_nibble_en);
        $sformat(s, "%s preamble_len          \t%0d\n", s, preamble_len);
        $sformat(s, "%s ifg_delay             \t%0d\n", s, ifg_delay);
        $sformat(s, "%s inject_late_collision \t%0b\n", s, inject_late_collision);
        
        return s;
    endfunction

endclass // mii_rx_seq_item

`endif // `ifndef MII_RX_SEQ_ITEM_SV


//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : mii_tx_driver_collision.sv
// Author   : Nada
// Date     : 2026-07-21
//------------------------------------------------------------------------------
// Description:
// UVM driver for half-duplex Ethernet collision injection.
//
// Extends mii_tx_driver_base to model PHY behavior during collision tests.
// The driver monitors the DUT transmit enable signal (MTxEN) and drives the
// MII receive-side status signals accordingly.
//
// Responsibilities:
//   - Assert MCrS whenever the DUT asserts MTxEN, indicating that the medium
//     is busy.
//   - Inject a one-clock MColl pulse upon request from the sequence to emulate
//     a collision on the Ethernet medium.
//   - Keep MCrS asserted throughout the transmission attempt, including the
//     JAM sequence generated after a collision.
//   - Deassert MCrS only after the DUT deasserts MTxEN, marking the end of
//     the transmission attempt.
//   - Deassert MColl after a single MII clock.
//
// This driver is intended for half-duplex collision, backoff, retry, and
// excessive deferral verification. It can be factory-overridden in place of
// mii_tx_driver_base for collision-specific test cases.
//------------------------------------------------------------------------------


`ifndef MII_TX_DRIVER_COLLISION_SV
`define MII_TX_DRIVER_COLLISION_SV

class mii_tx_driver_collision extends mii_tx_driver_base;

    `uvm_component_utils(mii_tx_driver_collision)

    function new(string name = "mii_tx_driver_collision",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        bit prev_txen;
        super.reset_items();

        fork
            //------------------------------------------------------
            // Continuously drive Carrier Sense
            //------------------------------------------------------
            forever begin
                @(vif.cb_mii_tx);
                vif.cb_mii_tx.MCrS <= vif.MTxEN | prev_txen;
                prev_txen=vif.MTxEN;
            end

            //------------------------------------------------------
            // Handle collision requests
            //------------------------------------------------------
            forever begin
                m_seq_item = mii_tx_seq_item_base::type_id::create("m_seq_item");

                seq_item_port.get_next_item(m_seq_item);

                drive_items(m_seq_item);

                seq_item_port.item_done();
            end
        join

    endtask


    task drive_items(mii_tx_seq_item_base m_seq_item);
        `uvm_info(get_name(), "COLLISION DRIVER", UVM_MEDIUM)
        
    if (m_seq_item.MColl) begin

        // Wait  30  MII clocks for normal collision  or 150 MII clocks for late collision 
        repeat (30) begin
            @(vif.cb_mii_tx);
            if (!vif.MTxEN)
                break;
        end

        // If transmission already ended, don't inject collision
        if (vif.MTxEN) begin
            vif.cb_mii_tx.MColl <= 1'b1;
            @(vif.cb_mii_tx);
            vif.cb_mii_tx.MColl <= 1'b0;
        end
    end

    endtask

endclass

`endif  


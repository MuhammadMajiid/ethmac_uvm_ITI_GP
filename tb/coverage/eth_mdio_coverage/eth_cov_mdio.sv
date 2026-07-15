//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : eth_mdio_coverage.sv
// Author   : Muhammad Majid
// Date     : 2026-07-14
//------------------------------------------------------------------------------
// Description:
//   Functional coverage collector for the MDIO interface.
//==============================================================================

`ifndef ETH_MDIO_COVERAGE_SV
`define ETH_MDIO_COVERAGE_SV

class eth_mdio_coverage extends uvm_subscriber #(mdio_seq_item_base);
    `uvm_component_utils(eth_mdio_coverage)

    mdio_seq_item_base m_item;

    covergroup mdio_cg;
        option.per_instance = 1;

        // Coverage for Opcodes
        cp_op: coverpoint m_item.op {
            bins write_op = {2'b01};
            bins read_op  = {2'b10};
        }

        // Coverage for PHY Addresses
        cp_phy_addr: coverpoint m_item.phy_addr {
            bins addr_min = {5'h00};
            bins addr_max = {5'h1F};
            bins addr_mid = {[5'h01:5'h1E]};
        }

        // Coverage for Register Addresses (Focus on Control & Status)
        cp_reg_addr: coverpoint m_item.reg_addr {
            bins ctrl_reg   = {5'h00};
            bins status_reg = {5'h01};
            bins other_regs = {[5'h02:5'h1F]};
        }

        // Cross operations with specific registers
        cr_op_reg: cross cp_op, cp_reg_addr {
            // E.g., check that we both read and write to control/status
            ignore_bins invalid_write_status = binsof(cp_op.write_op) && binsof(cp_reg_addr.status_reg); // Status is usually read-only
        }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        mdio_cg = new();
    endfunction

    function void write(mdio_seq_item_base t);
        m_item = t;
        mdio_cg.sample();
    endfunction

endclass

`endif // ETH_MDIO_COVERAGE_SV

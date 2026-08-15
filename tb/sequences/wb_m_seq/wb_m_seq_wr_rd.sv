//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_m_seq_wr_rd.sv
// Author   : Wael
// Date     : 2026-07-05
//------------------------------------------------------------------------------
// Description:
//   Sequence perform basic write & read transactions from external dma memory
//   model when DUT requests transaction .
//==============================================================================

`ifndef WB_M_SEQ_WR_RD_SV
`define WB_M_SEQ_WR_RD_SV

class wb_m_seq_wr_rd extends wb_m_seq_base;

    `uvm_object_utils(wb_m_seq_wr_rd)

    function new(string name = "");
        super.new(name);
    endfunction
    
    virtual function command(wb_m_seq_item_base m_tr_item); 
    // Default response for idle/invalid transactions
    m_tr_item.m_data_i = '0;
    m_tr_item.m_ack_i  = 1'b0;
    m_tr_item.m_err_i  = 1'b0;

    if ((&m_tr_item.m_sel_o) &&
        m_tr_item.m_cyc_o    &&
        m_tr_item.m_stb_o) begin

        case (m_tr_item.m_dir)
            WB_WRITE: begin
                dma_mem::write(
                    m_tr_item.m_addr_o,
                    m_tr_item.m_data_o
                );
                m_tr_item.m_ack_i = 1'b1;
            end

            WB_READ: begin
                dma_mem::read(
                    m_tr_item.m_addr_o,
                    m_tr_item.m_data_i
                );
                m_tr_item.m_ack_i = 1'b1;
            end
        endcase
    end
    endfunction

    task body;

        // Initial idle response
        m_tr_item = wb_m_seq_item_base::type_id::create("m_tr_item");
        m_tr_item.m_data_i = '0;
        m_tr_item.m_ack_i  = 1'b0;
        m_tr_item.m_err_i  = 1'b0;

        forever begin
            // Send the response prepared during the previous iteration
            start_item(m_tr_item);
            finish_item(m_tr_item);

            // Receive the DUT request sampled and returned by the driver
            get_response(m_tr_item);
            // Process transaction to determine if it's read or write
            command(m_tr_item);
        end

    endtask

endclass : wb_m_seq_wr_rd

`endif // WB_M_SEQ_WR_RD_SV
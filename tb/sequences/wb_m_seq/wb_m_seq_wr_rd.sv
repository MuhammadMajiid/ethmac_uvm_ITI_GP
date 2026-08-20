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
    
    // Processes the sampled DUT request and prepares the next slave response.
    virtual function void command(
        wb_m_seq_item_base m_rsp_item,
        wb_m_seq_item_base m_req_item
    );
    // Default response for idle/invalid transactions
    m_req_item.m_data_i = '0;
    m_req_item.m_ack_i  = 1'b0;
    m_req_item.m_err_i  = 1'b0;

    // Respond only to a valid full-word Wishbone transfer.
    if ((&m_rsp_item.m_sel_o) &&
        m_rsp_item.m_cyc_o    &&
        m_rsp_item.m_stb_o) begin

        case (m_rsp_item.m_dir)
            WB_WRITE: begin
                // Store the DUT data and acknowledge the write.
                dma_mem::write(
                    m_rsp_item.m_addr_o,
                    m_rsp_item.m_data_o
                );
                m_req_item.m_ack_i = 1'b1;
            end

            WB_READ: begin
                // Return the stored data and acknowledge the read.
                dma_mem::read(
                    m_rsp_item.m_addr_o,
                    m_req_item.m_data_i
                );
                m_req_item.m_ack_i = 1'b1;
            end
        endcase
    end
    endfunction

    task body;

        // Initial idle response
        m_req_item = wb_m_seq_item_base::type_id::create("m_req_item");
        m_req_item.m_data_i = '0;
        m_req_item.m_ack_i  = 1'b0;
        m_req_item.m_err_i  = 1'b0;

        forever begin
            // Send the response prepared during the previous iteration
            start_item(m_req_item);
            finish_item(m_req_item);

            // Receive the DUT request sampled and returned by the driver
            get_response(m_rsp_item);
            // Process transaction to determine if it's read or write
            command(m_rsp_item, m_req_item);
        end

    endtask

endclass : wb_m_seq_wr_rd

`endif // WB_M_SEQ_WR_RD_SV

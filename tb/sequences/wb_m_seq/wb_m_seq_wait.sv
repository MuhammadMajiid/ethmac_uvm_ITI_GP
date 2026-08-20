//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : wb_m_seq_wait.sv
// Author   : Wael
// Date     : 2026-07-19
//------------------------------------------------------------------------------
// Description:
//   Sequence  performs dma memory wait states by asserting ack after random 
//   time to trigger underrun .
//==============================================================================

`ifndef WB_M_SEQ_WAIT_SV
`define WB_M_SEQ_WAIT_SV

class wb_m_seq_wait extends wb_m_seq_base;

    `uvm_object_utils(wb_m_seq_wait)

    bit          m_read_wait_active;

    function new(string name = "");
        super.new(name);
    endfunction

    // Processes the sampled DUT request and prepares a delayed read response.
    virtual function void command(
        wb_m_seq_item_base m_rsp_item,
        wb_m_seq_item_base m_req_item
    );
        // Default response for idle/invalid transactions and wait cycles
        m_req_item.m_data_i = '0;
        m_req_item.m_ack_i  = 1'b0;
        m_req_item.m_err_i  = 1'b0;

        // Respond only to a valid full-word Wishbone transfer.
        if ((&m_rsp_item.m_sel_o) &&
            m_rsp_item.m_cyc_o    &&
            m_rsp_item.m_stb_o) begin

            case (m_rsp_item.m_dir)
                WB_WRITE: begin
                    // Complete writes immediately.
                    dma_mem::write(
                        m_rsp_item.m_addr_o,
                        m_rsp_item.m_data_o
                    );
                    m_req_item.m_ack_i = 1'b1;
                end

                WB_READ: begin
                    if (m_read_wait_active) begin
                        // Count down, then return data and acknowledge the read.
                        if (m_req_item.wait_cycles == 0) begin
                            dma_mem::read(
                                m_rsp_item.m_addr_o,
                                m_req_item.m_data_i
                            );
                            m_req_item.m_ack_i = 1'b1;
                            m_read_wait_active = 1'b0;
                        end
                        else begin
                            m_req_item.wait_cycles--;
                        end
                    end
                    else begin
                        // Start a new randomized read delay.
                        assert (m_req_item.randomize() with {
                            wait_cycles inside {[250:400]};
                            m_data_i == '0;
                            m_err_i  == 1'b0;
                            m_ack_i  == 1'b0;
                        })
                        else `uvm_fatal(get_name(), "Failed Randomization");

                        m_req_item.wait_cycles--;
                        m_read_wait_active = 1'b1;
                    end
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
        m_read_wait_active = 1'b0;

        forever begin
            // Send the response prepared during the previous iteration
            start_item(m_req_item);
            finish_item(m_req_item);

            // Receive the DUT request sampled and returned by the driver
            get_response(m_rsp_item);
            // Process the request and prepare the next response
            command(m_rsp_item, m_req_item);
        end
    endtask

endclass : wb_m_seq_wait

`endif // WB_M_SEQ_WAIT_SV

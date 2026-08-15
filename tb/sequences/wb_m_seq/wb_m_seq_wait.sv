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

    int unsigned m_wait_cycles_left;
    bit          m_read_wait_active;

    function new(string name = "");
        super.new(name);
    endfunction

    virtual function command(wb_m_seq_item_base m_tr_item);
        // Default response for idle/invalid transactions and wait cycles
        m_tr_item.m_data_i = '0;
        m_tr_item.m_ack_i  = 1'b0;
        m_tr_item.m_err_i  = 1'b0;

        if (m_read_wait_active) begin
            if (m_wait_cycles_left == 0) begin
                dma_mem::read(
                    m_tr_item.m_addr_o,
                    m_tr_item.m_data_i
                );
                m_tr_item.m_ack_i = 1'b1;
                m_read_wait_active = 1'b0;
            end
            else begin
                m_wait_cycles_left--;
            end
        end
        else if ((&m_tr_item.m_sel_o) &&
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
                    assert (m_tr_item.randomize() with {
                        wait_cycles inside {[250:400]};
                        m_data_i == '0;
                        m_err_i  == 1'b0;
                        m_ack_i  == 1'b0;
                    })
                    else `uvm_fatal(get_name(), "Failed Randomization");

                    m_wait_cycles_left = m_tr_item.wait_cycles - 1;
                    m_read_wait_active = 1'b1;
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
        m_wait_cycles_left = 0;
        m_read_wait_active = 1'b0;

        forever begin
            // Send the response prepared during the previous iteration
            start_item(m_tr_item);
            finish_item(m_tr_item);

            // Receive the DUT request sampled and returned by the driver
            get_response(m_tr_item);
            // Process the request and prepare the next response
            command(m_tr_item);
        end
    endtask

endclass : wb_m_seq_wait

`endif // WB_M_SEQ_WAIT_SV

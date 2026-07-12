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
 
 task body;
        forever begin
            // Get request item from monitor
            p_sequencer.request_fifo.get(m_req_item);    
            m_tr_item  = wb_m_seq_item_base::type_id::create("m_tr_item");
            
            // Check if sel is valid
            if((&m_req_item.m_sel_o)) begin
            // Check if transaction is write or read
            case (m_req_item.m_dir)
                WB_WRITE:
                begin
                    // Write data to external memory model
                    dma_mem::write(m_req_item.m_addr_o,m_req_item.m_data_o);
                    m_tr_item.m_ack_i=1;
                    m_tr_item.m_err_i=0;
                end
                WB_READ:
                begin
                    // Read data from external memory model
                    dma_mem::read(m_req_item.m_addr_o,m_tr_item.m_data_i);
                    m_tr_item.m_ack_i=1;
                    m_tr_item.m_err_i=0;
                end
                endcase
            end
            //There's no transaction so don't assert ack signal and Error is always 0.
            else begin
                m_tr_item.m_ack_i=0;
                m_tr_item.m_err_i=0;
            end
            // start transaction on sequencer
            start_item(m_tr_item);
            finish_item(m_tr_item);
        end
    endtask

endclass : wb_m_seq_wr_rd

`endif // WB_M_SEQ_WR_RD_SV
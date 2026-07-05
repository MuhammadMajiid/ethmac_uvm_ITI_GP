//==============================================================================
// Project  : ethmac_uvm_ITI_GP
// File     : crc_func.sv
// Author   : Wael
// Date     : 2026-07-1
//------------------------------------------------------------------------------
// Description:
//   Function to calculate crc
//==============================================================================
`ifndef CRC_FUNC_SV
`define CRC_FUNC_SV
    function bit [31:0] calc_crc32(bytes_q data);

        bit          [31:0] crc;
        byte         current_byte;
        bit          b;
        int         len ;
        
        len = data.size();
        crc = 32'hFFFF_FFFF;

        for (int i = 0; i < len; i++) begin
            current_byte = data[i];
            for (int bit_i = 0; bit_i < 8; bit_i++) begin
                b   = crc[0] ^ current_byte[bit_i];
                crc = crc >> 1;
                if (b) crc = crc ^ ETH_CRC_POLY;
            end
        end

        return ~crc;

    endfunction   
`endif // DMA_MEM_SV
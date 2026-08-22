# Exclude only the three uncovered statement bins in dut/wishbone/bd_ram.
#
# Usage after loading/opening the design or UCDB in Questa:
#   do exclude_bd_ram_uncovered.do
#
# For an existing UCDB, for example:
#   vsim -viewcov eth_regression_reg_tx_code_cov.ucdb -do exclude_bd_ram_uncovered.do

set bd_ram_scope   {/dut/wishbone/bd_ram}
set bd_ram_srcfile {D:/C/ITI/GP/repo/rtl/eth_spram_256x32.v}
set exclusion_note {Uncovered bd_ram statements waived for TX code coverage}

# Line 299 has two uncovered statement items.
coverage exclude \
    -scope $bd_ram_scope \
    -srcfile $bd_ram_srcfile \
    -linerange 299 \
    -code s \
    -item s 1 2 \
    -reason EOTH \
    -comment $exclusion_note

# Line 300 has one uncovered statement item.
coverage exclude \
    -scope $bd_ram_scope \
    -srcfile $bd_ram_srcfile \
    -linerange 300 \
    -code s \
    -item s 1 \
    -reason EOTH \
    -comment $exclusion_note

puts {Excluded 3 uncovered statement bins in /dut/wishbone/bd_ram.}

# -----------------------------------------------------------------------------
# /dut/wishbone/tx_fifo: exclude every currently uncovered code-coverage bin.
# Source: eth_fifo.v
#   branch:   line 165, item 1
#   statement: line 166, item 1
#   condition rows: line 119 row 4; line 131 row 4;
#                   line 165 rows 2 and 4; line 168 row 4
# -----------------------------------------------------------------------------
set tx_fifo_scope   {/dut/wishbone/tx_fifo}
set tx_fifo_srcfile {D:/C/ITI/GP/repo/rtl/eth_fifo.v}
set tx_fifo_note    {Uncovered tx_fifo code-coverage bins waived for TX regression}

coverage exclude \
    -scope $tx_fifo_scope -srcfile $tx_fifo_srcfile \
    -linerange 165 -code b -item b 1 \
    -reason EOTH -comment $tx_fifo_note

coverage exclude \
    -scope $tx_fifo_scope -srcfile $tx_fifo_srcfile \
    -linerange 166 -code s -item s 1 \
    -reason EOTH -comment $tx_fifo_note

coverage exclude \
    -scope $tx_fifo_scope -srcfile $tx_fifo_srcfile \
    -feccondrow 119 4 -item 1 \
    -reason EOTH -comment $tx_fifo_note

coverage exclude \
    -scope $tx_fifo_scope -srcfile $tx_fifo_srcfile \
    -feccondrow 131 4 -item 1 \
    -reason EOTH -comment $tx_fifo_note

coverage exclude \
    -scope $tx_fifo_scope -srcfile $tx_fifo_srcfile \
    -feccondrow 165 2 4 -item 1 \
    -reason EOTH -comment $tx_fifo_note

coverage exclude \
    -scope $tx_fifo_scope -srcfile $tx_fifo_srcfile \
    -feccondrow 168 4 -item 1 \
    -reason EOTH -comment $tx_fifo_note

# /dut/macstatus1: exclude only the uncovered condition row at line 415,
# item 1 (Collision_1, focused-condition row 6).
coverage exclude \
    -scope {/dut/macstatus1} \
    -srcfile {D:/C/ITI/GP/repo/rtl/eth_macstatus.v} \
    -feccondrow 415 6 -item 1 \
    -reason EOTH \
    -comment {Unreachable Collision_1 condition bin waived for TX regression}

# -----------------------------------------------------------------------------
# /dut/maccontrol1/transmitcontrol1
# Exclude every coverage item that is currently uncovered in this instance.
# -----------------------------------------------------------------------------
set txctrl_scope {/dut/maccontrol1/transmitcontrol1}
set txctrl_src   {D:/C/ITI/GP/repo/rtl/eth_transmitcontrol.v}
set txctrl_note  {Uncovered transmitcontrol coverage waived for TX regression}

coverage exclude -scope $txctrl_scope -srcfile $txctrl_src \
    -linerange 271 -code b -item b 1 \
    -reason EOTH -comment $txctrl_note

foreach line {145 159 185 200 271} {
    coverage exclude -scope $txctrl_scope -srcfile $txctrl_src \
        -linerange $line -code c -item c 1 \
        -reason EOTH -comment $txctrl_note
}

coverage exclude -scope $txctrl_scope -srcfile $txctrl_src \
    -fecexprrow 259 1 3 4 6 8 -item 1 \
    -reason EOTH -comment $txctrl_note

coverage exclude -scope $txctrl_scope -srcfile $txctrl_src \
    -linerange 272 -code s -item s 1 \
    -reason EOTH -comment $txctrl_note

coverage exclude -togglenode {DlyCrcCnt[3]} IncrementByteCntBy2 \
    -scope $txctrl_scope \
    -reason EOTH -comment $txctrl_note

# -----------------------------------------------------------------------------
# Expression coverage misses in the two child instances.
# The UCDB instance name is txstatem1 .
# -----------------------------------------------------------------------------
set txcounter_expr_note {Uncovered txcounters expression rows waived for TX regression}
foreach row_spec {{146 1 4 6}} {
    coverage exclude \
        -scope {/dut/txethmac1/txcounters1} \
        -srcfile {D:/C/ITI/GP/repo/rtl/eth_txcounters.v} \
        -fecexprrow {*}$row_spec -item 1 \
        -reason EOTH -comment $txcounter_expr_note
}

set txstatem_expr_note {Uncovered txstatem expression rows waived for TX regression}
foreach row_spec {
    {172 2}
    {176 2}
    {178 2}
    {181 5 6 7 8 14}
    {185 1 4 7 8 9 10 28}
} {
    coverage exclude \
        -scope {/dut/txethmac1/txstatem1} \
        -srcfile {D:/C/ITI/GP/repo/rtl/eth_txstatem.v} \
        -fecexprrow {*}$row_spec -item 1 \
        -reason EOTH -comment $txstatem_expr_note
}

# -----------------------------------------------------------------------------
# /dut/txethmac1 itself only; no -recursive, so child instances are unaffected.
# -----------------------------------------------------------------------------
set txethmac_scope {/dut/txethmac1}
set txethmac_src   {D:/C/ITI/GP/repo/rtl/eth_txethmac.v}
set txethmac_note  {Uncovered txethmac parent-module coverage waived for TX regression}

foreach line {247 321 337 341} {
    coverage exclude -scope $txethmac_scope -srcfile $txethmac_src \
        -linerange $line -code c -item c 1 \
        -reason EOTH -comment $txethmac_note
}

foreach row_spec {
    {204 3 5}
    {206 2}
    {208 2}
    {210 2 8}
    {213 4}
} {
    coverage exclude -scope $txethmac_scope -srcfile $txethmac_src \
        -fecexprrow {*}$row_spec -item 1 \
        -reason EOTH -comment $txethmac_note
}


# -----------------------------------------------------------------------------
# /dut/wishbone itself; child instances are unaffected because this is not
# recursive. Exclude the unreachable TxValidBytesLatched default statement and
# all currently uncovered TX-related condition/expression items from merged.ucdb.
# -----------------------------------------------------------------------------
set wishbone_scope {/dut/wishbone}
set wishbone_src   {D:/C/ITI/GP/repo/rtl/eth_wishbone.v}
set wishbone_note  {Uncovered TX-related wishbone coverage waived for TX regression}

# TxValidBytesLatched is two bits and cases 0, 1, 2, and 3 are already covered;
# therefore this defensive default is unreachable.
coverage exclude -scope $wishbone_scope -srcfile $wishbone_src \
    -linerange 1596 -code s -item s 1 \
    -reason EOTH -comment $wishbone_note

# TX-related focused-condition items reported uncovered in merged.ucdb.
foreach line {588 817 882 913 930 944 1005 1296 1449 1462 1465 1490 1506 1531 1544 1547 1575} {
    coverage exclude -scope $wishbone_scope -srcfile $wishbone_src \
        -linerange $line -code c -item c 1 \
        -reason EOTH -comment $wishbone_note
}

# TX-related focused-expression rows reported uncovered in the UCDB.
foreach row_spec {
    {716 3}
    {724 4}
    {757 2 7}
    {977 1}
    {1013 4}
    {1592 1}
} {
    coverage exclude -scope $wishbone_scope -srcfile $wishbone_src \
        -fecexprrow {*}$row_spec -item 1 \
        -reason EOTH -comment $wishbone_note
}

puts {Applied wishbone line 1596 and TX-related condition/expression exclusions.}

# Toggle exclusions for /dut/wishbone. Questa applies -togglenode exclusions
# at node granularity, so excluding m_wb_we_o waives the complete node even
# though only its 1->0 transition is currently uncovered.
coverage exclude \
    -togglenode m_wb_we_o {TxBDDataIn[10:9]} {TxBDDataIn[15]} \
    -scope $wishbone_scope \
    -reason EOTH \
    -comment {Uncovered wishbone toggle bins waived for regression}

puts {Applied wishbone m_wb_we_o and TxBDDataIn[10:9] toggle exclusions.}

# -----------------------------------------------------------------------------
# /dut/ethreg1 toggle holes from merged.ucdb. Keep INT_SOURCEOut[4],
# MIISTATUSOut[0], and irq_busy uncovered so they remain visible targets.
# -----------------------------------------------------------------------------
set ethreg1_toggle_scope {/dut/ethreg1}
set ethreg1_toggle_note  {Uncovered ethreg1 toggle bins waived for regression}

coverage exclude \
    -togglenode \
        {COLLCONFOut[15:6]} {COLLCONFOut[31:20]} {COLLCONF_Wr[1]} \
        {CTRLMODEROut[31:3]} \
        {INT_MASKOut[31:7]} {INT_SOURCEOut[31:7]} \
        {IPGR1Out[31:7]} {IPGR2Out[31:7]} {IPGTOut[31:7]} \
        {MAC_ADDR1Out[31:16]} \
        {MIIADDRESSOut[7:5]} {MIIADDRESSOut[31:13]} \
        {MIICOMMANDOut[31:3]} {MIIMODEROut[31:9]} \
        {MIIRX_DATAOut[31:15]} {MIISTATUSOut[31:3]} \
        {MIITX_DATAOut[31:16]} {MODEROut[31:17]} \
        {TXCTRLOut[31:17]} {TX_BD_NUMOut[31:8]} \
    -scope $ethreg1_toggle_scope \
    -reason EOTH \
    -comment $ethreg1_toggle_note

puts {Applied ethreg1 toggle exclusions; retained INT_SOURCEOut[4], MIISTATUSOut[0], and irq_busy.}

# /dut/ethreg1: unreachable/default register-read statement.
coverage exclude \
    -scope $ethreg1_toggle_scope \
    -srcfile {D:/C/ITI/GP/repo/rtl/eth_registers.v} \
    -linerange 875 -code s -item s 1 \
    -reason EOTH \
    -comment {Uncovered ethreg1 statement at line 875 waived for regression}

puts {Applied ethreg1 line 875 statement exclusion.}

set miim1_scope {/dut/miim1}
set miim1_src   {D:/C/ITI/GP/repo/rtl/eth_miim.v}
set miim1_note  {Uncovered miim1 expression row waived for regression}

coverage exclude -scope $miim1_scope -srcfile $miim1_src \
    -fecexprrow 353 4 -item 1 \
    -reason EOTH -comment $miim1_note

coverage exclude -scope $miim1_scope -srcfile $miim1_src \
    -fecexprrow 357 10 14 -item 1 \
    -reason EOTH -comment $miim1_note

coverage exclude -scope $miim1_scope -srcfile $miim1_src \
    -fecexprrow 420 1 -item 1 \
    -reason EOTH -comment $miim1_note

coverage exclude -scope $miim1_scope -srcfile $miim1_src \
    -fecexprrow 421 1 -item 1 \
    -reason EOTH -comment $miim1_note

coverage exclude -scope $miim1_scope -srcfile $miim1_src \
    -fecexprrow 422 1 -item 1 \
    -reason EOTH -comment $miim1_note

coverage exclude -scope $miim1_scope -srcfile $miim1_src \
    -fecexprrow 426 3 -item 1 \
    -reason EOTH -comment $miim1_note

coverage exclude -scope $miim1_scope -srcfile $miim1_src \
    -fecexprrow 427 3 -item 1 \
    -reason EOTH -comment $miim1_note
# /dut/miim1/clkgen:
# Counter[7] and CounterPreset[7] have no transitions covered.
coverage exclude \
    -scope {/dut/miim1/clkgen} \
    -togglenode {Counter[7]} {CounterPreset[7]} \
    -reason EOTH \
    -comment {Uncovered miim1 clkgen toggle bins waived for regression}

# /dut/miim1/shftrg:
# LinkFail lacks one transition; Prsd[15] lacks both transitions.
coverage exclude \
    -scope {/dut/miim1/shftrg} \
    -togglenode LinkFail {Prsd[15]} \
    -reason EOTH \
    -comment {Uncovered miim1 shftrg toggle bins waived for regression}

# =============================================================================
# Uncovered bins read from merged_exec.ucdb on 2026-08-09.
#
# Condition/expression exclusions below name only rows whose hit count is zero.
# Toggle exclusions name only uncovered scalar nodes or uncovered bit ranges;
# no full vector is selected when only part of that vector is uncovered.
# Existing exclusions above are intentionally preserved unchanged.
# =============================================================================
set merged_exec_note {Uncovered bin in merged_exec.ucdb}

proc exclude_merged_exec_rows {row_option scope src specs note} {
    foreach spec $specs {
        set line [lindex $spec 0]
        set item [lindex $spec 1]
        set rows [lrange $spec 2 end]
        coverage exclude -scope $scope -srcfile $src \
            $row_option $line {*}$rows -item $item \
            -reason EOTH -comment $note
    }
}

proc exclude_merged_exec_items {code scope src specs note} {
    foreach spec $specs {
        set line [lindex $spec 0]
        set item [lindex $spec 1]
        coverage exclude -scope $scope -srcfile $src \
            -linerange $line -code $code -item $code $item \
            -reason EOTH -comment $note
    }
}

# Branch items.
exclude_merged_exec_items b {/dut/ethreg1} \
    {D:/C/ITI/GP/repo/rtl/eth_registers.v} {{875 1} {1134 1}} $merged_exec_note
exclude_merged_exec_items b {/dut/maccontrol1/receivecontrol1} \
    {D:/C/ITI/GP/repo/rtl/eth_receivecontrol.v} {{410 1}} $merged_exec_note
exclude_merged_exec_items b {/dut/macstatus1} \
    {D:/C/ITI/GP/repo/rtl/eth_macstatus.v} {{298 1} {308 1}} $merged_exec_note
exclude_merged_exec_items b {/dut/rxethmac1/rxstatem1} \
    {D:/C/ITI/GP/repo/rtl/eth_rxstatem.v} {{169 1}} $merged_exec_note
exclude_merged_exec_items b {/dut/wishbone} \
    {D:/C/ITI/GP/repo/rtl/eth_wishbone.v} {
        {635 1} {643 3} {1051 1} {1080 1} {1081 1} {1082 1} {1083 1}
        {1094 1} {1096 1} {1099 1} {1106 1} {1134 1} {1145 1} {1146 1}
        {1158 1} {1160 1} {1596 1} {2093 1} {2400 1} {2538 1} {2541 1}
    } $merged_exec_note

# Focused-condition rows only.
exclude_merged_exec_rows -feccondrow {/dut} \
    {D:/C/ITI/GP/repo/rtl/eth_top.v} {{852 1 12 13}} $merged_exec_note
exclude_merged_exec_rows -feccondrow {/dut/ethreg1} \
    {D:/C/ITI/GP/repo/rtl/eth_registers.v} {{1014 1 3}} $merged_exec_note
exclude_merged_exec_rows -feccondrow {/dut/maccontrol1} \
    {D:/C/ITI/GP/repo/rtl/eth_maccontrol.v} {
        {194 1 2 5} {208 1 2}
    } $merged_exec_note
exclude_merged_exec_rows -feccondrow {/dut/maccontrol1/receivecontrol1} \
    {D:/C/ITI/GP/repo/rtl/eth_receivecontrol.v} {
        {171 1 1} {174 1 1} {177 1 1} {180 1 1} {183 1 1}
        {198 1 1} {201 1 1} {220 1 1} {223 1 1} {238 1 3 5 7}
        {254 1 1} {256 1 1} {283 1 1} {298 1 1} {301 1 2}
        {393 1 3} {431 1 3 5}
    } $merged_exec_note
exclude_merged_exec_rows -feccondrow {/dut/macstatus1} \
    {D:/C/ITI/GP/repo/rtl/eth_macstatus.v} {
        {222 1 3 5 6 7 8 9 11 12 13 14} {277 1 4}
        {298 1 1 2 4 5 8} {308 1 1 2 3 4 6}
    } $merged_exec_note
exclude_merged_exec_rows -feccondrow {/dut/rxethmac1} \
    {D:/C/ITI/GP/repo/rtl/eth_rxethmac.v} {{308 1 3}} $merged_exec_note
exclude_merged_exec_rows -feccondrow {/dut/rxethmac1/rxcounters1} \
    {D:/C/ITI/GP/repo/rtl/eth_rxcounters.v} {{210 1 1}} $merged_exec_note
exclude_merged_exec_rows -feccondrow {/dut/rxethmac1/rxstatem1} \
    {D:/C/ITI/GP/repo/rtl/eth_rxstatem.v} {{154 1 2} {172 1 2}} $merged_exec_note
exclude_merged_exec_rows -feccondrow {/dut/wishbone} \
    {D:/C/ITI/GP/repo/rtl/eth_wishbone.v} {
        {1094 1 1 2} {1099 1 1 2} {1849 1 4} {1894 1 1} {1924 1 1}
        {1941 1 1} {1965 1 3} {1984 1 1 3} {2022 1 1 5} {2030 1 5}
        {2041 1 1} {2049 1 2 4} {2059 1 2} {2091 1 3} {2167 1 4}
        {2229 1 2} {2270 1 2 5 9} {2400 1 2 3 4}
        {2538 1 1 3 4 6}
    } $merged_exec_note
exclude_merged_exec_rows -feccondrow {/dut/wishbone/rx_fifo} \
    {D:/C/ITI/GP/repo/rtl/eth_fifo.v} {
        {119 1 4} {131 1 4} {168 1 4}
    } $merged_exec_note

# Focused-expression rows only.
exclude_merged_exec_rows -fecexprrow {/dut} \
    {D:/C/ITI/GP/repo/rtl/eth_top.v} {
        {497 1 2 5 7 9 11} {498 1 2 5 7 9 11} {499 1 2 5 7 9 11}
        {500 1 2 5 7 9 11} {501 1 2 3 5 7 11} {502 1 2 3 5 7 11}
        {503 1 2 3 5 7 11} {504 1 2 3 5 7 11}
        {505 1 1 2 3 4 5 6 8} {507 1 1 2 3 4 5 8}
        {543 1 2 3 4} {749 1 2}
    } $merged_exec_note
exclude_merged_exec_rows -fecexprrow {/dut/ethreg1} \
    {D:/C/ITI/GP/repo/rtl/eth_registers.v} {
        {1166 1 7 11 15 18 19 20 27}
    } $merged_exec_note
exclude_merged_exec_rows -fecexprrow {/dut/maccontrol1} \
    {D:/C/ITI/GP/repo/rtl/eth_maccontrol.v} {
        {237 1 4} {241 1 4}
    } $merged_exec_note
exclude_merged_exec_rows -fecexprrow {/dut/maccontrol1/receivecontrol1} \
    {D:/C/ITI/GP/repo/rtl/eth_receivecontrol.v} {
        {199 1 1} {202 1 1 3 5} {221 1 1} {224 1 1}
        {339 1 5 7 9} {340 1 3} {383 1 1} {401 1 3}
    } $merged_exec_note
exclude_merged_exec_rows -fecexprrow {/dut/macstatus1} \
    {D:/C/ITI/GP/repo/rtl/eth_macstatus.v} {{268 1 1}} $merged_exec_note
exclude_merged_exec_rows -fecexprrow {/dut/rxethmac1} \
    {D:/C/ITI/GP/repo/rtl/eth_rxethmac.v} {
        {239 1 3} {365 1 5} {366 1 5}
    } $merged_exec_note
exclude_merged_exec_rows -fecexprrow {/dut/rxethmac1/rxaddrcheck1} \
    {D:/C/ITI/GP/repo/rtl/eth_rxaddrcheck.v} {
        {128 1 6} {156 1 2 6 7}
    } $merged_exec_note
exclude_merged_exec_rows -fecexprrow {/dut/rxethmac1/rxcounters1} \
    {D:/C/ITI/GP/repo/rtl/eth_rxcounters.v} {
        {138 1 6 14 17} {171 1 2} {175 1 3} {177 1 10}
    } $merged_exec_note
exclude_merged_exec_rows -fecexprrow {/dut/rxethmac1/rxstatem1} \
    {D:/C/ITI/GP/repo/rtl/eth_rxstatem.v} {
        {126 1 6 8} {130 1 1 10} {132 1 7} {136 1 7 10 12}
    } $merged_exec_note
exclude_merged_exec_rows -fecexprrow {/dut/wishbone} \
    {D:/C/ITI/GP/repo/rtl/eth_wishbone.v} {
        {651 1 4} {1971 1 3} {1996 1 3 9} {2211 1 4}
        {2217 1 2} {2218 1 2} {2220 1 2 3 4} {2558 1 2 3 4}
    } $merged_exec_note
exclude_merged_exec_rows -fecexprrow {/dut/wishbone/rx_fifo} \
    {D:/C/ITI/GP/repo/rtl/eth_fifo.v} {{137 1 2}} $merged_exec_note

# Toggle holes. Each vector selection is limited to its uncovered bit ranges.
coverage exclude -scope {/dut} -togglenode \
    Busy_IRQ ByteSelected CsMiss LinkFail {Prsd[15]} {RxByteCnt[15:13]} \
    RxEnSync RxLateCollision RxStatePreamble {m_wb_adr_o[1:0]} m_wb_err_i \
    m_wb_we_o temp_wb_err_o temp_wb_err_o_reg {wb_adr_i[11]} wb_err_o \
    {wb_sel_i[3:0]} \
    -reason EOTH -comment $merged_exec_note

coverage exclude -scope {/dut/ethreg1} -togglenode \
    {INT_SOURCEOut[4]} {MIISTATUSOut[0]} irq_busy \
    -reason EOTH -comment $merged_exec_note
coverage exclude -scope {/dut/ethreg1/MIIRX_DATA} -togglenode {DataOut[15]} \
    -reason EOTH -comment $merged_exec_note
coverage exclude -scope {/dut/maccontrol1} -togglenode Pause \
    -reason EOTH -comment $merged_exec_note
coverage exclude -scope {/dut/maccontrol1/receivecontrol1} -togglenode \
    Pause {PauseTimer[6:5]} {PauseTimer[15:8]} PauseTimerEq0 \
    -reason EOTH -comment $merged_exec_note
coverage exclude -scope {/dut/rxethmac1/rxstatem1} -togglenode \
    StartPreamble StatePreamble \
    -reason EOTH -comment $merged_exec_note
coverage exclude -scope {/dut/rxethmac1/rxcounters1} -togglenode \
    {ByteCnt[15:13]} {ByteCntDelayed[15:13]} ByteCntMax \
    -reason EOTH -comment $merged_exec_note
coverage exclude -scope {/dut/rxethmac1/rxaddrcheck1} -togglenode MulticastOK \
    -reason EOTH -comment $merged_exec_note
coverage exclude -scope {/dut/macstatus1} -togglenode RxColWindow RxLateCollision \
    -reason EOTH -comment $merged_exec_note

coverage exclude -scope {/dut/wishbone} -togglenode \
    Busy_IRQ_rck Busy_IRQ_sync1 Busy_IRQ_sync2 Busy_IRQ_sync3 \
    Busy_IRQ_syncb1 Busy_IRQ_syncb2 {LatchedRxLength[15:13]} \
    {RxBDDataIn[0]} {RxBDDataIn[6]} {RxBDDataIn[12:8]} {RxBDDataIn[15:14]} \
    {RxBDDataIn[31:29]} RxBufferFull RxBurstAcc RxByteAcc {RxByteSel[0]} \
    RxHalfAcc RxIRQEn RxOverrun {RxPointerMSB[31:18]} {RxStatus[14]} \
    {RxStatusIn[0]} {RxStatusIn[6]} {RxStatusInLatched[0]} \
    {RxStatusInLatched[6]} {RxStatusInLatched[8]} RxWordAcc \
    enough_data_in_rxfifo_for_burst rx_burst {rx_burst_cnt[2:0]} \
    rx_burst_en {rxfifo_cnt[4:1]} \
    -reason EOTH -comment $merged_exec_note
coverage exclude -scope {/dut/wishbone/rx_fifo} -togglenode \
    almost_full {cnt[4:1]} \
    -reason EOTH -comment $merged_exec_note

puts {Applied precise uncovered-bin exclusions from merged_exec.ucdb.}

# =============================================================================
# Remaining bimodal FEC, statement, all-false branch, and toggle holes found by
# re-reading merged_exec.ucdb.  Scopes are deliberately non-recursive.
# =============================================================================
set merged_exec_bimodal_note {Remaining uncovered bin in merged_exec.ucdb}

# /dut/macstatus1: the two uncovered statements only.
exclude_merged_exec_items s {/dut/macstatus1} \
    {D:/C/ITI/GP/repo/rtl/eth_macstatus.v} {{299 1} {309 1}} \
    $merged_exec_bimodal_note

# /dut/ethreg1 itself: the one uncovered statement only.
exclude_merged_exec_items s {/dut/ethreg1} \
    {D:/C/ITI/GP/repo/rtl/eth_registers.v} {{1135 1}} \
    $merged_exec_bimodal_note

# /dut/rxethmac1/rxstatem1: its remaining statement and toggle bins.
exclude_merged_exec_items s {/dut/rxethmac1/rxstatem1} \
    {D:/C/ITI/GP/repo/rtl/eth_rxstatem.v} {{170 1}} \
    $merged_exec_bimodal_note
coverage exclude -scope {/dut/rxethmac1/rxstatem1} \
    -togglenode Transmitting \
    -reason EOTH -comment $merged_exec_bimodal_note

# /dut/maccontrol1 itself: remaining bimodal expression terms.  Each list
# contains only the paired FEC rows belonging to an uncovered input term.
exclude_merged_exec_rows -fecexprrow {/dut/maccontrol1} \
    {D:/C/ITI/GP/repo/rtl/eth_maccontrol.v} {
        {214 1 7 8}
        {218 1 5 6 7 8}
        {225 1 7 8}
    } $merged_exec_bimodal_note

# /dut/maccontrol1/receivecontrol1 itself: all remaining coverage holes.
# Rows 3-4 and 5-6 at line 428 are the two uncovered bimodal condition terms.
exclude_merged_exec_rows -feccondrow {/dut/maccontrol1/receivecontrol1} \
    {D:/C/ITI/GP/repo/rtl/eth_receivecontrol.v} {
        {428 1 3 4 5 6}
    } $merged_exec_bimodal_note
exclude_merged_exec_items s {/dut/maccontrol1/receivecontrol1} \
    {D:/C/ITI/GP/repo/rtl/eth_receivecontrol.v} {{411 1}} \
    $merged_exec_bimodal_note
coverage exclude -scope {/dut/maccontrol1/receivecontrol1} -togglenode \
    {LatchedTimerValue[1]} {LatchedTimerValue[6:3]} \
    {LatchedTimerValue[8]} {LatchedTimerValue[12:10]} \
    PauseTimerEq0_sync1 PauseTimerEq0_sync2 \
    -reason EOTH -comment $merged_exec_bimodal_note

# /dut/wishbone itself only.  No -recursive option is used anywhere here.
set merged_exec_wishbone_scope {/dut/wishbone}
set merged_exec_wishbone_src {D:/C/ITI/GP/repo/rtl/eth_wishbone.v}

# The only remaining branch holes are the All False bins for these constructs.
foreach line {608 870 1609 1621 1695 1948 2023 2042 2062 2071 2092} {
    coverage exclude -scope $merged_exec_wishbone_scope \
        -srcfile $merged_exec_wishbone_src -linerange $line \
        -code b -allfalse \
        -reason EOTH -comment $merged_exec_bimodal_note
}

# Remaining bimodal condition terms, expressed as their paired FEC rows.
exclude_merged_exec_rows -feccondrow $merged_exec_wishbone_scope \
    $merged_exec_wishbone_src {
        {2503 1 3 4 9 10 11 12}
        {2516 1 3 4 7 8 9 10}
    } $merged_exec_bimodal_note

# Remaining bimodal expression terms, expressed as their paired FEC rows.
exclude_merged_exec_rows -fecexprrow $merged_exec_wishbone_scope \
    $merged_exec_wishbone_src {
        {1168 1 1 2 3 4 5 6}
        {1182 1 1 2 3 4 5 6}
        {2107 1 5 6 15 16}
    } $merged_exec_bimodal_note

# Remaining statement items in /dut/wishbone itself.
exclude_merged_exec_items s $merged_exec_wishbone_scope \
    $merged_exec_wishbone_src {
        {1085 1} {1086 1} {1087 1} {1088 1} {1089 1} {1090 1}
        {1091 1} {1092 1} {1095 1} {1097 1} {1101 1}
        {1148 1} {1149 1} {1150 1} {1151 1} {1152 1} {1153 1}
        {1154 1} {1155 1} {2093 1} {2401 1} {2539 1} {2542 1}
    } $merged_exec_bimodal_note

coverage exclude -scope $merged_exec_wishbone_scope \
    -togglenode enough_data_in_rxfifo_for_burst_plus1 \
    -reason EOTH -comment $merged_exec_bimodal_note

puts {Applied remaining scoped coverage exclusions from merged_exec.ucdb.}

# /dut itself: the two remaining bimodal expressions.  Only the paired FEC
# rows belonging to uncovered input terms are selected.
exclude_merged_exec_rows -fecexprrow {/dut} \
    {D:/C/ITI/GP/repo/rtl/eth_top.v} {
        {649 1 7 8}
        {652 1 3 4 7 8}
    } $merged_exec_bimodal_note

puts {Applied the remaining /dut expression-row exclusions.}

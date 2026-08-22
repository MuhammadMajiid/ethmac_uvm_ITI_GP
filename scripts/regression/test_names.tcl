set TEST_NAMES_0 [list \
    [list eth_test_miim_clkdiv               8   0] \
    [list eth_test_miim_rw_preamble         10   0] \
    [list eth_test_miim_rst_phy              5   0] \
    [list eth_test_miim_scan                 5   0] \
    [list eth_test_miim_cov_cross            1   0] \
    [list eth_test_miim_walking             16   0] \
    [list eth_test_miim_write_readonly_regs 32   0] \
    [list eth_test_miim_priority            10   0] \
    [list eth_test_miim_wrong_phy_addr      31   0] \
    [list eth_test_miim_scan_intr           10   0] \
    [list eth_test_miim_reg_bits            16   0] \
    [list eth_test_miim_scan_intr_sweep     16   0] \
    [list eth_test_miim_back_to_back        16   0] \
    [list eth_test_miim_phy_addr_sweep      16   0] \
    [list eth_test_miim_reset_in_flight     16   0] \
    [list eth_test_miim_overwrite_while_busy 16   0] \
    [list eth_test_miim_clkdiv_extremes     16   0] \
    [list eth_test_miim_linkfail_toggle     16   0] \
    [list eth_test_miim_scan_continuous     16   0] \
    [list eth_test_miim_clear_cmd_while_busy 16  0] \
    [list eth_test_miim_bitcounter_abort_sweep 16 0] \
]

set TEST_NAMES_1 [list \
    [list eth_test_bd_access       1   1] \
    [list eth_test_reg_access      1   1] \
    [list eth_test_tx_ptr          1   1] \
    [list eth_test_tx_coll         95  550] \
    [list eth_test_tx_coll_pre     1   4] \
    [list eth_test_tx_df           15  1] \
    [list eth_test_tx_underrun     2   1] \
    [list eth_test_tx_interrupts   30  1] \
    [list eth_test_tx_len          150 1] \
    [list eth_test_tx_ipgt         15  1] \
    [list eth_test_tx_cs           4   1] \
    [list eth_test_tx_maxfl        110  1] \
    [list eth_test_tx_minfl        280 1] \
    [list eth_test_tx_ctrl_flow    220 1] \
    [list eth_test_tx_moder        260 1] \
    [list eth_test_tx_bd_num       18  1] \
    [list eth_test_tx_max_len      1   1] \
]
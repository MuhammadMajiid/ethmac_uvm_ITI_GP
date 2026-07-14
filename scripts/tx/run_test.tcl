# Default test if TESTNAME is not set externally
if {![info exists TESTNAME]} {
    set TESTNAME "eth_test_tx_smoke"
    puts "WARNING: TESTNAME not set, defaulting to $TESTNAME"
}

puts ""
puts "=================================================="
puts " Compiling and Running TEST = $TESTNAME"
puts "=================================================="



set seed [clock milliseconds]

set fp [open "repo/results/tx/seeds.txt" a]
puts $fp "$TESTNAME,$seed"
close $fp

vlib work
vmap work work

transcript file repo/results/tx/log/${TESTNAME}.log


vlog repo/tb/global/eth_glob_pkg.sv \
repo/tb/interfaces/*.sv \
repo/tb/seq_items/mii_tx/mii_tx_seq_item_pkg.sv \
repo/tb/seq_items/wb_m/wb_m_seq_item_pkg.sv \
repo/tb/seq_items/wb_s/wb_s_seq_item_pkg.sv \
repo/tb/seq_items/mii_rx/mii_rx_seq_item_pkg.sv \
repo/tb/config/eth_config_pkg.sv \
repo/tb/ral/eth_ral_pkg.sv \
repo/tb/sequences/wb_m_seq/wb_m_seq_pkg.sv \
repo/tb/sequences/wb_s_seq/wb_s_seq_pkg.sv \
repo/tb/sequences/mii_tx_seq/mii_tx_seq_pkg.sv \
repo/tb/virtual_seq_sqr/eth_v_seq_sqr_pkg.sv \
repo/tb/agents/mii_tx/mii_tx_agent_pkg.sv \
repo/tb/agents/mii_rx/mii_rx_agent_pkg.sv \
repo/tb/agents/wb_m/wb_m_agent_pkg.sv \
repo/tb/agents/wb_s/wb_s_agent_pkg.sv \
repo/tb/scoreboards/eth_tx_scoreboard/eth_tx_scoreboard_pkg.sv \
repo/tb/scoreboards/eth_rx_scoreboard/eth_rx_scoreboard_pkg.sv \
repo/tb/coverage/eth_cov_pkg.sv \
repo/tb/env/eth_env_pkg.sv \
repo/tb/tests/eth_tests_tx/eth_test_tx_pkg.sv \
repo/rtl/*.v \
repo/tb/top/eth_tb.sv \
+cover -covercells

vsim -c -voptargs=+acc work.eth_tb -coverage -classdebug -sv_seed seed -uvmcontrol=all \
  +uvm_set_verbosity=uvm_test_top.m_env.*,_ALL_,UVM_MEDIUM,time,0 \
  +UVM_TESTNAME=$TESTNAME -onfinish stop \
  -do {
    run -all; 
    coverage save repo/results/tx/coverage/${TESTNAME}_code_cov.ucdb -codeAll -instance eth_tb.dut
    coverage save repo/results/tx/coverage/${TESTNAME}_func_cov.ucdb -cvg -directive -assert
    }
transcript file ""

vcover report repo/results/tx/coverage/${TESTNAME}_func_cov.ucdb -details -annotate -all -output repo/results/tx/coverage/${TESTNAME}_func_cov.txt
vcover report repo/results/tx/coverage/${TESTNAME}_code_cov.ucdb -details -annotate -all -output repo/results/tx/coverage/${TESTNAME}_code_cov.txt
set TESTNAME "eth_test_tx_ctrl_flow"
set VERBOSITY "UVM_NONE"
set SEQ_NUM 220
vlib work
vmap work work
do scripts/compile.tcl
do scripts/run_test.tcl
exit
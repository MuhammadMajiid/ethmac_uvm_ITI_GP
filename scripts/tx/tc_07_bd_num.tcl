set TESTNAME "eth_test_tx_bd_num"
set VERBOSITY "UVM_MEDIUM"
vlib work
vmap work work
do scripts/compile.tcl
do scripts/run_test.tcl
exit
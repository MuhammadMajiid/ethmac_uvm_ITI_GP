set TESTNAME "eth_test_tx_smoke"
set VERBOSITY "UVM_MEDIUM"
vlib work
vmap work work
do scripts/tx/compile.tcl
do scripts/tx/run_test.tcl
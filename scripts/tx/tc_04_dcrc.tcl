set TESTNAME "eth_test_tx_dcrc"
set VERBOSITY "UVM_MEDIUM"
vlib work
vmap work work
do scripts/compile.tcl
do scripts/run_test.tcl
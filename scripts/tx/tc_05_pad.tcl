
set TESTNAME "eth_test_tx_pad"
set VERBOSITY "UVM_HIGH"
vlib work
vmap work work
do scripts/compile.tcl
do scripts/run_test.tcl
exit
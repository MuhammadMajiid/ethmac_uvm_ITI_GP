set TESTNAME "eth_test_tx_interrupts"
set VERBOSITY "UVM_HIGH"
set SEQ_NUM  25
vlib work
vmap work work
do scripts/tx/compile.tcl
do scripts/tx/run_test.tcl
exit


set TESTNAME "eth_test_tx_bd_num_rand"
set VERBOSITY "UVM_MEDIUM"
set SEQ_NUM  18
vlib work
vmap work work
do scripts/tx/compile.tcl
do scripts/tx/run_test.tcl
exit


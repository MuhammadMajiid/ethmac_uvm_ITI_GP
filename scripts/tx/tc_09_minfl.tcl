
set TESTNAME "eth_test_tx_minfl"
set VERBOSITY "UVM_MEDIUM"
set SEQ_NUM  240
vlib work
vmap work work 
do scripts/compile.tcl
do scripts/run_test.tcl
exit

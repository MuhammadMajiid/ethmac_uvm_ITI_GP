
set TESTNAME "eth_test_tx_maxfl"
set VERBOSITY "UVM_NONE"
set SEQ_NUM  150
vlib work
vmap work work 
do scripts/compile.tcl
do scripts/run_test.tcl
exit

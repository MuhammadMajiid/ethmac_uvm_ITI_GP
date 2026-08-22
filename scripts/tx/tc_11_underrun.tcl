
set TESTNAME "eth_test_tx_underrun"
set VERBOSITY "UVM_MEDIUM"
set COV_PATH    "repo/results/tx/coverage"
set LOG_PATH    "repo/results/tx/log"
set SEQ_NUM 2
vlib work
vmap work work 
do scripts/compile.tcl
do scripts/run_test.tcl
exit

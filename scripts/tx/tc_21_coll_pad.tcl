set TESTNAME  "eth_test_tx_coll_pad"
set VERBOSITY "UVM_MEDIUM"
set SEQ_NUM   1
set COLL_NUM  4
set COV_PATH    "repo/results/tx/coverage"
set LOG_PATH    "repo/results/tx/log"
vlib work
vmap work work
do scripts/compile.tcl
do scripts/run_test.tcl
exit
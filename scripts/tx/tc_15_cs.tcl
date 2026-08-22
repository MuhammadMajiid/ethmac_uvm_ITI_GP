set TESTNAME  "eth_test_tx_cs"
set VERBOSITY "UVM_MEDIUM"
set SEQ_NUM   4
set COV_PATH    "repo/results/tx/coverage"
set LOG_PATH    "repo/results/tx/log"
vlib work
vmap work work
do scripts/compile.tcl
do scripts/run_test.tcl
exit
set TESTNAME  "eth_test_tx_coll"
set VERBOSITY "UVM_HIGH"
set SEQ_NUM   1
set COLL_NUM  5

vlib work
vmap work work
do scripts/tx/compile.tcl
do scripts/tx/run_test.tcl
exit
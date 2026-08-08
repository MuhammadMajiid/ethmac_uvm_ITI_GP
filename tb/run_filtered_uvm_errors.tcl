source scripts/test_names.tcl

set FILTERED_TEST_NAMES {}
foreach test_config $TEST_NAMES {
    if {[lindex $test_config 0] ne "eth_test_tx_ctrl_flow"} {
        lappend FILTERED_TEST_NAMES $test_config
    }
}

set VERBOSITY "UVM_NONE"
vlib work
vmap work work
do scripts/compile.tcl

foreach test_config $FILTERED_TEST_NAMES {
    lassign $test_config TESTNAME SEQ_NUM COLL_NUM
    puts "========== Running $TESTNAME (SEQ_NUM=$SEQ_NUM, COLL_NUM=$COLL_NUM) =========="
    do scripts/run_test.tcl
}

quit -f

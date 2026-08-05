puts ""
puts "=================================================="
puts "         STARTING REG & TX REGRESSION                "
puts "=================================================="
puts ""



# Test names
do scripts/test_names.tcl

# Verbosity
set VERBOSITY "UVM_MEDIUM"

# Paths
set COV_PATH    "repo/results/tx/coverage"
set LOG_PATH    "repo/results/tx/log"

# Master files
set TOTAL_LOG       "${LOG_PATH}/eth_regression_reg_tx.log"
set TOTAL_FUNC_UCDB "${COV_PATH}/eth_regression_reg_tx_func_cov.ucdb"
set TOTAL_CODE_UCDB "${COV_PATH}/eth_regression_reg_tx_code_cov.ucdb"
set TOTAL_FUNC_REP  "${COV_PATH}/eth_regression_reg_tx_func_cov.txt"
set TOTAL_CODE_REP  "${COV_PATH}/eth_regression_reg_tx_code_cov.txt"


# Remove old coverage files
set fp [open $TOTAL_CODE_UCDB w]
close $fp
set fp [open $TOTAL_FUNC_UCDB w]
close $fp
set fp [open $TOTAL_CODE_REP w]
close $fp
set fp [open $TOTAL_FUNC_REP w]
close $fp

# Prepare the summary log file
set fp [open $TOTAL_LOG w]
puts $fp "=================================================="
puts $fp "       REG & TX REGRESSION SUMMARY REPORT"
puts $fp "=================================================="
puts $fp "Date : [clock format [clock seconds]]"
puts $fp ""
puts $fp [format "%-30s %s" "TEST NAME" "STATUS"]
puts $fp "--------------------------------------------------"
close $fp

vlib work
vmap work work

# Compile all files 
do scripts/compile.tcl

# Iterate over all test configurations
foreach test_config $TEST_NAMES {
    lassign $test_config TESTNAME SEQ_NUM COLL_NUM

    puts "========== Running $TESTNAME (SEQ_NUM=$SEQ_NUM, COLL_NUM=$COLL_NUM) =========="
    do scripts/run_test.tcl

    vcover merge  -out $TOTAL_FUNC_UCDB $TOTAL_FUNC_UCDB $FUNC_UCDB
    vcover merge  -out $TOTAL_CODE_UCDB $TOTAL_CODE_UCDB $CODE_UCDB
    
    set fp [open $TOTAL_LOG a]
    puts $fp [format "%-30s %s" $TESTNAME \
        "DONE  -> log: $LOG_FILE"]
    close $fp
}


vcover report $TOTAL_FUNC_UCDB -details -annotate -all -output $TOTAL_FUNC_REP
vcover report $TOTAL_CODE_UCDB -details -annotate -all -output $TOTAL_CODE_REP

set fp [open $TOTAL_LOG a]
puts $fp ""
puts $fp "=================================================="
puts $fp "         FINISHING REG & TX REGRESSION                "
puts $fp "=================================================="
puts $fp ""
close $fp
exit

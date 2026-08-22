puts ""
puts "=================================================="
puts "         STARTING REG-TX-MIIM REGRESSION          "
puts "=================================================="
puts ""

# Master files
set TOTAL_LOG       "repo/results/eth/log/eth_regression_reg_tx_miim.log"
set TOTAL_FUNC_UCDB "repo/results/eth/coverage/eth_regression_reg_tx_miim_func_cov.ucdb"
set TOTAL_CODE_UCDB "repo/results/eth/coverage/eth_regression_reg_tx_miim_code_cov.ucdb"
set TOTAL_FUNC_REP  "repo/results/eth/coverage/eth_regression_reg_tx_miim_func_cov"
set TOTAL_CODE_REP  "repo/results/eth/coverage/eth_regression_reg_tx_miim_code_cov"


# Remove old coverage files
set fp [open $TOTAL_CODE_UCDB w]
close $fp
set fp [open $TOTAL_FUNC_UCDB w]
close $fp
set fp [open "${TOTAL_CODE_REP}.txt" w]
close $fp
set fp [open "${TOTAL_FUNC_REP}.txt" w]
close $fp


# Prepare the summary log file
set fp [open $TOTAL_LOG w]
puts $fp "=================================================="
puts $fp "       REG-TX-MIIM REGRESSION SUMMARY REPORT"
puts $fp "=================================================="
puts $fp "Date : [clock format [clock seconds]]"
puts $fp ""
puts $fp [format "%-30s %s" "TEST NAME" "STATUS"]
puts $fp "--------------------------------------------------"
close $fp

# create work library
vlib work
vmap work work

# Compile all files 
do scripts/compile.tcl

# Test names
do scripts/regression/test_names.tcl

# Verbosity
set VERBOSITY "UVM_NONE"

# Paths
set COV_PATH    "repo/results/mdio/coverage"
set LOG_PATH    "repo/results/mdio/log"

# Iterate over miim configurations
foreach test_config $TEST_NAMES_0 {
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

# Paths
set COV_PATH    "repo/results/tx/coverage"
set LOG_PATH    "repo/results/tx/log"

# Iterate over reg & tx test configurations
foreach test_config $TEST_NAMES_1 {
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

# text format
vcover report $TOTAL_FUNC_UCDB -details -annotate -all -output "${TOTAL_FUNC_REP}.txt"
vcover report $TOTAL_CODE_UCDB -details -annotate -all -output "${TOTAL_CODE_REP}.txt"

# html format
vcover report -html -output $TOTAL_FUNC_REP $TOTAL_FUNC_UCDB  -details -testhitdata
vcover report -html -output $TOTAL_CODE_REP $TOTAL_CODE_UCDB  -details -testhitdata

set fp [open $TOTAL_LOG a]
puts $fp ""
puts $fp "=================================================="
puts $fp "         FINISHING REG-TX-MIIM REGRESSION         "
puts $fp "=================================================="
puts $fp ""
close $fp
exit

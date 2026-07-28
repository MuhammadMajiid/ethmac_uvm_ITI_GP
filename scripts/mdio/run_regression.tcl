puts ""
puts "=================================================="
puts "         STARTING MDIO REGRESSION                "
puts "=================================================="
puts ""

# Load test cases
do scripts/mdio/test_names.tcl

# Default Verbosity
set VERBOSITY "UVM_MEDIUM"

# Paths
set COV_PATH "results/mdio/coverage"
set LOG_PATH "results/mdio/log"

file mkdir $COV_PATH
file mkdir $LOG_PATH

# Master aggregate files
set TOTAL_LOG       "${LOG_PATH}/eth_regression_mdio.log"
set TOTAL_FUNC_UCDB "${COV_PATH}/eth_regression_mdio_func_cov.ucdb"
set TOTAL_CODE_UCDB "${COV_PATH}/eth_regression_mdio_code_cov.ucdb"
set TOTAL_FUNC_REP  "${COV_PATH}/eth_regression_mdio_func_cov.txt"
set TOTAL_CODE_REP  "${COV_PATH}/eth_regression_mdio_code_cov.txt"

# Clear previous regression outputs
set fp [open $TOTAL_CODE_UCDB w]; close $fp
set fp [open $TOTAL_FUNC_UCDB w]; close $fp
set fp [open $TOTAL_CODE_REP w]; close $fp
set fp [open $TOTAL_FUNC_REP w]; close $fp

# Prepare regression log header
set fp [open $TOTAL_LOG w]
puts $fp "=================================================="
puts $fp "         MDIO REGRESSION SUMMARY REPORT"
puts $fp "=================================================="
puts $fp "Date : [clock format [clock seconds]]"
puts $fp ""
puts $fp [format "%-35s %s" "TEST NAME" "STATUS"]
puts $fp "--------------------------------------------------"
close $fp

vlib work
vmap work work

# Compile all source files
do scripts/mdio/compile.tcl

# Loop through all configured tests
foreach test_config $TEST_NAMES {
    lassign $test_config TESTNAME SEQ_NUM COLL_NUM

    puts "========== Running $TESTNAME (SEQ_NUM=$SEQ_NUM, COLL_NUM=$COLL_NUM) =========="
    do scripts/mdio/run_test.tcl

    vcover merge -out $TOTAL_FUNC_UCDB $TOTAL_FUNC_UCDB $FUNC_UCDB
    vcover merge -out $TOTAL_CODE_UCDB $TOTAL_CODE_UCDB $CODE_UCDB
    
    set fp [open $TOTAL_LOG a]
    puts $fp [format "%-35s %s" $TESTNAME "DONE -> log: $LOG_FILE"]
    close $fp
}

# Generate merged coverage reports
vcover report $TOTAL_FUNC_UCDB -details -annotate -all -output $TOTAL_FUNC_REP
vcover report $TOTAL_CODE_UCDB -details -annotate -all -output $TOTAL_CODE_REP

set fp [open $TOTAL_LOG a]
puts $fp ""
puts $fp "=================================================="
puts $fp "         FINISHING MDIO REGRESSION                "
puts $fp "=================================================="
puts $fp ""
close $fp
exit
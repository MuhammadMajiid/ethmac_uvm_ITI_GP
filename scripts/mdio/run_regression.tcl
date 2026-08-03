puts ""
puts "=================================================="
puts "         STARTING MDIO REGRESSION                "
puts "=================================================="
puts ""

# Load test cases unless the caller already provided a custom TEST_NAMES list.
if {![info exists TEST_NAMES]} {
    do scripts/mdio/test_names.tcl
}

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

# Clear previous regression outputs. Do not create empty UCDB placeholders
# because later vcover commands will reject them as corrupted files.
file delete -force $TOTAL_CODE_UCDB $TOTAL_FUNC_UCDB $TOTAL_CODE_REP $TOTAL_FUNC_REP

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

if [file exists "work"] {vdel -all}
vlib work
vmap work work

# Compile all source files
do scripts/mdio/compile.tcl

# Loop through all configured tests
foreach test_config $TEST_NAMES {
    lassign $test_config TESTNAME SEQ_NUM COLL_NUM

    puts "========== Running $TESTNAME (SEQ_NUM=$SEQ_NUM, COLL_NUM=$COLL_NUM) =========="
    do scripts/mdio/run_test.tcl

    if {[file exists $FUNC_UCDB] && [file size $FUNC_UCDB] > 0} {
        if {[file exists $TOTAL_FUNC_UCDB] && [file size $TOTAL_FUNC_UCDB] > 0} {
            vcover merge -out $TOTAL_FUNC_UCDB $TOTAL_FUNC_UCDB $FUNC_UCDB
        } else {
            file copy -force $FUNC_UCDB $TOTAL_FUNC_UCDB
        }
    }
    if {[file exists $CODE_UCDB] && [file size $CODE_UCDB] > 0} {
        if {[file exists $TOTAL_CODE_UCDB] && [file size $TOTAL_CODE_UCDB] > 0} {
            vcover merge -out $TOTAL_CODE_UCDB $TOTAL_CODE_UCDB $CODE_UCDB
        } else {
            file copy -force $CODE_UCDB $TOTAL_CODE_UCDB
        }
    }

    # run_test.tcl's coverage-save lines only get reached if the sim actually
    # finished -- a mid-run Fatal/SIGSEGV kills vsim before them, so a 0-byte
    # report here means that test crashed, not completed.
    set fp [open $TOTAL_LOG a]
    set code_rep_exists [file exists $CODE_REP]
    set func_rep_exists [file exists $FUNC_REP]
    if {(!$code_rep_exists || ![file exists $FUNC_REP]) || ($code_rep_exists && [file size $CODE_REP] == 0) || ($func_rep_exists && [file size $FUNC_REP] == 0)} {
        puts $fp [format "%-35s %s" $TESTNAME "CRASHED (no coverage saved) -> log: $LOG_FILE"]
    } else {
        puts $fp [format "%-35s %s" $TESTNAME "DONE -> log: $LOG_FILE"]
    }
    close $fp
}

# Generate merged coverage reports only when a real aggregate UCDB exists.
if {[file exists $TOTAL_FUNC_UCDB] && [file size $TOTAL_FUNC_UCDB] > 0} {
    if {[catch {vcover report $TOTAL_FUNC_UCDB -details -annotate -all -output $TOTAL_FUNC_REP} err]} {
        puts "WARNING: functional aggregate coverage report generation failed: $err"
    }
} else {
    puts "WARNING: no aggregate functional UCDB exists; skipping merged report"
}
if {[file exists $TOTAL_CODE_UCDB] && [file size $TOTAL_CODE_UCDB] > 0} {
    if {[catch {vcover report $TOTAL_CODE_UCDB -details -annotate -all -output $TOTAL_CODE_REP} err]} {
        puts "WARNING: code aggregate coverage report generation failed: $err"
    }
} else {
    puts "WARNING: no aggregate code UCDB exists; skipping merged report"
}

# Generate HTML coverage reports only when a real aggregate UCDB exists.
if {[file exists $TOTAL_FUNC_UCDB] && [file size $TOTAL_FUNC_UCDB] > 0} {
    if {[catch {vcover report -html -output ${COV_PATH}/html_func_report $TOTAL_FUNC_UCDB -details -testhitdata} err]} {
        puts "WARNING: functional aggregate HTML coverage report generation failed: $err"
    }
}
if {[file exists $TOTAL_CODE_UCDB] && [file size $TOTAL_CODE_UCDB] > 0} {
    if {[catch {vcover report -html -output ${COV_PATH}/html_code_report $TOTAL_CODE_UCDB -details -testhitdata} err]} {
        puts "WARNING: code aggregate HTML coverage report generation failed: $err"
    }
}

set fp [open $TOTAL_LOG a]
puts $fp ""
puts $fp "=================================================="
puts $fp "         FINISHING MDIO REGRESSION                "
puts $fp "=================================================="
puts $fp ""
close $fp
exit
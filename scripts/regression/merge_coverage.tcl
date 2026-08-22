# Merge the functional and code coverage databases for all tests in test_names.tcl.
# Run this script from Questa/ModelSim with:
#     do scripts/merge_functional_coverage.tcl

set SCRIPT_DIR "D:/C/ITI/GP/scripts/regression"
source [file join $SCRIPT_DIR test_names.tcl]

set COV_PATH "D:/C/ITI/GP/repo/results/eth/coverage"
set MERGED_FUNC_UCDB [file join $COV_PATH "eth_regression_reg_tx_miim_func_cov.ucdb"]
set MERGED_CODE_UCDB [file join $COV_PATH "eth_regression_reg_tx_miim_code_cov.ucdb"]

set FUNC_UCDBS {}
set CODE_UCDBS {}
set MISSING_FUNC_UCDBS {}
set MISSING_CODE_UCDBS {}

set COV_PATH "D:/C/ITI/GP/repo/results/mdio/coverage"
foreach test_config $TEST_NAMES_0 {
    set TESTNAME [lindex $test_config 0]
    set FUNC_UCDB [file join $COV_PATH "${TESTNAME}_func_cov.ucdb"]
    set CODE_UCDB [file join $COV_PATH "${TESTNAME}_code_cov.ucdb"]

    if {[file isfile $FUNC_UCDB]} {
        lappend FUNC_UCDBS $FUNC_UCDB
    } else {
        lappend MISSING_FUNC_UCDBS $FUNC_UCDB
    }

    if {[file isfile $CODE_UCDB]} {
        lappend CODE_UCDBS $CODE_UCDB
    } else {
        lappend MISSING_CODE_UCDBS $CODE_UCDB
    }
}

set COV_PATH "D:/C/ITI/GP/repo/results/tx/coverage"
foreach test_config $TEST_NAMES_1 {
    set TESTNAME [lindex $test_config 0]
    set FUNC_UCDB [file join $COV_PATH "${TESTNAME}_func_cov.ucdb"]
    set CODE_UCDB [file join $COV_PATH "${TESTNAME}_code_cov.ucdb"]

    if {[file isfile $FUNC_UCDB]} {
        lappend FUNC_UCDBS $FUNC_UCDB
    } else {
        lappend MISSING_FUNC_UCDBS $FUNC_UCDB
    }

    if {[file isfile $CODE_UCDB]} {
        lappend CODE_UCDBS $CODE_UCDB
    } else {
        lappend MISSING_CODE_UCDBS $CODE_UCDB
    }
}

if {[llength $MISSING_FUNC_UCDBS] > 0} {
    puts stderr "ERROR: The following functional coverage databases are missing:"
    foreach db $MISSING_FUNC_UCDBS {
        puts stderr "  $db"
    }
}

if {[llength $MISSING_CODE_UCDBS] > 0} {
    puts stderr "ERROR: The following code coverage databases are missing:"
    foreach db $MISSING_CODE_UCDBS {
        puts stderr "  $db"
    }
}

if {[llength $MISSING_FUNC_UCDBS] > 0 ||
    [llength $MISSING_CODE_UCDBS] > 0} {
    error "Coverage merge aborted because one or more databases are missing."
}

if {[llength $FUNC_UCDBS] == 0 || [llength $CODE_UCDBS] == 0} {
    error "No functional or code coverage databases were found to merge."
}

puts "Merging [llength $FUNC_UCDBS] functional coverage databases..."
vcover merge -out $MERGED_FUNC_UCDB {*}$FUNC_UCDBS
puts "Merged functional coverage database: $MERGED_FUNC_UCDB"

puts "Merging [llength $CODE_UCDBS] code coverage databases..."
vcover merge -out $MERGED_CODE_UCDB {*}$CODE_UCDBS
puts "Merged code coverage database: $MERGED_CODE_UCDB"

set COV_PATH "D:/C/ITI/GP/repo/results/eth/coverage"
vcover report -html -output ${COV_PATH}/eth_regression_reg_tx_miim_code_cov ${MERGED_CODE_UCDB} -details -testhitdata
vcover report -html -output ${COV_PATH}/eth_regression_reg_tx_miim_func_cov ${MERGED_FUNC_UCDB} -details -testhitdata
exit
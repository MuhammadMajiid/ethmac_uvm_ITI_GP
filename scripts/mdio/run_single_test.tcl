# Run a single MDIO test by overriding TEST_NAMES with one entry.
# Example:
#   vsim -c -do "set TEST_NAMES [list [list eth_test_miim_walking 1 0]]; do scripts/mdio/run_regression.tcl"

# if [file exists "work"] {vdel -all}
# vlib work
# vmap work work

if {![info exists TEST_NAMES]} {
    set TEST_NAMES [list [list eth_test_miim_walking 1 0]]
}

if {![info exists TESTNAME]} {
    set TESTNAME [lindex [lindex $TEST_NAMES 0] 0]
}

do scripts/mdio/run_regression.tcl

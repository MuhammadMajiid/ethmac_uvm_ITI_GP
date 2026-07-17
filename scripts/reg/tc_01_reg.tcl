set TESTNAME "eth_test_reg_access"
set VERBOSITY "UVM_MEDIUM"
vlib work
vmap work work
do scripts/reg/compile.tcl
do scripts/reg/run_test.tcl
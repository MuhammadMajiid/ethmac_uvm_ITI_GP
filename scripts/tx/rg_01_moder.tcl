puts ""
puts "=================================================="
puts "         STARTING TX MODER REGRESSION                "
puts "=================================================="
puts ""

# number of runs
set NUM_RUNS    200

# testname and verbosity
set TESTNAME "eth_test_tx_moder"
set VERBOSITY "UVM_MEDIUM"

# Paths
set COV_PATH    "repo/results/tx/coverage"
set LOG_PATH    "repo/results/tx/log"

# Master files
set TOTAL_LOG       "${LOG_PATH}/eth_rg_tx_moder.log"
set TOTAL_FUNC_UCDB "${COV_PATH}/eth_rg_tx_moder_func_cov.ucdb"
set TOTAL_CODE_UCDB "${COV_PATH}/eth_rg_tx_moder_code_cov.ucdb"
set TOTAL_FUNC_REP  "${COV_PATH}/eth_rg_tx_moder_func_cov.txt"
set TOTAL_CODE_REP  "${COV_PATH}/eth_rg_tx_moder_code_cov.txt"

# Remove old files
set fp [open $TOTAL_LOG w]
close $fp
set fp [open $TOTAL_CODE_UCDB w]
close $fp
set fp [open $TOTAL_FUNC_UCDB w]
close $fp
set fp [open $TOTAL_CODE_REP w]
close $fp
set fp [open $TOTAL_FUNC_REP w]
close $fp

vlib work
vmap work work

# Compile all files 
do scripts/compile.tcl

# Iterate over test
for {set i 1} {$i <= $NUM_RUNS} {incr i} {

    puts "========== Run $i =========="
    do scripts/run_test.tcl
   # Append simulator log
    set in [open $LOG_FILE r]
    set out [open $TOTAL_LOG a]
    puts $out [read $in]
    close $in
    close $out

    vcover merge  -out $TOTAL_FUNC_UCDB $TOTAL_FUNC_UCDB $FUNC_UCDB
    vcover merge  -out $TOTAL_CODE_UCDB $TOTAL_CODE_UCDB $CODE_UCDB
}

vcover report $TOTAL_FUNC_UCDB -details -annotate -all -output $TOTAL_FUNC_REP
vcover report $TOTAL_CODE_UCDB -details -annotate -all -output $TOTAL_CODE_REP
exit
puts ""
puts "=================================================="
puts "         FINISHING TX MODER REGRESSION                "
puts "=================================================="
puts ""

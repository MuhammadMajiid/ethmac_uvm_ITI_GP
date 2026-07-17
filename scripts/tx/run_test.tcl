# Default test if TESTNAME is not set externally
if {![info exists TESTNAME]} {
    set TESTNAME "eth_test_tx_smoke"
    puts "WARNING: TESTNAME not set, defaulting to $TESTNAME"
}

puts ""
puts "=================================================="
puts " Compiling and Running TEST = $TESTNAME"
puts "=================================================="

# Paths
set SCRIPT_PATH "repo/results/tx/log"
set COV_PATH    "repo/results/tx/coverage"
set LOG_PATH    "repo/results/tx/log"

# Log file and ucdb variables
set LOG_FILE "${SCRIPT_PATH}/${TESTNAME}.log"
set CODE_UCDB "${COV_PATH}/${TESTNAME}_code_cov.ucdb"
set FUNC_UCDB "${COV_PATH}/${TESTNAME}_func_cov.ucdb"
set CODE_REP "${COV_PATH}/${TESTNAME}_code_cov.txt"
set FUNC_REP "${COV_PATH}/${TESTNAME}_func_cov.txt"

# Clear previous coverage files
set fp [open $CODE_UCDB w]
close $fp
set fp [open $FUNC_UCDB w]
close $fp
set fp [open $CODE_REP w]
close $fp
set fp [open $FUNC_REP w]
close $fp

transcript file $LOG_FILE

if {![info exists SEQ_NUM]} {
  set SEQ_NUM 1
}

vsim -c -voptargs=+acc work.eth_tb -coverage -classdebug -sv_seed random -uvmcontrol=all \
  +uvm_set_verbosity=uvm_test_top.m_env.*,_ALL_,$VERBOSITY,time,0 +seq_num=$SEQ_NUM \
  +UVM_TESTNAME=$TESTNAME -onfinish stop \
  -do {
    run -all; 
    coverage save $CODE_UCDB -codeAll -instance eth_tb.dut
    coverage save $FUNC_UCDB -cvg -directive -assert
    transcript file ""
    }


vcover report $FUNC_UCDB -details -annotate -all -output  $FUNC_REP
vcover report $CODE_UCDB -details -annotate -all -output  $CODE_REP

puts ""
puts "=================================================="
puts " Finishing TEST = $TESTNAME"
puts "=================================================="
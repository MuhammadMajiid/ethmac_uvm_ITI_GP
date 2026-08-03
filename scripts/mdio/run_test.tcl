# Default test if TESTNAME is not set externally
if {![info exists TESTNAME]} {
    set TESTNAME "eth_test_mdio_smoke"
    puts "WARNING: TESTNAME not set, defaulting to $TESTNAME"
}

if {![info exists VERBOSITY]} {
    set VERBOSITY "UVM_MEDIUM"
}

puts ""
puts "=================================================="
puts " Compiling and Running TEST = $TESTNAME"
puts "=================================================="

# Paths
set SCRIPT_PATH "results/mdio/log"
set COV_PATH    "results/mdio/coverage"

# Create directories if they don't exist
file mkdir $SCRIPT_PATH
file mkdir $COV_PATH

# Log file and ucdb variables
set LOG_FILE "${SCRIPT_PATH}/${TESTNAME}.log"
set CODE_UCDB "${COV_PATH}/${TESTNAME}_code_cov.ucdb"
set FUNC_UCDB "${COV_PATH}/${TESTNAME}_func_cov.ucdb"
set CODE_REP "${COV_PATH}/${TESTNAME}_code_cov.txt"
set FUNC_REP "${COV_PATH}/${TESTNAME}_func_cov.txt"

# Clear previous coverage files. Do not create zero-byte UCDB placeholders
# here because Questa's vcover tools treat them as invalid/corrupted files.
file delete -force $CODE_UCDB $FUNC_UCDB $CODE_REP $FUNC_REP

transcript file $LOG_FILE

if {![info exists SEQ_NUM]} {
    set SEQ_NUM 1
}

if {![info exists COLL_NUM]} {
    set COLL_NUM 0
}

vsim -c -voptargs=+acc work.eth_tb -coverage -classdebug -sv_seed random -uvmcontrol=all \
  +uvm_set_verbosity=uvm_test_top.m_env.*,_ALL_,$VERBOSITY,time,0 \
  +seq_num=$SEQ_NUM \
  +coll_num=$COLL_NUM \
  +UVM_TESTNAME=$TESTNAME \
  -onfinish stop \
  -do {
    view wave
    add wave -r /eth_tb/dut/*
    onerror {
      puts "ERROR/FATAL encountered -- saving partial coverage before continuing"
      coverage save $CODE_UCDB -codeAll -instance eth_tb.dut
      coverage save $FUNC_UCDB -cvg -directive -assert
      resume
    }

    # Exclusions
    coverage exclude -du eth_clockgen -togglenode Counter[7]
    coverage exclude -du eth_clockgen -togglenode CounterPreset[7]
    # coverage exclude -du eth_shiftreg -togglenode Prsd[0]
    # coverage exclude -du eth_shiftreg -togglenode Prsd[1]
    # coverage exclude -du eth_shiftreg -togglenode Prsd[3]
    # coverage exclude -du eth_shiftreg -togglenode Prsd[4]
    # coverage exclude -du eth_shiftreg -togglenode Prsd[5]
    # coverage exclude -du eth_shiftreg -togglenode Prsd[6]
    # coverage exclude -du eth_shiftreg -togglenode Prsd[7]
    # coverage exclude -du eth_shiftreg -togglenode Prsd[8]
    # coverage exclude -du eth_shiftreg -togglenode Prsd[9]
    # coverage exclude -du eth_shiftreg -togglenode Prsd[10]
    # coverage exclude -du eth_shiftreg -togglenode Prsd[11]

    run -all
    coverage save $CODE_UCDB -codeAll -instance eth_tb.dut
    coverage save $FUNC_UCDB -cvg -directive -assert
    transcript file ""
}

if {[file exists $FUNC_UCDB] && [file size $FUNC_UCDB] > 0} {
  catch {vcover report $FUNC_UCDB -details -annotate -all -output $FUNC_REP} err
  if {[info exists err] && $err ne ""} {
    puts "WARNING: functional coverage report generation failed for $TESTNAME: $err"
  }
} else {
  puts "WARNING: no functional UCDB generated for $TESTNAME"
}

if {[file exists $CODE_UCDB] && [file size $CODE_UCDB] > 0} {
  catch {vcover report $CODE_UCDB -details -annotate -all -output $CODE_REP} err
  if {[info exists err] && $err ne ""} {
    puts "WARNING: code coverage report generation failed for $TESTNAME: $err"
  }
} else {
  puts "WARNING: no code UCDB generated for $TESTNAME"
}

# Generate HTML reports for the single test only if a real UCDB exists.
if {[file exists $FUNC_UCDB] && [file size $FUNC_UCDB] > 0} {
  catch {vcover report -html -output ${COV_PATH}/${TESTNAME}_html_func $FUNC_UCDB -details -testhitdata} err
}
if {[file exists $CODE_UCDB] && [file size $CODE_UCDB] > 0} {
  catch {vcover report -html -output ${COV_PATH}/${TESTNAME}_html_code $CODE_UCDB -details -testhitdata} err
}

puts ""
puts "=================================================="
puts " Finishing TEST = $TESTNAME"
puts "=================================================="
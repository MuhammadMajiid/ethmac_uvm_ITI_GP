set TESTNAME    "eth_test_tx_smoke"
set VERBOSITY   "UVM_MEDIUM"
set COV_PATH    "repo/results/tx/coverage"
set LOG_PATH    "repo/results/tx/log"

vlib work
vmap work work
do scripts/compile.tcl
do scripts/run_test.tcl

#────────────────────────────────────────────────────────────────────────────────
#─────────────────XML to UCDB Conversion of Questa Testplan──────────────────────
#────────────────────────────────────────────────────────────────────────────────
#xml2ucdb -format Excel scripts/Testplan_TX.xml -ucdbfilename scripts/Verification_Plan.ucdb


#────────────────────────────────────────────────────────────────────────────────
# ────────────────── MERGE SIM COVERAGE + TESTPLAN ──────────────────────────────
#────────────────────────────────────────────────────────────────────────────────
#vcover merge -out scripts/Verification_Plan.ucdb scripts/Verification_Plan.ucdb $FUNC_UCDB




#────────────────────────────────────────────────────────────────────────────────
#───────────────────────────── HTML REPORT ──────────────────────────────────────
#────────────────────────────────────────────────────────────────────────────────
#vcover report -html -output scripts/cov_report scripts/Verification_Plan.ucdb -details -testhitdata

exit
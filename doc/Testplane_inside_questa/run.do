vlib work
vlog -f src_files.list
vsim -voptargs=+acc -cover -sv_seed random -l sim.log work.top
add wave -position insertpoint sim:/top/DUT/*
coverage save sim.ucdb -onexit
run -all
quit -sim
vcover report sim.ucdb -details -annotate -all -output Coverage_report.txt 

#────────────────────────────────────────────────────────────────────────────────
#─────────────────XML to UCDB Conversion of Questa Testplan──────────────────────
#────────────────────────────────────────────────────────────────────────────────
xml2ucdb -format Excel TestPlan.xml -ucdbfilename Verification_Plan.ucdb


#────────────────────────────────────────────────────────────────────────────────
# ────────────────── MERGE SIM COVERAGE + TESTPLAN ──────────────────────────────
#────────────────────────────────────────────────────────────────────────────────
vcover merge merged.ucdb Verification_Plan.ucdb sim.ucdb


#────────────────────────────────────────────────────────────────────────────────
# ────────── BACK-ANNOTATE (you can remove it, not important ) ──────────────────
#────────────────────────────────────────────────────────────────────────────────
vcover report merged.ucdb -plansection=/. -annotate \
              -output coverage_plan.txt


#────────────────────────────────────────────────────────────────────────────────
#───────────────────────────── HTML REPORT ──────────────────────────────────────
#────────────────────────────────────────────────────────────────────────────────
vcover report -html -output covreport merged.ucdb -details -testhitdata

#────────────────────────────────────────────────────────────────────────────────
# ── 13. OPEN VM TRACKER ────────────────────────────────────────────────────────
#────────────────────────────────────────────────────────────────────────────────
vsim -viewcov merged.ucdb

######### DO this to open Tracker to show the TestPlan #########
######### In Questa GUI menu:    "View > Verification Management > Tracker" #########





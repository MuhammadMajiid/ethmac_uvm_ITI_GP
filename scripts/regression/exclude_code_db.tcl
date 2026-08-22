vsim -viewcov repo/results/eth/coverage/merged.ucdb
do scripts/regression/exclude_code_cov.tcl
coverage save repo/results/eth/coverage/merged_exec.ucdb
vcover report -html -output repo/results/eth/coverage/merged_exec \
repo/results/eth/coverage/merged_exec.ucdb -details -testhitdata
exit
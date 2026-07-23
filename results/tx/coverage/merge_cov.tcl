set func_ucdb_files [list]
set code_ucdb_files [list]

set MERGED_FUNC_COV_UCDB "eth_tx_merged_func_cov.ucdb"
set MERGED_FUNC_COV_REP "eth_tx_merged_func_cov.txt"

set MERGED_CODE_COV_UCDB "eth_tx_merged_code_cov.ucdb"
set MERGED_CODE_COV_REP "eth_tx_merged_code_cov.txt"

foreach f [glob -nocomplain *.ucdb] {
    if {[string match "*_func_cov.ucdb" $f]} {
        if {![string equal $f MERGED_FUNC_COV_UCDB]} {
            lappend func_ucdb_files $f
        }
    }
    if {[string match "*_code_cov.ucdb" $f]} {
        if {![string equal $f MERGED_CODE_COV_UCDB]} {
            lappend code_ucdb_files $f
        }
    }
}

if {[llength $func_ucdb_files] > 0} {
    eval vcover merge  $MERGED_FUNC_COV_UCDB $func_ucdb_files
} else {
    echo "No func_cov.ucdb files found"
}

if {[llength $code_ucdb_files] > 0} {
    eval vcover merge  $MERGED_CODE_COV_UCDB $code_ucdb_files
} else {
    echo "No code_cov.ucdb files found"
}

vcover report  $MERGED_FUNC_COV_UCDB -details -annotate -all -output  $MERGED_FUNC_COV_REP
vcover report  $MERGED_CODE_COV_UCDB -details -annotate -all -output  $MERGED_CODE_COV_REP

exit
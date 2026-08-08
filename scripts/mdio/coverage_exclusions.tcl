#==============================================================================
# MIIM/MDIO Coverage Exclusions
# Project: ethmac_uvm_ITI_GP -- Group 2 (MIIM/MDIO)
#==============================================================================

# -----------------------------------------------------------------------------
# Exclusion 1: CounterPreset[7] toggle -- structurally unreachable
# -----------------------------------------------------------------------------
# Reason: Structurally unreachable (provable by construction, not untested).
# Justification: eth_clockgen.v line 90: CounterPreset = (TempDivider>>1) - 1.
#   TempDivider is clamped to max 8'hFF (255) (line ~88: TempDivider =
#   (Divider<2) ? 2 : Divider). Max value of TempDivider>>1 is 127 (0x7F,
#   7 bits); max value of CounterPreset is 126 (0x7E = 7'b1111110). Bit 7
#   can never be set for ANY legal Divider value (0-255). No stimulus,
#   however exhaustive, can toggle this bit.
coverage exclude -du eth_clockgen -togglenode CounterPreset[7]

# -----------------------------------------------------------------------------
# Exclusion 2-6: eth_miim.v expression coverage, BitCounter-abort terms
# -----------------------------------------------------------------------------
# Reason: Time-boxed exclusion, BLOCKED BY OPEN BUG (MIIM-001) -- NOT a
# structural/design unreachability claim. Revisit once MIIM-001 is fixed.
# Justification: These 5 terms need InProgress==0 while BitCounter holds a
# specific value (40/48/55/56/63), which only occurs if an in-flight
# operation is aborted (command bit cleared) mid-shift. MIIM-001 causes
# exactly this abort to permanently strand Busy/InProgress instead of
# cleanly dropping InProgress to 0 -- confirmed via tc_miim_bitcounter_abort_sweep,
# 6/6 abort attempts left BUSY stuck. Coverage closure for these terms is
# therefore blocked on the RTL fix, not on additional stimulus. Excluded
# for this GP submission; tracked as future work alongside MIIM-001.
coverage exclude -du eth_miim -line 420
coverage exclude -du eth_miim -line 421
coverage exclude -du eth_miim -line 422
coverage exclude -du eth_miim -line 426
coverage exclude -du eth_miim -line 427

# -----------------------------------------------------------------------------
# NOT excluded (deliberately) -- see RTL_notes_and_bugs.md
# -----------------------------------------------------------------------------
# Prsd[15] toggle coverage and LinkFail toggle coverage (1->0 direction) are
# LEFT OPEN/FAILING in this report. Both are reproducible, non-TB-timing
# anomalies with a credible but unconfirmed lead (UpdateMIIRX_DATAReg pulse
# width in eth_miim.v). Excluding them would hide a real open finding.

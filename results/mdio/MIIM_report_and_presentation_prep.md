# MIIM/MDIO Verification — Final Status, RTL Findings, and Presentation Prep

## Part 1 — RTL Bugs & Notes Table (for the report)

| ID | Type | Title | Module/Signal | Status | Severity | Confidence |
|---|---|---|---|---|---|---|
| **MIIM-001** | Bug | In-flight MIIM operation abort permanently deadlocks Busy | `eth_miim.v` — `Nvalid`, `InProgress`, `Busy` | **Confirmed** | High | High — root cause traced and proven for the SCANSTAT case; confirmed to also occur on WRITE/READ (broader scope) but exact mechanism for those not yet traced |
| **CLKGEN-NOTE-001** | Note (exclusion) | `CounterPreset[7]` structurally unreachable | `eth_clockgen.v` — `CounterPreset` | **Confirmed, excluded** | N/A (not a bug) | Certain — proven by construction (bit-width math), not empirical |
| **RTL-NOTE-002** | Open finding | `Prsd[15]` / `LinkFail` read back incorrect via WB register interface | `eth_registers.v` — `MIIRX_DATA`, `MIISTATUS`; possibly `eth_miim.v` — `UpdateMIIRX_DATAReg` | **Open / unresolved** | Medium (data-integrity, not a hang) | Medium — TB ruled out as cause (2 independent fix attempts, zero change); one credible RTL lead identified but not proven |
| **EXPR-COV-NOTE-003** | Note (exclusion) | 5 `eth_miim.v` expression terms unreachable while MIIM-001 is open | `eth_miim.v` lines 420/421/422/426/427 | **Blocked, excluded (time-boxed)** | N/A (coverage bookkeeping) | High — directly follows from MIIM-001 |

---

### MIIM-001 — Full detail

**What it is:** Interrupting (aborting) an in-flight MIIM operation — by clearing its command bit (`SCANSTAT`, `WCTRLDATA`, or `RSTAT`) in `MIICOMMAND` before the operation completes on its own — can permanently strand `MIISTATUS.BUSY` at 1. Once stuck, no further register write recovers it; only a core reset clears it.

**How it was found:** `tc_miim_scan_intr` / `tc_miim_walking` both hit `UVM_FATAL [MIIM_TIMEOUT]` after stopping an active `SCANSTAT` scan. Traced and reproduced independently via three purpose-built tests:
- `tc_miim_scan_intr_sweep` — swept the SCANSTAT stop-delay from 0ns to 40,000ns (well past one full 32,000ns frame); **10/10 delays got stuck**.
- `tc_miim_clear_cmd_while_busy` — cleared `WCTRLDATA` mid-write; **stuck**.
- `tc_miim_bitcounter_abort_sweep` — aborted WRITE at `BitCounter` 40/48/56 and READ at 40/55/63; **6/6 stuck**.

**Root cause (confirmed for the SCANSTAT case):** `Nvalid` sets whenever `ScanStat_q2 & ~SyncStatMdcEn` is true — a window that opens on every scan start/restart, before the MDC-domain synchronizer catches up. `Nvalid`'s **only** clear path in the RTL is `~InProgress_q2 & InProgress_q3` — a transition that requires a full `InProgress` pipeline cycle to complete. If `SCANSTAT` is deasserted before that happens, `Nvalid` is left set with no remaining path to 0. Since `Busy = ... | InProgress | InProgress_q3 | Nvalid`, `Busy` is then stuck permanently.

**Root cause (WRITE/READ case):** confirmed to occur empirically, mechanism not yet traced with the same rigor as the SCANSTAT case (would need the same signal-by-signal trace applied to `WriteDataOp`/`ReadStatusOp`'s generation logic). Flagged as future work.

**Why it's a real, reportable bug and not a TB artifact:** the trigger stimulus is legal, ordinary register writes — nothing out of spec. The TB is otherwise clean (0 `UVM_ERROR` across the full 21-test suite as of the last full run).

**Recommended fix direction (not implemented — outside TB scope):** give `Nvalid` an unconditional clear path independent of a completed `InProgress` cycle — e.g., clear it directly when `SCANSTAT`/`WCTRLDATA`/`RSTAT` are all deasserted and `Busy` is otherwise idle, rather than relying solely on the pipeline transition.

---

### CLKGEN-NOTE-001 — Full detail

`CounterPreset[7]` can never be set for any legal `Divider` value. `eth_clockgen.v` line 90: `CounterPreset = (TempDivider>>1) - 1`, where `TempDivider` is clamped to a max of `8'hFF` (255). Max value of `TempDivider>>1` is 127 (7 bits); max value of `CounterPreset` is 126. This is a dead bit by design, not a coverage hole — proven mathematically, not empirically. Excluded from toggle coverage with this justification (see `coverage_exclusions.tcl`).

---

### RTL-NOTE-002 — Full detail

**Symptom:** Writing `0x8000` (Reset bit) to reg0 and reading it back returns `MIIRX_DATA=0x4000` — exactly the written value shifted right by one bit. Separately, `LinkFail` (`MISTATUS` bit 0) reads as `1` permanently across an entire directed test that explicitly toggles link status up/down/up/down via the PHY model — including the very first read, before link status is ever touched.

**What's been ruled out:**
- `mdio_driver_base.sv` timing — two independent, differently-targeted defensive fixes (read-drive-side, then write-sample-side) produced **zero change** in the captured value across three separate runs. A genuine delta-cycle race would show some variance; this didn't. Not a TB timing issue.
- `eth_shiftreg.v` — traced the exact bit history by hand through the last 8 shift cycles; `LinkFail <= ~ShiftReg[1]` correctly taps bit[2] of the incoming byte, matching the file's own documented historical fix (CVS log, rev 1.4/1.5: *"LinkFail signal was not latching appropriate bit"*). This file is correct.

**Current lead (not confirmed):** `eth_registers.v`'s `MIIRX_DATA` register is not wired directly to `Prsd` — it's a separate register that only latches `Prsd` when `UpdateMIIRX_DATAReg` (from `eth_miim.v`) pulses. That signal is generated in the **host-clock domain without `MdcEn` gating**, off `~InProgress_q2 & InProgress_q3`, both of which only change on `MdcEn` edges (~500ns apart at `clkdiv=100`). By inspection, this looks like it could stay asserted for far longer than the single host-clock cycle a register write-enable normally should — which could cause `MIIRX_DATA` to latch at the wrong moment. Not proven; needs a waveform or `eth_register.v` (the register primitive) to confirm.

**Status:** Open. Recommended as future work — plan below.

---

## Part 2 — Current State Summary (say this plainly on the day)

- **21 directed tests**, 0 `UVM_ERROR` across the entire suite except the tests specifically designed to characterize MIIM-001 (which report errors *because* they're proving the bug exists).
- **1 confirmed, root-caused RTL bug** (MIIM-001) reachable via ordinary register writes.
- **1 confirmed structural coverage exclusion** (CounterPreset[7]).
- **1 open, unresolved RTL anomaly** (Prsd[15]/LinkFail) — real, reproducible, TB ruled out, root cause not yet confirmed.
- **Code coverage:** expression coverage on `eth_miim` will read ~87.8% (36/41) once the continuous-scan test's results merge, with the remaining 5 terms formally excluded as blocked-by-MIIM-001. Toggle coverage: `CounterPreset[7]` excluded (proven unreachable); `Prsd[15]` and `LinkFail`'s 1→0 transition remain open/failing on purpose.

## Part 3 — Future Work (for your conclusion slide)

1. Fix MIIM-001 in RTL (give `Nvalid` — and likely an analogous signal on the WRITE/READ path — an unconditional clear path), then re-run `tc_miim_scan_intr_sweep`, `tc_miim_clear_cmd_while_busy`, and `tc_miim_bitcounter_abort_sweep` to confirm and close the 5 excluded expression terms.
2. Get `eth_register.v` (the primitive) and/or a waveform to close out RTL-NOTE-002.
3. Explain the still-unresolved discrepancy where `tc_miim_scan` (same stop-pattern, 1000ns delay) passes while the sweep consistently fails at the same delay — worth a dedicated investigation once MIIM-001 is fixed, since it may simply resolve itself.
4. Optional: a constrained-random layer on top of the current directed suite for broader confidence beyond the specific scenarios tested.

---

## Part 4 — Slide-by-Slide Structure

### Slide 1: MIIM/MDIO Verification — Scope & Objective
**Bullets:**
- Group 2 scope: full UVM-based functional and code coverage verification of the OpenCores Ethernet MAC's MIIM/MDIO management interface (`eth_miim.v`, `eth_clockgen.v`, `eth_shiftreg.v`)
- Goal: 100% functional coverage, maximize code coverage, separate TB defects from genuine RTL bugs
- Testbench: SystemVerilog/UVM 1.1d, QuestaSim 2021.2

**What to say:** Frame this as the "why" — you're not just running tests, you're building confidence that the block behaves correctly under both normal and adversarial conditions, and distinguishing your own bugs from the DUT's.

**Likely question:** *"Why MIIM specifically, and what's out of scope?"*
**Answer:** MIIM is the PHY management interface — register-based read/write/scan access to an external PHY over a 2-wire serial bus (MDC/MDIO), independent of the actual Ethernet frame TX/RX datapath (Groups 1/3/8 own that). It's self-contained enough to verify in isolation but has real protocol timing and clock-domain-crossing complexity, which is exactly where the bug we found lives.

---

### Slide 2: Testbench Architecture
**Bullets:**
- 5 UVM agents across the full DUT; MIIM-relevant: MDIO agent (driver/monitor/sequencer modeling the PHY side) + Wishbone Slave agent (modeling the host register-access side)
- RAL (register abstraction layer) model (`eth_reg_block`) mirrors all MIIM registers (`MIICOMMAND`, `MIIADDRESS`, `MIITX_DATA`, `MIIRX_DATA`, `MIISTATUS`, `MIIMODER`)
- Scoreboard (`eth_mdio_scoreboard`) independently predicts and checks every field of every MDIO frame (preamble, ST, OP, PHY addr, REG addr, turn-around, data) — not just pass/fail on the transaction as a whole
- PHY responder model drives realistic PHY behavior including self-clearing status bits and dynamic link-status changes

**What to say:** Emphasize the scoreboard checks *fields*, not just frames — this is why you were able to pin down bugs to a specific bit position instead of just "something's wrong."

**Likely question:** *"How do you know your scoreboard itself is correct?"*
**Answer:** Be honest: iteratively, the same way we found the DUT bugs — by cross-checking scoreboard predictions against known-good reference behavior (e.g., matching bit-ordering conventions between the monitor and predictor, verifying formulas like clock period against the actual RTL divider logic) and treating any unexplained mismatch as a hypothesis to prove, not assume. Several TB bugs (see Slide 5) were found exactly this way — the scoreboard was wrong before the RTL was confirmed right.

---

### Slide 3: Test Suite Overview
**Bullets:**
- 21 directed test cases covering: basic R/W/scan operations, priority arbitration (simultaneous command bits), PHY address decode, CLKDIV boundary values, read-only register protection, reset-mid-transaction, back-to-back zero-idle-gap operations, and — after bug discovery — targeted characterization tests for the lockup bug
- 0 `UVM_ERROR` across the suite except the tests specifically built to characterize MIIM-001

**What to say:** Walk through 3-4 categories briefly, don't read all 21 names. Group them: "protocol correctness," "corner-case timing," "register/priority edge cases," "bug characterization."

**Likely question:** *"Why 21 tests — how did you decide you'd covered enough?"*
**Answer:** Coverage-driven, not a fixed number — started from a test plan derived from the register map and protocol spec, then added tests specifically to close functional/code coverage gaps as they were identified (e.g., `tc_miim_linkfail_toggle` was added specifically because `LinkFail`'s 1→0 toggle bin was uncovered). The suite grew in response to coverage data, not a target count.

---

### Slide 4: Functional & Code Coverage Results
**Bullets:**
- Functional coverage: 100%
- Code coverage (`eth_miim`): statement/branch/condition high; expression coverage 32/41 → 36/41 after latest test additions, remaining 5 formally excluded (blocked by MIIM-001, not unreachable)
- Toggle coverage: one clean structural exclusion (`CounterPreset[7]`); two signals (`Prsd[15]`, `LinkFail`) deliberately left open/failing, not excluded

**What to say:** This is where you show the exclusion table. Be upfront that not every gap is closed and explain *why*, in the terms from Part 1 above — this reads as rigor, not as a shortcut, if you present it that way.

**Likely question:** *"Why not just exclude Prsd[15] and LinkFail too, if you're already excluding other things?"*
**Answer:** Because those two aren't proven unreachable or blocked by a known bug — they're an unresolved anomaly that TB-side investigation has ruled out as our own defect. Excluding it would hide a real, still-open finding instead of reporting it. The `CounterPreset[7]` exclusion is backed by a bit-width proof; the BitCounter-abort exclusion is backed by a confirmed causal bug. Prsd[15]/LinkFail have neither — so they stay open.

---

### Slide 5: TB Bugs Found & Fixed (brief, sets up credibility for Slide 6)
**Bullets:**
- Scoreboard opcode bit-order mismatch between comp_read()/comp_write() (root cause of most early cascading mismatches)
- MDIO driver missing a full turn-around cycle on reads (root cause of Turnaround/Data/LinkFail field mismatches)
- Scoreboard clock-period formula off by 2× vs. the actual `eth_clockgen.v` divider logic
- PHY responder model's self-clearing bits cleared instantaneously instead of after being read once (blocked Prsd[9]/Prsd[15] toggle coverage until fixed)

**What to say:** Keep this fast — the point is "we didn't just find one DUT bug and stop; we spent real effort making sure the environment itself was trustworthy first." This is what makes MIIM-001 credible.

**Likely question:** *"How do you know there aren't more TB bugs hiding right now?"*
**Answer:** Be honest — you don't know with certainty; that's true of any verification effort. What gives confidence: every fix was root-caused against the actual RTL behavior (not just "made the error go away"), the scoreboard checks individual protocol fields rather than aggregate pass/fail, and the remaining open item (RTL-NOTE-002) was specifically *not* assumed to be a TB bug just because two plausible TB-side fixes didn't work — that's the same discipline applied consistently.

---

### Slide 6: RTL Bug Found — MIIM-001
**Bullets:**
- Interrupting an in-flight MIIM operation (SCANSTAT, and confirmed also WRITE/READ) can permanently deadlock `Busy`
- Root cause (SCANSTAT case): `Nvalid` sets on every scan start but its only clear path requires a full completed `InProgress` cycle — if the scan is stopped before that, `Nvalid` never clears
- Reproduced independently in 3 separate purpose-built tests; 10/10, 1/1, and 6/6 failure rates respectively
- Confirmed via legal, in-spec register writes — not a corner case outside the protocol

**What to say:** This is your headline finding — spend real time here. Show the signal trace (Nvalid set condition → its only clear condition → why that clear condition can't be reached). If you can, put the actual RTL snippet on the slide (the `Nvalid`/`Busy` always-block).

**Likely question 1:** *"Is this exploitable/reachable by real host software, or only by an aggressive testbench?"*
**Answer:** Reachable by ordinary software — stopping a continuous scan early (e.g., a driver deciding it no longer needs periodic link-status polling) is completely normal usage, not an edge case. That's exactly why it's high severity.

**Likely question 2:** *"Did you try to fix it?"*
**Answer:** No — fixing DUT RTL was out of scope for the verification task; the deliverable is finding, root-causing, and characterizing it precisely enough that whoever owns the RTL can fix it with confidence. We do have a recommended fix direction (an unconditional clear path for `Nvalid`) documented for that purpose.

**Likely question 3:** *"How severe, really — can you recover from it?"*
**Answer:** Only via a full core reset; there's no register write that recovers `Busy` once stuck. That's what makes it high severity rather than a minor timing quirk.

---

### Slide 7: Open Item — Prsd[15]/LinkFail Read-Back Anomaly
**Bullets:**
- `MIIRX_DATA` reads back a right-shifted value after writing a specific bit pattern; `LinkFail` reads as stuck-at-1
- Ruled out as a TB timing issue: two independent driver-side fixes produced zero change across three runs
- Ruled out `eth_shiftreg.v` via manual signal trace — logic is correct and matches a documented historical fix
- Current lead: `MIIRX_DATA`'s write-enable (`UpdateMIIRX_DATAReg`, in `eth_miim.v`) is generated without MDC-domain gating and may be asserted for longer than one cycle — not yet confirmed
- Left open in coverage reporting rather than excluded

**What to say:** This slide is your "we know the limits of what we found" slide — professors respect knowing what you don't know as much as what you do. Present it as "here's exactly how far we got and exactly what's needed to finish it."

**Likely question:** *"Why didn't you just get a waveform and settle it?"*
**Answer:** Time-boxed against the presentation deadline — this was flagged as the clear next step and documented as future work rather than rushed. A waveform of `Prsd`/`LinkFail`/`MIIRX_DATA` around a single read is the fastest way to close it, and it's the first item in the future-work plan.

---

### Slide 8: Conclusion & Future Work
**Bullets:**
- MIIM/MDIO: 100% functional coverage, high code coverage with every remaining gap formally justified (not silently ignored)
- 1 confirmed, root-caused RTL bug with real-world reachability and no software recovery path
- 1 open anomaly, fully characterized and scoped, with a concrete next step
- Future work: fix MIIM-001 in RTL and re-close the 5 blocked coverage terms; resolve RTL-NOTE-002 with a waveform/register-primitive review; optional constrained-random layer

**What to say:** Close by reiterating the discipline point — every exclusion and every open item has a documented, defensible reason, not a "ran out of time" wave-off (even though some genuinely are time-boxed — frame it as "explicitly time-boxed and documented," which is true and is the professional standard, not a weakness).

**Likely question:** *"If you had one more week, what's the single highest-value thing to do?"*
**Answer:** Get a waveform to close RTL-NOTE-002 — it's the fastest remaining unknown to resolve and would tell us within one debug session whether it's a second RTL bug or a subtle top-level connectivity issue.

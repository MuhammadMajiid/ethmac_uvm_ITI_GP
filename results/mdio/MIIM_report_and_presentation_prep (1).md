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

## Part 4 — Slide-by-Slide Structure (detailed)

## Slide 1 — MIIM/MDIO Verification: Scope & Objective

**Bullets:**
- Group 2 scope: UVM-based functional and code coverage verification of the OpenCores Ethernet MAC's MIIM/MDIO management interface
- DUT files under test: `eth_miim.v`, `eth_clockgen.v`, `eth_shiftreg.v`
- Objective: reach 100% functional coverage, maximize code coverage, and rigorously separate testbench defects from genuine RTL bugs before reporting either
- Environment: SystemVerilog/UVM 1.1d, QuestaSim 2021.2, Linux

**What to say:** Open by framing *why* this matters, not just what you did. MIIM is the register-based interface a host uses to read/write/scan an external PHY's registers over a 2-wire serial bus (MDC/MDIO) — it's how the MAC discovers link status, configures autonegotiation, etc. It's a small block but has real protocol timing and a clock-domain crossing (host clock ↔ MDC, generated by an internal programmable divider), which is exactly where the bug you'll present later lives. Mention the "separate TB defects from RTL bugs" objective explicitly — it's the thread that ties your whole presentation together and explains why so much of your work was TB debugging before RTL bug-hunting could even start.

**Predicted questions:**

*Q: "Why MIIM specifically — what's out of scope for your part?"*
A: MIIM is the PHY management/register-access interface, independent of the actual Ethernet frame TX/RX datapath. Groups 3/1/8 (frame transmission, register/BD access, interrupts) own the rest of the core. MIIM is self-contained enough to verify in isolation via its own protocol (a 32-bit preamble, start bits, opcode, PHY/register address, turnaround, and 16 data bits), which is what let us build a focused, deep test suite around it.

*Q: "What does '100% functional coverage' actually mean here — coverage of what?"*
A: A functional coverage model (covergroups) tracking that every operation type (write/read/scan), every priority-arbitration combination, every PHY/register address class, and key data-value corner cases were exercised and observed correctly by the scoreboard — not just "code was executed," but "the intended behaviors were seen and checked."

---

## Slide 2 — Testbench Architecture

**Bullets:**
- 5 UVM agents across the full DUT environment; the two directly relevant to MIIM: the MDIO agent (models the PHY side of the MDC/MDIO bus) and the Wishbone Slave agent (models the host issuing register reads/writes)
- RAL (Register Abstraction Layer) model mirrors every MIIM register: `MIICOMMAND`, `MIIADDRESS`, `MIITX_DATA`, `MIIRX_DATA`, `MIISTATUS`, `MIIMODER`
- Scoreboard independently predicts and checks *every field* of every MDIO frame — preamble, start bits, opcode, PHY address, register address, turnaround, data — not just a pass/fail on the transaction as a whole
- PHY responder sequence models realistic PHY behavior: self-clearing status bits (Reset, Restart AutoNeg), and dynamically settable link status for testing link-up/link-down transitions

**What to say:** The key point to land here is the scoreboard's field-level granularity — this is *why* you were able to pin bugs down to a specific bit position (e.g., "the opcode field specifically is backwards" or "the very first data bit after turnaround is wrong") instead of just seeing generic transaction failures. If you have an environment block diagram, this is the slide to show it on.

**Predicted questions:**

*Q: "How do you know your scoreboard itself is correct — what verifies the verifier?"*
A: Honestly — iteratively, the same way DUT bugs get found: any unexplained mismatch is treated as a hypothesis to prove, not assumed to be either side's fault. We cross-checked scoreboard conventions (like bit ordering) against the monitor's own sampling convention, and checked formulas (like the expected MDC clock period) directly against the RTL's actual divider arithmetic rather than trusting an assumed formula. Several TB bugs were found exactly this way — where the scoreboard was initially wrong, not the RTL.

*Q: "What's the PHY responder, and why does it matter that it 'self-clears' bits?"*
A: Real PHY hardware has status bits that clear themselves after being acted on (e.g., a Reset bit clears itself once the reset completes) or after being read once. Modeling that accurately in the TB — rather than either always-0 or always-held — was itself a source of a coverage gap we had to fix, because an earlier version of the model cleared those bits *instantly* on write, meaning a status read could never actually observe them as 1.

---

## Slide 3 — Test Suite Overview

**Bullets:**
- 21 directed test cases, grown incrementally in response to functional and code coverage data — not a fixed target count
- Protocol correctness: basic write/read/scan, preamble suppression, clock-divider configuration
- Register/priority edge cases: simultaneous command bits (write+read+scan arbitration), read-only register write protection, full PHY address sweep
- Timing/corner-case: CLKDIV boundary values, reset mid-transaction, back-to-back zero-idle-gap operations, live register overwrite while busy
- Bug-characterization tests: built specifically after discovering MIIM-001, to determine its trigger conditions and scope

**What to say:** Group these into the 4-5 categories above rather than listing all 21 names — professors will tune out a name-by-name recitation. Explain that the last category (bug characterization) is unusual: those tests weren't part of the original plan, they were built reactively once a real bug was suspected, specifically to nail down *when* it triggers.

**Predicted questions:**

*Q: "How did you decide you'd written 'enough' tests?"*
A: Coverage-driven. We started from a test plan derived from the register map and the IEEE 802.3 MDIO protocol spec, then added tests specifically to close gaps as functional and code coverage data revealed them — for example, a dedicated `LinkFail`-toggle test was added specifically because the 1→0 transition bin was uncovered by the existing suite. The suite grew in response to data, not a predetermined number.

*Q: "Give a concrete example of a corner case you specifically went looking for."*
A: Simultaneous command bits — what happens if a host writes `WCTRLDATA`, `RSTAT`, and `SCANSTAT` all in the same register write? The protocol doesn't obviously define which wins. We built a dedicated priority test for every pairwise and triple combination to confirm the RTL picks one consistently and doesn't corrupt state.

---

## Slide 4 — Functional & Code Coverage Results

**Bullets:**
- Functional coverage: **100%**
- Code coverage on `eth_miim`: statement/branch/condition coverage high; expression (FEC) coverage 32/41 initially, expected to reach 36/41 after the newest tests merge
- Toggle coverage: one clean, mathematically-provable structural exclusion (`CounterPreset[7]` in `eth_clockgen.v`); two signals (`Prsd[15]`, `LinkFail`) deliberately left **open and failing**, not excluded
- Every coverage gap in this report has a documented reason — either closed, formally excluded with justification, or explicitly carried forward as an open finding

**What to say:** This is the slide where you show the exclusion table. Be upfront and matter-of-fact that not every gap is closed, and immediately explain why in the terms below — this reads as verification rigor, not as cutting corners, *if* you present it with the reasoning attached rather than just showing a percentage.

**Predicted questions:**

*Q: "Why exclude some things but leave Prsd[15]/LinkFail open instead of also excluding them?"*
A: Because those two aren't proven unreachable and aren't blocked by a bug we've already root-caused — they're an unresolved anomaly where we've specifically ruled out our own testbench as the cause but haven't yet confirmed the RTL mechanism. Excluding it would hide a real, still-open finding instead of reporting it honestly. Compare: the `CounterPreset[7]` exclusion is backed by a bit-width math proof; the 5 excluded expression terms are backed by a bug we already root-caused and reproduced 10/10 and 6/6 times. Prsd[15]/LinkFail has neither of those yet, so it stays open rather than swept away.

*Q: "What's 'expression coverage' as opposed to statement coverage — why does it matter?"*
A: Statement coverage just asks "was this line executed." Expression (focused expression) coverage asks, for a multi-term boolean expression, "was *each individual input term* independently responsible for the result at least once" — it catches cases where a line executes constantly but one specific input combination that matters (e.g., a rare timing-adjacency window) never actually occurs. It's a stricter bar, and it's exactly what surfaced the coverage gaps tied to MIIM-001.

---

## Slide 5 — TB Bugs Found & Fixed

**Bullets:**
- Scoreboard opcode bit-order mismatch between the write-checking and read-checking functions — root cause of most early cascading field mismatches
- MDIO driver missing a full turnaround cycle on reads — root cause of turnaround/data/link-status field mismatches
- Scoreboard's expected clock-period formula was off by 2× versus the actual RTL divider arithmetic
- PHY responder model cleared self-clearing status bits *instantly* on write instead of after being read once — was silently blocking two toggle-coverage bins until fixed

**What to say:** Move fast through this slide — the point isn't the individual bugs, it's establishing "we didn't just find one DUT bug and declare victory; we spent real, methodical effort making the environment itself trustworthy first." This is what gives Slide 6 (the real RTL bug) credibility instead of looking like a fluke.

**Predicted questions:**

*Q: "How do you know there aren't more TB bugs still hiding right now?"*
A: We don't know with certainty — that's true of any verification effort, TB or DUT. What gives confidence: every fix here was root-caused against actual RTL behavior, not just "the error went away." The scoreboard checks individual protocol fields rather than aggregate pass/fail, which makes silent TB bugs less likely to hide. And critically, the same discipline was applied to the still-open item on Slide 7 — we specifically did *not* assume it was a TB bug just because two plausible TB-side fixes didn't resolve it; we kept investigating rather than declaring it "probably fine."

*Q: "Which of these TB bugs took the longest to find, and why?"*
A: The missing turnaround cycle in the driver — because its symptom (a one-bit-shifted data value) looked identical to a subtler bug we found later in a completely different place, and it took carefully tracing the *exact* RTL bit-counter timing, not just re-checking the testbench, to separate the two.

---

## Slide 6 — RTL Bug Found: MIIM-001 (headline finding — spend real time here)

**Bullets:**
- Interrupting an in-flight MIIM operation — confirmed for SCANSTAT, and also confirmed (though not yet fully root-caused) for WRITE/READ — can permanently deadlock `MISTATUS.BUSY`
- Root cause (SCANSTAT case, fully traced): `Nvalid` sets on every scan start/restart; its *only* clear path requires a complete `InProgress` pipeline cycle. If the scan is stopped before that cycle finishes, `Nvalid` never clears
- Since `Busy = ... | InProgress | InProgress_q3 | Nvalid`, a stuck `Nvalid` permanently strands `Busy`
- Reproduced independently across 3 purpose-built tests: 10/10 (scan interruption at varying delays), 1/1 (write command clear mid-flight), 6/6 (precisely-timed write/read abort)
- Triggered by ordinary, in-spec register writes — not an artificial or out-of-protocol stimulus
- No software recovery path once stuck — only a full core reset clears it

**What to say:** This is your centerpiece. If you can fit it, put the actual signal relationship on the slide:
```
Nvalid <= 1  when (ScanStat_q2 & ~SyncStatMdcEn)
Nvalid clears only on: (~InProgress_q2 & InProgress_q3)
Busy  = ... | InProgress | InProgress_q3 | Nvalid
```
Walk through it as a story: scan starts → `Nvalid` sets transiently (by design, this is normal) → it's *supposed* to clear once the scan cycle fully completes → if you stop the scan before that happens, the clear condition can never occur → `Nvalid` is stuck → `Busy` is stuck forever.

**Predicted questions:**

*Q: "Is this reachable by real host software, or only by an aggressive testbench?"*
A: Completely ordinary usage — a driver deciding to stop periodic link-status polling early, for any reason, is normal software behavior, not an edge case. That's exactly what makes this high severity: it doesn't require adversarial or malformed input, just a timing coincidence that's entirely plausible in real operation.

*Q: "Did you attempt to fix it in the RTL?"*
A: No — fixing DUT RTL is outside the verification task's scope; our deliverable is finding, root-causing, and characterizing the bug precisely enough for whoever owns the RTL to fix it confidently. We do have a recommended fix direction documented: give `Nvalid` (and likely the analogous mechanism on the write/read path) an unconditional clear path — for example, clearing it directly whenever all three command bits are deasserted and no operation is genuinely in flight — rather than relying solely on a completed pipeline transition.

*Q: "How severe is this really — can the system recover on its own?"*
A: No. There's no register write that clears `Busy` once it's stuck this way — only a full core reset recovers it. That's the basis for calling it high severity rather than a minor timing quirk: once triggered, the entire MIIM interface is unusable until reset.

*Q: "You said WRITE/READ interruption also gets stuck, but the root cause isn't traced yet — why not?"*
A: Time. The SCANSTAT mechanism required signal-by-signal tracing through `Nvalid`'s exact set/clear conditions, which took real effort to get right and to verify by hand against the RTL rather than guessing. Confirming the WRITE/READ case empirically (6/6 failures) was enough to establish it's real and worth reporting; doing the equivalent signal trace for `WriteDataOp`/`ReadStatusOp`'s generation logic is explicitly the next step, listed as future work rather than rushed for this deadline.

---

## Slide 7 — Open Item: Prsd[15] / LinkFail Read-Back Anomaly

**Bullets:**
- Writing a specific bit pattern (Reset bit, `0x8000`) and reading it back returns a value shifted right by one bit; separately, `LinkFail` reads as stuck-at-1 permanently across a directed test that explicitly toggles link status up/down/up/down
- Ruled out testbench timing: two independent, differently-targeted driver-side fixes produced **zero change** in the observed value across three separate simulation runs — a genuine timing race would show variation, this didn't
- Ruled out `eth_shiftreg.v`: manually traced the exact bit history through the last 8 shift cycles; the logic is correct and matches the module's own documented historical bugfix
- Current lead, not yet confirmed: `MIIRX_DATA`'s write-enable signal is generated in the host-clock domain without gating by the MDC-domain enable, and by inspection may stay asserted longer than the single cycle a register write-enable normally should
- Deliberately left open/failing in coverage reporting rather than excluded

**What to say:** Present this as "here's exactly how far we got and exactly what's needed to finish it" — not as a failure to close it out. The fact that you *ruled things out* systematically (not just tried things randomly) is the actual content of this slide.

**Predicted questions:**

*Q: "Why didn't you just pull a waveform and settle this?"*
A: Time-boxed against the presentation deadline. It's flagged as the clear, fastest next step rather than something we're unsure how to do — a waveform of the read-data signal alongside the register's actual output around a single read operation would very likely settle this within one debug session. We chose to document it precisely and move on rather than risk running out of time on the rest of the deliverable.

*Q: "Could this be the same root cause as MIIM-001?"*
A: We considered that and don't think so — MIIM-001 is about `Busy` never clearing (a control-path/state-machine issue), while this is about a data value being wrong even when the operation completes normally and `Busy` clears as expected. They look like separate issues, but we can't rule out a shared underlying cause with full confidence without further investigation.

*Q: "Is this a hardware bug or a testbench bug, in your best guess?"*
A: More likely RTL at this point, based on process of elimination rather than direct proof — two independent testbench-side hypotheses were tested and both produced identical, unchanged results, which is inconsistent with a testbench timing explanation. But we're explicitly not calling it a confirmed RTL bug in the report, because we haven't proven the mechanism the way we did for MIIM-001.

---

## Slide 8 — Conclusion & Future Work

**Bullets:**
- MIIM/MDIO verification: 100% functional coverage; high code coverage with every remaining gap formally justified, not silently dropped
- 1 confirmed, fully root-caused RTL bug (MIIM-001) with real-world reachability and no software recovery path
- 1 clean structural coverage exclusion, proven by construction
- 1 open anomaly, fully characterized, systematically narrowed down, with a concrete documented next step
- Future work: fix MIIM-001 in RTL and re-close the 5 blocked coverage terms; get a waveform to resolve the Prsd[15]/LinkFail lead; trace the WRITE/READ mechanism of MIIM-001 with the same rigor as the SCANSTAT case; investigate why one existing passing test uses an identical stop-pattern without triggering the bug; optionally add a constrained-random layer on top of the current directed suite

**What to say:** Close by reiterating the discipline theme from Slide 5 — every exclusion and every open item in this report has a documented, specific reason, not a generic "ran out of time." Some genuinely *are* time-boxed, and that's fine to say plainly — professionally, "explicitly time-boxed with a documented next step" is the standard, not a weakness, as long as you can show you know exactly what the next step is.

**Predicted questions:**

*Q: "If you had one more week, what's the single highest-value thing to do?"*
A: Get a waveform to resolve Prsd[15]/LinkFail — it's the fastest remaining unknown, and would tell us within one debug session whether it's a second RTL bug, a top-level connectivity issue, or something we've still missed.

*Q: "What was the hardest part of this whole verification effort?"*
A: Distinguishing testbench bugs from RTL bugs when both produce similar-looking symptoms — several of the TB bugs on Slide 5 initially looked exactly like they could have been RTL issues, and the discipline of proving root cause before reporting anything, in either direction, was the actual hard part, more than writing any individual test.

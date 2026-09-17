# Coverage Gap Analysis — 2026-09 Teller Regression vs. Test-Case Catalog

Cross-check of the master test-case catalog (`ITG Full Regression Testing - September 2026` sheet) against the **September automated run** (`results/2026-09_full-regression/`).

> Note: the catalog sheet's recorded results are all from **April 2026** (dates 4/20–4/30, links to the old `pvillados-nmblr` site). It does **not** yet reflect the September run. September coverage below comes from the automated regression + pending manual execution.

## Summary

| Bucket | Count |
|--------|------:|
| Catalog test cases (CSV) | 319 |
| ✅ Covered by September automated run | 285 |
| 🟡 Needs manual September execution | 29 |
| 🟢 "Dropped" — actually covered/stale (numbering mismatch) | 5 → 0 real gaps |
| 🚧 Blocked — feature not yet deployed on ITG (t3.3) | 8 TCs |
| ➕ Extra Sept modules not in the catalog | 7 modules |

> There are **no automatable gaps** in the current build. The only module with no suite — **t3.3 Create New Bank Account** — is **not yet deployed on ITG** (verified 16 Sep 2026, see Section E), so it cannot be automated or executed yet. Everything else is covered by the September automated run, needs manual execution (Section A), or is a numbering/stale artifact (Section B).

## A. 🟡 Section-A cases — now executed (see `SECTION_A_RESULTS_2026-09.md`)

These were the "not in the automated run" cases. Status after the Section-A effort:

| Module | Test cases | Status |
|--------|-----------|--------|
| t1.1 Reset Password | t1.1.21 .22 .23 .25 | ✅ executed manually (PASS) — OTP-session 60-min block matrix |
| t1.1 Reset Password | t1.1.1 | ✅ executed manually 17 Sep (PASS) — via emailed "RESET PASSWORD NOW" link (email-link entry stays human-manual) |
| t1.1 Reset Password | t1.1.24 · t1.1.26 | ✅ PASS 17 Sep — **now codified as automated** (`wall-clock` tag) |
| t1.3 Forgot Password | t1.3.21 .22 .23 .25 | ✅ executed manually (PASS) |
| t1.3 Forgot Password | t1.3.24 · t1.3.26 | ✅ PASS 17 Sep — **now codified as automated** (`wall-clock` tag) |
| t1.4 Change Password | t1.4.17 .18 .19 .21 | ✅ executed manually (PASS) |
| t1.4 Change Password | t1.4.20 · t1.4.22 | ✅ PASS 17 Sep — **now codified as automated** (`wall-clock` tag) |
| t2.5 Avail Savings Product | t2.5.19 | ✅ **now automated** (session-timeout; `slow` tag) |
| t5.3 Create New Product | t5.3.36 | ✅ **now automated** (version→Deprecated; idempotent/reusable) |

The OTP-session 60-min block feature is proven identically across all three password flows.
The 6 wall-clock cases (`.24`/`.26` per flow) and t1.1.1's email-link entry are **all now
executed & PASS (17 Sep)**. The 6 wall-clock cases are **now codified as automated Robot
tests** (tag `wall-clock`) — they need no human, inbox, or live OTP, only real time (magic
OTPs + `Sleep`), so next cycle they run unattended:

```bash
./run_july_regression.sh --tag wall-clock      # or: robot --include wall-clock ...
```

They are kept out of the fast suite (long: ~62 min for `.24/.20`, ~33 min for `.26/.22`).
Only t1.1.1's **email-link entry step** remains genuinely human-manual (needs mailbox access);
the reset flow it exercises is otherwise identical to the automated t1.1.2.

> **t3.3 Create New Bank Account** is **blocked**, not manually runnable yet. See Section E.

## B. 🟢 "Dropped" — verified as covered/stale (numbering mismatch, NOT gaps)

On inspection these are **not** coverage gaps — the automated suites cover them under different numbering (the automation has extra sub-tests, and the app's account statuses changed). No restoration needed.

| Catalog TC | Reality |
|-----------|---------|
| t2.2.10 (Filter by Closed) | **Covered** — automated **t2.2.9** (Filter Account List by Status - Closed). *(The automated t2.2.10-13 are the status-change tests, hence the numbering divergence.)* |
| t2.2.12 (Filter by Blocked) | **Now covered** — added automated **t2.2.15** (Filter by Blocked), PASS (17 Sep 2026). |
| t3.1.12 (Filter by Blocked) | **Covered** — the automated suite has all 6 status filters as t3.1.6–11; Blocked = **t3.1.11** |
| t3.1.13 (Filter by Suspended) | **Stale** — the app has **no "Suspended" status** (statuses are Active, Dormant, Frozen, Blocked, Deceased, Closed) |
| t4.1.3 (View Specific Transaction Details) | **Covered** — same test exists as automated **t4.1.4** (suite renumbered after adding more type/status filters) |

## C. ➕ Covered by September automation but NOT in the catalog sheet

These modules were executed in September but have **no rows in the catalog CSV** — the sheet should be extended to track them.

| Module | Sept sub-tests |
|--------|--------------:|
| t2.6 Avail Loan Product | 20 |
| t7.1 Loan Listing | 13 |
| t7.2 Loan Approval & Rejection | 10 |
| t7.3 Loan Disbursements | 7 |
| t7.4 Loan Schedule | 5 |
| t7.5 Loan Repayment Processing | 15 |
| t7.6 Loan Payment History | 13 |

## D. ✅ Covered by the September automated run

The remaining **285** catalog test cases across modules t1.1–t1.4, t2.1–t2.5, t3.1–t3.2, t4.1–t4.3, t5.1–t5.3, t6.1 are present in the September automated suites. See the published report and `REGRESSION_SUMMARY_2026-09.md` for pass/fail. *(A few may be tagged skip / manual-verify within the suite — check the report for any SKIP status.)*

## E. 🚧 Blocked — feature not yet deployed on ITG

**t3.3 Create New Bank Account (t3.3.1–t3.3.8)** — the catalog's account-onboarding wizard (T&C → Personal Info → Address → Financial Info) is **not available in the current San Antonio ITG build**. Verified live on **16 Sep 2026**:

- **Teller role** (`jjavier+sa`, full t2–t7 module nav) — no "Create New Bank Account" button on the Accounts module.
- **Maker role** (`jjavier+jr1`, "James Reid") — narrow nav (Customers / Accounts / Change Requests only); no create-account entry point. Direct route `/accounts/create` redirects to the default page.
- The **User Management → "+ Create User"** flow (visible to Administrator/Super-Admin roles) is a **different feature** — it creates *system users* (Maker / Checker / Branch Manager), **not** a customer bank account, so it does not satisfy t3.3.

**Conclusion:** t3.3 cannot be automated or executed until the account-onboarding feature is deployed and surfaced to a teller role. Track it as blocked, not as a missing test. Re-scope and build the suite once the wizard is live.

## F. 🔎 Full catalog reconciliation (verified 17 Sep 2026)

Every catalog TC ID (`t*.*.*`) was cross-checked against the actual execution records
(the September automated `output.xml`s + this cycle's manual runs) to confirm nothing was
left untested. **320 catalog TCs → 305 executed (298 automated/earlier-manual + 7 executed
manually 17 Sep: the 6 wall-clock cases + t1.1.1); the remaining 15 all fall into a known,
accounted-for category — none were overlooked:**

| Disposition | Count | TCs |
|-------------|------:|-----|
| ✅ Same test under different numbering — executed | 3 | t2.2.10 (=auto t2.2.9 Filter Closed), t3.1.12 (=auto t3.1.11 Filter Blocked), t4.1.3 (=auto t4.1.4 View Txn Details) |
| ✅ Was a candidate gap — **now automated + PASS** | 1 | t2.2.12 Filter customer accounts by Blocked → new **t2.2.15** (PASS) |
| ⚪ Stale — not applicable | 1 | t3.1.13 Filter by "Suspended" (no such status) |
| 🚧 Blocked — feature not deployed | 8 | t3.3.1–t3.3.8 Create New Bank Account (Section E) |
| ✅ Wall-clock — **executed & PASS (17 Sep) + now codified as automated** (`wall-clock` tag) | 6 | t1.1.24/.26, t1.3.24/.26, t1.4.20/.22 (60-min-expiry / >15-min-window) |
| ✅ Manual via emailed link — **now executed & PASS (17 Sep)** | 1 | t1.1.1 (reset via "RESET PASSWORD NOW" email link; recording captured) |
| ✅ Resend-after-cooldown — **already executed + now fully automated** | 2 | t1.3.16 / t1.4.12: resend mechanics run in the default suite via combined **t1.3.15-16 / t1.4.11-12** (type1); the success tail is now automated as new **t1.3.16 / t1.4.12** (tag `resend-complete`, magic OTP, ~61s, no live email) |

**Conclusion:** no test case was accidentally left untested. The 6 wall-clock cases and
t1.1.1 (emailed-link entry) are executed & PASS (17 Sep), and t1.3.16 / t1.4.12 are now fully
automated (`resend-complete`). **The only items not runnable are the 8 deployment-blocked t3.3
cases** (feature not on ITG) and 1 stale non-applicable case (t3.1.13, no "Suspended" status);
t3.1.12 / t4.1.3 are covered under renumbered auto tests. The one true candidate gap (t2.2.12)
is closed by automated **t2.2.15**.

> **Re-verified 17 Sep 2026 (post wall-clock + resend-complete codification):** diffed all
> catalog IDs against the actual robot test IDs across `tests/**` (423 automated tests).
> **308 of 320 catalog IDs now have a same-numbered automated test**; the remaining 12 are
> exactly the accounted-for set above — t3.3.1–8 blocked, t1.1.1 manual-PASS, t3.1.13 stale,
> and t3.1.12 / t4.1.3 covered under renumbered auto tests t3.1.11 / t4.1.4. The 6 wall-clock
> cases and t1.3.16 / t1.4.12 now resolve to same-numbered automated tests (earlier they only
> looked "missing" because `t1.3.15-16` / `t1.4.11-12` are hyphenated combined-test names).
>
> **Catalog data note — FIXED 17 Sep 2026:** the sheet's duplicate `t5.1.13` (the second row,
> "Archive Product – Confirm Archive") was renumbered to **t5.1.14** in the working catalog
> CSVs to match automation (t5.1.13 = modal-appears, t5.1.14 = confirm-archive). Apply the same
> renumber to the master sheet when convenient.

## Recommended actions

1. **t3.3 Create New Bank Account — BLOCKED, no action possible yet.** The onboarding wizard is not deployed on ITG (Section E). Do **not** treat it as an open automation gap; revisit and automate once the feature ships. There are currently **no automatable coverage gaps**.

2. **Run the other manual TCs in September** (Section A) and record results — the OTP-session/blocking and session-timeout sets.

3. **Section B needs no action** — those "dropped" TCs are already covered under different numbers, excluded on purpose, or stale (no "Suspended" status). Consider realigning the catalog's numbering with the automated suite.

4. **Add catalog rows for t2.6 and t7.1–t7.6** (Section C) so the sheet reflects what September actually ran.

4. **Update the catalog's report links/dates** from the April `pvillados-nmblr` links to the September run: `https://qa-jo.github.io/teller-automation/reports/2026-09_full-regression/`

# Teller 2026-09 Full Regression — Results Summary

**Environment:** rural-bank-san-antonio (ITG)
**Run folder:** `results/2026-09_full-regression/`
**Published report:** https://talino-labs.github.io/teller-automation/reports/2026-09_full-regression/

## Overall
**352 passed / 10 failed / 17 skipped** (379 tests across 25 test-case files).
All modules executed **except 8_interest (t8.1)**, which is blocked (see below).

Of the 10 failures: **1** is a confirmed product defect, **4** are a product defect covered by a separate updated test set, and **5** are blocked by an environment limitation (account counter reset). None are open test-code bugs.

## Results by module

| Module | Test case | Pass | Fail | Skip | Notes |
|--------|-----------|-----:|-----:|-----:|-------|
| 1_auth | t1.1 Reset Password | 16 | 0 | 3 | ✅ |
| 1_auth | t1.2 Login | 15 | 5 | 0 | 5 lockout counter-detail tests blocked (see #1) |
| 1_auth | t1.3 Forgot Password | 16 | 0 | 3 | ✅ |
| 1_auth | t1.4 Change Password | 12 | 0 | 3 | ✅ |
| 2_customers | t2.1 View Customer List | 13 | 2 | 0 | status-change (separate set) |
| 2_customers | t2.2 View Customer Accounts | 10 | 2 | 0 | status-change (separate set) |
| 2_customers | t2.3 View Cust. Acct. Transactions | 16 | 0 | 1 | ✅ |
| 2_customers | t2.4 Availed & Eligible Products | 10 | 0 | 0 | ✅ |
| 2_customers | t2.5 Avail Savings Product | 19 | 0 | 0 | ✅ |
| 2_customers | t2.6 Avail Loan Product | 19 | 0 | 1 | ✅ |
| 3_accounts | t3.1 View Accounts | 11 | 0 | 0 | ✅ |
| 3_accounts | t3.2 View Account Transactions | 17 | 0 | 0 | ✅ |
| 3_accounts | t3.3 Create New Bank Account | — | — | — | **Not run — feature not deployed on ITG** (see below) |
| 4_transactions | t4.1 View All Transactions | 15 | 0 | 0 | ✅ |
| 4_transactions | t4.2 Withdrawal Transaction | 26 | 0 | 5 | ✅ |
| 4_transactions | t4.3 Deposit Transaction | 19 | 0 | 0 | ✅ |
| 5_products | t5.1 View Active Products | 14 | 0 | 0 | ✅ |
| 5_products | t5.2 View Archived Products | 4 | 0 | 0 | ✅ |
| 5_products | t5.3 Create New Product | 34 | 0 | 1 | ✅ |
| 6_reports | t6.1 Generate Reports | 4 | 0 | 0 | ✅ |
| 7_loans | t7.1 Loan Listing | 13 | 0 | 0 | ✅ |
| 7_loans | t7.2 Loan Approval & Rejection | 10 | 0 | 0 | ✅ |
| 7_loans | t7.3 Loan Disbursements | 7 | 0 | 0 | ✅ |
| 7_loans | t7.4 Loan Schedule | 5 | 0 | 0 | ✅ |
| 7_loans | t7.5 Loan Repayment Processing | 15 | 0 | 0 | ✅ |
| 7_loans | t7.6 Loan Payment History | 12 | 1 | 0 | loan double-count (see #1) — ✅ fix verified 30 Sep on a post-fix payment |
| 8_interest | t8.1 Interest Crediting | — | — | — | **Not run — blocked** (see #3) |

## Failure breakdown

### Confirmed product defect — filed
1. **Loan payment "Total Amount Paid" double-counts interest** — `t7.6.11`
   Total = Principal + 2×Interest (839.94 vs expected 837.85). → GitHub [project#1969](https://github.com/talino-labs/higala.project/issues/1969)
   **✅ Retested & verified fixed 30 Sep 2026 (forward).** A fresh post-fix payment (loan `7710345096460289`, 15% rate) reconciles: Principal 164,600.59 + Interest 6,250.00 = **Total 170,850.59** (would be 177,100.59 if still buggy); `t7.6.11` passes. *Note:* pre-fix records from the May–Sep 2026 window (loan interest off), incl. the originally-reported 10 Sep record on loan `7710396736994875`, still show Total = P + 2×Interest — historical artifacts, not backfilled (forward-only fix).
2. **Transaction detail returns errored/empty payload for older records** — `t2.3.4` / `t3.2.4`
   Older transactions show Type `ERR - N/A` / all-N/A in the detail modal though the list shows Success. → GitHub [project#1970](https://github.com/talino-labs/higala.project/issues/1970)
   **✅ Retested & verified fixed 30 Sep 2026.** All 3 originally-errored records in Peach Villados' account (`7710458152114857`) now render real values: `547fa043…` Fund Transfer 88.00 Success · `7482a6a9…` Fund Transfer 848.00 Success · `f62692b4…` Fund Transfer 8,484.00 Success — no more `ERR - N/A`. (Backfilled/endpoint fix — historical records corrected, unlike #1969.)

### Product defect — covered by a separate updated test set
- **Customer/account status change silently fails** — `t2.1.13/.14`, `t2.2.11/.13`
  Status change submits, dismisses, and persists nothing (no success toast). Being verified in a separate updated test case; excluded from this run's scope.

### Environment limitation — not a defect
- **t1.2 lockout counter-detail tests** — `t1.2.11/.12/.13/.16/.19`
  Each needs the account's failed-attempt counter reset to exactly 0; lifting the lock doesn't reset the counter reliably, so they fail on a precondition. The lockout feature itself is proven (t1.2.10 blocks-after-5, t1.2.14 per-account, t1.2.15 reset-lifts-block pass).

### Blocked module(s)
3. **t8.1 Interest Crediting — BLOCKED (by design), not a defect.** Confirmed with dev (jmangune-agsx, [project#1971](https://github.com/talino-labs/higala.project/issues/1971)): savings-interest crediting is **intentionally disabled on ITG under RFC-1722** (per-DFSP EOD rework) — prodmgmt commit `ea60dae` / PR #74 (merged 2026-08-14) no-ops `SavingsInterestService` and comments out the midnight scheduler (`0 0 0 * * *`); the last ITG credit on 17 Aug lines up with that merge. Cadence is **per-product config** (`interestConfiguration.interest.timePeriod`: daily→rate/365, monthly→rate/12), so the 01 Aug monthly-~2% batch and the 15–17 Aug daily credits are **both correct — not drift**. Crediting resumes with the per-DFSP EOD infra: talino-labs/higala-prodmgmt-api#92 (open; blocked on higala-microledger#190 + higala-jison#125). **Action taken:** the t8.1 suite is now **cadence-aware** (computes expected per each account's configured `timePeriod` instead of assuming daily). Structural tests (t8.1.6/.7) pass against existing records; computation tests re-validate once crediting resumes. Test-data prep (5% product + exact-balance accounts) can proceed now. → [project#1971](https://github.com/talino-labs/higala.project/issues/1971) (labeled `no qa testing` / blocked)
4. **t3.3 Create New Bank Account — not run (feature not deployed).** The account-onboarding wizard (T&C → Personal Info → Address → Financial Info) is not surfaced in the current ITG build. Verified 16 Sep 2026: no "Create New Bank Account" entry point for the Teller role (`jjavier+sa`) or the Maker role (`jjavier+jr1`); `/accounts/create` redirects away. The User Management → "Create User" flow is a different feature (creates system users, not customer accounts). No automated suite exists; revisit once the feature ships. Details in `COVERAGE_GAP_2026-09.md` §E.

## Test-defects fixed & verified this effort
- **t2.5.15, t2.6.9/.19/.21, t7.5.5** — stale test bugs (fixes committed but never re-run)
- **t4.1.5** — wrong seed data (credit bank name → "Rizal Commercial Banking Corporation")
- **t2.3.4 / t3.2.4** — repointed off an errored record to a healthy one
- **t1.1 reset flow** — `Complete Reset Password Form` re-entered the wrong temp password
- **t1.3.1** — verified login as the wrong account (TELLER instead of the reset CP account)
- **t1.4.11-12** — OTP resend button is disabled-not-hidden during cooldown
- **t7.2.10** — SoD "reject own" logged in as the approver instead of the maker

## Escalations & tracking
- Parent ticket: [project#1968 — Teller and Mobile Regression September 2026 bugs encountered](https://github.com/talino-labs/higala.project/issues/1968) (Higala Project / Iteration 16), with sub-issues #1969 (loan double-count), #1970 (errored txn payload), #1971 (t8.1 interest — blocked/RFC-1722).
- Full detail and evidence: `ESCALATIONS_2026-09.md`.

## Notes on environment constraints
- **Auth network rate limit** (~7-8 login/OTP requests → "Too many requests from this network") required manual resets between OTP/lockout batches; auth suites were run in isolated batches and merged into the report.
- Auth tests use dedicated accounts (`jjavier+sa` disposable; `jjavier+temp*` one-time temp-password accounts, which must be refreshed each run).

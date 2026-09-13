# Teller 2026-09 Full Regression — Results Summary

**Environment:** rural-bank-san-antonio (ITG)
**Run folder:** `results/2026-09_full-regression/`
**Published report:** https://qa-jo.github.io/teller-automation/reports/2026-09_full-regression/

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
| 7_loans | t7.6 Loan Payment History | 12 | 1 | 0 | loan double-count (see #2) |
| 8_interest | t8.1 Interest Crediting | — | — | — | **Not run — blocked** (see #3) |

## Failure breakdown

### Confirmed product defect — filed
1. **Loan payment "Total Amount Paid" double-counts interest** — `t7.6.11`
   Total = Principal + 2×Interest (839.94 vs expected 837.85). → GitHub [#35](https://github.com/QA-Jo/teller-automation/issues/35)
2. **Transaction detail returns errored/empty payload for older records** — `t2.3.4` / `t3.2.4`
   Older transactions show Type `ERR - N/A` / all-N/A in the detail modal though the list shows Success. → GitHub [#36](https://github.com/QA-Jo/teller-automation/issues/36)

### Product defect — covered by a separate updated test set
- **Customer/account status change silently fails** — `t2.1.13/.14`, `t2.2.11/.13`
  Status change submits, dismisses, and persists nothing (no success toast). Being verified in a separate updated test case; excluded from this run's scope.

### Environment limitation — not a defect
- **t1.2 lockout counter-detail tests** — `t1.2.11/.12/.13/.16/.19`
  Each needs the account's failed-attempt counter reset to exactly 0; lifting the lock doesn't reset the counter reliably, so they fail on a precondition. The lockout feature itself is proven (t1.2.10 blocks-after-5, t1.2.14 per-account, t1.2.15 reset-lifts-block pass).

### Blocked module
3. **t8.1 Interest Crediting — not run.** No interest credits observed since 17 Aug (~27 days; no September batch — crediting job appears stopped), and historical cadence is mixed (daily on one account 15–17 Aug; monthly-style batch 01 Aug). Needs confirmation of whether the scheduler is running and the intended cadence (daily vs monthly) before the computation tests can be finalized. Structural tests (t8.1.6/.7) pass against existing records. → GitHub [#38](https://github.com/QA-Jo/teller-automation/issues/38)

## Test-defects fixed & verified this effort
- **t2.5.15, t2.6.9/.19/.21, t7.5.5** — stale test bugs (fixes committed but never re-run)
- **t4.1.5** — wrong seed data (credit bank name → "Rizal Commercial Banking Corporation")
- **t2.3.4 / t3.2.4** — repointed off an errored record to a healthy one
- **t1.1 reset flow** — `Complete Reset Password Form` re-entered the wrong temp password
- **t1.3.1** — verified login as the wrong account (TELLER instead of the reset CP account)
- **t1.4.11-12** — OTP resend button is disabled-not-hidden during cooldown
- **t7.2.10** — SoD "reject own" logged in as the approver instead of the maker

## Escalations & tracking
- Parent ticket: [#37 — Teller Regression September 2026 bugs encountered](https://github.com/QA-Jo/teller-automation/issues/37) (Higala Project / Iteration 16), with sub-issues #35, #36, #38.
- Full detail and evidence: `ESCALATIONS_2026-09.md`.

## Notes on environment constraints
- **Auth network rate limit** (~7-8 login/OTP requests → "Too many requests from this network") required manual resets between OTP/lockout batches; auth suites were run in isolated batches and merged into the report.
- Auth tests use dedicated accounts (`jjavier+sa` disposable; `jjavier+temp*` one-time temp-password accounts, which must be refreshed each run).

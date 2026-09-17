# 2026-07 Regression — Pre-deployment to SBX

Published results: https://talino-labs.github.io/teller-automation/
(run: `2026-07_regression-pre-deployment-to-sbx`)

## In scope — executed, all passing (21 TCs)
| Module | Test cases | Result |
|--------|-----------|--------|
| Customers | t2.1–t2.6 | ✅ Pass |
| Accounts | t3.1–t3.2 | ✅ Pass |
| Transactions | t4.1–t4.3 | ✅ Pass |
| Products | t5.1–t5.3 | ✅ Pass |
| Reports | t6.1 | ✅ Pass |
| Loans | t7.1–t7.6 | ✅ Pass |

## Out of scope — excluded this run
Excluded — **no recent changes to these areas on the current deployment.**
Regression testing for them was done last **June 2026** (see the `2026-06-02_regression-post-deployment` results).

| Module | Test cases | Notes |
|--------|-----------|-------|
| 1_auth | t1.1–t1.4 | Excluded — no recent changes; last regressed June 2026 (`2026-06-02_regression-post-deployment`). |
| 8_interest | t8.1 | Excluded — no recent changes; additionally pending dedicated interest-test accounts to be provisioned. |

---

# Teller SBX + SIT July 2026 Smoke Testing

Published results: https://talino-labs.github.io/teller-automation/
(run: `Teller_SBX_and_SIT_July2026_Smoke_Testing`, one sub-folder per bank)

Per-bank smoke run across SBX/SIT environments. Auth (t1.2–t1.4) is included;
`t1.1` reset-password (one-time temp passwords) and `t8.1` interest (accounts
not provisioned) are excluded for all banks.

## Limited-module banks (SNR-SBX, Guagua-SBX) smoke scope

Some SBX tenants expose **only Customers, Accounts, Transactions and Reports** —
there are **no Products or Loans modules**, and the tenant has no cash
deposit/withdrawal, external-transfer, or loan/interest transaction data.
Running the full suite yields ~140 not-applicable failures, so these banks are
run through the scoped wrapper **`run_limited_smoke.sh <bank>`**
(`run_snr_sbx_smoke.sh` is a thin wrapper for SNR-SBX). Confirmed limited-module
banks so far: **SNR-SBX**, **Guagua-SBX**, **Hermosa-SBX**, **abucay-SBX**.

**In scope (run + reported):**
| Module | Test cases |
|--------|-----------|
| Auth | t1.2, t1.3, t1.4 |
| Customers | t2.1, t2.2, t2.3 |
| Accounts | t3.1, t3.2 |
| Transactions | t4.1 (view/list) |
| Reports | t6.1 |

**Out of scope — whole TC files not run:** t2.4/t2.5/t2.6 (product & loan
availment), t4.2/t4.3 (cash withdrawal/deposit), t5.* (products), t7.* (loans),
t1.1 (reset-password), t8.1 (interest).

**Out of scope — status-change sub-tests, excluded at RUN time** (never executed).
These are mutating and share the account other tests verify as Active, so running
them corrupts test data. They carry a `status-change` tag; the wrapper passes
`--exclude-tag status-change` to `run_july_regression.sh`.
| Sub-tests | Reason |
|-----------|--------|
| t2.1.13, t2.1.14, t2.2.10–t2.2.13 | Change customer/account status (excluded on request; mutating) |

**Out of scope — read-only sub-tests filtered from the report** (feature/data not
present in these tenants; safe to run, then removed via `rebot`):
| Sub-tests | Reason |
|-----------|--------|
| t2.3.10–14, t3.2.9–13, t4.1.9–13 | Filter by Cash Withdrawal/Deposit, Savings Interest, Loan Disbursement/Payment — those transaction types don't exist in the tenant |
| t4.1.5 | Search by ID targets an External Transfer — no external-transfer data (no partner account code set up) |
| t2.1.12 | Profile detail verification checks the Eligible Products tab, which requires the Products module |

**Per-bank data notes** (each tenant needs its own valid customer/account data):
- **SNR-SBX** — `VALID_CUSTOMER` = Louisa May (Active customer with an Active account).
- **Guagua-SBX** — `VALID_CUSTOMER`/account = **Jocelyn Javier Amban** (`7711031228974342`,
  Active). The originally-configured Josephine Santos only has a **Closed** account
  (terminal status, cannot be reactivated), which failed the Active-account checks
  (t2.2.3/.4), so the dataset was switched to Jocelyn. `VALID_ACCOUNT_NUMBER` (the
  module-level account search, t3.1.3) points at Myka Feliciano Quiambao's Active
  account. Result: **54/54**.
- **Hermosa-SBX** — `VALID_CUSTOMER`/account = **Lena Moretti** (Active). Only
  `VALID_ACCOUNT_NUMBER`/`EXPECTED_*` (t3.1.3) needed fixing — pointed at Lena's own
  Active account `7710744278473292` (was Warren Test Hermosa's Deceased account).
  Result: **54/54**.
- **abucay-SBX** (Banco Abucay) — `VALID_CUSTOMER`/account = **Peach Marie Villados**
  (Active). No config changes needed — clean on the first scoped run. Result: **54/54**.

Run + publish (per bank):
```
bash run_limited_smoke.sh SNR-SBX        # or: bash run_snr_sbx_smoke.sh
bash run_limited_smoke.sh Guagua-SBX
bash publish_reports.sh --timestamp Teller_SBX_and_SIT_July2026_Smoke_Testing \
  --title "Teller SBX and SIT July 2026 Smoke Testing"
```

---

# 2026-09-10 Full Regression — rural-bank-san-antonio (ITG)

Run folder: `results/2026-09_full-regression/` — every test, no `--include` tag
filter (only `skip` excluded), executed in 4 batches by rate-limit risk.

**Result: 294 passed / 68 failed / 17 skipped (379 tests, 25 TCs).**

| Module | Pass | Fail | Skip |
|--------|-----:|-----:|-----:|
| Customers (t2.1–t2.6)    | 82 | 9  | 2 |
| Accounts (t3.1–t3.2)     | 27 | 1  | 0 |
| Transactions (t4.1–t4.3) | 59 | 1  | 5 |
| Products (t5.1–t5.3)     | 52 | 0  | 1 |
| Reports (t6.1)           |  1 | 3  | 0 |
| Loans (t7.1–t7.6)        | 50 | 13 | 0 |
| Auth (t1.1–t1.4)         | 23 | 41 | 9 |

## Product defects — escalate
- **Status change silently fails** (t2.1.13/.14, t2.2.11/.13). Customer *and*
  account. The modal submits, dismisses itself, persists nothing and shows no
  error. Confirmed: `Last Updated` unchanged, and a re-query by status returns
  "No data".
- **Loan payment total double-counts interest** (t7.6.11). Total Amount Paid
  `839.94` vs Principal `835.76` + Interest `2.09` = `837.85`. The gap is
  exactly the interest, i.e. `Total = Principal + 2 x Interest`.

## Environment blockers — need admin, not code
- **Auth rate limit.** Network-level block: *"Too many requests from this
  network, try again after 1 hour."* One manual reset buys ~20 tests. 41 auth
  failures are artifacts of this, not defects. Needs the QA IP whitelisted.
  See [[itg-rate-limit-blocker]] notes.
- **Approver lacks Loans permission** (all of t7.2 + t7.3.1 = 11 tests).
  `pvillados+u1`-style approver `pvillados@agsx.net` authenticates but the app
  returns **"Access Restricted — your current role doesn't include permission
  to view this page."** t7.3.1 depends on t7.2 approving a loan first.

## Open question
- Transaction `547fa043e7424b6c956926466daa91df` (Fund Transfer) returns an
  empty detail payload — every field `N/A`, amounts `0.00` — while
  `20327d2dec2046b1bf2c3353c94c0fcf` (External Transfer) renders all 12 fields
  correctly. Bad record, or Fund-Transfer-specific? One manual check settles it.
  Affects t2.3.4 and t3.2.4 (both use that same record).

## Test defects fixed in this commit
- **t1.4.2–.8** passed `email=${TELLER_EMAIL}` while `password` still defaulted
  to `${CP_USER_PASSWORD}`, so they never reached the change-password form —
  they died at login. These 7 tests had never actually tested anything.
- **t1.4.1** changed the CP account's password with nothing to restore it,
  poisoning `${CP_USER_PASSWORD}` for the rest of the suite and all later runs.
  Now has a `Restore CP Password And Close Browser` teardown (idempotent).
- **t2.6.9/.19/.21** hardcoded `[data-field="employerName"]`; the product under
  test uses `tellUsSomethingAboutYourself`. Now use the product-agnostic helper
  / `${AVAIL_LOAN_CUSTOM_FIELD_INPUT}`.
- **t2.1.12 was defined twice** under one name (a `type1.1` typo variant and a
  `type2` product-tabs variant). Renamed the second to `t2.1.12b` and corrected
  `type1.1` -> `type1`; `run_limited_smoke.sh` now filters `t2.1.12b` so Type 1
  banks keep real profile-detail coverage instead of losing both variants.
- **t2.5.15** expected superseded copy; the guardrail works, only the message
  changed to *"This request cannot be completed at this time..."*.
- **t7.5.5** clicked a row without searching first, but `Test Setup` lands on
  the unfiltered list. Now searches, like every other test in that suite.

## Still to do
- **t6.1 (3 tests)** predates the Reports redesign: the suite expects
  date-select -> `Download CSV`, but the UI now has `Generate Report` with an
  async status. **Whether report generation works at all is still unverified** —
  the suite never gets far enough to tell.
- **`T4_TXN_CREDIT_BANK_NAME`** pairs BIC `RCBCPHMMXXX` (RCBC) with the name
  "Banco Abucay". The true display string can't be recovered from the artifacts
  because `:text-is()` logs nothing on a miss — needs one look at the modal.

## Runner changes
- `run_july_regression.sh`: `--all-tags` (drop the `--include` filter entirely —
  `type1`/`type2` are bank-CAPABILITY tags, not depth tags, and 15 tests carry
  neither, so any tag union silently drops applicable tests on a Type 2 bank);
  `--headless` (`-v HEADLESS:True`, since all var files ship `HEADLESS: False`
  and a visible Chromium gets long runs OOM-killed); and explicit TC arguments
  now execute in the order given rather than filesystem sort order — auth needs
  t1.1 LAST or it burns the attempt budget before the login suites run.
- `run_full_regression_batched.sh`: new batched wrapper (Reports+Customers /
  Accounts+Transactions / Products+Loans / Auth), auth last and alone.

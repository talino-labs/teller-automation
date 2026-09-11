# Teller 2026-09 Regression — Escalations & Blockers

**Environment:** rural-bank-san-antonio (ITG)
**Run folder:** `results/2026-09_full-regression/`
**Final standing:** ~303 passed / 59 failed / 17 skipped.

Of the 59 failures, **none are test-code defects** — all were triaged and the
fixable ones already turned green. What remains splits into product defects
(need dev) and access blockers (need admin):

| Bucket | Tests | Owner |
|--------|------:|-------|
| Product defects | 6 | Dev |
| Loans approver permission | 11 | Admin / access |
| Auth rate limit + account | 41 | Infra / admin |

Fixed & re-verified green this session (not in the counts above as failures):
t2.5.15, t2.6.9/.19/.21, t7.5.5 (stale test bugs), and t4.1.5 (wrong seed data —
see note under defect #4).

---

## A. Product defects — escalate to dev

### 1. Customer status change silently fails — `t2.1.13`, `t2.1.14`
Changing a customer Active→Inactive: the modal submits and dismisses itself,
but the **"Customer status updated successfully" toast never appears** and the
status does not persist. Confirmed previously: `Last Updated` is unchanged and a
re-query by the new status returns "No data". `t2.1.14` (Inactive→Active) then
fails downstream because no inactive customer exists to reactivate.

### 2. Account status change silently fails — `t2.2.11`, `t2.2.13`
Same failure mode on **account** status (Active→Frozen): submits, dismisses,
persists nothing, no success toast. `t2.2.13` (→Active) fails downstream for the
same reason. Customer- and account-level status changes are both affected.

### 3. Loan payment total double-counts interest — `t7.6.11`
Transaction-details modal for a loan payment:

| Field | Value |
|-------|------:|
| Principal | 835.76 |
| Interest | 2.09 |
| **Expected total** (P + I) | **837.85** |
| **Total Amount Paid shown** | **839.94** |

Overstatement = `839.94 − 837.85 = 2.09` = **exactly the interest again**, i.e.
`Total = Principal + 2 × Interest`. Interest is being added twice.

### 4. Transaction detail returns an error for a cluster of older records (data integrity, low severity)
Certain transactions return an errored/empty detail payload: opening the detail
modal shows **Transaction Type = `ERR - N/A`** and every field N/A / 0.00, even
though the list row shows the transaction as **Success**. Persists after a 6s
settle, so it is not a load race — the detail endpoint **throws** for these
records.

**Confirmed record-specific and age-correlated, NOT feature-wide** (verified
this session against the live list):
- In **Peach Villados' account (7710458152114857)**, the **3 oldest** of 10
  transactions error out — `547fa043e7424b6c956926466daa91df`,
  `7482a6a9f2774312a76e0df2e0ced215`, `f62692b4cea846fbbf7fa8d0b18e13e2` — while
  all 7 newer (2026) records render every field.
- Across the transactions module, 8 sampled Internal Transfers and every sampled
  External Transfer render correctly. (One External first *looked* empty but
  that was a rendering race — it renders fully with an adequate wait.)

So the detail feature works; a set of **older (pre-2026) records** throws on
detail fetch — likely missing/un-backfilled detail data. Dev to confirm the
common cause and whether a backfill is needed.

**Test impact — RESOLVED in test:** `t2.3.4` / `t3.2.4` had been seeded with
`547fa043…` (one of the broken records) via `VALID_TXN_ID`, so they could never
pass. **Repointed** to a healthy Fund Transfer in the same account
(`fffcf209b08049a4b87f28be8f3c1a3c`, values verified against ITG); both tests are
now green. The broken records above still need the dev fix.

> Note (not a defect): `t4.1.5` failed on the credit **bank name**. Config had
> `T4_TXN_CREDIT_BANK_NAME: "Banco Abucay"`, but the ITG record shows BIC
> `RCBCPHMMXXX` → **"Rizal Commercial Banking Corporation"**. Wrong seed data,
> now corrected; test is green.

---

## B. Access / environment blockers — need admin, not code

### 5. Loans approver lacks permission — `t7.2.1`–`t7.2.10`, `t7.3.1` (11 tests)
Approver `pvillados@agsx.net` authenticates but the Loans area returns
**"Access Restricted — your current role doesn't include permission to view this
page."** The whole `t7.2` suite fails at parent-suite setup on
`nav-sidebar-loans`; `t7.3.1` depends on `t7.2` approving a loan first.
**Need:** a second Loans-capable account to act as approver (kept distinct from
the maker so Separation-of-Duties tests remain valid).

### 6. Auth network rate limit — `t1.1`–`t1.4` (41 tests)
Network-level block: *"Too many requests from this network, try again after
1 hour."* One manual reset buys ~20 tests. These 41 failures are artifacts of
the block, not defects. **Need:** the QA IP whitelisted.

### 7. Dedicated disposable auth account for `t1.3` / `t1.4`
`CP_USER_EMAIL` currently points at the **main teller** (`jjavier+1@nmblr.ai`).
`t1.3.1` resets that account's password with **no restore step**, and `t1.4.1`
changes it too — running either against the main teller would change the
credential **every module logs in with** and lock out the whole suite. These
suites need a **disposable, isolated account** (the deleted `pvillados+u1` was
the right shape). **Need:** an account like `jjavier+2@nmblr.ai` to repoint
`CP_USER_EMAIL` / `FP_MIXED_CASE_EMAIL` at, restoring the safe blast radius.

---

## Summary of what's needed to close the run
1. **Dev:** fix defects #1–#3 (and #4 pending the QA check above).
2. **Access:** provision a Loans-capable approver account (#5).
3. **Infra:** whitelist the QA IP for auth (#6).
4. **Access:** provision a disposable auth account for t1.3/t1.4 (#7).

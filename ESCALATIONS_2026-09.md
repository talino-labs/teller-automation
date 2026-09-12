# Teller 2026-09 Regression — Escalations & Blockers

**Environment:** rural-bank-san-antonio (ITG)
**Run folder:** `results/2026-09_full-regression/`

Almost every original failure has been resolved — as a stale test-defect fixed
in code, or by provisioning the missing test accounts. What genuinely remains is
a small set of **product defects (need dev)** plus a handful of auth lockout
tests that need a **pristine account state** the environment can't reliably give.

| Bucket | Status |
|--------|--------|
| Product defects (dev) | 3 open (status-change is verified in a separate set) |
| Loans approver | ✅ Resolved — approver account provisioned |
| Auth suites t1.1 / t1.3 / t1.4 | ✅ All green |
| Auth t1.2 (login/lockout) | 18/20 — feature proven; 4 counter-detail tests blocked on account-state reset |

### Test-defects fixed & verified this session
- **t2.5.15, t2.6.9/.19/.21, t7.5.5** — stale test bugs (fixes were committed but never re-run)
- **t4.1.5** — wrong seed data (bank name; see note under defect #4)
- **t2.3.4 / t3.2.4** — repointed off an errored record (see defect #4)
- **t1.1 reset flow** — `Complete Reset Password Form` re-entered the wrong temp
  password (defaulted to `RTP_TEMP_PASSWORD` instead of the account actually
  logged in with); latent until these tests first cleared the rate limit
- **t1.3.1** — verified the reset by logging in as `TELLER_EMAIL` instead of the
  account that was reset (`CP_USER_EMAIL`); latent while they were the same account
- **t1.4.11-12** — asserted the OTP resend button was *hidden* during cooldown;
  it is actually *visible but disabled* (countdown), now asserted correctly

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

## B. Resolved this session (accounts provisioned)

### 5. Loans approver — ✅ RESOLVED
Previously `pvillados@agsx.net` authenticated but hit **"Access Restricted"** on
the Loans area, failing all of `t7.2` + `t7.3.1`. Repointed `T72_APPROVER_*` to a
Loans-capable account (`jjavier+sa`, distinct from the maker so Separation-of-
Duties stays valid). **Result: t7.3 7/7, t7.2 10/10.** `t7.2.10` (SOD "cannot
reject own") was fixed this session — it was logging in as the *approver*
instead of the *maker*, so the "cannot reject own" block never fired (a different
teller rejecting an app is valid). Now logs in as the maker (default teller),
matching its docstring and t7.2.9. Not a product defect.

### 6. Disposable auth account for t1.3 / t1.4 — ✅ RESOLVED
`CP_USER_EMAIL` / `FP_MIXED_CASE_EMAIL` repointed from the main teller to a
dedicated disposable account (`jjavier+sa`), so t1.3 (which resets the password
with no restore) and t1.4 (which changes it) no longer risk locking out the whole
suite. **Result: t1.3 16/16, t1.4 12/12.** Note: t1.3.1 leaves `jjavier+sa` at
its reset password, so it should be reset to `Password!1` after an auth run.

---

## C. Remaining blockers

### 7. Auth network rate limit — handled by manual reset (not an infra ask)
The app throttles at **~7-8 login/OTP requests** from the network:
*"Too many requests from this network, try again after 1 hour."* Per QA decision
this is left as-is (it reflects real behavior) and **worked around by manually
resetting** the limit between runs. Consequence for automation: OTP- and
lockout-heavy tests must be run in **small isolated batches with a reset between**
(a full suite run trips it mid-way). This is a known operational constraint, not
a defect.

### 8. t1.2 lockout counter-detail tests — need a pristine account counter
`t1.2` login is at **15/20** in the published run folder. The lockout **feature
is proven working**:
- ✅ t1.2.10 — blocks after 5 failed attempts
- ✅ t1.2.14 — blocking is per-account (not per-device/IP)
- ✅ t1.2.15 — password reset lifts the block
- (t1.2.11 blocked-during-cooldown passes on a truly pristine counter, but is
  unreliable — see below)

The remaining 5 — **t1.2.11** (blocked during cooldown), **t1.2.12** (auto-unlock
after cooldown), **t1.2.13** (counter persists across sessions), **t1.2.16**
(counter resets after success), **t1.2.19** (still blocked on 6th) — each need
`jjavier+1` to start with a **failed-attempt counter of exactly 0**. Lifting the
account lock does **not** reliably reset the counter, so these hit the lockout on
an early attempt and fail on a precondition, not on the behavior under test.
**Need:** a reliable way to reset the account's failed-attempt counter to 0 (or a
fresh unused account per run).

### T4 bank-name credit record — resolved (was a config note, not a blocker)
Handled — see the t4.1.5 note under defect #4.

### 9. t8.1 Interest Crediting — DESIGN MISMATCH: system credits MONTHLY, tests assume DAILY
`t8.1` was never run in the 2026-09 regression (excluded, "pending dedicated
interest-test accounts"). Investigated this session against live ITG data.

**Key finding — interest is credited MONTHLY at ~2%, but t8.1 is written for
DAILY interest.** t8.1's expected values use `balance × rate / 365` (e.g. ₱2.74
for ₱50,000 @ 2%). The actual system credits **monthly** — verified rigorously
against 4 real accounts (`balance × 2% / 12`, within balance-drift):

| Account | Balance | Credited | Monthly `bal×2%/12` |
|---------|--------:|---------:|--------------------:|
| Jace Amban (7710373294475998)   | 273,978.19 | 455.87 | 456.63 |
| Jello Mangune (7710338140519887)|  50,586.25 |  84.17 |  84.31 |
| Shia (7710383355350139)         |  10,606.86 |  17.65 |  17.68 |
| Joy Amban (7710388942877702)    |     308.51 |   0.51 |   0.51 |

Credit **dates confirm the monthly cadence** (Jace: 01 Aug, 02 Jul, 01 Jul,
02 Jun, 01 Jun). So all of t8.1's daily-computation tests (t8.1.2–.5, .9, .10,
.13, .14) cannot match real data as written.

**The interest feature itself works** — the transaction-history list and detail
modal render correctly (Type "Savings Interest", Amount, Service Fee 0.00,
Remarks "Savings Interest Auto Credit", Success, credit account, dates).

**Other gaps found:**
- **No 5% savings product exists** in the tenant (rates seen: 2%, 2.5%, 0%). A
  5% product was created this session but has no accounts/interest yet. t8.1's
  "Product B (5%)" tests need it (plus accounts + a job cycle).
- **Scenario tests** (t8.1.9 ₱1M, t8.1.10 ₱73, t8.1.14 ₱72.99, t8.1.15 zero,
  t8.1.16 closed, t8.1.17 0%-product) need purpose-built accounts at exact
  balances — not producible via the standard UI flows.
- **t8.1.1** (scheduler runs at 12 AM) is manual-verify; note the most recent
  system-wide interest credit seen was 17 Aug (vs a monthly cadence), worth a
  scheduler check.
- **t8.1.6 / t8.1.7** (structural: record exists + detail renders) are the only
  tests satisfiable with existing data today; they need minor test fixes (one
  ambiguous `text=Savings Interest` locator fixed this session; the account
  table also has a known intermittent empty-render).

**Staged this session:** `T81_PRODUCT_B_ACCOUNT_NO` pointed at a real credited
account (Jace Amban) so the structural tests have real data to run against.

**Needs decision (test design / product owner):** reconcile t8.1 with actual
behavior — either the savings products should credit **daily** (config change) or
t8.1 should expect **monthly** interest. Until then t8.1's computation tests
cannot pass.

---

## Summary of what's needed to close the run
1. **Dev:** fix product defects #1–#3, and investigate the errored older-record
   detail payloads in #4 (possible data backfill).
2. **QA ops:** to fully green t1.2, provide a way to reset `jjavier+1`'s
   failed-attempt counter (or a fresh account per run) — the lockout feature
   itself is already verified.
3. **QA ops:** keep resetting the network rate limit between OTP/lockout batches
   (per the manual-reset workflow); and reset the disposable auth account
   (`jjavier+sa`) to `Password!1` after auth runs.
4. **Test design / product owner:** reconcile t8.1 with actual interest behavior
   (system credits **monthly ~2%**, tests assume **daily**); provision a 5%
   product + exact-balance interest test accounts if daily testing is intended.

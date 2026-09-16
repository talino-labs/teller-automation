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

## A. 🟡 Needs manual September execution

Inherently manual (OTP-session blocking, 5-min session/OTP timeouts, or no automated suite). Not covered by the September automated run — must be run manually and recorded.

| Module | Test cases | Note |
|--------|-----------|------|
| t1.1 Reset Password (First-Time Login) | t1.1.1 t1.1.21 t1.1.22 t1.1.23 t1.1.24 t1.1.25 t1.1.26 | incl. t1.1.1 reset-link + t1.1.21–26 OTP-session blocking |
| t1.3 Forgot Password | t1.3.21 t1.3.22 t1.3.23 t1.3.24 t1.3.25 t1.3.26 | t1.3.21–26 OTP-session blocking |
| t1.4 Change Password | t1.4.17 t1.4.18 t1.4.19 t1.4.20 t1.4.21 t1.4.22 | t1.4.17–22 OTP-session/blocking |
| t2.5 Avail Savings Product | t2.5.19 | t2.5.19 |
| t5.3 Create New Product | t5.3.36 | t5.3.36 |

> **t3.3 Create New Bank Account** was removed from this "manual execution" list — it is **blocked**, not manually runnable yet. See Section E.

## B. 🟢 "Dropped" — verified as covered/stale (numbering mismatch, NOT gaps)

On inspection these are **not** coverage gaps — the automated suites cover them under different numbering (the automation has extra sub-tests, and the app's account statuses changed). No restoration needed.

| Catalog TC | Reality |
|-----------|---------|
| t2.2.10, t2.2.12 | Exist as "Change Account Status to Dormant / Closed" — **excluded** on purpose (your separate status-change test set) |
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

## Recommended actions

1. **t3.3 Create New Bank Account — BLOCKED, no action possible yet.** The onboarding wizard is not deployed on ITG (Section E). Do **not** treat it as an open automation gap; revisit and automate once the feature ships. There are currently **no automatable coverage gaps**.

2. **Run the other manual TCs in September** (Section A) and record results — the OTP-session/blocking and session-timeout sets.

3. **Section B needs no action** — those "dropped" TCs are already covered under different numbers, excluded on purpose, or stale (no "Suspended" status). Consider realigning the catalog's numbering with the automated suite.

4. **Add catalog rows for t2.6 and t7.1–t7.6** (Section C) so the sheet reflects what September actually ran.

4. **Update the catalog's report links/dates** from the April `pvillados-nmblr` links to the September run: `https://qa-jo.github.io/teller-automation/reports/2026-09_full-regression/`

# Coverage Gap Analysis — 2026-09 Teller Regression vs. Test-Case Catalog

Cross-check of the master test-case catalog (`ITG Full Regression Testing - September 2026` sheet) against the **September automated run** (`results/2026-09_full-regression/`).

> Note: the catalog sheet's recorded results are all from **April 2026** (dates 4/20–4/30, links to the old `pvillados-nmblr` site). It does **not** yet reflect the September run. September coverage below comes from the automated regression + pending manual execution.

## Summary

| Bucket | Count |
|--------|------:|
| Catalog test cases (CSV) | 319 |
| ✅ Covered by September automated run | 285 |
| 🟡 Needs manual September execution | 29 |
| 🟠 Dropped from the automated suite (confirm) | 5 |
| ➕ Extra Sept modules not in the catalog | 7 modules |

## A. 🟡 Needs manual September execution

Inherently manual (OTP-session blocking, 5-min session/OTP timeouts, or no automated suite). Not covered by the September automated run — must be run manually and recorded.

| Module | Test cases | Note |
|--------|-----------|------|
| t1.1 Reset Password (First-Time Login) | t1.1.1 t1.1.21 t1.1.22 t1.1.23 t1.1.24 t1.1.25 t1.1.26 | incl. t1.1.1 reset-link + t1.1.21–26 OTP-session blocking |
| t1.3 Forgot Password | t1.3.21 t1.3.22 t1.3.23 t1.3.24 t1.3.25 t1.3.26 | t1.3.21–26 OTP-session blocking |
| t1.4 Change Password | t1.4.17 t1.4.18 t1.4.19 t1.4.20 t1.4.21 t1.4.22 | t1.4.17–22 OTP-session/blocking |
| t2.5 Avail Savings Product | t2.5.19 | t2.5.19 |
| t3.3 Create New Bank Account | t3.3.1 t3.3.2 t3.3.3 t3.3.4 t3.3.5 t3.3.6 t3.3.7 t3.3.8 | **entire module — no automated suite exists** |
| t5.3 Create New Product | t5.3.36 | t5.3.36 |

## B. 🟠 Dropped from the automated suite (were automated in April, not in the Sept suite)

These had April automation report links but are **absent from the current September suites**. Confirm whether removal was intentional (refactor) or a coverage regression.

| Test case | Detail |
|-----------|--------|
| t2.2.10 | Account status-change — excluded (separate updated test set) |
| t2.2.12 | Account status-change — excluded (separate updated test set) |
| t3.1.12 | Sept t3.1 suite has only t3.1.1–11 |
| t3.1.13 | Sept t3.1 suite has only t3.1.1–11 |
| t4.1.3 | Sept t4.1 suite skips it (has .1, .2, .4, .5 …) |

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

## Recommended actions

1. **Run the manual TCs in September** (Section A) and record results — especially **t3.3 Create New Bank Account (8 TCs)**, which has no automation.

2. **Confirm the 5 dropped sub-tests** (Section B) — restore to automation if the coverage is still required.

3. **Add catalog rows for t2.6 and t7.1–t7.6** (Section C) so the sheet reflects what September actually ran.

4. **Update the catalog's report links/dates** from the April `pvillados-nmblr` links to the September run: `https://qa-jo.github.io/teller-automation/reports/2026-09_full-regression/`

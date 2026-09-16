# Section A — Manual Execution Results (2026-09)

Manual execution of the "needs manual September execution" cases from
`COVERAGE_GAP_2026-09.md` §A, against **rural-bank-san-antonio (ITG)**.

## Summary

| TC | Title | Result | Method |
|----|-------|--------|--------|
| t2.5.19 | Session Timeout During Savings Availment Flow | ✅ PASS | Automated (implemented; was a `Skip`) |
| t5.3.36 | Savings Product Version Update Creates Deprecated Version | ✅ PASS | Manual UI (16 Sep 2026) — automation to follow |
| t1.1.1  | Reset Password via "Reset Password Now" link | 🟡 PARTIAL | Flow verified by equivalence; email-link step needs inbox |
| t1.1.21–26 | Reset Password — OTP-session 60-min block set | ⏳ IN PROGRESS | Manual w/ magic OTP values (see below) |
| t1.3.21–26 | Forgot Password — OTP-session 60-min block set | ⏳ IN PROGRESS | Manual w/ magic OTP values |
| t1.4.17–22 | Change Password — OTP-session 60-min block set | ⏳ IN PROGRESS | Manual w/ magic OTP values |

## Details

### t2.5.19 — Session Timeout During Savings Availment Flow ✅ PASS
Implemented a real test body (previously a `Skip` placeholder) using the proven
301s-idle pattern (as in t1.2.6/.8). Navigate to the avail-product page, idle past
the 5-minute timeout, attempt to continue → **"Session Expired"** modal shown and
user redirected to Login. Ran headless: **1 passed**. Tagged `slow` (excluded from
CI, runnable on demand).

### t5.3.36 — Version Update Creates Deprecated Version ✅ PASS
Executed manually in the live app as `jjavier+1` (Jo DFSP3 / Administrator):
1. Baseline — customer **John Deep** (`a11c5d77c5184a8692d36545eb19dbd6`) holds
   **Savings 0602041715** = `PROD_3921fe6e16b24ee79bb4800a61a1b992_000`,
   Interest rate **2.50%**, Status **Active**.
2. Products → edited that product, changed Interest rate **2.50 → 3.00**, Save Changes.
3. Result — product version bumped **`_000` → `_001`** (new active version at 3.00%,
   now top of Active Products).
4. Verification in John Deep's **Products Availed** tab → the held `_000` version now
   shows **Status: Deprecated**, retains its original **2.50%** terms, and is still
   viewable in the Availed tab.

Matches all expected results: (1) held version → Deprecated ✅, (2) old version no
longer in the active/marketplace list (only `_001` active) ✅, (3) existing customer
can still view their Deprecated product ✅.

> Note: this permanently created version `_001` of Savings 0602041715 on ITG (by
> design — that is the feature under test). John Deep's `_000` remains at 2.50%.

### t1.1.1 — Reset Password via "Reset Password Now" link 🟡 PARTIAL
The temp-password → new-password → OTP reset flow was exercised end-to-end this
session (on `jjavier+jr1`) and succeeded ("Password has been changed successfully").
The only unverified nuance specific to t1.1.1 is arriving via the **email link**,
which needs inbox access.

### OTP-session 60-minute block sets (t1.1.21–26, t1.3.21–26, t1.4.17–22) ⏳
Being executed manually using backend magic OTP values
(`000000` = invalid/expired, `999999` = max-attempts, `123456` = valid) with manual
network-rate-limit resets between sessions. The two cases per set that require real
wall-clock waits — **`.24`** (reset after 60-min block expiry) and **`.26`**
(3 sessions spanning >15 min) — cannot be machine-timed and remain human-manual.

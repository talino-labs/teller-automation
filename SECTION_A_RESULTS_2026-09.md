# Section A — Manual Execution Results (2026-09)

Manual execution of the "needs manual September execution" cases from
`COVERAGE_GAP_2026-09.md` §A, against **rural-bank-san-antonio (ITG)**.

## Summary

| TC | Title | Result | Method |
|----|-------|--------|--------|
| t2.5.19 | Session Timeout During Savings Availment Flow | ✅ PASS | Automated (implemented; was a `Skip`) |
| t5.3.36 | Savings Product Version Update Creates Deprecated Version | ✅ PASS | Automated (implemented; idempotent/reusable) |
| t1.1.1  | Reset Password via "Reset Password Now" link | 🟡 PARTIAL | Flow verified by equivalence; email-link step needs inbox |
| t1.3.21 | Forgot Password — 60-min block after 3 unverified sessions (5 invalid attempts) | ✅ PASS | Manual, magic OTP `999999` |
| t1.3.23 | Forgot Password — blocked email keeps returning error during block | ✅ PASS | Manual |
| t1.3.22 | Forgot Password — block via abandoned sessions | ✅ PASS | Manual (`jjavier+temp2`) |
| t1.3.25 | Forgot Password — valid OTP on 5th attempt → not blocked | ✅ PASS | Manual (`jjavier+temp2`) |
| t1.3.24 | Forgot Password — reset works after 60-min block expiry | 🕒 HUMAN-MANUAL | Real 60-min wait |
| t1.3.26 | Forgot Password — 3 sessions spanning >15 min → no block | 🕒 HUMAN-MANUAL | Real 15-min staged waits |
| t1.1.21 | Reset Password — 60-min block after 3 unverified sessions | ✅ PASS | Manual, magic OTP `999999` (`jjavier+i1`) |
| t1.1.23 | Reset Password — blocked email keeps returning error | ✅ PASS | Manual (timer 59→58) |
| t1.1.22 | Reset Password — block via abandoned sessions | ✅ PASS | Manual (`jjavier+jc1`) |
| t1.1.25 | Reset Password — valid OTP on 5th attempt → not blocked | ✅ PASS | Manual (`jjavier+cg1`) |
| t1.1.24 | Reset Password — reset works after 60-min block expiry | 🕒 HUMAN-MANUAL | Real 60-min wait |
| t1.1.26 | Reset Password — 3 sessions spanning >15 min → no block | 🕒 HUMAN-MANUAL | Real 15-min staged waits |
| t1.4.17 | Change Password — 60-min block after 3 unverified sessions | ✅ PASS | Manual (`jjavier+cg1`, logged in) |
| t1.4.19 | Change Password — blocked email keeps returning error | ✅ PASS | Manual (timer 59→58) |
| t1.4.18 | Change Password — block via abandoned sessions | ✅ PASS | Manual (`jjavier+temp4`) |
| t1.4.21 | Change Password — valid OTP on 5th attempt → not blocked | ✅ PASS | Manual (`jjavier+temp4`) |
| t1.4.20 | Change Password — reset works after 60-min block expiry | 🕒 HUMAN-MANUAL | Real 60-min wait |
| t1.4.22 | Change Password — 3 sessions spanning >15 min → no block | 🕒 HUMAN-MANUAL | Real 15-min staged waits |
| t1.3.22 | Forgot Password — block via abandoned sessions | ✅ PASS | Manual (`jjavier+temp2`) |
| t1.3.25 | Forgot Password — valid OTP on 5th attempt → not blocked | ✅ PASS | Manual (`jjavier+temp2`) |

### Change Password 60-min block set (t1.4.17–22) — observed behavior

Executed live logged in as `jjavier+cg1` (Cat Gray). Change Password lives at
**Profile menu → Change password** (`/dashboard/profile/change-password`): enter
current + new + re-enter → Continue → OTP → verify. Magic OTP `999999`:

- **t1.4.17 ✅ PASS** — 3 change-password sessions, each `999999` → *"Verification
  Failed — maximum number of attempts."* On **session #4** (Continue) the email was
  blocked: **"You have exceeded the maximum number of attempts. You can try again in
  59 minutes."** — user remains on the Change Password page (expected #4 ✅).
- **t1.4.19 ✅ PASS** — retrying Continue during the block → same error, timer
  **59 → 58 minutes** (expected #3 ✅).
- **t1.4.21 ✅ PASS** (`jjavier+temp4`) — 2 unverified sessions (`999999`), then session #3:
  4 invalid (`000000`) + **valid `123456` on the 5th attempt** → *"Password has been
  changed successfully."* No block — expected ✅.
- **t1.4.18 ✅ PASS** (`jjavier+temp4`) — 3 **abandoned** sessions (reach OTP, click the
  ← back arrow to leave). On the session #4 Continue the email was blocked:
  **"You have exceeded the maximum number of attempts. You can try again in 59 minutes."**
  — user stays on the Change Password page (expected #4 ✅).

> **All three flows (Reset t1.1, Forgot t1.3, Change t1.4) confirmed to share the
> identical OTP-session-block backend** — same modal wording, same 60-min timer,
> same behavior for the max-attempts (`999999`), abandoned-session, and valid-on-5th
> paths. The full block set passes on every flow except the two wall-clock cases
> (`.24`/`.26` per flow → `.20`/`.22` for Change), which remain human-manual.

### Forgot Password — remaining cases (t1.3.22 / t1.3.25)

Completed with `jjavier+temp2` (magic OTP):

- **t1.3.25 ✅ PASS** — 2 unverified sessions (`999999`), then session #3: 4 invalid
  (`000000`) + **valid `123456` on the 5th attempt** → advanced to the **"Create new
  password"** screen and completed → *"Password has been changed successfully."* No
  block — expected ✅.
- **t1.3.22 ✅ PASS** — 3 **abandoned** sessions (reach OTP, click "Log in" → *"Are you
  sure you want to exit?"* → Confirm). On the session #4 Send the email was blocked:
  **"You have exceeded the maximum number of attempts. You can try again in 59 minutes."**
  — user stays on the Forgot Password page (expected #4 ✅).

## Final status

**All machine-runnable Section-A cases pass (14):** t2.5.19, t5.3.36, and the full
OTP-session-block matrix across all three flows — Reset (t1.1.21/.22/.23/.25), Forgot
(t1.3.21/.22/.23/.25), Change (t1.4.17/.18/.19/.21).

**Only human-manual remainders** (real wall-clock waits, no account/app blocker):
t1.1.24 / t1.1.26 / t1.3.24 / t1.3.26 / t1.4.20 / t1.4.22 — the 60-min-block-expiry and
>15-min-window cases. Plus **t1.1.1** email-link entry (needs inbox), already verified
by equivalence otherwise.

**Accounts consumed** (all throwaway, left blocked ~60 min and/or password-reset):
`i1`, `jc1`, `cg1`→Password!1, `temp4`→Password!2, `temp2`→Password!2.

### Reset Password 60-min block set (t1.1.21–26) — observed behavior

Executed live using first-time-login temp account `jjavier+i1@nmblr.ai` + magic OTP
`999999`. The Reset-Password flow keeps the user on the reset form between failed
sessions (no re-login needed):

- **t1.1.21 ✅ PASS** — 3 reset sessions, each `999999` → *"Verification Failed —
  maximum number of attempts."* On **session #4** (RESET PASSWORD) the email was
  blocked: **"You have exceeded the maximum number of attempts. You can try again in
  59 minutes."** — user remains on the Reset Password page (expected #4 ✅). Security
  Notice email (expected #5) unverifiable (no inbox).
- **t1.1.23 ✅ PASS** — retrying RESET PASSWORD during the block → same error, timer
  **59 → 58 minutes** (expected #3 ✅).
- **t1.1.22 ✅ PASS** (`jjavier+jc1`) — 3 **abandoned** sessions (reach OTP screen, click
  "Log in" → *"Are you sure you want to exit? All data will be lost"* → Confirm). On the
  session #4 login attempt the email was blocked: **"You have exceeded the maximum number
  of attempts. You can try again in 59 minutes."** — user stays on the Login page
  (expected #4 ✅). Confirms **abandonment** counts as an unverified session, same as
  max-attempts.
- **t1.1.25 ✅ PASS** (`jjavier+cg1`) — 2 unverified sessions (`999999`), then session #3:
  4 invalid attempts (`000000`) followed by the **valid OTP `123456` on the 5th attempt**
  → **"Success! Password has been changed successfully."** No block (only 2 unverified
  sessions in the window) — expected ✅. Proves the counter allows a valid 5th attempt
  and does not over-block.

> Confirms the block uses the **same backend** as Forgot Password (t1.3) — identical
> modal text and timer behavior across both flows. The full t1.1 block set passes except
> the two wall-clock cases (t1.1.24 / t1.1.26), which stay human-manual.
> Note: no network rate limit was hit across the entire t1.1 run (the reset flow reuses
> the authenticated session, keeping request volume low).

### Forgot Password 60-min block set (t1.3.21–26) — observed behavior

Executed live against ITG using the sacrificial email `jjavier+jr1@nmblr.ai` and
magic OTP `999999` (= max-attempts, collapses one "5-invalid-attempts session"):

- **t1.3.21 ✅ PASS** — 3 forgot-password sessions, each `999999` → modal
  *"Verification Failed — You have reached the maximum number of attempts."* On
  attempting **session #4**, the app blocked the email:
  **"You have exceeded the maximum number of attempts. You can try again in 59 minutes."**
  (CONFIRM keeps the user on the Forgot Password page — expected #4 ✅). Only the
  "Security Notice" email (expected #5) is unverifiable here (no inbox).
- **t1.3.23 ✅ PASS** — re-attempting Send Verification Code during the block shows
  the same error with the time **decremented (59 → 58 minutes)** — expected #3 ✅.
- The whole run stayed **under** the network rate limit (~7 requests total).

> The 999999 magic value works exactly as intended, so the block feature is proven.
> Remaining cases are gated only by account availability / real time, not by the app.

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

**Now automated** as `t5.3.36` in `tests/5_products/t5.3_create_new_product.robot`
(reusable across cycles — see the note below). Verified **PASS twice back-to-back**
to confirm idempotency. New reusable keywords: `Open Active Product Edit Page`,
`Update Product Interest Rate To Force New Version` (products), and
`Verify Customer Availed Product Is Deprecated` (customers).

> Note: each run permanently creates a new version of Savings 0602041715 on ITG (by
> design — that is the feature under test). The interest rate is toggled between
> `T536_INTEREST_RATE_A`/`_B` so the product stays sane and every run makes a real change.

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

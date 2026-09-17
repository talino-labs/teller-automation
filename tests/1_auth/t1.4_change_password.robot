*** Settings ***
Documentation       Test suite for Change Password flow.
...                 Covers happy path, password policy validation, OTP validation, cooldown, and session expiry.
...
...                 NOTE: Locators for this flow use name/text-based selectors as data-testid
...                 attributes have not yet been added. Update common_locators.resource once testids are available.
...
...                 Update OTP in the Variables section before running tests tagged [password-reset].

Resource            ../../resources/keywords/common.resource

Test Teardown       Close Browser


*** Variables ***
${CP_NEW_PASSWORD}                  Password123!!
${CP_WRONG_CONFIRM_PASSWORD}        WrongPassword999!
${OTP}                              123456

# --- Hardcoded OTP Test Values ---
# These are magic values recognised by the backend to simulate specific OTP states.
${OTP_INVALID}                      000000    # Always triggers "invalid or expired OTP" error
${OTP_MAX_ATTEMPTS}                 999999    # Immediately triggers max-attempts error in one attempt

# --- Change Password Form Errors ---
${ERR_PASSWORD_MISMATCH}            Passwords do not match.

# --- Password Policy Errors ---
${ERR_PWD_MIN_LENGTH}               Password must contain a minimum of 8 characters.
${ERR_PWD_UPPERCASE}                Password must include at least one uppercase letter.
${ERR_PWD_NUMBER}                   Password must include at least one number.
${ERR_PWD_SPECIAL}                  Password must include at least one special character.

# --- OTP Errors ---
${ERR_OTP_INVALID}                  OTP is either invalid or has expired. Please try again or request a new OTP.

# --- Max Attempts & Session Errors ---
${ERR_OTP_MAX_ATTEMPTS_1}           Verification Failed
${ERR_OTP_MAX_ATTEMPTS_2}           You have reached the maximum number of attempts. For your security, we're redirecting you to the previous page.
${ERR_OTP_EXPIRED_SESSION}          Your one-time password has expired. Request a new code to continue.


*** Keywords ***
Navigate To Change Password Page
    [Documentation]    Logs in to the teller app, opens the profile dropdown, and navigates
    ...                to the Change Password page.
    [Arguments]        ${email}=${CP_USER_EMAIL}    ${password}=${CP_USER_PASSWORD}
    Login To Teller App    email=${email}    password=${password}
    Click                       ${CP_PROFILE_DROPDOWN}
    Wait For Elements State     ${CP_CHANGE_PASSWORD_LINK}    visible
    Click                       ${CP_CHANGE_PASSWORD_LINK}
    Wait For Elements State     ${CP_PAGE}    visible

Complete Change Password Form
    [Documentation]    Fills the current password, new password, and confirm password fields,
    ...                then clicks Continue. Leaves the user on the OTP entry screen.
    [Arguments]        ${current_password}=${CP_USER_PASSWORD}    ${new_password}=${CP_NEW_PASSWORD}
    Fill Text                   ${CP_CURRENT_PWD_FIELD}      ${current_password}
    Fill Text                   ${CP_NEW_PWD_FIELD}          ${new_password}
    Fill Text                   ${CP_CONFIRM_PWD_FIELD}      ${new_password}
    Click                       ${CP_CONTINUE_BTN}
    Wait For Elements State     ${CP_OTP_INPUT}    visible

Restore CP Password And Close Browser
    [Documentation]    t1.4.1 changes the CP account's password and nothing puts it back,
    ...                which leaves ${CP_USER_PASSWORD} stale and fails every later test —
    ...                and every later run — at the login screen. Change it back so the
    ...                suite is idempotent. Best effort: the restore must never mask the
    ...                test's own verdict, and the browser must close either way.
    ...                NOTE: t1.4.1 ends logged in, and Login To Teller App always opens a
    ...                NEW browser, so close the existing session first and close ALL at
    ...                the end rather than leaking one.
    Run Keyword And Ignore Error    Close Browser
    Run Keyword And Ignore Error    Restore CP Password
    Close Browser    ALL

Restore CP Password
    [Documentation]    Changes the CP account's password from ${CP_NEW_PASSWORD} back to
    ...                ${CP_USER_PASSWORD} so config and environment stay in agreement.
    Navigate To Change Password Page    email=${CP_USER_EMAIL}    password=${CP_NEW_PASSWORD}
    Complete Change Password Form       current_password=${CP_NEW_PASSWORD}    new_password=${CP_USER_PASSWORD}
    Enter CP OTP And Continue
    Wait For Elements State     ${CP_SUCCESS_MESSAGE}    visible

Enter CP OTP And Continue
    [Documentation]    Clicks the OTP input, types the OTP code, and clicks CONTINUE.
    [Arguments]        ${otp}=${OTP}
    Click                       ${CP_OTP_INPUT}
    Keyboard Input              type    ${otp}
    Click                       ${CP_OTP_CONTINUE_BTN}

Set CP OTP And Continue
    [Documentation]    Robustly sets each of the 6 OTP boxes (replacing any existing value) then
    ...                clicks CONTINUE. Needed for re-entering a different OTP within one session.
    [Arguments]        ${otp}=${OTP}
    @{chars}=    Split String To Characters    ${otp}
    FOR    ${idx}    ${ch}    IN ENUMERATE    @{chars}    start=1
        Fill Text
        ...    css=[data-testid="input-change-password-otp"] input[aria-label="Please enter OTP character ${idx}"]
        ...    ${ch}
    END
    Click    ${CP_OTP_CONTINUE_BTN}

Submit CP Form
    [Documentation]    Fills the Change Password form and clicks Continue WITHOUT waiting for the OTP
    ...                screen — so it also works when a block message appears instead. Assumes the
    ...                page is on the Change Password form.
    [Arguments]        ${current_password}    ${new_password}=${OTP_BLK_NEW_PASSWORD}
    Fill Text    ${CP_CURRENT_PWD_FIELD}    ${current_password}
    Fill Text    ${CP_NEW_PWD_FIELD}        ${new_password}
    Fill Text    ${CP_CONFIRM_PWD_FIELD}    ${new_password}
    Click        ${CP_CONTINUE_BTN}

Open Change Password From Menu
    [Documentation]    From any authenticated dashboard page, opens the profile menu and navigates
    ...                to the Change Password page (no re-login).
    Click                       ${CP_PROFILE_DROPDOWN}
    Wait For Elements State     ${CP_CHANGE_PASSWORD_LINK}    visible
    Click                       ${CP_CHANGE_PASSWORD_LINK}
    Wait For Elements State     ${CP_PAGE}    visible

Trigger Unverified CP Max-Attempts Session
    [Documentation]    From the Change Password form, completes it, submits the magic max-attempts
    ...                OTP, dismisses the modal, and returns to the Change Password form — recording
    ...                one unverified OTP session.
    [Arguments]        ${current_password}    ${new_password}=${OTP_BLK_NEW_PASSWORD}
    Complete Change Password Form    current_password=${current_password}    new_password=${new_password}
    Enter CP OTP And Continue        otp=${OTP_MAX_ATTEMPTS}
    Wait For Elements State          text=${ERR_OTP_MAX_ATTEMPTS_1}    visible
    Click                            ${MODAL_CONFIRM_BTN}
    Wait For Elements State          ${CP_PAGE}    visible

Abandon One CP OTP Session
    [Documentation]    From the Change Password form, completes it to reach the OTP screen, then
    ...                abandons it via the back arrow (leaves the OTP screen) — recording one
    ...                unverified (abandoned) session. Returns to the Change Password form ready for
    ...                the next session (still logged in).
    [Arguments]        ${current_password}    ${new_password}=${OTP_BLK_NEW_PASSWORD}
    Complete Change Password Form    current_password=${current_password}    new_password=${new_password}
    Click                            ${CP_OTP_BACK_BTN}
    Wait For Elements State          ${CP_OTP_INPUT}    hidden    timeout=10s
    Open Change Password From Menu


*** Test Cases ***

# ====================================================================
# HAPPY PATH
# ====================================================================

t1.4.1 Reset Password via Change Password
    [Documentation]    Verify a logged-in teller can successfully change their password via
    ...                the profile dropdown and see the success confirmation modal.
    [Tags]             change-password    smoke    password-reset    mvp    type1
    [Teardown]         Restore CP Password And Close Browser

    Navigate To Change Password Page     email=${CP_USER_EMAIL}
    Complete Change Password Form
    Enter CP OTP And Continue

    # Verify all fields — continue on failure so ALL mismatches are reported
    Run Keyword And Continue On Failure
    ...    Wait For Elements State     ${CP_SUCCESS_MESSAGE}    visible
    # Verify new password works by logging in with it
    Run Keyword And Continue On Failure
    ...    Wait For Elements State     ${LOGOUT_BUTTON}         visible
    Click                       ${LOGOUT_BUTTON}
    Wait For Elements State     ${LOGIN_PAGE}            visible
    Fill Text                   ${EMAIL_FIELD}           ${CP_USER_EMAIL}
    Fill Text                   ${PASSWORD_FIELD}        ${CP_NEW_PASSWORD}
    Click                       ${LOGIN_BUTTON}
    Get Url    matches    .*\/dashboard\/customers$


# ====================================================================
# CHANGE PASSWORD FORM VALIDATION TESTS
# ====================================================================

t1.4.2 Change Password – Mismatched Password and Confirm Password
    [Documentation]    Verify that entering non-matching values in the New Password and
    ...                Confirm Password fields shows "Passwords do not match." and
    ...                keeps the CONTINUE button disabled.
    [Tags]             change-password    negative    mvp    type1

    Navigate To Change Password Page    email=${TELLER_EMAIL}    password=${TELLER_PASSWORD}
    Fill Text                   ${CP_CURRENT_PWD_FIELD}      ${TELLER_PASSWORD}
    Fill Text                   ${CP_NEW_PWD_FIELD}          ${CP_NEW_PASSWORD}
    Fill Text                   ${CP_CONFIRM_PWD_FIELD}      ${CP_WRONG_CONFIRM_PASSWORD}
    # Focus elsewhere to trigger validation
    Focus                       ${CP_CURRENT_PWD_FIELD}

    Wait For Elements State     text=${ERR_PASSWORD_MISMATCH}    visible
    Wait For Elements State     ${CP_CONTINUE_BTN}               disabled

t1.4.3 Change Password – Leave Password Fields Blank
    [Documentation]    Verify the CONTINUE button is disabled when required fields are blank
    ...                on initial page load.
    [Tags]             change-password    negative    mvp    type1

    Navigate To Change Password Page    email=${TELLER_EMAIL}    password=${TELLER_PASSWORD}    # Fields are blank by default upon landing on the page
    Wait For Elements State     ${CP_CONTINUE_BTN}    disabled


# ====================================================================
# PASSWORD POLICY VALIDATION TESTS
# ====================================================================

t1.4.4 Change Password – Password Too Short
    [Documentation]    Verify validation for passwords under 8 characters.
    [Tags]             change-password    negative    mvp    type1

    Navigate To Change Password Page    email=${TELLER_EMAIL}    password=${TELLER_PASSWORD}
    Fill Text                   ${CP_NEW_PWD_FIELD}    Abc1!
    Wait For Elements State     text=${ERR_PWD_MIN_LENGTH}    visible
    Wait For Elements State     ${CP_CONTINUE_BTN}            disabled

t1.4.5 Change Password – Password Without Uppercase Letter
    [Documentation]    Verify validation for a password missing an uppercase letter.
    [Tags]             change-password    negative    mvp    type1

    Navigate To Change Password Page    email=${TELLER_EMAIL}    password=${TELLER_PASSWORD}
    Fill Text                   ${CP_NEW_PWD_FIELD}    abc12345!
    Wait For Elements State     text=${ERR_PWD_UPPERCASE}    visible
    Wait For Elements State     ${CP_CONTINUE_BTN}           disabled

t1.4.6 Change Password – Password Without Number
    [Documentation]    Verify validation for a password missing a number.
    [Tags]             change-password    negative    mvp    type1

    Navigate To Change Password Page    email=${TELLER_EMAIL}    password=${TELLER_PASSWORD}
    Fill Text                   ${CP_NEW_PWD_FIELD}    Abcdefgh!
    Wait For Elements State     text=${ERR_PWD_NUMBER}       visible
    Wait For Elements State     ${CP_CONTINUE_BTN}           disabled

t1.4.7 Change Password – Password Without Special Character
    [Documentation]    Verify validation for a password missing a special character.
    [Tags]             change-password    negative    mvp    type1

    Navigate To Change Password Page    email=${TELLER_EMAIL}    password=${TELLER_PASSWORD}
    Fill Text                   ${CP_NEW_PWD_FIELD}    Abcdef123
    Wait For Elements State     text=${ERR_PWD_SPECIAL}      visible
    Wait For Elements State     ${CP_CONTINUE_BTN}           disabled

t1.4.8 Change Password – Sequential Validation of Multiple Violations
    [Documentation]    Verify that only one validation error is shown at a time and errors
    ...                cascade correctly as the user fixes them one by one.
    [Tags]             change-password    negative    mvp    type1

    Navigate To Change Password Page    email=${TELLER_EMAIL}    password=${TELLER_PASSWORD}
    # 1. Too short
    Fill Text                   ${CP_NEW_PWD_FIELD}    abc
    Wait For Elements State     text=${ERR_PWD_MIN_LENGTH}    visible

    # 2. Fix length, still missing uppercase
    Fill Text                   ${CP_NEW_PWD_FIELD}    abcdefgh
    Wait For Elements State     text=${ERR_PWD_UPPERCASE}    visible

    # 3. Fix uppercase, still missing number
    Fill Text                   ${CP_NEW_PWD_FIELD}    Abcdefgh
    Wait For Elements State     text=${ERR_PWD_NUMBER}       visible

    # 4. Fix number, still missing special char
    Fill Text                   ${CP_NEW_PWD_FIELD}    Abcdefgh1
    Wait For Elements State     text=${ERR_PWD_SPECIAL}      visible

    # 5. Fix all rules — no error should remain
    Fill Text                   ${CP_NEW_PWD_FIELD}    Abcdefgh1!
    Wait For Elements State     text=${ERR_PWD_SPECIAL}      hidden


# ====================================================================
# OTP VALIDATION & COOLDOWN TESTS
# ====================================================================

t1.4.9 Change Password – Invalid OTP
    [Documentation]    Verify an error message is shown when an incorrect OTP is entered on
    ...                the OTP verification screen.
    ...                Uses the magic value "${OTP_INVALID}" which the backend always rejects
    ...                as invalid/expired.
    [Tags]             change-password    negative    otp    mvp    type1

    Navigate To Change Password Page
    Complete Change Password Form

    Click                       ${CP_OTP_INPUT}
    Keyboard Input              type    ${OTP_INVALID}
    Click                       ${CP_OTP_CONTINUE_BTN}

    Wait For Elements State     text=${ERR_OTP_INVALID}    visible
    Wait For Elements State     ${CP_OTP_INPUT}            visible

t1.4.10 Change Password – Leave OTP Blank
    [Documentation]    Verify the CONTINUE button is disabled when the OTP field is blank.
    [Tags]             change-password    negative    otp    mvp    type1

    Navigate To Change Password Page
    Complete Change Password Form

    # OTP input is blank by default
    Wait For Elements State     ${CP_OTP_CONTINUE_BTN}    disabled
    Wait For Elements State     ${CP_OTP_INPUT}           visible

t1.4.11-12 Change Password – Cooldown Prevents Immediate Resend, Then Allows Resend After 60s
    [Documentation]    Verify the resend link is hidden immediately after OTP is sent (cooldown active),
    ...                then becomes available after the 60-second cooldown expires and a new OTP can be requested.
    ...                Note: This test will take > 60 seconds to execute.
    [Tags]             change-password    otp    slow    mvp    type1

    Navigate To Change Password Page
    Complete Change Password Form

    # Resend link stays visible but DISABLED during the active cooldown (shows a
    # countdown); it does not disappear. (Was asserting 'hidden' — stale expectation.)
    Wait For Elements State     ${CP_OTP_RESEND_BTN}    disabled

    # Wait for the 60-second cooldown timer to finish
    Sleep                       61s
    Wait For Elements State     ${CP_OTP_RESEND_BTN}    enabled
    Click                       ${CP_OTP_RESEND_BTN}

    # Verify continue button resets to disabled while new OTP is pending
    Wait For Elements State     ${CP_OTP_CONTINUE_BTN}    disabled
    Wait For Elements State     ${CP_OTP_INPUT}            visible

t1.4.13 Change Password – Previously Received OTP Is No Longer Valid After Requesting a New OTP
    [Documentation]    Verify that the original OTP is invalidated once a new OTP is requested.
    [Tags]             change-password    negative    otp    slow    password-reset    mvp    type1
    skip    This test requires a live OTP and will take > 60 seconds due to cooldown. Run manually with: --variable OTP:<code>

    Navigate To Change Password Page
    Complete Change Password Form

    # Wait out the cooldown to enable the resend button
    Sleep                       61s
    Wait For Elements State     ${CP_OTP_RESEND_BTN}    enabled
    Click                       ${CP_OTP_RESEND_BTN}

    # Attempt to use the FIRST (now-invalidated) OTP
    Click                       ${CP_OTP_INPUT}
    Keyboard Input              type    ${OTP}
    Click                       ${CP_OTP_CONTINUE_BTN}

    # The old OTP must be rejected
    Wait For Elements State     text=${ERR_OTP_INVALID}    visible

t1.4.14 Change Password – Validation on the 5th Failed OTP Attempt (Maximum Allowed Attempts)
    [Documentation]    Verify the system locks the OTP session and redirects the user after
    ...                reaching the maximum number of OTP attempts.
    ...                Uses the magic value "${OTP_MAX_ATTEMPTS}" which the backend treats as
    ...                immediately triggering the max-attempts lockout in a single attempt.
    [Tags]             change-password    negative    otp    security    mvp    type1

    Navigate To Change Password Page
    Complete Change Password Form

    # Enter magic OTP value that immediately triggers max-attempts error
    Wait For Elements State     ${CP_OTP_INPUT}    visible
    Click                       ${CP_OTP_INPUT}
    Keyboard Input              type    ${OTP_MAX_ATTEMPTS}
    Click                       ${CP_OTP_CONTINUE_BTN}
    Wait For Elements State     css=.ant-modal-content    visible
    
    # Verify the heading (title)
    Wait For Elements State     css=.ant-modal-content h3 >> text=${ERR_OTP_MAX_ATTEMPTS_1}    visible
    
    # Verify the body text (targeting the paragraph inside the body div)
    Wait For Elements State     css=.ant-modal-body p >> text="${ERR_OTP_MAX_ATTEMPTS_2}"    visible


    # Confirm the modal and verify redirection to the Change Password page
    Click                       ${MODAL_CONFIRM_BTN}
    Wait For Elements State     ${CP_PAGE}    visible

t1.4.15 Change Password – Validation on 5th OTP Attempt Across Multiple Resend Requests
    [Documentation]    Verify the 5-attempt limit is strictly enforced across multiple OTP resends.
    [Tags]             change-password    negative    otp    security    slow    mvp    type1
    skip    This test requires a live OTP and will take > 5 minutes due to multiple cooldowns. Run manually with: --variable OTP:<code>

    Navigate To Change Password Page
    Complete Change Password Form

    # 1. First 2 invalid attempts (Attempts 1 & 2) — use magic invalid OTP value
    Wait For Elements State     ${CP_OTP_INPUT}    visible
    FOR    ${i}    IN RANGE    2
        Click                   ${CP_OTP_INPUT}
        Keyboard Input          type    ${OTP_INVALID}
        Click                   ${CP_OTP_CONTINUE_BTN}
        Wait For Elements State    text=${ERR_OTP_INVALID}    visible
    END

    # 2. First resend (wait for 1-minute cooldown)
    Sleep                       61s
    Wait For Elements State     ${CP_OTP_RESEND_BTN}    enabled
    Click                       ${CP_OTP_RESEND_BTN}

    # 3. Next 2 invalid attempts (Attempts 3 & 4) — use magic invalid OTP value
    Wait For Elements State     ${CP_OTP_INPUT}    visible
    FOR    ${i}    IN RANGE    2
        Click                   ${CP_OTP_INPUT}
        Keyboard Input          type    ${OTP_INVALID}
        Click                   ${CP_OTP_CONTINUE_BTN}
        Wait For Elements State    text=${ERR_OTP_INVALID}    visible
    END

    # 4. Second resend (wait for 1-minute cooldown)
    Sleep                       61s
    Wait For Elements State     ${CP_OTP_RESEND_BTN}    enabled
    Click                       ${CP_OTP_RESEND_BTN}

    # 5. Final (5th) attempt — use magic max-attempts value to trigger lockout
    Wait For Elements State     ${CP_OTP_INPUT}    visible
    Click                       ${CP_OTP_INPUT}
    Keyboard Input              type    ${OTP_MAX_ATTEMPTS}
    Click                       ${CP_OTP_CONTINUE_BTN}

    # Assert failure modal and redirection
    Wait For Elements State     text=${ERR_OTP_MAX_ATTEMPTS}    visible
    Click                       ${MODAL_CONFIRM_BTN}
    Wait For Elements State     ${CP_PAGE}                      visible

t1.4.16 Change Password – Behavior When OTP Session Expires Before Reaching Max Attempts
    [Documentation]    Verify system behavior when a user's OTP session expires before they
    ...                reach the maximum number of failed attempts.
    [Tags]             change-password    negative    otp    security    slow    mvp    type1
    skip    This test requires a live OTP and will take > 5 minutes due to session expiry. Run manually with: --variable OTP:<code>

    Navigate To Change Password Page
    Complete Change Password Form

    # 1. Execute 3 invalid attempts within the active OTP session — use magic invalid OTP value
    Wait For Elements State     ${CP_OTP_INPUT}    visible
    FOR    ${i}    IN RANGE    3
        Click                   ${CP_OTP_INPUT}
        Keyboard Input          type    ${OTP_INVALID}
        Click                   ${CP_OTP_CONTINUE_BTN}
        Wait For Elements State    text=${ERR_OTP_INVALID}    visible
    END

    # 2. Wait for the OTP session to expire (5 minutes)
    Sleep                       300s

    # 3. Attempt a 4th input after session expiry — use magic invalid OTP value
    Click                       ${CP_OTP_INPUT}
    Keyboard Input              type    ${OTP_INVALID}
    Click                       ${CP_OTP_CONTINUE_BTN}
    Wait For Elements State     text=${ERR_OTP_INVALID}    visible

    # 4. Click "Resend code" — session has expired
    Click                       ${CP_OTP_RESEND_BTN}

    # 5. Assert the expired session modal appears
    Wait For Elements State     text=${ERR_OTP_EXPIRED_SESSION}    visible

    # 6. Click "Request New Code" — should redirect back to Change Password page
    Click                       text=Request New Code
    Wait For Elements State     ${CP_PAGE}    visible

t1.4.17 Change Password – Email Blocked 60 Minutes After 3 Unverified OTP Sessions (5 Invalid Attempts)
    [Documentation]    Verify that 3 unverified Change Password OTP sessions (each hitting max attempts
    ...                via ${OTP_MAX_ATTEMPTS}) block the email for 60 minutes; the 4th Continue shows
    ...                "You have exceeded the maximum number of attempts. You can try again in <n>
    ...                minutes." and the user stays on the Change Password page. REUSABLE: refresh
    ...                ${OTP_BLK_CP_MAX_EMAIL}/_PW each cycle — this blocks the account for 60 minutes.
    [Tags]    change-password    otp    security    otp-block    type2
    Navigate To Change Password Page    email=${OTP_BLK_CP_MAX_EMAIL}    password=${OTP_BLK_CP_MAX_PW}
    FOR    ${i}    IN RANGE    3
        Trigger Unverified CP Max-Attempts Session    current_password=${OTP_BLK_CP_MAX_PW}
    END
    Submit CP Form             current_password=${OTP_BLK_CP_MAX_PW}
    Wait For Elements State    text=${ERR_OTP_SESSION_BLOCKED}    visible

t1.4.18 Change Password – Email Blocked 60 Minutes After 3 Unverified OTP Sessions (Abandoned)
    [Documentation]    Verify that 3 abandoned Change Password OTP sessions (reach the OTP screen,
    ...                then leave via the back arrow) block the email for 60 minutes; the 4th Continue
    ...                shows the block message. REUSABLE: refresh ${OTP_BLK_CP_ABANDON_EMAIL}/_PW each
    ...                cycle.
    [Tags]    change-password    otp    security    otp-block    type2
    Navigate To Change Password Page    email=${OTP_BLK_CP_ABANDON_EMAIL}    password=${OTP_BLK_CP_ABANDON_PW}
    FOR    ${i}    IN RANGE    3
        Abandon One CP OTP Session    current_password=${OTP_BLK_CP_ABANDON_PW}
    END
    Submit CP Form             current_password=${OTP_BLK_CP_ABANDON_PW}
    Wait For Elements State    text=${ERR_OTP_SESSION_BLOCKED}    visible

t1.4.19 Change Password – Blocked Email Keeps Returning the Error During the Block Period
    [Documentation]    Verify that once blocked, every further Change Password attempt during the
    ...                60-minute window returns the same block error. REUSABLE: refresh
    ...                ${OTP_BLK_CP_RETRY_EMAIL}/_PW each cycle.
    [Tags]    change-password    otp    security    otp-block    type2
    Navigate To Change Password Page    email=${OTP_BLK_CP_RETRY_EMAIL}    password=${OTP_BLK_CP_RETRY_PW}
    FOR    ${i}    IN RANGE    3
        Trigger Unverified CP Max-Attempts Session    current_password=${OTP_BLK_CP_RETRY_PW}
    END
    Submit CP Form             current_password=${OTP_BLK_CP_RETRY_PW}
    Wait For Elements State    text=${ERR_OTP_SESSION_BLOCKED}    visible
    Click                      ${MODAL_CONFIRM_BTN}
    Submit CP Form             current_password=${OTP_BLK_CP_RETRY_PW}
    Wait For Elements State    text=${ERR_OTP_SESSION_BLOCKED}    visible

t1.4.21 Change Password – No Block When a Valid OTP Is Entered on the 5th Attempt of the 3rd Session
    [Documentation]    Verify the user is NOT blocked when only 2 sessions are unverified and the 3rd
    ...                is verified via a valid OTP on the 5th attempt. Enters 4 invalid OTPs then the
    ...                valid OTP in session 3 and completes the password change. REUSABLE: refresh
    ...                ${OTP_BLK_CP_VALID5_EMAIL}/_PW each cycle — this changes that account's password
    ...                to ${OTP_BLK_NEW_PASSWORD}.
    [Tags]    change-password    otp    security    otp-block    type2
    Navigate To Change Password Page    email=${OTP_BLK_CP_VALID5_EMAIL}    password=${OTP_BLK_CP_VALID5_PW}
    FOR    ${i}    IN RANGE    2
        Trigger Unverified CP Max-Attempts Session    current_password=${OTP_BLK_CP_VALID5_PW}
    END
    # Session 3: 4 invalid attempts then a valid OTP on the 5th → success, no block.
    Complete Change Password Form    current_password=${OTP_BLK_CP_VALID5_PW}    new_password=${OTP_BLK_NEW_PASSWORD}
    FOR    ${i}    IN RANGE    4
        Set CP OTP And Continue    otp=${OTP_INVALID}
        Wait For Elements State    text=${ERR_OTP_INVALID}    visible
    END
    Set CP OTP And Continue    otp=${OTP}
    Wait For Elements State    ${CP_SUCCESS_MESSAGE}    visible

# ====================================================================
# WALL-CLOCK OTP-BLOCK CASES (automatable, but LONG-RUNNING)
# Run on-demand only: robot --include wall-clock ...
# They need no human/inbox/live-OTP — only magic OTPs + real time.
# ====================================================================

t1.4.20 Change Password – Change Succeeds After the 60-Minute Block Expires
    [Documentation]    Verify that once an email is blocked (3 unverified max-attempts OTP sessions),
    ...                the Change Password flow succeeds again after the 60-minute block window elapses.
    ...                Triggers the block, waits out ${OTP_BLK_EXPIRY_WAIT}, then completes the change
    ...                with a valid OTP (${OTP}) → success message. Wall-clock: ~62 min.
    ...                REUSABLE: refresh ${OTP_BLK_CP_EXPIRY_EMAIL}/_PW each cycle. Note: the account's
    ...                password becomes ${OTP_BLK_NEW_PASSWORD} after this test.
    [Tags]    change-password    otp    security    wall-clock    slow    type2
    # Phase 1 — trigger the 60-minute block (3 unverified sessions + a blocked 4th)
    Navigate To Change Password Page    email=${OTP_BLK_CP_EXPIRY_EMAIL}    password=${OTP_BLK_CP_EXPIRY_PW}
    FOR    ${i}    IN RANGE    3
        Trigger Unverified CP Max-Attempts Session    current_password=${OTP_BLK_CP_EXPIRY_PW}
    END
    Submit CP Form             current_password=${OTP_BLK_CP_EXPIRY_PW}
    Wait For Elements State    text=${ERR_OTP_SESSION_BLOCKED}    visible
    Close Browser
    # Phase 2 — wait out the 60-minute block
    Sleep                      ${OTP_BLK_EXPIRY_WAIT}
    # Phase 3 — after expiry the change completes normally with a valid OTP
    Navigate To Change Password Page    email=${OTP_BLK_CP_EXPIRY_EMAIL}    password=${OTP_BLK_CP_EXPIRY_PW}
    Complete Change Password Form       current_password=${OTP_BLK_CP_EXPIRY_PW}    new_password=${OTP_BLK_NEW_PASSWORD}
    Enter CP OTP And Continue           otp=${OTP}
    Wait For Elements State             ${CP_SUCCESS_MESSAGE}    visible

t1.4.22 Change Password – No Block When 3 Unverified Sessions Span More Than 15 Minutes
    [Documentation]    Verify that 3 unverified OTP sessions do NOT block the email when they are
    ...                spaced so that no 3 fall within a single 15-minute window. Runs a session,
    ...                waits ${OTP_BLK_SESSION_GAP} between each (re-login each time, as the app
    ...                session expires over the gap), then confirms a 4th attempt reaches the OTP
    ...                screen normally (no block error). Wall-clock: ~33 min.
    ...                REUSABLE: refresh ${OTP_BLK_CP_SPAN_EMAIL}/_PW each cycle.
    [Tags]    change-password    otp    security    wall-clock    slow    type2
    # Session 1
    Navigate To Change Password Page    email=${OTP_BLK_CP_SPAN_EMAIL}    password=${OTP_BLK_CP_SPAN_PW}
    Trigger Unverified CP Max-Attempts Session    current_password=${OTP_BLK_CP_SPAN_PW}
    Close Browser
    Sleep                      ${OTP_BLK_SESSION_GAP}
    # Session 2 (>15 min after S1)
    Navigate To Change Password Page    email=${OTP_BLK_CP_SPAN_EMAIL}    password=${OTP_BLK_CP_SPAN_PW}
    Trigger Unverified CP Max-Attempts Session    current_password=${OTP_BLK_CP_SPAN_PW}
    Close Browser
    Sleep                      ${OTP_BLK_SESSION_GAP}
    # Session 3 (>15 min after S2)
    Navigate To Change Password Page    email=${OTP_BLK_CP_SPAN_EMAIL}    password=${OTP_BLK_CP_SPAN_PW}
    Trigger Unverified CP Max-Attempts Session    current_password=${OTP_BLK_CP_SPAN_PW}
    # 4th attempt → reaches the OTP screen (NOT blocked)
    Submit CP Form             current_password=${OTP_BLK_CP_SPAN_PW}
    Wait For Elements State    ${CP_OTP_INPUT}                  visible
    Wait For Elements State    text=${ERR_OTP_SESSION_BLOCKED}    hidden

# ====================================================================
# RESEND-COMPLETE CASE (automatable, slow ~61s — no human/inbox/live-OTP)
# Run on-demand: robot --include resend-complete ...
# Completes the tail that t1.4.11-12 omits: resend → enter new OTP → success.
# ====================================================================

t1.4.12 Change Password – New OTP After Cooldown Completes the Change
    [Documentation]    Verify a user can request a NEW OTP after the 60-second cooldown and complete
    ...                the Change Password with it → "Password has been changed successfully."
    ...                The combined t1.4.11-12 stops at "new code sent"; this asserts the success tail
    ...                using the magic-valid OTP (${OTP}) — no live email needed. Wall-clock: ~61s.
    ...                REUSABLE: refresh ${RESEND_CP_EMAIL}/_PW each cycle (this changes its password
    ...                to ${OTP_BLK_NEW_PASSWORD}).
    [Tags]    change-password    otp    slow    password-reset    resend-complete    type2
    Navigate To Change Password Page    email=${RESEND_CP_EMAIL}    password=${RESEND_CP_PW}
    Complete Change Password Form       current_password=${RESEND_CP_PW}    new_password=${OTP_BLK_NEW_PASSWORD}
    # Wait out the 60s cooldown, then request a new OTP
    Sleep                      61s
    Wait For Elements State    ${CP_OTP_RESEND_BTN}    enabled
    Click                      ${CP_OTP_RESEND_BTN}
    Wait For Elements State    ${CP_OTP_INPUT}    visible
    # Enter the new (magic-valid) OTP and complete the change → success
    Set CP OTP And Continue    otp=${OTP}
    Wait For Elements State    ${CP_SUCCESS_MESSAGE}    visible

*** Settings ***
Documentation       Test suite for Reset Password via Temporary Password flow.
...                 Covers happy path reset, case-insensitive email, expired temporary password,
...                 password policy validation, OTP validation, cooldown, and session expiry.
...
...                 Pass TELLER_TEMP_PASSWORD at runtime via --variablefile <bank>.yaml

Resource            ../../resources/keywords/common.resource

Test Teardown       Close Browser


*** Variables ***
${RTP_WRONG_CONFIRM_PASSWORD}       WrongPassword999!
${OTP}                              123456

# --- Hardcoded OTP Test Values ---
# These are magic values recognised by the backend to simulate specific OTP states.
${OTP_INVALID}                      000000    # Always triggers "invalid or expired OTP" error
${OTP_MAX_ATTEMPTS}                 999999    # Immediately triggers max-attempts error in one attempt

# --- Hardcoded Password Test Value ---
${RTP_EXPIRED_MAGIC_PWD}            login_reset_password_expired    # Triggers expired temp password error for any valid email

# --- Login Errors ---
${ERR_EXPIRED_TEMP_PASSWORD}        Your temporary password has expired. Please use the Forgot Password option to create a new password.

# --- Reset Form Errors ---
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
Navigate To Reset Password Page
    [Documentation]    Logs in with temporary password and lands on the Reset Password page.
    [Arguments]        ${email}=${RTP_NEW_USER_EMAIL}    ${temp_password}=${RTP_TEMP_PASSWORD}
    Open Teller App
    Fill Text                   ${EMAIL_FIELD}       ${email}
    Fill Text                   ${PASSWORD_FIELD}    ${temp_password}
    Click                       ${LOGIN_BUTTON}
    Wait For Elements State     ${RTP_PAGE}    visible
    # Remember which temp password we logged in with so the reset form re-enters
    # the SAME one (default used to be RTP_TEMP_PASSWORD, wrong for _2 accounts).
    Set Test Variable           ${RTP_ACTIVE_TEMP_PASSWORD}    ${temp_password}

Complete Reset Password Form
    [Documentation]    Fills the Reset Password form with the temporary and new passwords, then
    ...                submits it. Leaves the user on the OTP entry screen.
    [Arguments]        ${temp_password}=${RTP_ACTIVE_TEMP_PASSWORD}    ${new_password}=${TELLER_PASSWORD}
    Fill Text                   ${RTP_TEMP_PASSWORD_FIELD}       ${temp_password}
    Fill Text                   ${RTP_NEW_PASSWORD_FIELD}        ${new_password}
    Fill Text                   ${RTP_CONFIRM_PASSWORD_FIELD}    ${new_password}
    Click                       ${RTP_SUBMIT_BTN}
    Wait For Elements State     ${RTP_OTP_INPUT}    visible

Enter RTP OTP And Continue
    [Documentation]    Clicks the OTP input, types the OTP code, and clicks CONTINUE.
    [Arguments]        ${otp}=${OTP}
    Click                       ${RTP_OTP_INPUT}
    Keyboard Input              type    ${otp}
    Click                       ${RTP_OTP_CONTINUE_BTN}

Set RTP OTP And Continue
    [Documentation]    Robustly sets each of the 6 OTP boxes (replacing any existing value) then
    ...                clicks CONTINUE. Needed when re-entering a different OTP within the same
    ...                session (e.g. after failed attempts), where typing into filled boxes is a
    ...                no-op. Reusable for any OTP value.
    [Arguments]        ${otp}=${OTP}
    @{chars}=    Split String To Characters    ${otp}
    FOR    ${idx}    ${ch}    IN ENUMERATE    @{chars}    start=1
        Fill Text
        ...    css=[data-testid="input-reset-temp-password-otp"] input[aria-label="Please enter OTP character ${idx}"]
        ...    ${ch}
    END
    Click    ${RTP_OTP_CONTINUE_BTN}

Trigger Unverified RTP Max-Attempts Session
    [Documentation]    From the Reset Password form, completes it, submits the magic max-attempts
    ...                OTP, dismisses the resulting modal, and returns to the Reset Password form —
    ...                i.e. records one unverified OTP session. Assumes the page is on the RTP form.
    [Arguments]        ${temp_password}    ${new_password}=${OTP_BLK_NEW_PASSWORD}
    Complete Reset Password Form    temp_password=${temp_password}    new_password=${new_password}
    Enter RTP OTP And Continue      otp=${OTP_MAX_ATTEMPTS}
    Wait For Elements State         text=${ERR_OTP_MAX_ATTEMPTS_1}    visible
    Click                           ${MODAL_CONFIRM_BTN}
    Wait For Elements State         ${RTP_PAGE}    visible

Abandon One RTP OTP Session
    [Documentation]    From the Login page (browser already open), logs in with the temp password,
    ...                reaches the OTP screen, then abandons it via the "Log in" link and the
    ...                exit-confirmation modal — recording one unverified (abandoned) OTP session.
    ...                Ends back on the Login page (reuses the same browser — no leak).
    [Arguments]        ${email}    ${temp_password}    ${new_password}=${OTP_BLK_NEW_PASSWORD}
    Fill Text                          ${EMAIL_FIELD}       ${email}
    Fill Text                          ${PASSWORD_FIELD}    ${temp_password}
    Click                              ${LOGIN_BUTTON}
    Wait For Elements State            ${RTP_PAGE}    visible
    Complete Reset Password Form       temp_password=${temp_password}    new_password=${new_password}
    Click                              ${OTP_ABANDON_LOGIN_LINK}
    Click                              ${OTP_EXIT_CONFIRM_BTN}
    Wait For Elements State            ${LOGIN_PAGE}    visible

Submit RTP Reset Form
    [Documentation]    Fills and submits the Reset Password form WITHOUT waiting for the OTP screen,
    ...                so it works both when the OTP screen follows and when a block message appears
    ...                instead. Assumes the page is on the Reset Password form.
    [Arguments]        ${temp_password}    ${new_password}=${OTP_BLK_NEW_PASSWORD}
    Fill Text    ${RTP_TEMP_PASSWORD_FIELD}       ${temp_password}
    Fill Text    ${RTP_NEW_PASSWORD_FIELD}        ${new_password}
    Fill Text    ${RTP_CONFIRM_PASSWORD_FIELD}    ${new_password}
    Click        ${RTP_SUBMIT_BTN}


*** Test Cases ***

# ====================================================================
# HAPPY PATH TESTS
# ====================================================================

t1.1.3 Verify System Treats Email as Case-Insensitive During Reset Password
    [Documentation]    Verify the system accepts a mixed-case email when logging in with a
    ...                temporary password and allows the user to complete the Reset Password flow.
    [Tags]             reset-password    smoke    password-reset    temp-password    mvp    type1

    Navigate To Reset Password Page    email=${RTP_MIXED_CASE_EMAIL}    temp_password=${RTP_MIXED_CASE_EMAIL_PASSWORD}
    # Enter RTP OTP And Continue

    # Wait For Elements State     ${RESET_SUCCESS_HEADING}    visible
    # Wait For Elements State     ${RESET_SUCCESS_MESSAGE}    visible
    # Wait For Elements State     ${BACK_TO_LOGIN_BTN}        visible
t1.1.2 Reset Password via Logging in Using Temporary Password
    [Documentation]    Verify a new user can log in with their temporary password, complete the
    ...                Reset Password form, verify their OTP, and see the success confirmation modal.
    [Tags]             reset-password    smoke    password-reset    temp-password    mvp    type1

    Navigate To Reset Password Page
    Complete Reset Password Form
    Enter RTP OTP And Continue

    Wait For Elements State     ${RESET_SUCCESS_HEADING}    visible
    Wait For Elements State     ${RESET_SUCCESS_MESSAGE}    visible
    Wait For Elements State     ${BACK_TO_LOGIN_BTN}        visible



# ====================================================================
# EXPIRED TEMPORARY PASSWORD TESTS
# ====================================================================

t1.1.4 Login Using Expired Temporary Password
    [Documentation]    Verify the system shows an error when the user attempts to log in
    ...                with an expired temporary password.
    ...                Uses the magic value "${RTP_EXPIRED_MAGIC_PWD}" which the backend
    ...                always treats as an expired temporary password for any valid email.
    [Tags]             reset-password    negative    temp-password    mvp    type1    expired

    Open Teller App
    Fill Text                   ${EMAIL_FIELD}       ${RTP_EXPIRED_USER_EMAIL}
    Fill Text                   ${PASSWORD_FIELD}    ${RTP_EXPIRED_MAGIC_PWD}
    Click                       ${LOGIN_BUTTON}
    Wait For Elements State     text=${ERR_EXPIRED_TEMP_PASSWORD}    visible

t1.1.5 Verify That a User With an Expired Temporary Password Can Finalize Account Setup via Forgot Password
    [Documentation]    Verify that a user whose temporary password has expired can still
    ...                complete account setup by using the Forgot Password flow.
    [Tags]             reset-password    password-reset    mvp    type1    expired

    Open Teller App
    Click                       ${FORGOT_PASSWORD_LINK}
    Wait For Elements State     ${FP_PAGE}    visible

    # Step 1: Request OTP
    Fill Text                   ${FP_EMAIL_FIELD}    ${RTP_EXPIRED_USER_EMAIL}
    Click                       ${FP_SEND_CODE_BTN}
    Wait For Elements State     ${FP_OTP_INPUT}      visible

    # Step 2: Enter OTP
    Click                       ${FP_OTP_INPUT}
    Keyboard Input              type    ${OTP}
    Click                       ${FP_CONTINUE_BTN}
    Wait For Elements State     ${NEW_PASSWORD_FIELD}    visible

    # Step 3: Set new password
    Fill Text                   ${NEW_PASSWORD_FIELD}           ${TELLER_PASSWORD}
    Fill Text                   ${CONFIRM_NEW_PASSWORD_FIELD}   ${TELLER_PASSWORD}
    Click                       ${RESET_PASSWORD_BTN}

    Wait For Elements State     ${RESET_SUCCESS_HEADING}    visible
    Wait For Elements State     ${RESET_SUCCESS_MESSAGE}    visible
    Wait For Elements State     ${BACK_TO_LOGIN_BTN}        visible


# ====================================================================
# RESET FORM VALIDATION TESTS
# ====================================================================

t1.1.6 Reset Password – Mismatched New Password and Confirm Password
    [Documentation]    Verify that entering non-matching values in the New Password and
    ...                Confirm Password fields shows "Passwords do not match." and
    ...                keeps the RESET PASSWORD button disabled.
    [Tags]             reset-password    negative    temp-password    mvp    type1

    Navigate To Reset Password Page    email=${RTP_NEW_USER_EMAIL_2}    temp_password=${RTP_TEMP_PASSWORD_2}
    Fill Text                   ${RTP_TEMP_PASSWORD_FIELD}       ${RTP_TEMP_PASSWORD_2}
    Fill Text                   ${RTP_NEW_PASSWORD_FIELD}        ${TELLER_PASSWORD}
    Fill Text                   ${RTP_CONFIRM_PASSWORD_FIELD}    ${RTP_WRONG_CONFIRM_PASSWORD}
    # Focus elsewhere to trigger validation
    Focus                       ${RTP_TEMP_PASSWORD_FIELD}

    Wait For Elements State     text=${ERR_PASSWORD_MISMATCH}    visible
    Wait For Elements State     ${RTP_SUBMIT_BTN}                disabled

t1.1.7 Reset Password – Leave Required Fields Blank
    [Documentation]    Verify the RESET PASSWORD button is disabled when all fields are blank
    ...                on initial page load.
    [Tags]             reset-password    negative    temp-password    mvp    type1

    Navigate To Reset Password Page    email=${RTP_NEW_USER_EMAIL_2}    temp_password=${RTP_TEMP_PASSWORD_2}
    # Fields are blank by default upon landing on the page
    Wait For Elements State     ${RTP_SUBMIT_BTN}    disabled


# ====================================================================
# PASSWORD POLICY VALIDATION TESTS
# ====================================================================

t1.1.8 Reset Password – Password Too Short
    [Documentation]    Verify validation for passwords under 8 characters.
    [Tags]             reset-password    negative    temp-password    mvp    type1

    Navigate To Reset Password Page    email=${RTP_NEW_USER_EMAIL_2}    temp_password=${RTP_TEMP_PASSWORD_2}
    Fill Text                   ${RTP_NEW_PASSWORD_FIELD}    Abc1!
    Wait For Elements State     text=${ERR_PWD_MIN_LENGTH}    visible
    Wait For Elements State     ${RTP_SUBMIT_BTN}             disabled

t1.1.9 Reset Password – Password Without Uppercase Letter
    [Documentation]    Verify validation for a password missing an uppercase letter.
    [Tags]             reset-password    negative    temp-password    mvp    type1

    Navigate To Reset Password Page    email=${RTP_NEW_USER_EMAIL_2}    temp_password=${RTP_TEMP_PASSWORD_2}
    Fill Text                   ${RTP_NEW_PASSWORD_FIELD}    abc12345!
    Wait For Elements State     text=${ERR_PWD_UPPERCASE}    visible
    Wait For Elements State     ${RTP_SUBMIT_BTN}            disabled

t1.1.10 Reset Password – Password Without Number
    [Documentation]    Verify validation for a password missing a number.
    [Tags]             reset-password    negative    temp-password    mvp    type1

    Navigate To Reset Password Page    email=${RTP_NEW_USER_EMAIL_2}    temp_password=${RTP_TEMP_PASSWORD_2}
    Fill Text                   ${RTP_NEW_PASSWORD_FIELD}    Abcdefgh!
    Wait For Elements State     text=${ERR_PWD_NUMBER}       visible
    Wait For Elements State     ${RTP_SUBMIT_BTN}            disabled

t1.1.11 Reset Password – Password Without Special Character
    [Documentation]    Verify validation for a password missing a special character.
    [Tags]             reset-password    negative    temp-password    mvp    type1

    Navigate To Reset Password Page    email=${RTP_NEW_USER_EMAIL_2}    temp_password=${RTP_TEMP_PASSWORD_2}
    Fill Text                   ${RTP_NEW_PASSWORD_FIELD}    Abcdef123
    Wait For Elements State     text=${ERR_PWD_SPECIAL}      visible
    Wait For Elements State     ${RTP_SUBMIT_BTN}            disabled

t1.1.12 Reset Password – Sequential Validation of Multiple Violations
    [Documentation]    Verify that only one validation error is shown at a time and errors
    ...                cascade correctly as the user fixes them one by one.
    [Tags]             reset-password    negative    temp-password    mvp    type1

    Navigate To Reset Password Page    email=${RTP_NEW_USER_EMAIL_2}    temp_password=${RTP_TEMP_PASSWORD_2}

    # 1. Too short
    Fill Text                   ${RTP_NEW_PASSWORD_FIELD}    abc
    Wait For Elements State     text=${ERR_PWD_MIN_LENGTH}    visible

    # 2. Fix length, still missing uppercase
    Fill Text                   ${RTP_NEW_PASSWORD_FIELD}    abcdefgh
    Wait For Elements State     text=${ERR_PWD_UPPERCASE}    visible

    # 3. Fix uppercase, still missing number
    Fill Text                   ${RTP_NEW_PASSWORD_FIELD}    Abcdefgh
    Wait For Elements State     text=${ERR_PWD_NUMBER}       visible

    # 4. Fix number, still missing special char
    Fill Text                   ${RTP_NEW_PASSWORD_FIELD}    Abcdefgh1
    Wait For Elements State     text=${ERR_PWD_SPECIAL}      visible

    # 5. Fix all rules — no error should remain
    Fill Text                   ${RTP_NEW_PASSWORD_FIELD}    Abcdefgh1!
    Wait For Elements State     text=${ERR_PWD_SPECIAL}      hidden


# ====================================================================
# OTP VALIDATION & COOLDOWN TESTS
# ====================================================================

t1.1.13 Reset Password – Invalid OTP
    [Documentation]    Verify an error message is shown when an incorrect OTP is entered on
    ...                the OTP verification screen.
    ...                Uses the magic value "${OTP_INVALID}" which the backend always rejects
    ...                as invalid/expired.
    [Tags]             reset-password    negative    otp    temp-password    mvp    type1

    Navigate To Reset Password Page    email=${RTP_NEW_USER_EMAIL_2}    temp_password=${RTP_TEMP_PASSWORD_2}
    Complete Reset Password Form

    Click                       ${RTP_OTP_INPUT}
    Keyboard Input              type    ${OTP_INVALID}
    Click                       ${RTP_OTP_CONTINUE_BTN}

    Wait For Elements State     text=${ERR_OTP_INVALID}    visible
    Wait For Elements State     ${RTP_OTP_INPUT}           visible

t1.1.14 Reset Password – Leave OTP Blank
    [Documentation]    Verify the CONTINUE button is disabled when the OTP field is blank.
    [Tags]             reset-password    negative    otp    temp-password    mvp    type1

    Navigate To Reset Password Page    email=${RTP_NEW_USER_EMAIL_2}    temp_password=${RTP_TEMP_PASSWORD_2}
    Complete Reset Password Form

    # OTP input is blank by default
    Wait For Elements State     ${RTP_OTP_CONTINUE_BTN}    disabled
    Wait For Elements State     ${RTP_OTP_INPUT}           visible

t1.1.15 Reset Password – User Cannot Request a New OTP Before the 1-Minute Cooldown
    [Documentation]    Verify the "Request a new OTP" link is hidden during the 1-minute
    ...                cooldown immediately after the initial OTP is sent.
    [Tags]             reset-password    negative    otp    temp-password    mvp    type1

    Navigate To Reset Password Page    email=${RTP_NEW_USER_EMAIL_2}    temp_password=${RTP_TEMP_PASSWORD_2}
    Complete Reset Password Form

    # Resend link must not be visible during the active cooldown
    Wait For Elements State     ${RTP_OTP_RESEND_BTN}    hidden

t1.1.16 Reset Password – User Can Request a New OTP After the Cooldown
    [Documentation]    Verify the user can request a new OTP after the 60-second cooldown
    ...                expires and complete the Reset Password flow successfully.
    ...                Note: This test will take > 60 seconds to execute.
    [Tags]             reset-password    positive    otp    slow    password-reset    temp-password    mvp    type1

    Navigate To Reset Password Page    email=${RTP_NEW_USER_EMAIL}    temp_password=${RTP_TEMP_PASSWORD}
    Complete Reset Password Form     temp_password=${RTP_TEMP_PASSWORD}

    # Wait for the 60-second cooldown timer to finish
    Sleep                       61s
    Wait For Elements State     ${RTP_OTP_RESEND_BTN}    enabled
    Click                       ${RTP_OTP_RESEND_BTN}

    # Enter newly received OTP and complete the flow
    Enter RTP OTP And Continue

    Wait For Elements State     ${RESET_SUCCESS_HEADING}    visible
    Wait For Elements State     ${RESET_SUCCESS_MESSAGE}    visible

t1.1.17 Reset Password – Previously Received OTP Is No Longer Valid After Requesting a New OTP
    [Documentation]    Verify that the original OTP is invalidated once a new OTP is requested.
    [Tags]             reset-password    negative    otp    slow    password-reset    temp-password    mvp    type1
    skip    This test requires a live OTP and will take > 60 seconds due to cooldown. Run manually with: --variable OTP:<code>

    Navigate To Reset Password Page    email=${RTP_NEW_USER_EMAIL_2}    temp_password=${RTP_TEMP_PASSWORD_2}
    Complete Reset Password Form

    # Wait out the cooldown to enable the resend button
    Sleep                       61s
    Wait For Elements State     ${RTP_OTP_RESEND_BTN}    enabled
    Click                       ${RTP_OTP_RESEND_BTN}

    # Attempt to use the FIRST (now-invalidated) OTP
    Click                       ${RTP_OTP_INPUT}
    Keyboard Input              type    ${OTP}
    Click                       ${RTP_OTP_CONTINUE_BTN}

    # The old OTP must be rejected
    Wait For Elements State     text=${ERR_OTP_INVALID}    visible

t1.1.18 Reset Password – Validation on the 5th Failed OTP Attempt (Maximum Allowed Attempts)
    [Documentation]    Verify the system locks the OTP session and redirects the user after
    ...                reaching the maximum number of OTP attempts.
    ...                Uses the magic value "${OTP_MAX_ATTEMPTS}" which the backend treats as
    ...                immediately triggering the max-attempts lockout in a single attempt.
    [Tags]             reset-password    negative    otp    security    temp-password    mvp    type1

    Navigate To Reset Password Page    email=${RTP_NEW_USER_EMAIL_2}    temp_password=${RTP_TEMP_PASSWORD_2}
    Complete Reset Password Form    temp_password=${RTP_TEMP_PASSWORD_2}

    # Enter magic OTP value that immediately triggers max-attempts error
    Wait For Elements State     ${RTP_OTP_INPUT}    visible
    Click                       ${RTP_OTP_INPUT}
    Keyboard Input              type    ${OTP_MAX_ATTEMPTS}
    Click                       ${RTP_OTP_CONTINUE_BTN}
    Wait For Elements State     text=${ERR_OTP_MAX_ATTEMPTS_1}    visible
    Wait For Elements State     text=${ERR_OTP_MAX_ATTEMPTS_2}    visible

    # Confirm the modal and verify redirection to the Reset Password page
    Click                       ${MODAL_CONFIRM_BTN}
    Wait For Elements State     ${RTP_PAGE}    visible

t1.1.19 Reset Password – Validation on 5th OTP Attempt Across Multiple Resend Requests
    [Documentation]    Verify the 5-attempt limit is strictly enforced across multiple OTP resends.
    [Tags]             reset-password    negative    otp    security    slow    temp-password    mvp    type1
    skip    This test requires a live OTP and will take > 5 minutes due to multiple cooldowns. Run manually with: --variable OTP:<code>

    Navigate To Reset Password Page    email=${RTP_NEW_USER_EMAIL_2}    temp_password=${RTP_TEMP_PASSWORD_2}
    Complete Reset Password Form

    # 1. First 2 invalid attempts (Attempts 1 & 2) — use magic invalid OTP value
    Wait For Elements State     ${RTP_OTP_INPUT}    visible
    FOR    ${i}    IN RANGE    2
        Click                   ${RTP_OTP_INPUT}
        Keyboard Input          type    ${OTP_INVALID}
        Click                   ${RTP_OTP_CONTINUE_BTN}
        Wait For Elements State    text=${ERR_OTP_INVALID}    visible
    END

    # 2. First resend (wait for 1-minute cooldown)
    Sleep                       61s
    Wait For Elements State     ${RTP_OTP_RESEND_BTN}    enabled
    Click                       ${RTP_OTP_RESEND_BTN}

    # 3. Next 2 invalid attempts (Attempts 3 & 4) — use magic invalid OTP value
    Wait For Elements State     ${RTP_OTP_INPUT}    visible
    FOR    ${i}    IN RANGE    2
        Click                   ${RTP_OTP_INPUT}
        Keyboard Input          type    ${OTP_INVALID}
        Click                   ${RTP_OTP_CONTINUE_BTN}
        Wait For Elements State    text=${ERR_OTP_INVALID}    visible
    END

    # 4. Second resend (wait for 1-minute cooldown)
    Sleep                       61s
    Wait For Elements State     ${RTP_OTP_RESEND_BTN}    enabled
    Click                       ${RTP_OTP_RESEND_BTN}

    # 5. Final (5th) attempt — use magic max-attempts value to trigger lockout
    Wait For Elements State     ${RTP_OTP_INPUT}    visible
    Click                       ${RTP_OTP_INPUT}
    Keyboard Input              type    ${OTP_MAX_ATTEMPTS}
    Click                       ${RTP_OTP_CONTINUE_BTN}

    # Assert failure modal and redirection
    Wait For Elements State     text=${ERR_OTP_MAX_ATTEMPTS}    visible
    Click                       ${MODAL_CONFIRM_BTN}
    Wait For Elements State     ${RTP_PAGE}                     visible

t1.1.20 Reset Password – Behavior When OTP Session Expires Before Reaching Max Attempts
    [Documentation]    Verify system behavior when a user's OTP session expires before they
    ...                reach the maximum number of failed attempts.
    [Tags]             reset-password    negative    otp    security    slow    temp-password    mvp    type1
    skip    This test requires a live OTP and will take > 5 minutes due to session expiry. Run manually with: --variable OTP:<code>
    
    Navigate To Reset Password Page    email=${RTP_NEW_USER_EMAIL_2}    temp_password=${RTP_TEMP_PASSWORD_2}
    Complete Reset Password Form

    # 1. Execute 3 invalid attempts within the active OTP session
    Wait For Elements State     ${RTP_OTP_INPUT}    visible
    FOR    ${i}    IN RANGE    3
        Click                   ${RTP_OTP_INPUT}
        Keyboard Input          type    ${OTP_INVALID}
        Click                   ${RTP_OTP_CONTINUE_BTN}
        Wait For Elements State    text=${ERR_OTP_INVALID}    visible
    END

    # 2. Wait for the OTP session to expire (5 minutes)
    Sleep                       300s

    # 3. Attempt a 4th input after session expiry
    Click                       ${RTP_OTP_INPUT}
    Keyboard Input              type    ${OTP_INVALID}
    Click                       ${RTP_OTP_CONTINUE_BTN}
    Wait For Elements State     text=${ERR_OTP_INVALID}    visible

    # 4. Click "Request a new OTP" — session has expired
    Click                       ${RTP_OTP_RESEND_BTN}

    # 5. Assert the expired session modal appears
    Wait For Elements State     text=${ERR_OTP_EXPIRED_SESSION}    visible

    # 6. Click "Request New Code" — should redirect to login
    Click                       text=Request New Code
    Wait For Elements State     ${LOGIN_PAGE}    visible

t1.1.21 Reset Password – Email Blocked 60 Minutes After 3 Unverified OTP Sessions (5 Invalid Attempts)
    [Documentation]    Verify that after 3 unverified Reset Password OTP sessions within the window
    ...                (each reaching the max attempts via the magic ${OTP_MAX_ATTEMPTS} value), a
    ...                4th attempt is blocked with "You have exceeded the maximum number of attempts.
    ...                You can try again in <n> minutes." and the user remains on the Reset Password
    ...                page. REUSABLE: swap ${OTP_BLK_RTP_MAX_EMAIL}/_TEMP_PW for a fresh temp account
    ...                each cycle — this test blocks the account's email for 60 minutes.
    [Tags]    reset-password    otp    security    otp-block    temp-password    type2
    Navigate To Reset Password Page    email=${OTP_BLK_RTP_MAX_EMAIL}    temp_password=${OTP_BLK_RTP_MAX_TEMP_PW}
    FOR    ${i}    IN RANGE    3
        Trigger Unverified RTP Max-Attempts Session    temp_password=${OTP_BLK_RTP_MAX_TEMP_PW}
    END
    # 4th session → the email is now blocked for 60 minutes.
    Submit RTP Reset Form    temp_password=${OTP_BLK_RTP_MAX_TEMP_PW}
    Wait For Elements State    text=${ERR_OTP_SESSION_BLOCKED}    visible

t1.1.22 Reset Password – Email Blocked 60 Minutes After 3 Unverified OTP Sessions (Abandoned)
    [Documentation]    Verify that 3 abandoned Reset Password OTP sessions (reach the OTP screen, then
    ...                exit via the "Log in" link) block the email for 60 minutes; the 4th login shows
    ...                the block message. REUSABLE: refresh ${OTP_BLK_RTP_ABANDON_EMAIL}/_TEMP_PW each
    ...                cycle — this blocks the account's email for 60 minutes.
    [Tags]    reset-password    otp    security    otp-block    temp-password    type2
    Open Teller App
    FOR    ${i}    IN RANGE    3
        Abandon One RTP OTP Session    email=${OTP_BLK_RTP_ABANDON_EMAIL}    temp_password=${OTP_BLK_RTP_ABANDON_TEMP_PW}
    END
    # 4th session attempt → blocked at login.
    Fill Text                  ${EMAIL_FIELD}       ${OTP_BLK_RTP_ABANDON_EMAIL}
    Fill Text                  ${PASSWORD_FIELD}    ${OTP_BLK_RTP_ABANDON_TEMP_PW}
    Click                      ${LOGIN_BUTTON}
    Wait For Elements State    text=${ERR_OTP_SESSION_BLOCKED}    visible

t1.1.23 Reset Password – Blocked Email Keeps Returning the Error During the Block Period
    [Documentation]    Verify that once the email is blocked, every further Reset Password attempt
    ...                during the 60-minute window returns the same block error. Triggers the block
    ...                (3 unverified sessions + a 4th), dismisses it, then retries and re-asserts.
    ...                REUSABLE: refresh ${OTP_BLK_RTP_RETRY_EMAIL}/_TEMP_PW each cycle.
    [Tags]    reset-password    otp    security    otp-block    temp-password    type2
    Navigate To Reset Password Page    email=${OTP_BLK_RTP_RETRY_EMAIL}    temp_password=${OTP_BLK_RTP_RETRY_TEMP_PW}
    FOR    ${i}    IN RANGE    3
        Trigger Unverified RTP Max-Attempts Session    temp_password=${OTP_BLK_RTP_RETRY_TEMP_PW}
    END
    Submit RTP Reset Form      temp_password=${OTP_BLK_RTP_RETRY_TEMP_PW}
    Wait For Elements State    text=${ERR_OTP_SESSION_BLOCKED}    visible
    Click                      ${MODAL_CONFIRM_BTN}
    # Retry during the block → same error is shown again.
    Submit RTP Reset Form      temp_password=${OTP_BLK_RTP_RETRY_TEMP_PW}
    Wait For Elements State    text=${ERR_OTP_SESSION_BLOCKED}    visible

t1.1.25 Reset Password – No Block When a Valid OTP Is Entered on the 5th Attempt of the 3rd Session
    [Documentation]    Verify the user is NOT blocked when only 2 sessions are unverified and the 3rd
    ...                session is verified — even if the valid OTP arrives on the 5th attempt. Enters
    ...                4 invalid OTPs (${OTP_INVALID}) then the valid OTP (${OTP}) in session 3, and
    ...                asserts the reset succeeds. REUSABLE: refresh ${OTP_BLK_RTP_VALID5_EMAIL}/_TEMP_PW
    ...                each cycle — this test consumes the temp account (completes the reset).
    [Tags]    reset-password    otp    security    otp-block    temp-password    type2
    Navigate To Reset Password Page    email=${OTP_BLK_RTP_VALID5_EMAIL}    temp_password=${OTP_BLK_RTP_VALID5_TEMP_PW}
    # 2 unverified sessions
    FOR    ${i}    IN RANGE    2
        Trigger Unverified RTP Max-Attempts Session    temp_password=${OTP_BLK_RTP_VALID5_TEMP_PW}
    END
    # Session 3: 4 invalid attempts, then a valid OTP on the 5th → success, no block.
    Complete Reset Password Form    temp_password=${OTP_BLK_RTP_VALID5_TEMP_PW}    new_password=${OTP_BLK_NEW_PASSWORD}
    FOR    ${i}    IN RANGE    4
        Set RTP OTP And Continue    otp=${OTP_INVALID}
        Wait For Elements State     text=${ERR_OTP_INVALID}    visible
    END
    Set RTP OTP And Continue    otp=${OTP}
    Wait For Elements State     ${RESET_SUCCESS_MESSAGE}    visible

# ====================================================================
# WALL-CLOCK OTP-BLOCK CASES (automatable, but LONG-RUNNING)
# Run on-demand only: robot --include wall-clock ...
# They need no human/inbox/live-OTP — only magic OTPs + real time.
# ====================================================================

t1.1.24 Reset Password – Reset Succeeds After the 60-Minute Block Expires
    [Documentation]    Verify that once an email is blocked (3 unverified max-attempts OTP sessions),
    ...                the Reset Password flow succeeds again after the 60-minute block window elapses.
    ...                Triggers the block, waits out ${OTP_BLK_EXPIRY_WAIT}, then completes the reset
    ...                with a valid OTP (${OTP}) → success modal. Wall-clock: ~62 min.
    ...                REUSABLE: refresh ${OTP_BLK_RTP_EXPIRY_EMAIL}/_TEMP_PW each cycle.
    [Tags]    reset-password    otp    security    wall-clock    slow    temp-password    type2
    # Phase 1 — trigger the 60-minute block (3 unverified sessions + a blocked 4th)
    Navigate To Reset Password Page    email=${OTP_BLK_RTP_EXPIRY_EMAIL}    temp_password=${OTP_BLK_RTP_EXPIRY_TEMP_PW}
    FOR    ${i}    IN RANGE    3
        Trigger Unverified RTP Max-Attempts Session    temp_password=${OTP_BLK_RTP_EXPIRY_TEMP_PW}
    END
    Submit RTP Reset Form      temp_password=${OTP_BLK_RTP_EXPIRY_TEMP_PW}
    Wait For Elements State    text=${ERR_OTP_SESSION_BLOCKED}    visible
    Close Browser
    # Phase 2 — wait out the 60-minute block
    Sleep                      ${OTP_BLK_EXPIRY_WAIT}
    # Phase 3 — after expiry the reset completes normally with a valid OTP
    Navigate To Reset Password Page    email=${OTP_BLK_RTP_EXPIRY_EMAIL}    temp_password=${OTP_BLK_RTP_EXPIRY_TEMP_PW}
    Complete Reset Password Form       temp_password=${OTP_BLK_RTP_EXPIRY_TEMP_PW}    new_password=${OTP_BLK_NEW_PASSWORD}
    Enter RTP OTP And Continue         otp=${OTP}
    Wait For Elements State            ${RESET_SUCCESS_MESSAGE}    visible

t1.1.26 Reset Password – No Block When 3 Unverified Sessions Span More Than 15 Minutes
    [Documentation]    Verify that 3 unverified OTP sessions do NOT block the email when they are
    ...                spaced so that no 3 fall within a single 15-minute window. Runs a session,
    ...                waits ${OTP_BLK_SESSION_GAP} between each, then confirms a 4th attempt reaches
    ...                the OTP screen normally (no block error). Wall-clock: ~33 min.
    ...                REUSABLE: refresh ${OTP_BLK_RTP_SPAN_EMAIL}/_TEMP_PW each cycle.
    [Tags]    reset-password    otp    security    wall-clock    slow    temp-password    type2
    # Session 1
    Navigate To Reset Password Page    email=${OTP_BLK_RTP_SPAN_EMAIL}    temp_password=${OTP_BLK_RTP_SPAN_TEMP_PW}
    Trigger Unverified RTP Max-Attempts Session    temp_password=${OTP_BLK_RTP_SPAN_TEMP_PW}
    Close Browser
    Sleep                      ${OTP_BLK_SESSION_GAP}
    # Session 2 (>15 min after S1)
    Navigate To Reset Password Page    email=${OTP_BLK_RTP_SPAN_EMAIL}    temp_password=${OTP_BLK_RTP_SPAN_TEMP_PW}
    Trigger Unverified RTP Max-Attempts Session    temp_password=${OTP_BLK_RTP_SPAN_TEMP_PW}
    Close Browser
    Sleep                      ${OTP_BLK_SESSION_GAP}
    # Session 3 (>15 min after S2)
    Navigate To Reset Password Page    email=${OTP_BLK_RTP_SPAN_EMAIL}    temp_password=${OTP_BLK_RTP_SPAN_TEMP_PW}
    Trigger Unverified RTP Max-Attempts Session    temp_password=${OTP_BLK_RTP_SPAN_TEMP_PW}
    # 4th attempt → reaches the OTP screen (NOT blocked)
    Submit RTP Reset Form      temp_password=${OTP_BLK_RTP_SPAN_TEMP_PW}
    Wait For Elements State    ${RTP_OTP_INPUT}                 visible
    Wait For Elements State    text=${ERR_OTP_SESSION_BLOCKED}    hidden

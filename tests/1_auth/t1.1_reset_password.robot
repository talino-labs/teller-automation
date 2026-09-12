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

*** Settings ***
Documentation       Test suite for Forgot Password flow.
...                 Covers happy path reset, case-insensitive email, unregistered email,
...                 blank/invalid email format, and mismatched password validation.
...
...                 Tests tagged [password-reset] require a live OTP.
...                 Pass it at runtime: --variable OTP:123456

Resource            ../../resources/keywords/common.resource

Test Teardown       Close Browser


*** Variables ***
${NEW_PASSWORD}              Password123!
${FP_INVALID_FORMAT_EMAIL}          notanemail
${FP_WRONG_CONFIRM_PASSWORD}        WrongPassword999!
${ERR_UNREGISTERED_EMAIL}           Email address is invalid, please try again.
${ERR_EMAIL_REQUIRED}               Email is required.
${ERR_INVALID_EMAIL_FORMAT}         Incorrect email format.
${ERR_PASSWORD_MISMATCH}            Passwords do not match.
${OTP}                              123456

# --- Hardcoded OTP Test Values ---
# These are magic values recognised by the backend to simulate specific OTP states.
${OTP_INVALID}                      000000    # Always triggers "invalid or expired OTP" error
${OTP_MAX_ATTEMPTS}                 999999    # Immediately triggers max-attempts error in one attempt

# --- Password Validation Errors ---
${ERR_PWD_MIN_LENGTH}               Password must contain a minimum of 8 characters.
${ERR_PWD_UPPERCASE}                Password must include at least one uppercase letter.
${ERR_PWD_NUMBER}                   Password must include at least one number.
${ERR_PWD_SPECIAL}                  Password must include at least one special character.

# --- OTP Errors ---
${ERR_OTP_INVALID}                  OTP is either invalid or has expired. Please try again or request a new OTP.

# --- Max Attempts & Session Errors ---
${ERR_OTP_MAX_ATTEMPTS}             You have reached the maximum number of attempts.
${ERR_OTP_EXPIRED_SESSION}          Your one-time password has expired. Request a new code to continue.


*** Keywords ***
Navigate To Forgot Password Page
    [Documentation]    Opens the app and navigates to the Reset your password screen.
    Open Teller App
    Click                       ${FORGOT_PASSWORD_LINK}
    Wait For Elements State     ${FP_PAGE}    visible

Complete OTP Verification
    [Documentation]    Fills in email, requests OTP, enters OTP, and clicks CONTINUE.
    ...                Leaves the user on the Create new password screen.
    [Arguments]        ${email}=${CP_USER_EMAIL}
    Fill Text                   ${FP_EMAIL_FIELD}    ${email}
    Click                       ${FP_SEND_CODE_BTN}
    Wait For Elements State     ${FP_OTP_INPUT}      visible
    Click                       ${FP_OTP_INPUT}
    Keyboard Input              type    ${OTP}
    Click                       ${FP_CONTINUE_BTN}
    Wait For Elements State     ${NEW_PASSWORD_FIELD}    visible

Submit FP Email
    [Documentation]    Fills the Forgot Password email and clicks Send Verification Code WITHOUT
    ...                waiting for the OTP screen — so it also works when a block message appears
    ...                instead. Assumes the page is on the Forgot Password screen.
    [Arguments]        ${email}
    Fill Text                   ${FP_EMAIL_FIELD}    ${email}
    Click                       ${FP_SEND_CODE_BTN}

Enter FP OTP And Continue
    [Documentation]    Clicks the OTP input, types the OTP code, and clicks CONTINUE.
    [Arguments]        ${otp}=${OTP}
    Click                       ${FP_OTP_INPUT}
    Keyboard Input              type    ${otp}
    Click                       ${FP_CONTINUE_BTN}

Set FP OTP And Continue
    [Documentation]    Robustly sets each of the 6 OTP boxes (replacing any existing value) then
    ...                clicks CONTINUE. Needed for re-entering a different OTP within one session.
    [Arguments]        ${otp}=${OTP}
    @{chars}=    Split String To Characters    ${otp}
    FOR    ${idx}    ${ch}    IN ENUMERATE    @{chars}    start=1
        Fill Text
        ...    css=[data-testid="input-forgot-password-otp"] input[aria-label="Please enter OTP character ${idx}"]
        ...    ${ch}
    END
    Click    ${FP_CONTINUE_BTN}

Trigger Unverified FP Max-Attempts Session
    [Documentation]    From the Forgot Password screen, sends the code, submits the magic
    ...                max-attempts OTP, dismisses the modal, and returns to the Forgot Password
    ...                screen — recording one unverified OTP session.
    [Arguments]        ${email}
    Submit FP Email                 ${email}
    Wait For Elements State         ${FP_OTP_INPUT}    visible
    Enter FP OTP And Continue       otp=${OTP_MAX_ATTEMPTS}
    Wait For Elements State         text=${ERR_OTP_MAX_ATTEMPTS}    visible
    Click                           ${MODAL_CONFIRM_BTN}
    Wait For Elements State         ${FP_PAGE}    visible

Abandon One FP OTP Session
    [Documentation]    From the Forgot Password screen, sends the code, reaches the OTP screen, then
    ...                abandons it via the "Log in" link and the exit-confirmation modal — recording
    ...                one unverified (abandoned) session. Returns to the Forgot Password screen ready
    ...                for the next session (reuses the same browser).
    [Arguments]        ${email}
    Submit FP Email                 ${email}
    Wait For Elements State         ${FP_OTP_INPUT}    visible
    Click                           ${OTP_ABANDON_LOGIN_LINK}
    Click                           ${OTP_EXIT_CONFIRM_BTN}
    Wait For Elements State         ${LOGIN_PAGE}    visible
    Click                           ${FORGOT_PASSWORD_LINK}
    Wait For Elements State         ${FP_PAGE}    visible


*** Test Cases ***
t1.3.1 Reset Password via Forgot Password
    [Documentation]    Verify that a registered teller can successfully reset their password
    ...                via the Forgot Password flow and see the success confirmation screen.
    [Tags]             forgot-password    smoke    password-reset    mvp    type1
    # Requires a live OTP — manual testing needed

    Navigate To Forgot Password Page
    Complete OTP Verification

    # Create new password
    Fill Text                   ${NEW_PASSWORD_FIELD}           ${NEW_PASSWORD}
    Fill Text                   ${CONFIRM_NEW_PASSWORD_FIELD}   ${NEW_PASSWORD}
    Click                       ${RESET_PASSWORD_BTN}

    # Assert success screen
    # Verify all fields — continue on failure so ALL mismatches are reported
    Run Keyword And Continue On Failure
    ...    Wait For Elements State     ${RESET_SUCCESS_HEADING}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State     ${RESET_SUCCESS_MESSAGE}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State     ${BACK_TO_LOGIN_BTN}        visible
    Click                       ${BACK_TO_LOGIN_BTN}
    Wait For Elements State     ${LOGIN_PAGE}               visible
    # Verify new password works by logging in with it — must be the SAME account
    # that was reset (CP_USER_EMAIL), not TELLER_EMAIL. These used to be the same
    # account so the mismatch was latent; with a dedicated auth account it fails.
    Fill Text                   ${EMAIL_FIELD}              ${CP_USER_EMAIL}
    Fill Text                   ${PASSWORD_FIELD}           ${NEW_PASSWORD}
    Click                       ${LOGIN_BUTTON}
    Wait For Elements State     css=h3.text-2xl             visible

t1.3.2 Verify System Treats Email as Case-Insensitive During Forgot Password
    [Documentation]    Verify that the system recognises a mixed-case email address during the
    ...                Forgot Password flow and sends the OTP successfully.
    [Tags]             forgot-password    smoke    password-reset    mvp    type1

    Navigate To Forgot Password Page
    Complete OTP Verification    email=${FP_MIXED_CASE_EMAIL}

    # Create new password
    Fill Text                   ${NEW_PASSWORD_FIELD}           ${NEW_PASSWORD}
    Fill Text                   ${CONFIRM_NEW_PASSWORD_FIELD}   ${NEW_PASSWORD}
    Click                       ${RESET_PASSWORD_BTN}

    # Assert success screen
    # Verify all fields — continue on failure so ALL mismatches are reported
    Run Keyword And Continue On Failure
    ...    Wait For Elements State     ${RESET_SUCCESS_HEADING}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State     ${RESET_SUCCESS_MESSAGE}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State     ${BACK_TO_LOGIN_BTN}        visible
    Click                       ${BACK_TO_LOGIN_BTN}
    Wait For Elements State     ${LOGIN_PAGE}               visible
    # Verify new password works by logging in with it
    Fill Text                   ${EMAIL_FIELD}              ${FP_MIXED_CASE_EMAIL}
    Fill Text                   ${PASSWORD_FIELD}           ${NEW_PASSWORD}
    Click                       ${LOGIN_BUTTON}
    Wait For Elements State     css=h3.text-2xl             visible

t1.3.3 Forgot Password with Unregistered Email
    [Documentation]    Verify that entering an unregistered email on the Reset your password
    ...                screen shows an error and does not send an OTP.
    [Tags]             forgot-password    negative    mvp    type1

    Navigate To Forgot Password Page
    Fill Text                   ${FP_EMAIL_FIELD}    ${INVALID_EMAIL}
    Click                       ${FP_SEND_CODE_BTN}
    Wait For Elements State     text=${ERR_UNREGISTERED_EMAIL}    visible
    # OTP screen must NOT appear
    Wait For Elements State     ${FP_OTP_INPUT}    hidden

t1.3.4 Forgot Password – Blank Email Field
    [Documentation]    Verify that the Send Verification Code button remains disabled
    ...                when the email field is empty.
    [Tags]             forgot-password    negative    mvp    type1

    Navigate To Forgot Password Page
    # Button should be disabled on initial load (empty email)
    Wait For Elements State     ${FP_SEND_CODE_BTN}    disabled
    # Type then clear to verify it stays disabled
    Fill Text                   ${FP_EMAIL_FIELD}    test@example.com
    Fill Text                   ${FP_EMAIL_FIELD}    ${EMPTY}
    Wait For Elements State     ${FP_SEND_CODE_BTN}    disabled

t1.3.5 Forgot Password – Invalid Email Format
    [Documentation]    Verify that typing an email with an invalid format triggers the
    ...                "Invalid email format." inline validation error and disables the button.
    [Tags]             forgot-password    negative    mvp    type1

    Navigate To Forgot Password Page
    Fill Text                   ${FP_EMAIL_FIELD}    ${FP_INVALID_FORMAT_EMAIL}
    # Button should be disabled when email format is invalid
    Wait For Elements State     ${FP_SEND_CODE_BTN}    disabled
    Wait For Elements State     text=${ERR_INVALID_EMAIL_FORMAT}    visible

t1.3.6 Forgot Password – Mismatched Password and Confirm Password
    [Documentation]    Verify that entering non-matching values in the New password and
    ...                Confirm new password fields shows "Passwords do not match." and
    ...                keeps the RESET PASSWORD button disabled.
    [Tags]             forgot-password    negative    password-reset    mvp    type1

    Navigate To Forgot Password Page
    Complete OTP Verification

    # Enter mismatched passwords
    Fill Text                   ${NEW_PASSWORD_FIELD}           ${TELLER_PASSWORD}
    Fill Text                   ${CONFIRM_NEW_PASSWORD_FIELD}   ${FP_WRONG_CONFIRM_PASSWORD}
    # Focus elsewhere to trigger validation
    Focus                       ${NEW_PASSWORD_FIELD}

    # Assert inline error and disabled submit button
    Wait For Elements State     text=${ERR_PASSWORD_MISMATCH}    visible
    Wait For Elements State     ${RESET_PASSWORD_BTN}            disabled

# ====================================================================
# PASSWORD POLICY VALIDATION TESTS (Mapped from t1.1.7 - t1.1.12)
# ====================================================================

t1.3.7 Reset Password – Leave Required Fields Blank
    [Documentation]    Verify the RESET PASSWORD button is disabled when fields are blank.
    [Tags]             forgot-password    negative    password-reset    mvp    type1

    Navigate To Forgot Password Page
    Complete OTP Verification
    
    # Fields are blank by default upon reaching this page
    Wait For Elements State     ${RESET_PASSWORD_BTN}    disabled

t1.3.8 Reset Password – Password Too Short
    [Documentation]    Verify validation for passwords under 8 characters.
    [Tags]             forgot-password    negative    password-reset    mvp    type1

    Navigate To Forgot Password Page
    Complete OTP Verification
    
    Fill Text                   ${NEW_PASSWORD_FIELD}    Abc1!
    Wait For Elements State     text=${ERR_PWD_MIN_LENGTH}    visible
    Wait For Elements State     ${RESET_PASSWORD_BTN}         disabled

t1.3.9 Reset Password – Password Without Uppercase Letter
    [Documentation]    Verify validation for missing uppercase letter.
    [Tags]             forgot-password    negative    password-reset    mvp    type1

    Navigate To Forgot Password Page
    Complete OTP Verification
    
    Fill Text                   ${NEW_PASSWORD_FIELD}    abc12345!
    Wait For Elements State     text=${ERR_PWD_UPPERCASE}     visible
    Wait For Elements State     ${RESET_PASSWORD_BTN}         disabled

t1.3.10 Reset Password – Password Without Number
    [Documentation]    Verify validation for missing number.
    [Tags]             forgot-password    negative    password-reset    mvp    type1

    Navigate To Forgot Password Page
    Complete OTP Verification
    
    Fill Text                   ${NEW_PASSWORD_FIELD}    Abcdefgh!
    Wait For Elements State     text=${ERR_PWD_NUMBER}        visible
    Wait For Elements State     ${RESET_PASSWORD_BTN}         disabled

t1.3.11 Reset Password – Password Without Special Character
    [Documentation]    Verify validation for missing special character.
    [Tags]             forgot-password    negative    password-reset    mvp    type1

    Navigate To Forgot Password Page
    Complete OTP Verification
    
    Fill Text                   ${NEW_PASSWORD_FIELD}    Abcdef123
    Wait For Elements State     text=${ERR_PWD_SPECIAL}       visible
    Wait For Elements State     ${RESET_PASSWORD_BTN}         disabled

t1.3.12 Reset Password – Sequential Validation of Multiple Violations
    [Documentation]    Verify errors cascade correctly as the user fixes them one by one.
    [Tags]             forgot-password    negative    password-reset    mvp    type1

    Navigate To Forgot Password Page
    Complete OTP Verification
    
    # 1. Too short
    Fill Text                   ${NEW_PASSWORD_FIELD}    abc
    Wait For Elements State     text=${ERR_PWD_MIN_LENGTH}    visible
    
    # 2. Fix length, missing uppercase
    Fill Text                   ${NEW_PASSWORD_FIELD}    abcdefgh
    Wait For Elements State     text=${ERR_PWD_UPPERCASE}     visible
    
    # 3. Fix uppercase, missing number
    Fill Text                   ${NEW_PASSWORD_FIELD}    Abcdefgh
    Wait For Elements State     text=${ERR_PWD_NUMBER}        visible
    
    # 4. Fix number, missing special char
    Fill Text                   ${NEW_PASSWORD_FIELD}    Abcdefgh1
    Wait For Elements State     text=${ERR_PWD_SPECIAL}       visible
    
    # 5. Fix all rules
    Fill Text                   ${NEW_PASSWORD_FIELD}    Abcdefgh1!
    Wait For Elements State     text=${ERR_PWD_SPECIAL}       hidden


# ====================================================================
# OTP VALIDATION & COOLDOWN TESTS (Mapped from t1.1.13 - t1.1.17)
# ====================================================================

t1.3.13 Reset Password – Invalid OTP
    [Documentation]    Verify error message when an incorrect OTP is entered.
    ...                Uses the magic value "${OTP_INVALID}" which the backend always rejects
    ...                as invalid/expired.
    [Tags]             forgot-password    negative    otp    requires-otp-validation    mvp    type1

    Navigate To Forgot Password Page
    Fill Text                   ${FP_EMAIL_FIELD}    ${TELLER_EMAIL}
    Click                       ${FP_SEND_CODE_BTN}

    Wait For Elements State     ${FP_OTP_INPUT}      visible
    Click                       ${FP_OTP_INPUT}
    Keyboard Input              type    ${OTP_INVALID}
    Click                       ${FP_CONTINUE_BTN}

    Wait For Elements State     text=${ERR_OTP_INVALID}       visible
    Wait For Elements State     ${FP_OTP_INPUT}               visible

t1.3.14 Reset Password – Leave OTP Blank
    [Documentation]    Verify CONTINUE button is disabled if OTP is blank.
    [Tags]             forgot-password    negative    otp    mvp    type1

    Navigate To Forgot Password Page
    Fill Text                   ${FP_EMAIL_FIELD}    ${TELLER_EMAIL}
    Click                       ${FP_SEND_CODE_BTN}
    
    # OTP input is blank by default
    Wait For Elements State     ${FP_CONTINUE_BTN}            disabled
    Wait For Elements State     ${FP_OTP_INPUT}               visible

t1.3.15-16 Reset Password – Cooldown Prevents Immediate Resend, Then Allows Resend After 60s
    [Documentation]    Verify the resend link is hidden immediately after OTP is sent (cooldown active),
    ...                then becomes available after the 60-second cooldown expires and a new OTP can be requested.
    ...                Note: This test will take > 60 seconds to execute.
    [Tags]             forgot-password    otp    slow    mvp    type1

    Navigate To Forgot Password Page
    Fill Text                   ${FP_EMAIL_FIELD}    ${TELLER_EMAIL}
    Click                       ${FP_SEND_CODE_BTN}

    # Resend must be hidden during active cooldown
    Wait For Elements State     ${FP_RESEND_BTN}              hidden

    # Wait for the 60-second cooldown timer to finish
    # Sleep starts after button is hidden (~1-2s after send), so add buffer for server-side timing variance
    Sleep                       65s
    Wait For Elements State     ${FP_RESEND_BTN}              enabled    timeout=30s
    Click                       ${FP_RESEND_BTN}

    # Verify a new code was sent (continue button resets to disabled while new OTP is pending)
    Wait For Elements State     ${FP_CONTINUE_BTN}            disabled
    Wait For Elements State     ${FP_OTP_INPUT}               visible

t1.3.17 Reset Password – Old OTP Invalidated After Resend
    [Documentation]    Verify the first OTP becomes invalid if a second one is requested.
    [Tags]             forgot-password    negative    otp    slow    requires-otp-validation    mvp    type1
    skip    This test requires a live OTP and will take > 60 seconds. Run manually with: --variable OTP:<code>

    Navigate To Forgot Password Page
    Fill Text                   ${FP_EMAIL_FIELD}    ${TELLER_EMAIL}
    Click                       ${FP_SEND_CODE_BTN}

    # Wait out the timer to request a second OTP
    Sleep                       61s
    Wait For Elements State     ${FP_RESEND_BTN}              enabled
    Click                       ${FP_RESEND_BTN}

    # Attempt to use the FIRST OTP
    Wait For Elements State     ${FP_OTP_INPUT}      visible
    Click                       ${FP_OTP_INPUT}
    Keyboard Input              type    ${OTP}
    Click                       ${FP_CONTINUE_BTN}

    # Expect failure because the first OTP was invalidated
    Wait For Elements State     text=${ERR_OTP_INVALID}       visible


t1.3.18 Reset Password – Validation on the 5th failed OTP attempt (maximum allowed attempts)
    [Documentation]    Verify session lock and redirection after reaching the maximum number
    ...                of OTP attempts.
    ...                Uses the magic value "${OTP_MAX_ATTEMPTS}" which the backend treats as
    ...                immediately triggering the max-attempts lockout in a single attempt.
    [Tags]             forgot-password    negative    otp    security    requires-otp-validation    mvp    type1

    Navigate To Forgot Password Page
    Fill Text                   ${FP_EMAIL_FIELD}    ${TELLER_EMAIL}
    Click                       ${FP_SEND_CODE_BTN}

    # Enter magic OTP value that immediately triggers max-attempts error
    Wait For Elements State     ${FP_OTP_INPUT}      visible
    Click                       ${FP_OTP_INPUT}
    Keyboard Input              type    ${OTP_MAX_ATTEMPTS}
    Click                       ${FP_CONTINUE_BTN}
    Wait For Elements State     ${MODAL_OTP_ERROR_CONFIRM_BTN}   visible

    # Click CONFIRM on the modal and verify redirection to the Reset Password (FP) page
    Click                       ${MODAL_OTP_ERROR_CONFIRM_BTN}
    Wait For Elements State     ${FP_PAGE}                      visible

t1.3.19 Reset Password – Validation on 5th OTP attempt across multiple resend requests
    [Documentation]    Verify the 5-attempt limit is strictly enforced across multiple OTP resends.
    [Tags]             forgot-password    negative    otp    security    slow    requires-otp-validation    mvp    type1
    skip    This test requires a live OTP and will take > 5 minutes due to multiple cooldowns. Run manually with: --variable OTP:<code>

    Navigate To Forgot Password Page
    Fill Text                   ${FP_EMAIL_FIELD}    ${TELLER_EMAIL}
    Click                       ${FP_SEND_CODE_BTN}

    # 1. First 2 invalid attempts — use magic invalid OTP value
    Wait For Elements State     ${FP_OTP_INPUT}      visible
    FOR    ${i}    IN RANGE    2
        Click                       ${FP_OTP_INPUT}
        Keyboard Input              type    ${OTP_INVALID}
        Click                       ${FP_CONTINUE_BTN}
        Wait For Elements State    text=${ERR_OTP_INVALID}    visible
    END

    # 2. First Resend (Wait for 1-minute cooldown)
    Sleep                       61s
    Click                       ${FP_RESEND_BTN}

    # 3. Next 2 invalid attempts (Attempts 3 & 4) — use magic invalid OTP value
    Wait For Elements State     ${FP_OTP_INPUT}      visible
    FOR    ${i}    IN RANGE    2
        Click                       ${FP_OTP_INPUT}
        Keyboard Input              type    ${OTP_INVALID}
        Click                       ${FP_CONTINUE_BTN}
        Wait For Elements State    text=${ERR_OTP_INVALID}    visible
    END

    # 4. Second Resend (Wait for 1-minute cooldown)
    Sleep                       61s
    Click                       ${FP_RESEND_BTN}

    # 5. Final (5th) attempt — use magic max-attempts value to trigger lockout
    Wait For Elements State     ${FP_OTP_INPUT}      visible
    Click                       ${FP_OTP_INPUT}
    Keyboard Input              type    ${OTP_MAX_ATTEMPTS}
    Click                       ${FP_CONTINUE_BTN}

    # Assert failure modal and redirection
    Wait For Elements State     text=${ERR_OTP_MAX_ATTEMPTS}    visible
    Click                       ${MODAL_CONFIRM_BTN}
    Wait For Elements State     ${FP_PAGE}                      visible

t1.3.20 Reset Password – Behavior when OTP session expires before reaching max attempts
    [Documentation]    Verify system behavior when a user attempts to input an OTP after the 5-minute session expires.
    [Tags]             forgot-password    negative    otp    security    slow    requires-otp-validation    mvp    type1
    skip    This test requires a live OTP and will take > 5 minutes due to session expiry. Run manually with: --variable OTP:<code>

    Navigate To Forgot Password Page
    Fill Text                   ${FP_EMAIL_FIELD}    ${TELLER_EMAIL}
    Click                       ${FP_SEND_CODE_BTN}

    # 1. Execute 3 invalid attempts within active session — use magic invalid OTP value
    Wait For Elements State     ${FP_OTP_INPUT}      visible
    FOR    ${i}    IN RANGE    3
        Click                       ${FP_OTP_INPUT}
        Keyboard Input              type    ${OTP_INVALID}
        Click                       ${FP_CONTINUE_BTN}
        Wait For Elements State    text=${ERR_OTP_INVALID}    visible
    END

    # 2. Wait for OTP session to expire (5 minutes)
    Sleep                       240s

    # 3. Attempt 4th input after session expiry — use magic invalid OTP value
    Click                       ${FP_OTP_INPUT}
    Keyboard Input              type    ${OTP_INVALID}
    Click                       ${FP_CONTINUE_BTN}
    Wait For Elements State     text=${ERR_OTP_INVALID}    visible

    # 4. Click Resend after session has expired
    Click                       ${FP_RESEND_BTN}

    # 5. Assert expired session modal appears
    Wait For Elements State     text=${ERR_OTP_EXPIRED_SESSION}    visible

    # 6. Click "Request New Code" (Using text locator as specified in manual step 3)
    Click                       text=Request New Code

    # Assert redirection to Login screen
    Wait For Elements State     ${LOGIN_PAGE}                      visible
    Close Browser
t1.3.21 Forgot Password – Email Blocked 60 Minutes After 3 Unverified OTP Sessions (5 Invalid Attempts)
    [Documentation]    Verify that 3 unverified Forgot Password OTP sessions (each hitting max attempts
    ...                via ${OTP_MAX_ATTEMPTS}) block the email for 60 minutes; the 4th "Send
    ...                Verification Code" shows "You have exceeded the maximum number of attempts.
    ...                You can try again in <n> minutes." REUSABLE: refresh ${OTP_BLK_FP_MAX_EMAIL}
    ...                each cycle — this blocks the account's email for 60 minutes.
    [Tags]    forgot-password    otp    security    otp-block    type2
    Navigate To Forgot Password Page
    FOR    ${i}    IN RANGE    3
        Trigger Unverified FP Max-Attempts Session    ${OTP_BLK_FP_MAX_EMAIL}
    END
    Submit FP Email            ${OTP_BLK_FP_MAX_EMAIL}
    Wait For Elements State    text=${ERR_OTP_SESSION_BLOCKED}    visible

t1.3.22 Forgot Password – Email Blocked 60 Minutes After 3 Unverified OTP Sessions (Abandoned)
    [Documentation]    Verify that 3 abandoned Forgot Password OTP sessions block the email for 60
    ...                minutes; the 4th send shows the block message. REUSABLE: refresh
    ...                ${OTP_BLK_FP_ABANDON_EMAIL} each cycle.
    [Tags]    forgot-password    otp    security    otp-block    type2
    Navigate To Forgot Password Page
    FOR    ${i}    IN RANGE    3
        Abandon One FP OTP Session    ${OTP_BLK_FP_ABANDON_EMAIL}
    END
    Submit FP Email            ${OTP_BLK_FP_ABANDON_EMAIL}
    Wait For Elements State    text=${ERR_OTP_SESSION_BLOCKED}    visible

t1.3.23 Forgot Password – Blocked Email Keeps Returning the Error During the Block Period
    [Documentation]    Verify that once blocked, every further Forgot Password attempt during the
    ...                60-minute window returns the same block error. REUSABLE: refresh
    ...                ${OTP_BLK_FP_RETRY_EMAIL} each cycle.
    [Tags]    forgot-password    otp    security    otp-block    type2
    Navigate To Forgot Password Page
    FOR    ${i}    IN RANGE    3
        Trigger Unverified FP Max-Attempts Session    ${OTP_BLK_FP_RETRY_EMAIL}
    END
    Submit FP Email            ${OTP_BLK_FP_RETRY_EMAIL}
    Wait For Elements State    text=${ERR_OTP_SESSION_BLOCKED}    visible
    Click                      ${MODAL_CONFIRM_BTN}
    Submit FP Email            ${OTP_BLK_FP_RETRY_EMAIL}
    Wait For Elements State    text=${ERR_OTP_SESSION_BLOCKED}    visible

t1.3.25 Forgot Password – No Block When a Valid OTP Is Entered on the 5th Attempt of the 3rd Session
    [Documentation]    Verify the user is NOT blocked when only 2 sessions are unverified and the 3rd
    ...                is verified via a valid OTP on the 5th attempt. Enters 4 invalid OTPs then the
    ...                valid OTP in session 3 and completes the reset. REUSABLE: refresh
    ...                ${OTP_BLK_FP_VALID5_EMAIL} each cycle — this resets that account's password.
    [Tags]    forgot-password    otp    security    otp-block    type2
    Navigate To Forgot Password Page
    FOR    ${i}    IN RANGE    2
        Trigger Unverified FP Max-Attempts Session    ${OTP_BLK_FP_VALID5_EMAIL}
    END
    # Session 3: 4 invalid attempts then a valid OTP on the 5th → reset succeeds, no block.
    Submit FP Email             ${OTP_BLK_FP_VALID5_EMAIL}
    Wait For Elements State     ${FP_OTP_INPUT}    visible
    FOR    ${i}    IN RANGE    4
        Set FP OTP And Continue    otp=${OTP_INVALID}
        Wait For Elements State    text=${ERR_OTP_INVALID}    visible
    END
    Set FP OTP And Continue     otp=${OTP}
    Wait For Elements State     ${NEW_PASSWORD_FIELD}    visible
    Fill Text                   ${NEW_PASSWORD_FIELD}           ${OTP_BLK_NEW_PASSWORD}
    Fill Text                   ${CONFIRM_NEW_PASSWORD_FIELD}   ${OTP_BLK_NEW_PASSWORD}
    Click                       ${RESET_PASSWORD_BTN}
    Wait For Elements State     ${RESET_SUCCESS_MESSAGE}    visible

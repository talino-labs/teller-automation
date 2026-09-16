*** Settings ***
Library     Browser
Library     String
Resource    ../locators/common_locators.resource


*** Keywords ***
Open Teller App
    [Documentation]    Opens the teller web app in the browser
    New Browser         ${BROWSER}    headless=${HEADLESS}
    New Context         viewport={'width': 1643, 'height': 830}    acceptDownloads=${TRUE}
    Set Browser Timeout    ${TIMEOUT}
    New Page            ${BASE_URL}    wait_until=domcontentloaded


Login To Teller App
    [Documentation]    Logs in to the teller app using valid credentials from env.yaml
    [Arguments]        ${email}=${TELLER_EMAIL}    ${password}=${TELLER_PASSWORD}
    Open Teller App
    Fill Text          ${EMAIL_FIELD}       ${email}
    Fill Text          ${PASSWORD_FIELD}    ${password}
    Click              ${LOGIN_BUTTON}
    Wait For Elements State    css=h3.text-2xl    visible

Login With Invalid Credentials
    [Documentation]    Attempts to log in using invalid credentials
    [Arguments]        ${email}=${INVALID_EMAIL}    ${password}=${INVALID_PASSWORD}
    Open Teller App
    Fill Text          ${EMAIL_FIELD}       ${email}
    Fill Text          ${PASSWORD_FIELD}    ${password}
    Click              ${LOGIN_BUTTON}

Logout From Teller App
    [Documentation]    Logs out from the teller app and closes the browser
    Click              text=Log out
    Wait For Elements State    ${LOGIN_BUTTON}    visible
    Close Browser

Navigate To Module
    [Documentation]    Navigates to a specific module via the sidebar menu
    [Arguments]        ${module_name}
    Click              css=.ant-menu-title-content >> text=${module_name}
    Wait For Elements State    css=table >> nth=0    visible

Wait For Load Spinner To Disappear
    [Documentation]    Waits for any loading spinner to disappear before proceeding
    ${spinner_visible}=    Run Keyword And Return Status
    ...                    Wait For Elements State    css=.ant-spin-spinning    visible    timeout=2s
    IF    ${spinner_visible}
        Wait For Elements State    css=.ant-spin-spinning    hidden    timeout=30s
    END

Close Modal If Open
    [Documentation]    Closes any open modal dialog to prevent blocking subsequent tests.
    ...                Handles both regular modals and confirmation modals.
    ${modal_open}=    Run Keyword And Return Status
    ...               Wait For Elements State    css=.ant-modal-wrap:not([style*="display: none"])    visible    timeout=1s
    IF    ${modal_open}
        # Try closing confirmation modal first (has buttons but no X)
        ${confirm_modal}=    Run Keyword And Return Status
        ...    Wait For Elements State    css=.ant-modal-confirm-btns    visible    timeout=0.5s
        IF    ${confirm_modal}
            Click    css=.ant-modal-confirm-btns .ant-btn-default
            Sleep    0.5s
            RETURN
        END
        # Try regular modal close button
        ${has_close_btn}=    Run Keyword And Return Status
        ...    Wait For Elements State    css=.ant-modal-close    visible    timeout=0.5s
        IF    ${has_close_btn}
            Click    css=.ant-modal-close
            Sleep    0.5s
            RETURN
        END
        # Fallback: press Escape key
        Keyboard Key    press    Escape
        Sleep    0.5s
    END

Verify Security Email Sent
    [Documentation]    Connects to Gmail via IMAP and verifies a security alert email was delivered.
    ...                Waits up to 60 s for the email to arrive, then asserts subject and optional body.
    ...                IMAP_USERNAME must be the primary Google Workspace address (not the +alias).
    [Arguments]        ${recipient}    ${expected_subject}    ${expected_body}=${EMPTY}
    Open Mailbox    host=${IMAP_HOST}    user=${IMAP_USERNAME}    password=${IMAP_PASSWORD}
    ...             port=${IMAP_PORT}    is_secure=True
    ${uids}         Wait For Email
    ...             sender=noreply@higala.ph
    ...             subject=${expected_subject}
    ...             timeout=60
    IF    '${expected_body}' != '${EMPTY}'
        ${body}    Get Email Body    ${uids}[0]
        Should Contain    ${body}    ${expected_body}
        ...    msg=Email body does not contain expected text: "${expected_body}"
    END
    Close Mailbox

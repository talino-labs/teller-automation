*** Variables ***

# ============================================================
# LOGIN PAGE
# data-testid: auth.login
# ============================================================

${LOGIN_PAGE}                       css=[data-testid="page-login"]
${EMAIL_FIELD}                      css=[data-testid="input-login-email"]
${PASSWORD_FIELD}                   css=[data-testid="input-login-password"]
${LOGIN_BUTTON}                     css=[data-testid="btn-login-submit"]
${FORGOT_PASSWORD_LINK}             css=[data-testid="link-login-forgot-password"]
${LOGIN_ERROR_MODAL}                css=[data-testid="modal-login-error"]


# ============================================================
# FORGOT PASSWORD — Step 1: Request OTP
# data-testid: auth.forgotPassword.requestOtp
# ============================================================

${FP_PAGE}                          css=[data-testid="page-forgot-password"]
${FP_EMAIL_FIELD}                   css=[data-testid="input-forgot-password-email"]
${FP_SEND_CODE_BTN}                 css=[data-testid="btn-forgot-password-send-code"]


# ============================================================
# FORGOT PASSWORD — Step 2: Verify OTP
# data-testid: auth.forgotPassword.verifyOtp
# Note: testid is on the OTP component wrapper; inner input targeted via aria-label
# ============================================================

${FP_OTP_INPUT}                     css=[data-testid="input-forgot-password-otp"] input[aria-label="Please enter OTP character 1"]
${FP_CONTINUE_BTN}                  css=[data-testid="btn-forgot-password-otp-continue"]
${FP_RESEND_BTN}                    css=[data-testid="btn-forgot-password-otp-resend"]


# ============================================================
# FORGOT PASSWORD — Step 3: Change Password
# data-testid: auth.forgotPassword.changePassword
# ============================================================

${NEW_PASSWORD_FIELD}               css=[data-testid="input-forgot-password-new-password"]
${CONFIRM_NEW_PASSWORD_FIELD}       css=[data-testid="input-forgot-password-confirm-password"]
${RESET_PASSWORD_BTN}               css=[data-testid="btn-forgot-password-reset"]
${RESET_SUCCESS_HEADING}            text=Success!
${RESET_SUCCESS_MESSAGE}            text=Password has been changed successfully.
${BACK_TO_LOGIN_BTN}                text=Back to Login


# ============================================================
# RESET TEMPORARY PASSWORD FLOW
# data-testid: auth.resetTemporaryPassword
# ============================================================

${RTP_PAGE}                         css=[data-testid="page-reset-temporary-password"]
${RTP_TEMP_PASSWORD_FIELD}          css=[data-testid="input-reset-temp-password-current"]
${RTP_NEW_PASSWORD_FIELD}           css=[data-testid="input-reset-temp-password-new"]
${RTP_CONFIRM_PASSWORD_FIELD}       css=[data-testid="input-reset-temp-password-confirm"]
${RTP_SUBMIT_BTN}                   css=[data-testid="btn-reset-temp-password-submit"]
${RTP_OTP_INPUT}                    css=[data-testid="input-reset-temp-password-otp"] input[aria-label="Please enter OTP character 1"]
${RTP_OTP_CONTINUE_BTN}             css=[data-testid="btn-reset-temp-password-otp-continue"]
${RTP_OTP_RESEND_BTN}               css=[data-testid="btn-reset-temp-password-otp-resend"]


# ============================================================
# CHANGE PASSWORD FLOW
# data-testid: profile.changePassword
# ============================================================

${CP_PROFILE_DROPDOWN}              css=[data-testid="btn-header-user-menu"]
${CP_CHANGE_PASSWORD_LINK}          css=[data-testid="menu-item-user-change-password"]
${CP_PAGE}                          css=[data-testid="page-profile-change-password"]
${CP_CURRENT_PWD_FIELD}             css=[data-testid="input-change-password-current"]
${CP_NEW_PWD_FIELD}                 css=[data-testid="input-change-password-new"]
${CP_CONFIRM_PWD_FIELD}             css=[data-testid="input-change-password-confirm"]
${CP_CONTINUE_BTN}                  css=[data-testid="btn-change-password-continue"]
${CP_OTP_INPUT}                     css=[data-testid="input-change-password-otp"]
${CP_OTP_CONTINUE_BTN}              css=[data-testid="btn-change-password-otp-continue"]
${CP_OTP_RESEND_BTN}                css=[data-testid="btn-change-password-otp-resend"]
${CP_SUCCESS_MESSAGE}               css=[data-testid="field-change-password-success"]


# ============================================================
# NAVIGATION / SIDEBAR
# data-testid: layout.sidebar
# ============================================================

${SIDEBAR_MENU_ITEM}                css=.ant-menu-title-content
${SIDEBAR_CUSTOMERS}                css=[data-testid="nav-sidebar-customers"]
${SIDEBAR_ACCOUNTS}                 css=[data-testid="nav-sidebar-accounts"]
${SIDEBAR_TRANSACTIONS}             css=[data-testid="nav-sidebar-transactions"]
${SIDEBAR_PRODUCTS}                 css=[data-testid="nav-sidebar-products"]
${SIDEBAR_LOANS}                    css=[data-testid="nav-sidebar-loans"]
${SIDEBAR_REPORTS}                  css=[data-testid="nav-sidebar-reports"]
${LOGOUT_BUTTON}                    css=[data-testid="btn-sidebar-logout"]


# ============================================================
# ANT DESIGN MODAL
# No testids for generic modal chrome — AntD class selectors remain.
# ============================================================

${MODAL}                            css=.ant-modal-content
${MODAL_TITLE}                      css=.ant-modal-title
${MODAL_CONFIRM_BTN}                xpath=//button[.//span[text()='CONFIRM'] or text()='CONFIRM']
${MODAL_OTP_ERROR}                  css=[data-testid="modal-otp-error"]
${MODAL_OTP_ERROR_CONFIRM_BTN}      css=[data-testid="modal-otp-error-btn-ok"]
${MODAL_CANCEL_BTN}                 xpath=//button[.//span[text()='CANCEL'] or text()='CANCEL']
${MODAL_OK_BTN}                     css=.ant-modal-footer button.ant-btn-primary
${MODAL_CLOSE_BTN}                  css=.ant-modal-close

# ============================================================
# OTP SESSION 60-MINUTE BLOCK (shared across Reset / Forgot / Change)
# Shown after 3 unverified OTP sessions within the window. The block modal's
# button is "CONFIRM" (reuse ${MODAL_CONFIRM_BTN}); the stable message prefix
# below tolerates the dynamic "X minutes" remaining-time text.
# ============================================================
${ERR_OTP_SESSION_BLOCKED}          You have exceeded the maximum number of attempts
# "Log in" link on the Reset/Forgot OTP screen — used to abandon an OTP session.
${OTP_ABANDON_LOGIN_LINK}           xpath=//a[normalize-space()='Log in']
# "Are you sure you want to exit?" confirmation shown when abandoning a Reset/Forgot OTP session.
${OTP_EXIT_CONFIRM_BTN}             xpath=//button[normalize-space()='Confirm']
# Back arrow on the Change Password OTP screen — used to abandon the (authenticated) OTP session.
${CP_OTP_BACK_BTN}                  xpath=//button[@aria-label='Go back']


# ============================================================
# ANT DESIGN TOAST MESSAGES
# No testids — AntD class selectors remain.
# ============================================================

${SUCCESS_TOAST}                    css=.ant-message-success
${ERROR_TOAST}                      css=.ant-message-error
${WARNING_TOAST}                    css=.ant-message-warning


# ============================================================
# CUSTOMERS MODULE
# data-testid: customers.*
# ============================================================

${CUSTOMERS_LIST_PAGE}              css=[data-testid="page-customers-list"]
${CUSTOMERS_PROFILE_PAGE}           css=[data-testid="page-customers-profile"]
${CUSTOMERS_ACCOUNTS_PAGE}          css=[data-testid="page-customers-accounts"]
${CUSTOMERS_TRANSACTIONS_PAGE}      css=[data-testid="page-customers-account-transactions"]
${AVAIL_PRODUCT_PAGE}               css=[data-testid="page-customers-avail-product"]
${AVAIL_PRODUCT_STEPS}              css=[data-testid="steps-avail-product"]

# Search — testid is on the Search component wrapper
${CUSTOMER_SEARCH}                  css=[data-testid="search-customers"]
${CUSTOMER_SEARCH_INPUT}            css=[data-testid="search-customers"] input
${CUSTOMER_SEARCH_BTN}              css=[data-testid="search-customers"] button

# Table
${CUSTOMERS_TABLE}                  css=[data-testid="table-customers"]
${TABLE_ROWS}                       css=[data-testid="table-customers"] tbody tr

# Row-level action buttons
${VIEW_PROFILE_LINK}                css=[data-testid="btn-customers-view-profile"]
${VIEW_ACCOUNTS_LINK}               css=[data-testid="btn-customers-view-accounts"]


# ============================================================
# CUSTOMERS MODULE — Enroll Customer
# data-testid: customers.enroll
# ============================================================

${ENROLL_MOBILE_INPUT}              css=[data-testid="input-enroll-customer-mobile"]
${ENROLL_CONTACT_CONTINUE_BTN}      css=[data-testid="btn-enroll-customer-contact-continue"]
${ENROLL_OTP_INPUT}                 css=[data-testid="input-enroll-customer-otp"] input[aria-label="Please enter OTP character 1"]
${ENROLL_OTP_CONTINUE_BTN}          css=[data-testid="btn-enroll-customer-otp-continue"]
${ENROLL_OTP_RESEND_BTN}            css=[data-testid="btn-enroll-customer-otp-resend"]
${ENROLL_AGREE_BTN}                 css=[data-testid="btn-enroll-customer-agree"]


# ============================================================
# ANT DESIGN TABLE (generic — for non-testid modules)
# ============================================================

${TABLE}                            css=table
${TABLE_BODY}                       css=table tbody
${NO_DATA}                          css=.ant-empty-description


# ============================================================
# ANT DESIGN PAGINATION (shared across all modules)
# ============================================================

${PAGINATION}                       css=.ant-pagination
${PAGINATION_NEXT}                  css=.ant-pagination-next button
${PAGINATION_PREV}                  css=.ant-pagination-prev button


# ============================================================
# ANT DESIGN MISC
# ============================================================

${LOADING_SPINNER}                  css=.ant-spin-spinning
${DROPDOWN_OPTIONS}                 css=.ant-select-dropdown .ant-select-item-option-content
${SEARCH_CLEAR_BTN}                 css=span.anticon-close-circle

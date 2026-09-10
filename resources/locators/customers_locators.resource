*** Variables ***
# ============================================================
# Customers Module Locators
# data-testid: customers.*
# ============================================================

# Navigation - Sidebar
${CUSTOMERS_MENU}                     css=[data-testid="nav-sidebar-customers"]


# Customer List Page
${CUSTOMER_SEARCH_FIELD}              css=[data-testid="search-customers"] input
${CUSTOMER_SEARCH_BUTTON}             css=[data-testid="search-customers"] button
${CUSTOMER_SEARCH_CLEAR}              css=span.ant-input-clear-icon

# Customer List Table
${CUSTOMER_TABLE}                     css=[data-testid="table-customers"]
${CUSTOMER_TABLE_ROWS}                css=[data-testid="table-customers"] tbody tr

# Customer List Actions (per row)
${VIEW_PROFILE_LINK}                  css=[data-testid="btn-customers-view-profile"]
${VIEW_ACCOUNTS_LINK}                 css=[data-testid="btn-customers-view-accounts"]


# Pagination
${PAGINATION_NEXT}                    css=button.ant-pagination-item-link:has(svg[data-icon="right"])
${PAGINATION_PREV}                    css=button.ant-pagination-item-link:has(svg[data-icon="left"])
${PAGINATION_PAGE}                    css=li.ant-pagination-item a[rel="nofollow"]

# Customer Status Filter (column header filter icon)
${CUSTOMER_STATUS_FILTER}             css=span.ant-table-filter-trigger

# Customer Accounts Page
${ACCOUNT_SEARCH_FIELD}               css=input[placeholder="Search accounts..."]
${ACCOUNT_SEARCH_BUTTON}              text=Search

# Customer Account Actions
${VIEW_ACCOUNT_TRANSACTIONS_LINK}     css=[data-testid="btn-accounts-view-transactions"]


# No Data
${NO_DATA_MESSAGE}                    text=No Data

# Customer Status Filter — AntD column filter dropdown
${FILTER_OPTION_ACTIVE}             css=[data-menu-id$="-active"]
${FILTER_OPTION_INACTIVE}           css=[data-menu-id$="-inactive"]
${FILTER_OPTION_DORMANT}            css=[data-menu-id$="-dormant"]
${FILTER_OPTION_CLOSED}             css=[data-menu-id$="-closed"]
${FILTER_OPTION_BLOCKED}            css=[data-menu-id$="-blocked"]
${FILTER_OPTION_RESTRICTED}         css=[data-menu-id$="-restricted"]
${FILTER_OPTION_DECEASED}           css=[data-menu-id$="-deceased"]
${FILTER_OPTION_SUSPENDED}          css=[data-menu-id$="-suspended"]
${FILTER_APPLY_BTN}                 css=button.ant-btn-primary.ant-btn-sm:has-text("OK")
${FILTER_RESET_BTN}                 css=.ant-table-filter-dropdown-btns .ant-btn-link
${FILTER_OPTION_FROZEN}             css=[data-menu-id$="-frozen"]
${FILTER_OPTION_OVERDRAWN}          css=[data-menu-id$="-overdrawn"]

# Customer Accounts Page — Table
${ACCOUNT_TABLE}                    css=[data-testid="table-customers-accounts"]
${ACCOUNT_TABLE_ROWS}               css=[data-testid="table-customers-accounts"] tbody tr
${ACCOUNT_TABLE_VISIBLE_ROWS}       css=[data-testid="table-customers-accounts"] tbody tr:not([aria-hidden="true"])

# Account Status Filter — AntD column filter dropdown (accounts page)
${ACCOUNT_STATUS_FILTER}            css=th:has-text("Account Status") span.ant-table-filter-trigger

# Customer Status Change (inline status badge dropdown + confirmation modal)
${CUSTOMER_STATUS_BADGE}                css=[data-testid="field-status-badge"]
${CUSTOMER_STATUS_DROPDOWN_INACTIVE}    css=.ant-select-dropdown .ant-select-item:not(.ant-select-item-option-selected) [data-testid="field-status-badge"]:has-text("Inactive")
${CUSTOMER_STATUS_DROPDOWN_ACTIVE}      css=.ant-select-dropdown .ant-select-item:not(.ant-select-item-option-selected) [data-testid="field-status-badge"]:has-text("Active")
${CUSTOMER_STATUS_CHANGE_MODAL}         css=.ant-modal-content:has([data-testid="modal-customer-status-change-btn-ok"])
${CUSTOMER_STATUS_REMARKS_INPUT}        css=[data-testid="input-customer-status-change-remarks"]
${CUSTOMER_STATUS_CONFIRM_BTN}          css=[data-testid="modal-customer-status-change-btn-ok"]
${CUSTOMER_STATUS_CANCEL_BTN}           css=[data-testid="modal-customer-status-change-btn-cancel"]

# Account Status Change (inline status badge dropdown + confirmation modal)
${ACCOUNT_STATUS_BADGE}                css=[data-testid="field-status-badge"]
${ACCOUNT_STATUS_DROPDOWN_DORMANT}     css=.ant-select-dropdown .ant-select-item[aria-selected="false"] [data-testid="field-status-badge"]:has-text("Dormant")
${ACCOUNT_STATUS_DROPDOWN_FROZEN}      css=.ant-select-dropdown .ant-select-item[aria-selected="false"] [data-testid="field-status-badge"]:has-text("Frozen")
${ACCOUNT_STATUS_DROPDOWN_CLOSED}      css=.ant-select-dropdown .ant-select-item[aria-selected="false"] [data-testid="field-status-badge"]:has-text("Closed")
${ACCOUNT_STATUS_DROPDOWN_ACTIVE}      css=.ant-select-dropdown .ant-select-item[aria-selected="false"] [data-testid="field-status-badge"]:has-text("Active")
${ACCOUNT_STATUS_CHANGE_MODAL}         css=.ant-modal-content:has([data-testid="modal-customer-status-change-btn-ok"])
${ACCOUNT_STATUS_REMARKS_INPUT}        css=[data-testid="input-customer-status-change-remarks"]
${ACCOUNT_STATUS_CONFIRM_BTN}          css=[data-testid="modal-customer-status-change-btn-ok"]
${ACCOUNT_STATUS_CANCEL_BTN}           css=[data-testid="modal-customer-status-change-btn-cancel"]

# Breadcrumb Navigation
${CUSTOMERS_BREADCRUMB_LINK}        css=a[href$="/dashboard/customers"]
${VIEW_ACCOUNTS_BREADCRUMB_LINK}    css=a:has-text("View Accounts")

# ============================================================
# CUSTOMER ACCOUNT TRANSACTIONS PAGE
# data-testid: customers.accountTransactions
# ============================================================

# Search
${TRANSACTION_SEARCH_FIELD}         css=input[placeholder="Search transactions..."]
${TRANSACTION_SEARCH_BUTTON}        text=Search

# Transaction Table
${TRANSACTION_TABLE}                css=[data-testid="table-customers-account-transactions"]
${TRANSACTION_TABLE_ROWS}           css=[data-testid="table-customers-account-transactions"] tbody tr
${TRANSACTION_TABLE_VISIBLE_ROWS}   css=[data-testid="table-customers-account-transactions"] tbody tr:not([aria-hidden="true"])

# Transaction Action Buttons
${VIEW_TXN_BTN}                     css=[data-testid="btn-customers-transaction-view"]
${DOWNLOAD_TXN_BTN}                 css=[data-testid="btn-customers-transaction-download"]

# Transaction Type Filter — AntD column filter dropdown
${TXN_TYPE_FILTER}                  css=th:has-text("Transaction Type") span.ant-table-filter-trigger
${TXN_TYPE_SEND_MONEY}              css=[data-menu-id$="-fund_transfer_external"]
${TXN_TYPE_RECEIVE_MONEY}           css=[data-menu-id$="-cash_in_external"]
${TXN_TYPE_FUND_TRANSFER}           css=[data-menu-id$="-fund_transfer_internal"]
${TXN_TYPE_CASH_WITHDRAWAL}         css=[data-menu-id$="-cash_withdrawal"]
${TXN_TYPE_CASH_DEPOSIT}            css=[data-menu-id$="-cash_deposit"]
${TXN_TYPE_SAVINGS_INTEREST}        css=[data-menu-id$="-interest_credit"]
${TXN_TYPE_LOAN_DISBURSEMENT}       css=[data-menu-id$="-loan_disbursement"]
${TXN_TYPE_LOAN_PAYMENT}            css=[data-menu-id$="-loan_payment"]

# Date & Time Column Filter — AntD custom date range filter
${DATE_TIME_FILTER}                 css=th:has-text("Date & Time") span.ant-table-filter-trigger
${DATE_START_INPUT}                 css=input[placeholder="Start date"]
${DATE_END_INPUT}                   css=input[placeholder="End date"]
${DATE_FILTER_SEARCH_BTN}           css=.ant-table-filter-dropdown button:has-text("Search")
${DATE_FILTER_RESET_BTN}            css=.ant-table-filter-dropdown button:has-text("Reset")

# AntD Date Picker Calendar Elements
${DATE_PICKER_PANEL}                css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden)
${DATE_PICKER_PREV_MONTH}           css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) button.ant-picker-header-prev-btn
${DATE_PICKER_NEXT_MONTH}           css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) button.ant-picker-header-next-btn
${DATE_PICKER_MONTH_SELECT}         css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-month-btn
${DATE_PICKER_YEAR_SELECT}          css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-year-btn

# Transaction Status Filter — AntD column filter dropdown
${TXN_STATUS_FILTER}                css=th:has-text("Status") span.ant-table-filter-trigger
${TXN_STATUS_PENDING}               css=[data-menu-id$="-pending"]
${TXN_STATUS_SUCCESS}               css=[data-menu-id$="-success"]
${TXN_STATUS_FAILED}                css=[data-menu-id$="-failed"]

# ============================================================
# CUSTOMER PROFILE — Products Availed & Eligible Products
# data-testid: customers.profile
# ============================================================

${PRODUCTS_AVAILED_TAB}             css=button:has-text("Products Availed")
${ELIGIBLE_PRODUCTS_TAB}            css=button:has-text("Eligible Products")

# Availed Products Table
${PRODUCTS_AVAILED_TABLE}           css=[data-testid="table-customers-availed-products"]
# Eligible Products Table
${PRODUCTS_ELIGIBLE_TABLE}          css=[data-testid="table-customers-eligible-products"]
# Generic fallback (used in tests that target either table)
${PRODUCT_TABLE}                    css=.ant-table-body table
${PRODUCT_TABLE_ROWS}               css=.ant-table-body table tbody tr:not([aria-hidden="true"])

# Action Buttons
${SEE_DETAILS_BTN}                  css=[data-testid="btn-customers-profile-see-details"]
${AVAIL_PRODUCT_BTN}                css=[data-testid="btn-customers-profile-avail-product"]

# Eligible Products Search
${PRODUCT_SEARCH_INPUT}             css=[data-testid="search-customers-eligible-products"] input
${PRODUCT_SEARCH_BTN}               css=[data-testid="search-customers-eligible-products"] button

# Product Drawers
${AVAILED_PRODUCT_DRAWER}           css=[data-testid="drawer-customers-availed-product"]
${ELIGIBLE_PRODUCT_DETAILS_DRAWER}  css=[data-testid="drawer-customers-eligible-product"]
${PRODUCT_DETAILS_CLOSE_BTN}        css=.ant-drawer-close


# Transaction Detail Modal
${TXN_DETAIL_MODAL}                 css=[data-testid="modal-customers-transaction-details"] .ant-modal
${TXN_DETAIL_CLOSE_BTN}             css=.ant-modal-close
${TXN_DETAIL_BACK_BTN}              css=[data-testid="modal-customers-transaction-details"] button:has-text("Back")


# ============================================================
# AVAIL PRODUCT FLOW
# data-testid: customers.availProduct
# ============================================================
${AVAIL_PRODUCT_FULL_NAME_INPUT}    css=[data-testid="page-customers-avail-product"] input[placeholder="Enter full name"]
${AVAIL_PRODUCT_SEE_DETAILS_BTN}    css=[data-testid="btn-avail-product-see-details"]
${AVAIL_PRODUCT_CONTINUE_BTN}       css=[data-testid="btn-avail-product-continue"]
${AVAIL_PRODUCT_BACK_BTN}           css=[data-testid="page-customers-avail-product"] button:has-text("Back")
${AVAIL_PRODUCT_CONFIRM_BTN}        css=[data-testid="btn-avail-product-submit"]
${AVAIL_PRODUCT_BACK_TO_PROFILE}    css=[data-testid="btn-avail-product-back-to-profile"]
# Drawer opened from the avail product page (no data-testid on this context's drawer)
${AVAIL_PRODUCT_DETAILS_DRAWER}     css=.ant-drawer-content

# Loan product availment — Customer Information step (t2.6)
${AVAIL_LOAN_AMOUNT_INPUT}          css=[data-field="loanAmount"] input.ant-input-number-input
${AVAIL_LOAN_INTEREST_RATE_INPUT}   css=[data-field="interestRate"] input.ant-input-number-input
${AVAIL_LOAN_TERM_LENGTH_INPUT}     css=[data-field="termLength"] input.ant-input-number-input
${AVAIL_LOAN_DISBURSEMENT_SELECT}   css=[data-field="disbursementMode"] .ant-select-selector
${AVAIL_LOAN_EMPLOYER_NAME_INPUT}   css=[data-field="employerName"] input
# Product-agnostic: the loan custom field is named per product (employerName on
# some, tellUsSomethingAboutYourself on Regular Home Loan), so match any
# [data-field] input that is not one of the four standard loan-detail inputs.
${AVAIL_LOAN_CUSTOM_FIELD_INPUT}    css=[data-field]:not([data-field="loanAmount"]):not([data-field="interestRate"]):not([data-field="termLength"]):not([data-field="disbursementMode"]) input >> nth=0
${AVAIL_LOAN_SUCCESS_PANEL}         css=[data-testid="field-avail-product-success"]

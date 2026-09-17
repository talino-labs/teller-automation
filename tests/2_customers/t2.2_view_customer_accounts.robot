*** Settings ***
Documentation       t2.2 View the List of Bank Accounts under a Customer
...                 Covers initial load, pagination, search, account status filtering,
...                 and navigation back to the customer list.

Resource            ../../resources/keywords/common.resource
Resource            ../../resources/keywords/customers.resource

Suite Setup         Login To Teller App
Suite Teardown      Close Browser
Test Setup          Navigate To Customer Accounts Page    ${CUSTOMER_NAME}


*** Variables ***
${ACCOUNT_STATUS}           Active
${ACCOUNT_ROW}              css=.ant-table-body table tbody tr.ant-table-row:has-text("${VALID_ACCOUNT_ID}")
${NON_EXISTING_ACCOUNT}     NonExistentAcc


*** Test Cases ***
t2.2.1 Customer Accounts List View
    [Documentation]    Verify that the accounts list for a customer is loaded and displayed
    ...                with all required columns and the View Account Transactions action link.
    [Tags]             customers    accounts    smoke    mvp    type1
    Get Url                    contains    /accounts
    Wait For Elements State    text=Account No                                  visible
    Wait For Elements State    text=Account Name                                visible
    Wait For Elements State    text=Balance                                     visible
    Wait For Elements State    text=Account Status                              visible
    Wait For Elements State    text=Created on                                  visible
    Wait For Elements State    text="Action"                                    visible
    Wait For Elements State    ${VIEW_ACCOUNT_TRANSACTIONS_LINK} >> nth=0    visible

t2.2.2 Account List Pagination and Navigation
    [Documentation]    Verify that pagination controls work correctly:
    ...                Next loads page 2, clicking page 3 loads page 3,
    ...                and Back returns to page 2. Skips if only one page exists.
    [Tags]             customers    accounts    regression    mvp    type1
    # Check if pagination has more than one page (next button not disabled)
    ${has_multiple_pages}=    Run Keyword And Return Status
    ...    Wait For Elements State    css=.ant-pagination-next:not(.ant-pagination-disabled)    visible    timeout=3s
    IF    ${has_multiple_pages}
        # Click Next arrow to go to page 2
        Click                      ${PAGINATION_NEXT}
        Wait For Elements State    css=li.ant-pagination-item-active:has-text("2")    visible
        # Click page number 3 if it exists
        ${page3_exists}=    Run Keyword And Return Status
        ...    Wait For Elements State    css=li.ant-pagination-item[title="3"]    visible    timeout=2s
        IF    ${page3_exists}
            Click                      css=li.ant-pagination-item[title="3"]
            Wait For Elements State    css=li.ant-pagination-item-active[title="3"]    visible
            # Click Back arrow to return to page 2
            Click                      ${PAGINATION_PREV}
            Wait For Elements State    css=li.ant-pagination-item-active:has-text("2")    visible
        ELSE
            # Only 2 pages - click Back to return to page 1
            Click                      ${PAGINATION_PREV}
            Wait For Elements State    css=li.ant-pagination-item-active:has-text("1")    visible
        END
    ELSE
        Log    Only one page of accounts - pagination navigation skipped
        Wait For Elements State    css=.ant-pagination-next.ant-pagination-disabled    visible
    END

t2.2.3 Search for Valid Account ID
    [Documentation]    Verify that searching by a valid Account ID returns exactly one record
    ...                and the result row contains all expected column values.
    [Tags]             customers    accounts    smoke    mvp    type1
    Fill Text                  ${ACCOUNT_SEARCH_FIELD}    ${VALID_ACCOUNT_ID}
    Click                      ${ACCOUNT_SEARCH_BUTTON}
    Wait For Elements State    ${ACCOUNT_ROW}    visible
    Get Element Count          ${ACCOUNT_TABLE_VISIBLE_ROWS}    ==    1
    # Verify column headers
    Wait For Elements State    text=Account No        visible
    Wait For Elements State    text=Account Name      visible
    Wait For Elements State    text=Balance           visible
    Wait For Elements State    css=th:has-text("Account Status")    visible
    Wait For Elements State    text=Created on        visible
    Wait For Elements State    text="Action"          visible
    # Verify all column values in the matching row
    Wait For Elements State    ${ACCOUNT_ROW} >> text=${VALID_ACCOUNT_ID}                  visible
    Wait For Elements State    ${ACCOUNT_ROW} >> text=${VALID_ACCOUNT_NAME}                visible
    Wait For Elements State    ${ACCOUNT_ROW} >> text=${ACCOUNT_STATUS}                    visible
    Wait For Elements State    ${ACCOUNT_ROW} >> text=${ACCOUNT_CREATED_ON}                visible
    Wait For Elements State    ${ACCOUNT_ROW} >> ${VIEW_ACCOUNT_TRANSACTIONS_LINK}         visible

t2.2.4 Search for Valid Account Name
    [Documentation]    Verify that searching by Account Name returns all matching records.
    ...                The system displays records where the name matches or partially matches,
    ...                all required columns remain visible, and the target row contains the correct data.
    [Tags]             customers    accounts    smoke    mvp    type1
    Fill Text                  ${ACCOUNT_SEARCH_FIELD}    ${VALID_ACCOUNT_NAME}
    Click                      ${ACCOUNT_SEARCH_BUTTON}
    Wait For Elements State    ${ACCOUNT_TABLE}        visible
    Wait For Elements State    ${ACCOUNT_TABLE_VISIBLE_ROWS} >> nth=0    visible
    # Verify column headers
    Wait For Elements State    text=Account No        visible
    Wait For Elements State    text=Account Name      visible
    Wait For Elements State    text=Balance           visible
    Wait For Elements State    css=th:has-text("Account Status")    visible
    Wait For Elements State    text=Created on        visible
    Wait For Elements State    text="Action"          visible
    # Verify all column values in the target account row
    Wait For Elements State    ${ACCOUNT_ROW} >> text=${VALID_ACCOUNT_ID}                  visible
    Wait For Elements State    ${ACCOUNT_ROW} >> text=${VALID_ACCOUNT_NAME}                visible
    Wait For Elements State    ${ACCOUNT_ROW} >> text=${ACCOUNT_STATUS}                    visible
    Wait For Elements State    ${ACCOUNT_ROW} >> text=${ACCOUNT_CREATED_ON}                visible
    Wait For Elements State    ${ACCOUNT_ROW} >> ${VIEW_ACCOUNT_TRANSACTIONS_LINK}         visible

t2.2.5 Search for Non-Existing Account
    [Documentation]    Verify that searching for a non-existing account shows a "No Data" message
    ...                with an empty table and no application errors.
    [Tags]             customers    accounts    negative    mvp    type1
    Fill Text                  ${ACCOUNT_SEARCH_FIELD}    ${NON_EXISTING_ACCOUNT}
    Click                      ${ACCOUNT_SEARCH_BUTTON}
    Wait For Elements State    css=.ant-empty-description:has-text("No data")    visible
    Wait For Elements State    ${ACCOUNT_TABLE}                                  visible

t2.2.6 Filter Account List by Status - Active
    [Documentation]    Verify that filtering by Active status shows only Active accounts.
    ...                If no Active accounts exist, a "No Data" message is shown.
    [Tags]             customers    accounts    regression    mvp    type1
    Click                      ${ACCOUNT_STATUS_FILTER}
    Click                      ${FILTER_OPTION_ACTIVE}
    Click                      ${FILTER_APPLY_BTN}
    Wait For Elements State    ${ACCOUNT_TABLE}    visible
    Filter Account Results Should Contain Only Status    Active

t2.2.7 Filter Account List by Status - Dormant
    [Documentation]    Verify that filtering by Dormant status shows only Dormant accounts.
    ...                If no Dormant accounts exist, a "No Data" message is shown.
    [Tags]             customers    accounts    regression    mvp    type1
    Click                      ${ACCOUNT_STATUS_FILTER}
    Click                      ${FILTER_OPTION_DORMANT}
    Click                      ${FILTER_APPLY_BTN}
    Wait For Elements State    ${ACCOUNT_TABLE}    visible
    Filter Account Results Should Contain Only Status    Dormant

t2.2.8 Filter Account List by Status - Frozen
    [Documentation]    Verify that filtering by Frozen status shows only Frozen accounts.
    ...                If no Frozen accounts exist, a "No Data" message is shown.
    [Tags]             customers    accounts    regression    mvp    type1
    Click                      ${ACCOUNT_STATUS_FILTER}
    Click                      ${FILTER_OPTION_FROZEN}
    Click                      ${FILTER_APPLY_BTN}
    Wait For Elements State    ${ACCOUNT_TABLE}    visible
    Filter Account Results Should Contain Only Status    Frozen

t2.2.9 Filter Account List by Status - Closed
    [Documentation]    Verify that filtering by Closed status shows only Closed accounts.
    ...                If no Closed accounts exist, a "No Data" message is shown.
    [Tags]             customers    accounts    regression    mvp    type1
    Click                      ${ACCOUNT_STATUS_FILTER}
    Click                      ${FILTER_OPTION_CLOSED}
    Click                      ${FILTER_APPLY_BTN}
    Wait For Elements State    ${ACCOUNT_TABLE}    visible
    Filter Account Results Should Contain Only Status    Closed


t2.2.10 Change Account Status to Dormant
    [Documentation]    INVALID: "Dormant" is a system-set status (applied automatically after
    ...                inactivity) — a teller cannot manually set it, so it is not offered in the
    ...                status-change dropdown. Marked skip; kept for reference/history.
    [Tags]             customers    accounts    status-change    smoke    type1    skip
    [Setup]            Navigate To Customer Accounts Page    ${T22_STATUS_CHANGE_CUSTOMER_ID}
    Skip               Invalid transition — teller cannot manually set an account to Dormant (system-set status)
    Wait For Elements State    ${ACCOUNT_TABLE}    visible
    Fill Text    ${ACCOUNT_SEARCH_FIELD}    ${T22_STATUS_CHANGE_ACCOUNT_NO}
    Click    ${ACCOUNT_SEARCH_BUTTON}
    Wait For Load Spinner To Disappear
    Wait For Elements State    css=[data-testid="table-customers-accounts"] tbody tr:not([aria-hidden="true"]) >> nth=0    visible
    Click    css=[data-testid="table-customers-accounts"] tbody tr:not([aria-hidden="true"]) >> nth=0 >> css=[data-testid="field-status-badge"]
    Wait For Elements State    ${ACCOUNT_STATUS_DROPDOWN_DORMANT}    visible
    Click    ${ACCOUNT_STATUS_DROPDOWN_DORMANT}
    Wait For Elements State    ${ACCOUNT_STATUS_CHANGE_MODAL}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ACCOUNT_STATUS_CHANGE_MODAL} >> text=Tag account as dormant?    visible
    Fill Text    ${ACCOUNT_STATUS_REMARKS_INPUT}    ${T22_STATUS_CHANGE_REMARKS}
    Wait For Elements State    ${ACCOUNT_STATUS_CONFIRM_BTN}    enabled
    Click    ${ACCOUNT_STATUS_CONFIRM_BTN}
    Wait For Elements State    text=Account status updated successfully.    visible
    Reload
    Wait For Load Spinner To Disappear
    Fill Text    ${ACCOUNT_SEARCH_FIELD}    ${T22_STATUS_CHANGE_ACCOUNT_NO}
    Click    ${ACCOUNT_SEARCH_BUTTON}
    Wait For Load Spinner To Disappear
    Wait For Elements State
    ...    css=[data-testid="table-customers-accounts"] tbody tr:not([aria-hidden="true"]) >> nth=0 >> css=[data-testid="field-status-badge"]:has-text("Dormant")
    ...    visible

t2.2.11 Change Account Status to Frozen
    [Documentation]    Verify that a teller can change an account's status to Frozen.
    ...                Searches for a specific account, clicks the status badge, selects
    ...                Frozen, fills remarks, confirms, verifies the success toast, then
    ...                searches again and verifies the status badge shows Frozen.
    [Tags]             customers    accounts    status-change    smoke    type1
    [Setup]            Navigate To Customer Accounts Page    ${T22_STATUS_CHANGE_CUSTOMER_ID}
    Wait For Elements State    ${ACCOUNT_TABLE}    visible
    Fill Text    ${ACCOUNT_SEARCH_FIELD}    ${T22_STATUS_CHANGE_ACCOUNT_NO}
    Click    ${ACCOUNT_SEARCH_BUTTON}
    Wait For Load Spinner To Disappear
    Wait For Elements State    css=[data-testid="table-customers-accounts"] tbody tr:not([aria-hidden="true"]) >> nth=0    visible
    Click    css=[data-testid="table-customers-accounts"] tbody tr:not([aria-hidden="true"]) >> nth=0 >> css=[data-testid="field-status-badge"]
    Wait For Elements State    ${ACCOUNT_STATUS_DROPDOWN_FROZEN}    visible
    Click    ${ACCOUNT_STATUS_DROPDOWN_FROZEN}
    Wait For Elements State    ${ACCOUNT_STATUS_CHANGE_MODAL}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ACCOUNT_STATUS_CHANGE_MODAL} >> text=Tag account as frozen?    visible
    Fill Text    ${ACCOUNT_STATUS_REMARKS_INPUT}    ${T22_STATUS_CHANGE_REMARKS}
    Wait For Elements State    ${ACCOUNT_STATUS_CONFIRM_BTN}    enabled
    Click    ${ACCOUNT_STATUS_CONFIRM_BTN}
    Wait For Elements State    text=Account status updated successfully.    visible
    Reload
    Wait For Load Spinner To Disappear
    Fill Text    ${ACCOUNT_SEARCH_FIELD}    ${T22_STATUS_CHANGE_ACCOUNT_NO}
    Click    ${ACCOUNT_SEARCH_BUTTON}
    Wait For Load Spinner To Disappear
    Wait For Elements State
    ...    css=[data-testid="table-customers-accounts"] tbody tr:not([aria-hidden="true"]) >> nth=0 >> css=[data-testid="field-status-badge"]:has-text("Frozen")
    ...    visible

t2.2.12 Change Account Status to Closed
    [Documentation]    INVALID for a repeatable suite: "Closed" is a terminal status — once set,
    ...                the account cannot be reverted, so this permanently burns the test account
    ...                on every run. Marked skip; the Frozen<->Active transitions (t2.2.11/t2.2.13)
    ...                provide repeatable status-change coverage. Kept for reference/history.
    [Tags]             customers    accounts    status-change    smoke    type1    skip
    [Setup]            Navigate To Customer Accounts Page    ${T22_STATUS_CHANGE_CUSTOMER_ID}
    Skip               Terminal status — closing the account is not reversible and would burn the test account each run
    Wait For Elements State    ${ACCOUNT_TABLE}    visible
    Fill Text    ${ACCOUNT_SEARCH_FIELD}    ${T22_STATUS_CHANGE_ACCOUNT_NO}
    Click    ${ACCOUNT_SEARCH_BUTTON}
    Wait For Load Spinner To Disappear
    Wait For Elements State    css=[data-testid="table-customers-accounts"] tbody tr:not([aria-hidden="true"]) >> nth=0    visible
    Click    css=[data-testid="table-customers-accounts"] tbody tr:not([aria-hidden="true"]) >> nth=0 >> css=[data-testid="field-status-badge"]
    Wait For Elements State    ${ACCOUNT_STATUS_DROPDOWN_CLOSED}    visible
    Click    ${ACCOUNT_STATUS_DROPDOWN_CLOSED}
    Wait For Elements State    ${ACCOUNT_STATUS_CHANGE_MODAL}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ACCOUNT_STATUS_CHANGE_MODAL} >> text=Tag account as closed?    visible
    Fill Text    ${ACCOUNT_STATUS_REMARKS_INPUT}    ${T22_STATUS_CHANGE_REMARKS}
    Wait For Elements State    ${ACCOUNT_STATUS_CONFIRM_BTN}    enabled
    Click    ${ACCOUNT_STATUS_CONFIRM_BTN}
    Wait For Elements State    text=Account status updated successfully.    visible
    Reload
    Wait For Load Spinner To Disappear
    Fill Text    ${ACCOUNT_SEARCH_FIELD}    ${T22_STATUS_CHANGE_ACCOUNT_NO}
    Click    ${ACCOUNT_SEARCH_BUTTON}
    Wait For Load Spinner To Disappear
    Wait For Elements State
    ...    css=[data-testid="table-customers-accounts"] tbody tr:not([aria-hidden="true"]) >> nth=0 >> css=[data-testid="field-status-badge"]:has-text("Closed")
    ...    visible

t2.2.13 Change Account Status to Active
    [Documentation]    Verify that a teller can restore an account from Frozen back to Active.
    ...                Runs after t2.2.11 (which sets the account Frozen); Frozen->Active is a
    ...                valid transition, so this restores the account to its starting state and
    ...                keeps the status-change chain repeatable.
    [Tags]             customers    accounts    status-change    smoke    type1
    [Setup]            Navigate To Customer Accounts Page    ${T22_STATUS_CHANGE_CUSTOMER_ID}
    Wait For Elements State    ${ACCOUNT_TABLE}    visible
    Fill Text    ${ACCOUNT_SEARCH_FIELD}    ${T22_STATUS_CHANGE_ACCOUNT_NO}
    Click    ${ACCOUNT_SEARCH_BUTTON}
    Wait For Load Spinner To Disappear
    Wait For Elements State    css=[data-testid="table-customers-accounts"] tbody tr:not([aria-hidden="true"]) >> nth=0    visible
    Click    css=[data-testid="table-customers-accounts"] tbody tr:not([aria-hidden="true"]) >> nth=0 >> css=[data-testid="field-status-badge"]
    Wait For Elements State    ${ACCOUNT_STATUS_DROPDOWN_ACTIVE}    visible
    Click    ${ACCOUNT_STATUS_DROPDOWN_ACTIVE}
    Wait For Elements State    ${ACCOUNT_STATUS_CHANGE_MODAL}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ACCOUNT_STATUS_CHANGE_MODAL} >> text=Tag account as active?    visible
    Fill Text    ${ACCOUNT_STATUS_REMARKS_INPUT}    ${T22_STATUS_CHANGE_REMARKS}
    Wait For Elements State    ${ACCOUNT_STATUS_CONFIRM_BTN}    enabled
    Click    ${ACCOUNT_STATUS_CONFIRM_BTN}
    Wait For Elements State    text=Account status updated successfully.    visible
    Reload
    Wait For Load Spinner To Disappear
    Fill Text    ${ACCOUNT_SEARCH_FIELD}    ${T22_STATUS_CHANGE_ACCOUNT_NO}
    Click    ${ACCOUNT_SEARCH_BUTTON}
    Wait For Load Spinner To Disappear
    Wait For Elements State
    ...    css=[data-testid="table-customers-accounts"] tbody tr:not([aria-hidden="true"]) >> nth=0 >> css=[data-testid="field-status-badge"]:has-text("Active")
    ...    visible

t2.2.14 Navigate Back to Customers List
    [Documentation]    Verify that clicking the 'Customers' breadcrumb link returns the user
    ...                to the main Customer List view with the customer table visible.
    [Tags]             customers    accounts    regression    mvp    rerun    type1
    Click                      ${CUSTOMERS_BREADCRUMB_LINK}
    Wait For Elements State    ${CUSTOMER_TABLE}          visible
    Wait For Elements State    ${CUSTOMER_SEARCH_FIELD}   visible
    Get Url                    contains    /dashboard/customers

t2.2.15 Filter Account List by Status - Blocked
    [Documentation]    Verify that filtering a customer's accounts by Blocked status shows only
    ...                Blocked accounts (or a "No Data" message if none exist). Covers catalog
    ...                TC t2.2.12 — the automated suite reuses t2.2.10-13 for the status-change
    ...                tests, so the Blocked column filter is verified here.
    [Tags]             customers    accounts    regression    type2
    Click                      ${ACCOUNT_STATUS_FILTER}
    Click                      ${FILTER_OPTION_BLOCKED}
    Click                      ${FILTER_APPLY_BTN}
    Wait For Elements State    ${ACCOUNT_TABLE}    visible
    Filter Account Results Should Contain Only Status    Blocked

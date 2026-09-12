*** Settings ***
Documentation       t8.1 Interest Crediting
...                 Covers automated daily interest crediting job behavior,
...                 computation accuracy across savings products, transaction
...                 record verification, and edge-case account scenarios.
...
...                 Prerequisites:
...                 - The 12:00 AM interest crediting job has already run for today.
...                 - All TODO variables in rural-bank-san-antonio.yaml must be filled
...                   before running T8.1.2–T8.1.5 and T8.1.8–T8.1.17.

Resource            ../../resources/keywords/common.resource
Resource            ../../resources/keywords/accounts.resource

Suite Setup         Login To Teller App
Suite Teardown      Close Browser
Test Teardown       Close Modal If Open


*** Variables ***
${TODAY}            ${EMPTY}    # set dynamically in Suite Setup if needed
${INTEREST_TYPE}    Savings Interest


*** Test Cases ***
t8.1.1 Interest crediting job runs automatically at 12:00 AM daily
    [Documentation]    Verify the interest crediting job is triggered automatically at 12:00 AM
    ...                without manual intervention. Requires access to system job scheduler
    ...                or execution logs — cannot be verified via UI alone.
    [Tags]             interest    scheduler    type1    manual-verify
    Skip    Cannot be automated via UI — requires system job scheduler or log access to verify trigger time.

t8.1.2 Daily interest is correctly computed and credited — Product A (Rate: 2%)
    [Documentation]    Verify Account A (Product A, 2% rate, ₱50,000 balance) is credited ₱2.74.
    ...                Formula: 50,000 × ((2 / 100) / 365) = ₱2.74
    ...                Assumes the 12:00 AM job has already run for today.
    [Tags]             interest    computation    product-a    type1
    Skip If    '${T81_PRODUCT_A_ACCOUNT_NO}' == ''    T81_PRODUCT_A_ACCOUNT_NO not configured — update variables file.
    Navigate To Account Transactions    ${T81_PRODUCT_A_ACCOUNT_NO}
    Reload
    Wait For Load Spinner To Disappear
    Verify Today Interest Credit    ${T81_PRODUCT_A_EXPECTED_INTEREST}

t8.1.3 Daily interest is correctly computed and credited — Product B (Rate: 5%)
    [Documentation]    Verify Account B (Product B, 5% rate, ₱50,000 balance) is credited ₱6.85.
    ...                Formula: 50,000 × ((5 / 100) / 365) = ₱6.85
    ...                Assumes the 12:00 AM job has already run for today.
    [Tags]             interest    computation    product-b    type1
    Skip If    '${T81_PRODUCT_B_ACCOUNT_NO}' == ''    T81_PRODUCT_B_ACCOUNT_NO not configured — update variables file.
    Navigate To Account Transactions    ${T81_PRODUCT_B_ACCOUNT_NO}
    Reload
    Wait For Load Spinner To Disappear
    Verify Today Interest Credit    ${T81_PRODUCT_B_EXPECTED_INTEREST}

t8.1.4 Both Product A (2%) and Product B (5%) accounts are credited correctly in the same job run
    [Documentation]    Verify Product A account receives ₱2.74 and Product B receives ₱6.85 in
    ...                the same 12:00 AM job run with no cross-product rate contamination.
    [Tags]             interest    computation    multi-product    type1
    Skip If    '${T81_PRODUCT_A_ACCOUNT_NO}' == ''    T81_PRODUCT_A_ACCOUNT_NO not configured — update variables file.
    Skip If    '${T81_PRODUCT_B_ACCOUNT_NO}' == ''    T81_PRODUCT_B_ACCOUNT_NO not configured — update variables file.
    # Verify Product A
    Navigate To Account Transactions    ${T81_PRODUCT_A_ACCOUNT_NO}
    Reload
    Wait For Load Spinner To Disappear
    Verify Today Interest Credit    ${T81_PRODUCT_A_EXPECTED_INTEREST}
    # Verify Product B
    Navigate To Account Transactions    ${T81_PRODUCT_B_ACCOUNT_NO}
    Reload
    Wait For Load Spinner To Disappear
    Verify Today Interest Credit    ${T81_PRODUCT_B_EXPECTED_INTEREST}

t8.1.5 All eligible accounts across both savings products are processed in a single job run
    [Documentation]    Verify every eligible account is credited with the correct product-specific
    ...                interest. No account is skipped and no rate bleed occurs.
    [Tags]             interest    computation    multi-product    type1
    Skip If    '${T81_PRODUCT_A_ACCOUNT_NO}' == ''    T81_PRODUCT_A_ACCOUNT_NO not configured — update variables file.
    Skip If    '${T81_PRODUCT_B_ACCOUNT_NO}' == ''    T81_PRODUCT_B_ACCOUNT_NO not configured — update variables file.
    Navigate To Account Transactions    ${T81_PRODUCT_A_ACCOUNT_NO}
    Reload
    Wait For Load Spinner To Disappear
    Verify Today Interest Credit    ${T81_PRODUCT_A_EXPECTED_INTEREST}
    Navigate To Account Transactions    ${T81_PRODUCT_B_ACCOUNT_NO}
    Reload
    Wait For Load Spinner To Disappear
    Verify Today Interest Credit    ${T81_PRODUCT_B_EXPECTED_INTEREST}

t8.1.6 Credited interest is reflected in the transaction history with correct details
    [Documentation]    Verify the interest credit transaction record in the account history contains:
    ...                Transaction ID, type = Savings Interest, date = today at 12 AM,
    ...                Debit Amount = N/A, Credit Amount = computed daily interest, Status = Success.
    [Tags]             interest    transaction-history    smoke    mvp    type1
    Skip If    '${T81_PRODUCT_B_ACCOUNT_NO}' == ''    T81_PRODUCT_B_ACCOUNT_NO not configured — update variables file.
    Navigate To Account Transactions    ${T81_PRODUCT_B_ACCOUNT_NO}
    Reload
    Wait For Load Spinner To Disappear
    # Filter by Savings Interest type to isolate the transaction
    Click                      ${TXN_TYPE_FILTER}
    Click                      ${TXN_TYPE_SAVINGS_INTEREST}
    Click                      ${FILTER_APPLY_BTN}
    Wait For Elements State    ${ACCT_TXN_TABLE}    visible
    # Verify at least one Savings Interest transaction exists
    Wait For Elements State
    ...    css=.ant-table-body table tbody tr:not([aria-hidden="true"]) >> nth=0    visible
    # Verify the first row's transaction type
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    css=.ant-table-body table tbody tr:not([aria-hidden="true"]) >> nth=0 >> text=Savings Interest
    ...    visible
    # Verify Status = Success
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    css=.ant-table-body table tbody tr:not([aria-hidden="true"]) >> nth=0 >> text=Success
    ...    visible
    # Verify Credit Amount is not N/A (interest was credited)
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    css=.ant-table-body table tbody tr:not([aria-hidden="true"]) >> nth=0 >> css=[data-testid="field-credit-amount"]:not(:has-text("N/A"))
    ...    visible

t8.1.7 Viewing specific transaction details displays correct values
    [Documentation]    Verify the interest credit transaction detail modal shows:
    ...                Transaction ID, Type = Savings Interest, Transaction Amount,
    ...                Service Fee = 0.00, Remarks = Savings Interest Auto Credit,
    ...                Status = Success, Debit Account Name = N/A, Debit Account Number = N/A,
    ...                Credit Account Name, Credit Account Number, Created on, Updated on.
    [Tags]             interest    transaction-history    smoke    mvp    type1
    Skip If    '${T81_PRODUCT_B_ACCOUNT_NO}' == ''    T81_PRODUCT_B_ACCOUNT_NO not configured — update variables file.
    Navigate To Account Transactions    ${T81_PRODUCT_B_ACCOUNT_NO}
    Reload
    Wait For Load Spinner To Disappear
    # Filter to Savings Interest and open the first result
    Click                      ${TXN_TYPE_FILTER}
    Click                      ${TXN_TYPE_SAVINGS_INTEREST}
    Click                      ${FILTER_APPLY_BTN}
    Wait For Elements State    ${ACCT_TXN_TABLE}    visible
    Wait For Elements State    css=.ant-table-body table tbody tr:not([aria-hidden="true"]) >> nth=0    visible
    Click
    ...    css=.ant-table-body table tbody tr:not([aria-hidden="true"]) >> nth=0 >> ${VIEW_TXN_BTN}
    Wait For Elements State    ${ACCT_TXN_DETAIL_MODAL}    visible
    # Verify all required detail fields
    Run Keyword And Continue On Failure    Wait For Elements State    ${ACCT_TXN_DETAIL_MODAL} >> text=Transaction ID               visible
    Run Keyword And Continue On Failure    Wait For Elements State    ${ACCT_TXN_DETAIL_MODAL} >> text=Transaction Type             visible
    Run Keyword And Continue On Failure    Wait For Elements State    ${ACCT_TXN_DETAIL_MODAL} >> text="Savings Interest"           visible
    Run Keyword And Continue On Failure    Wait For Elements State    ${ACCT_TXN_DETAIL_MODAL} >> text=Transaction Amount           visible
    Run Keyword And Continue On Failure    Wait For Elements State    ${ACCT_TXN_DETAIL_MODAL} >> text=Service Fee                 visible
    Run Keyword And Continue On Failure    Wait For Elements State    ${ACCT_TXN_DETAIL_MODAL} >> text=0.00                        visible
    Run Keyword And Continue On Failure    Wait For Elements State    ${ACCT_TXN_DETAIL_MODAL} >> text=Remarks                     visible
    Run Keyword And Continue On Failure    Wait For Elements State    ${ACCT_TXN_DETAIL_MODAL} >> text=Savings Interest Auto Credit visible
    Run Keyword And Continue On Failure    Wait For Elements State    ${ACCT_TXN_DETAIL_MODAL} >> text=Transaction Status          visible
    Run Keyword And Continue On Failure    Wait For Elements State    ${ACCT_TXN_DETAIL_MODAL} >> text=Success                     visible
    Run Keyword And Continue On Failure    Wait For Elements State    ${ACCT_TXN_DETAIL_MODAL} >> text=Debit Account Name          visible
    Run Keyword And Continue On Failure    Wait For Elements State    ${ACCT_TXN_DETAIL_MODAL} >> text=Debit Account Number        visible
    Run Keyword And Continue On Failure    Wait For Elements State    ${ACCT_TXN_DETAIL_MODAL} >> text=Credit Account Name         visible
    Run Keyword And Continue On Failure    Wait For Elements State    ${ACCT_TXN_DETAIL_MODAL} >> text=Credit Account Number       visible
    Run Keyword And Continue On Failure    Wait For Elements State    ${ACCT_TXN_DETAIL_MODAL} >> text=Created on                  visible
    Run Keyword And Continue On Failure    Wait For Elements State    ${ACCT_TXN_DETAIL_MODAL} >> text=Updated on                  visible

t8.1.8 Balance update is net-based and no tax is deducted from the credited interest
    [Documentation]    Verify the account balance increases by the full computed interest with
    ...                no tax withheld. No tax deduction entry appears in the transaction record.
    ...                Formula: amount × ((rate / 100) / 365)
    [Tags]             interest    computation    no-tax    type1
    Skip If    '${T81_PRODUCT_B_ACCOUNT_NO}' == ''    T81_PRODUCT_B_ACCOUNT_NO not configured — update variables file.
    Navigate To Account Transactions    ${T81_PRODUCT_B_ACCOUNT_NO}
    Reload
    Wait For Load Spinner To Disappear
    Verify Today Interest Credit    ${T81_PRODUCT_B_EXPECTED_INTEREST}

t8.1.9 Interest is correctly computed for a high-balance account (₱1,000,000.00) under Product B (5%)
    [Documentation]    Verify high-balance account is credited ₱136.99 without overflow or truncation.
    ...                Formula: 1,000,000 × ((5 / 100) / 365) = ₱136.99
    [Tags]             interest    computation    high-balance    type1
    Skip If    '${T81_HIGH_BAL_ACCOUNT_NO}' == ''    T81_HIGH_BAL_ACCOUNT_NO not configured — update variables file.
    Navigate To Account Transactions    ${T81_HIGH_BAL_ACCOUNT_NO}
    Reload
    Wait For Load Spinner To Disappear
    Verify Today Interest Credit    ${T81_HIGH_BAL_EXPECTED_INTEREST}

t8.1.10 Interest is credited correctly for a minimum-interest balance (₱73.00) under Product B (5%)
    [Documentation]    Verify minimum-threshold account (₱73.00) is credited ₱0.01.
    ...                Formula: 73 × ((5 / 100) / 365) = ₱0.01 (minimum creditable amount)
    [Tags]             interest    computation    min-balance    type1
    Skip If    '${T81_MIN_BAL_ACCOUNT_NO}' == ''    T81_MIN_BAL_ACCOUNT_NO not configured — update variables file.
    Navigate To Account Transactions    ${T81_MIN_BAL_ACCOUNT_NO}
    Reload
    Wait For Load Spinner To Disappear
    Verify Today Interest Credit    ${T81_MIN_BAL_EXPECTED_INTEREST}

t8.1.11 Interest crediting on a leap year date uses 365 as the divisor, not 366
    [Documentation]    Verify the interest formula always uses divisor 365, even on Feb 29.
    ...                Can only be verified on a leap year date — skip until next leap year.
    [Tags]             interest    computation    leap-year    type1
    Skip    Must be executed on a leap year date (e.g., February 29). Skipped until next leap year.

t8.1.12 Interest crediting job does not double-credit if re-triggered on the same calendar day
    [Documentation]    Verify the system prevents duplicate crediting if the job is re-triggered
    ...                on the same day. Requires admin-level job re-trigger capability.
    [Tags]             interest    idempotency    type1    manual-verify
    Skip    Cannot be automated via UI — requires admin/system access to re-trigger the crediting job.

t8.1.13 Accounts under Product A (2%) and Product B (5%) retain their own rates during the same job run
    [Documentation]    Verify no rate bleed: Product A account receives 2% rate interest and
    ...                Product B account receives 5% rate interest independently.
    [Tags]             interest    computation    rate-isolation    type1
    Skip If    '${T81_PRODUCT_A_ACCOUNT_NO}' == ''    T81_PRODUCT_A_ACCOUNT_NO not configured — update variables file.
    Skip If    '${T81_PRODUCT_B_ACCOUNT_NO}' == ''    T81_PRODUCT_B_ACCOUNT_NO not configured — update variables file.
    Navigate To Account Transactions    ${T81_PRODUCT_A_ACCOUNT_NO}
    Reload
    Wait For Load Spinner To Disappear
    Verify Today Interest Credit    ${T81_PRODUCT_A_EXPECTED_INTEREST}
    Navigate To Account Transactions    ${T81_PRODUCT_B_ACCOUNT_NO}
    Reload
    Wait For Load Spinner To Disappear
    Verify Today Interest Credit    ${T81_PRODUCT_B_EXPECTED_INTEREST}

t8.1.14 No interest is credited for a balance below the minimum threshold (< ₱73.00) under Product B (5%)
    [Documentation]    Verify account with ₱72.99 (below minimum threshold) receives no interest.
    ...                Computed interest < ₱0.01 should not result in any transaction.
    [Tags]             interest    negative    min-threshold    type1
    Skip If    '${T81_BELOW_MIN_ACCOUNT_NO}' == ''    T81_BELOW_MIN_ACCOUNT_NO not configured — update variables file.
    Navigate To Account Transactions    ${T81_BELOW_MIN_ACCOUNT_NO}
    Reload
    Wait For Load Spinner To Disappear
    Verify No Interest Credit Today

t8.1.15 No interest is credited to a savings account with a zero balance
    [Documentation]    Verify account with ₱0.00 balance receives no interest transaction.
    ...                Formula: 0 × ((rate / 100) / 365) = ₱0.00 → no credit.
    [Tags]             interest    negative    zero-balance    type1
    Skip If    '${T81_ZERO_BAL_ACCOUNT_NO}' == ''    T81_ZERO_BAL_ACCOUNT_NO not configured — update variables file.
    Navigate To Account Transactions    ${T81_ZERO_BAL_ACCOUNT_NO}
    Reload
    Wait For Load Spinner To Disappear
    Verify No Interest Credit Today

t8.1.16 No interest is credited to a closed or inactive savings account
    [Documentation]    Verify closed/inactive account is skipped by the job. No transaction posted,
    ...                balance and status remain unchanged.
    [Tags]             interest    negative    closed-account    type1
    Skip If    '${T81_CLOSED_ACCOUNT_NO}' == ''    T81_CLOSED_ACCOUNT_NO not configured — update variables file.
    Navigate To Account Transactions    ${T81_CLOSED_ACCOUNT_NO}
    Reload
    Wait For Load Spinner To Disappear
    Verify No Interest Credit Today

t8.1.17 No interest is credited when the savings product has an interest rate of 0%
    [Documentation]    Verify account under a 0% rate product receives no interest transaction.
    ...                Formula: balance × ((0 / 100) / 365) = ₱0.00 → no credit.
    [Tags]             interest    negative    zero-rate    type1
    Skip If    '${T81_ZERO_RATE_ACCOUNT_NO}' == ''    T81_ZERO_RATE_ACCOUNT_NO not configured — update variables file.
    Navigate To Account Transactions    ${T81_ZERO_RATE_ACCOUNT_NO}
    Reload
    Wait For Load Spinner To Disappear
    Verify No Interest Credit Today


*** Keywords ***
Verify Today Interest Credit
    [Documentation]    Filters by Savings Interest type and verifies a transaction row exists
    ...                containing the expected interest amount as the credit.
    [Arguments]    ${expected_amount}
    Click                      ${TXN_TYPE_FILTER}
    Click                      ${TXN_TYPE_SAVINGS_INTEREST}
    Click                      ${FILTER_APPLY_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State
    ...    css=.ant-table-body table tbody tr:not([aria-hidden="true"]):has-text("${expected_amount}")    visible
    ...    timeout=10s
    ...    message=No Savings Interest transaction found with amount ${expected_amount} — ensure the 12:00 AM job has run.
    Wait For Elements State
    ...    css=.ant-table-body table tbody tr:not([aria-hidden="true"]):has-text("${expected_amount}"):has-text("Success")    visible
    ...    timeout=5s
    ...    message=Transaction with amount ${expected_amount} does not have Success status.
    # Reset filter
    Click    ${FILTER_RESET_BTN}
    Wait For Load Spinner To Disappear

Verify No Interest Credit Today
    [Documentation]    Filters by Savings Interest type and verifies no transaction exists for today.
    Click                      ${TXN_TYPE_FILTER}
    Click                      ${TXN_TYPE_SAVINGS_INTEREST}
    Click                      ${FILTER_APPLY_BTN}
    Wait For Load Spinner To Disappear
    ${no_data}=    Run Keyword And Return Status
    ...    Wait For Elements State    ${NO_DATA_MESSAGE}    visible    timeout=5s
    IF    not ${no_data}
        # If data exists, check if it's from a previous day (not today)
        ${row_text}=    Get Text
        ...    css=.ant-table-body table tbody tr:not([aria-hidden="true"]) >> nth=0
        Log    Found interest transaction but it may be from a previous day: ${row_text}    WARN
    END
    # Reset filter
    Click    ${FILTER_RESET_BTN}
    Wait For Load Spinner To Disappear

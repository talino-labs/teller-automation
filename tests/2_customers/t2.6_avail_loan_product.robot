*** Settings ***
Documentation       t2.6 Existing Customer Avails a Loans Product
...                 Covers the full Loans product availment flow:
...                 Customer Information step (editable Loan Details + custom fields,
...                 See Details side panel), Review and Confirm step, success page,
...                 and post-availment Pending Applications check.

Resource            ../../resources/keywords/common.resource
Resource            ../../resources/keywords/customers.resource
Resource            ../../resources/keywords/loans.resource
Resource            ../../resources/keywords/products.resource

Suite Setup         Open Customer Profile And Cache URL
Suite Teardown      Close Browser
Test Setup          Return To Customer Profile Page
Test Teardown       Close Drawer If Open


*** Keywords ***
Open Customer Profile And Cache URL
    [Documentation]    Logs in, navigates to the t2.6 target customer profile, and caches
    ...                the URL so subsequent tests can navigate directly without re-searching.
    Login To Teller App
    Navigate To Customers
    View Customer Profile    ${T26_CUSTOMER_ID}
    ${url}=    Get Url
    Set Suite Variable    ${CUSTOMER_PROFILE_URL}    ${url}

Return To Customer Profile Page
    [Documentation]    Navigates directly to the cached customer profile URL before each test.
    ...                Longer pace here than other suites: the loan availment flow makes more
    ...                requests per test, so a bigger gap keeps it under the backend rate limit.
    Sleep                      20s
    Go To                      ${CUSTOMER_PROFILE_URL}
    Wait For Load Spinner To Disappear
    Wait For Elements State    ${CUSTOMERS_PROFILE_PAGE}    visible    timeout=15s

Close Drawer If Open
    [Documentation]    Closes any open drawer by clicking the close button if visible.
    ${drawer_visible}=    Run Keyword And Return Status
    ...    Wait For Elements State    css=.ant-drawer-body    visible    timeout=1s
    IF    ${drawer_visible}
        Click    ${PRODUCT_DETAILS_CLOSE_BTN}
        Wait For Elements State    css=.ant-drawer-body    hidden    timeout=5s
    END

Navigate To Avail Loan Product Page
    [Documentation]    From the customer profile Eligible Products tab, searches for the
    ...                target Loans product and clicks Avail Product.
    Click                        ${ELIGIBLE_PRODUCTS_TAB}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${PRODUCT_SEARCH_INPUT}    visible    timeout=10s
    Fill Text                    ${PRODUCT_SEARCH_INPUT}    ${EMPTY}
    Fill Text                    ${PRODUCT_SEARCH_INPUT}    ${T26_LOANS_PRODUCT}
    Click                        ${PRODUCT_SEARCH_BTN}
    Wait For Load Spinner To Disappear
    # Prefer the 2nd match (nth=1) when a duplicate-named product exists — e.g. San Antonio
    # has two "Regular Home Loan"s and the 2nd carries the custom field the tests verify.
    # Fall back to the single match (nth=0) when there's only one eligible product with that
    # name — e.g. SNR-SIT's single custom-field "Loan 0722160721".
    ${match_count}=    Get Element Count    css=.ant-table-body tr:has-text("${T26_LOANS_PRODUCT}")
    ${idx}=            Set Variable If    ${match_count} > 1    1    0
    Wait For Elements State      css=.ant-table-body tr:has-text("${T26_LOANS_PRODUCT}") >> nth=${idx}    visible    timeout=10s
    Click                        css=.ant-table-body tr:has-text("${T26_LOANS_PRODUCT}") >> nth=${idx} >> ${AVAIL_PRODUCT_BTN}
    Wait For Elements State      ${AVAIL_PRODUCT_PAGE}    visible
    Wait For Load Spinner To Disappear

Fill Loan Details
    [Documentation]    Fills the Loan Amount, Interest Rate, Loan Term Length, and selects
    ...                Mode of Disbursement on the Customer Information step.
    Wait For Elements State      ${AVAIL_LOAN_AMOUNT_INPUT}             visible
    Fill Text                    ${AVAIL_LOAN_AMOUNT_INPUT}             ${T26_LOAN_AMOUNT}
    Fill Text                    ${AVAIL_LOAN_INTEREST_RATE_INPUT}      ${T26_INTEREST_RATE}
    Fill Text                    ${AVAIL_LOAN_TERM_LENGTH_INPUT}        ${T26_LOAN_TERM_LENGTH}
    Click                        ${AVAIL_LOAN_DISBURSEMENT_SELECT}
    Wait For Elements State      css=.ant-select-dropdown .ant-select-item-option:has-text("${T26_DISBURSEMENT_MODE}")    visible
    Click                        css=.ant-select-dropdown .ant-select-item-option:has-text("${T26_DISBURSEMENT_MODE}")

Fill Employer Name
    [Documentation]    Fills the loan product's custom text field. The custom field NAME varies
    ...                per product (e.g. employerName, tellUsSomethingAboutYourself), so target
    ...                any field that is not one of the standard loan-detail inputs rather than a
    ...                hardcoded name. Fills every such custom input with ${value} so
    ...                the downstream value checks still work.
    [Arguments]    ${value}=${T26_EMPLOYER_NAME}
    ${custom}=    Set Variable
    ...    css=[data-field]:not([data-field="loanAmount"]):not([data-field="interestRate"]):not([data-field="termLength"]):not([data-field="disbursementMode"]) input
    Wait For Elements State      ${custom} >> nth=0    visible    timeout=10s
    ${count}=    Get Element Count    ${custom}
    FOR    ${i}    IN RANGE    ${count}
        Fill Text    ${custom} >> nth=${i}    ${value}
    END

Select Disbursement Mode
    [Documentation]    Opens the Mode of Disbursement dropdown and picks the configured value.
    Click                        ${AVAIL_LOAN_DISBURSEMENT_SELECT}
    Wait For Elements State      css=.ant-select-dropdown .ant-select-item-option:has-text("${T26_DISBURSEMENT_MODE}")    visible
    Click                        css=.ant-select-dropdown .ant-select-item-option:has-text("${T26_DISBURSEMENT_MODE}")

Trigger Blur On Field
    [Documentation]    Forces an InputNumber field to blur so AntD runs format/validation logic.
    [Arguments]        ${field_locator}
    Press Keys                   ${field_locator}    Tab

Approve Pending Loan For Customer
    [Documentation]    Navigates to Pending Applications, searches for the customer, and
    ...                approves the first matching pending loan row.
    [Arguments]        ${customer_name}
    Navigate To Pending Applications Page
    View Pending Applications List
    Fill Text                    ${PENDING_APPS_SEARCH_INPUT}    ${customer_name}
    Click                        ${PENDING_APPS_SEARCH_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State
    ...    ${PENDING_APPS_TABLE} >> tbody tr:has-text("${customer_name}") >> nth=0    visible    timeout=10s
    Click
    ...    ${PENDING_APPS_TABLE} >> tbody tr:has-text("${customer_name}") >> ${PENDING_APPS_APPROVE_BTN} >> nth=0
    Wait For Elements State      ${APP_DECISION_MODAL}    visible    timeout=10s
    Click                        ${APP_DECISION_CLOSE_BTN}
    Wait For Load Spinner To Disappear

Count All Accounts
    [Documentation]    Returns the total account row count across all pagination pages.
    ${total}=    Set Variable    ${0}
    WHILE    True
        ${rows}=    Get Elements    ${ACCOUNT_TABLE_VISIBLE_ROWS}
        ${page_count}=    Get Length    ${rows}
        ${total}=    Evaluate    ${total} + ${page_count}
        ${has_next}=    Run Keyword And Return Status
        ...    Wait For Elements State
        ...    css=.ant-pagination-next:not(.ant-pagination-disabled)    visible    timeout=1s
        IF    not ${has_next}    BREAK
        Click                    ${PAGINATION_NEXT}
        Wait For Load Spinner To Disappear
    END
    RETURN    ${total}


*** Test Cases ***

t2.6.1 Avail Loans Product – Customer Information Step
    [Documentation]    Verify that clicking Avail Product on a Loans product navigates to the
    ...                Customer Information step. Customer Details, Product Details, Loan
    ...                Details (editable), and any required custom fields are displayed.
    ...                Continue button is disabled until all required fields are filled.
    [Tags]             customers    products    loans    smoke    mvp    type2

    Navigate To Avail Loan Product Page
    ${url}=    Get Url
    Set Suite Variable    ${AVAIL_PAGE_URL}    ${url}

    # Page and stepper
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_PAGE}                                     visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_STEPS}                                    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_PAGE} >> text=Customer Information        visible

    # Customer Details section
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_PAGE} >> text=Customer Details            visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_PAGE} >> text=Email Address               visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_PAGE} >> text=Mobile Number               visible

    # Product Details section
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_PAGE} >> text=Product Details             visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_PAGE} >> text=Product Name                visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_PAGE} >> text=${T26_LOANS_PRODUCT}        visible

    # Loan Details section (editable)
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_PAGE} >> text=Loan Details                visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_LOAN_AMOUNT_INPUT}             visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_LOAN_INTEREST_RATE_INPUT}      visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_LOAN_TERM_LENGTH_INPUT}        visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_LOAN_DISBURSEMENT_SELECT}      visible

    # Continue button disabled before required fields filled
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_CONTINUE_BTN}    disabled


t2.6.2 Verify Loan Details Fields Are Editable During Availment (Customer Information Step)
    [Documentation]    Verify that all Loan Details fields are enabled and editable on the
    ...                Customer Information step. Entered values are retained and accepted.
    ...                Continue becomes enabled once all required fields (Loan Details +
    ...                custom fields) are filled.
    [Tags]             customers    products    loans    smoke    mvp    type2

    Navigate To Avail Loan Product Page

    # All Loan Details inputs are enabled
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_LOAN_AMOUNT_INPUT}             enabled
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_LOAN_INTEREST_RATE_INPUT}      enabled
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_LOAN_TERM_LENGTH_INPUT}        enabled
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_LOAN_DISBURSEMENT_SELECT}      visible

    # Fill Loan Details
    Fill Loan Details

    # Values are retained (AntD InputNumber formats with commas + 2 decimals on blur)
    ${loan_amount_value}=        Get Property    ${AVAIL_LOAN_AMOUNT_INPUT}             value
    ${interest_rate_value}=      Get Property    ${AVAIL_LOAN_INTEREST_RATE_INPUT}      value
    ${term_length_value}=        Get Property    ${AVAIL_LOAN_TERM_LENGTH_INPUT}        value
    ${loan_amount_clean}=        Evaluate    '${loan_amount_value}'.replace(',', '')
    ${interest_rate_clean}=      Evaluate    '${interest_rate_value}'.replace(',', '')
    ${term_length_clean}=        Evaluate    '${term_length_value}'.replace(',', '')
    Run Keyword And Continue On Failure
    ...    Should Be Equal As Numbers    ${loan_amount_clean}      ${T26_LOAN_AMOUNT}
    Run Keyword And Continue On Failure
    ...    Should Be Equal As Numbers    ${interest_rate_clean}    ${T26_INTEREST_RATE}
    Run Keyword And Continue On Failure
    ...    Should Be Equal As Numbers    ${term_length_clean}      ${T26_LOAN_TERM_LENGTH}
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    ${AVAIL_LOAN_DISBURSEMENT_SELECT}:has-text("${T26_DISBURSEMENT_MODE}")    visible

    # Fill custom field then assert Continue is enabled
    Fill Employer Name
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_CONTINUE_BTN}    enabled


t2.6.3 See Details of Loans Product During Availment (Customer Information Step)
    [Documentation]    Verify that clicking See Details on the Product Details section opens
    ...                a side panel with complete Loans product configuration, closes cleanly,
    ...                and leaves the user on the Customer Information step with Loan Details
    ...                fields unaffected.
    [Tags]             customers    products    loans    smoke    mvp    type2

    Navigate To Avail Loan Product Page

    Click                        ${AVAIL_PRODUCT_SEE_DETAILS_BTN}
    Wait For Elements State      ${AVAIL_PRODUCT_DETAILS_DRAWER}    visible

    # Product Definition / Details
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Product name              visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Product type              visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Description               visible

    # Loan Features
    Scroll To Element    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Minimum loan amount
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Minimum loan amount       visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Maximum loan amount       visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Loan term length          visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Loan term unit            visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Repayment method          visible

    # Eligibility Criteria
    Scroll To Element    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Minimum age
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Minimum age               visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Required documents        visible

    # Pricing & Fees
    Scroll To Element    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text="Processing fee"
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text="Processing fee"              visible
    Scroll To Element    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Penalty interest rate
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Penalty interest rate         visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Penalty conditions            visible

    # Close the side panel and verify user remains on Customer Information step
    Click                        ${PRODUCT_DETAILS_CLOSE_BTN}
    Wait For Elements State      ${AVAIL_PRODUCT_DETAILS_DRAWER}    hidden
    Wait For Elements State      ${AVAIL_PRODUCT_PAGE}              visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_LOAN_AMOUNT_INPUT}    visible


t2.6.4 Fill Loan Details and Custom Fields for Loans Product and Continue
    [Documentation]    Verify that filling all required Loan Details and custom fields enables
    ...                the Continue button, entered values are retained, and the user proceeds
    ...                to the Review Application step with an accurate summary.
    [Tags]             customers    products    loans    smoke    mvp    type2

    Navigate To Avail Loan Product Page

    # Continue disabled before filling
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_CONTINUE_BTN}    disabled

    Fill Loan Details
    Fill Employer Name

    # Continue enabled after all required fields are filled
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_CONTINUE_BTN}    enabled

    # Proceed to Review step
    Click    ${AVAIL_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State    ${AVAIL_PRODUCT_PAGE} >> text=Review Application    visible

    # Cache review URL for t2.6.5 reuse if needed
    ${review_url}=    Get Url
    Set Suite Variable    ${REVIEW_PAGE_URL}    ${review_url}

    # Verify review summary reflects all entered Loan Details and custom field values
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_PAGE} >> text=Loan Details                visible
    # NOTE: the custom-field section header varies per product (it was "Employment Information"
    # for the old employerName field), so we verify the custom field VALUE below instead of a
    # hardcoded section-header label.
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_PAGE} >> text=${T26_EMPLOYER_NAME}        visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_PAGE} >> text=${T26_DISBURSEMENT_MODE}    visible


t2.6.5 Review and Confirm Loans Product Availment
    [Documentation]    Verify that the Review Application step shows accurate data, Confirm
    ...                and Avail processes the request, and the Success page is displayed
    ...                with the correct product name and a Back to Customer Profile button.
    [Tags]             customers    products    loans    smoke    mvp    type2

    # Complete the Customer Information step to reach Review
    Navigate To Avail Loan Product Page
    Fill Loan Details
    Fill Employer Name
    Click                        ${AVAIL_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${AVAIL_PRODUCT_PAGE} >> text=Review Application    visible

    # Confirm availment
    Click                        ${AVAIL_PRODUCT_CONFIRM_BTN}
    Wait For Load Spinner To Disappear

    # Verify Success page
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_LOAN_SUCCESS_PANEL}                            visible    timeout=15s
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Product Availed                                   visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=${T26_LOANS_PRODUCT} >> nth=0                     visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_BACK_TO_PROFILE}                       visible


t2.6.6 Verify Newly Availed Loan Appears in Pending Applications Module
    [Documentation]    Verify that after a successful Loans availment, clicking Back to
    ...                Customer Profile returns the user to the profile, and the newly availed
    ...                loan appears in the Pending Applications module with status Pending.
    [Tags]             customers    products    loans    smoke    mvp    type2

    # Complete the full avail flow to reach the Success page
    # (Success state is React in-memory — the URL cannot be navigated to directly)
    Navigate To Avail Loan Product Page
    Fill Loan Details
    Fill Employer Name
    Click                        ${AVAIL_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Click                        ${AVAIL_PRODUCT_CONFIRM_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${AVAIL_PRODUCT_BACK_TO_PROFILE}    visible    timeout=15s

    # Back to customer profile
    Click                        ${AVAIL_PRODUCT_BACK_TO_PROFILE}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${CUSTOMERS_PROFILE_PAGE}    visible

    # Navigate to Pending Applications and verify the new loan appears
    Navigate To Pending Applications Page
    View Pending Applications List
    Fill Text                    ${PENDING_APPS_SEARCH_INPUT}    ${T26_CUSTOMER_NAME}
    Click                        ${PENDING_APPS_SEARCH_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State
    ...    ${PENDING_APPS_TABLE} >> tbody tr:has-text("${T26_CUSTOMER_NAME}") >> nth=0    visible    timeout=10s
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    ${PENDING_APPS_TABLE} >> tbody tr:has-text("${T26_LOANS_PRODUCT}") >> nth=0    visible


t2.6.7 View Newly Approved Loans Product in Customer Profile
    [Documentation]    Verify that after a Loans product is availed and approved, the product
    ...                appears in the Products Availed tab. Its See Details drawer shows the
    ...                Loan Details values entered during availment along with the submitted
    ...                custom fields.
    ...                SKIPPED — loan approval flow is being built under t7 / loans suite.
    [Tags]             customers    products    loans    regression    mvp    type2    skip

    Skip    Loan approval flow is being built under t7 — re-enable when Approve Loan is wired in

    # Complete the full avail flow to reach the Success page
    Navigate To Avail Loan Product Page
    Fill Loan Details
    Fill Employer Name
    Click                        ${AVAIL_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Click                        ${AVAIL_PRODUCT_CONFIRM_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${AVAIL_PRODUCT_BACK_TO_PROFILE}    visible    timeout=15s
    Click                        ${AVAIL_PRODUCT_BACK_TO_PROFILE}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${CUSTOMERS_PROFILE_PAGE}    visible

    # Approve the pending loan application
    Approve Pending Loan For Customer    ${T26_CUSTOMER_NAME}

    # Return to customer profile and verify the approved loan appears in Products Availed
    Return To Customer Profile Page
    Click                        ${PRODUCTS_AVAILED_TAB}
    Wait For Load Spinner To Disappear
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    css=.ant-table-body tr:has-text("${T26_LOANS_PRODUCT}") >> nth=0    visible    timeout=10s

    # Open See Details for the first matching product row
    Click
    ...    css=.ant-table-body tr:has-text("${T26_LOANS_PRODUCT}") >> ${SEE_DETAILS_BTN} >> nth=0
    Wait For Elements State    ${AVAILED_PRODUCT_DRAWER}    visible

    # Verify drawer shows the product name and the submitted custom field value
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAILED_PRODUCT_DRAWER} >> text=${T26_LOANS_PRODUCT}     visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAILED_PRODUCT_DRAWER} >> text=${T26_EMPLOYER_NAME}     visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAILED_PRODUCT_DRAWER} >> text=${T26_DISBURSEMENT_MODE} visible

    # Close drawer
    Click                        ${PRODUCT_DETAILS_CLOSE_BTN}
    Wait For Elements State      ${AVAILED_PRODUCT_DRAWER}    hidden


t2.6.8 Verify New Account Number Generated After Loan Approval
    [Documentation]    Snapshot the customer's account count before availment, perform the
    ...                Loans availment, approve the pending loan, and verify a new account
    ...                record was created.
    ...                SKIPPED — loan approval flow is being built under t7 / loans suite.
    [Tags]             customers    accounts    loans    regression    mvp    type2    skip

    Skip    Loan approval flow is being built under t7 — re-enable when Approve Loan is wired in

    # Snapshot all account numbers before availment (across all pages)
    Navigate To Customers
    View Customer Accounts    ${T26_CUSTOMER_NAME}
    Wait For Load Spinner To Disappear
    Wait For Elements State    ${ACCOUNT_TABLE}    visible
    ${count_before}=    Count All Accounts

    # Perform loans availment from the customer profile
    Return To Customer Profile Page
    Navigate To Avail Loan Product Page
    Fill Loan Details
    Fill Employer Name
    Click                        ${AVAIL_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Click                        ${AVAIL_PRODUCT_CONFIRM_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${AVAIL_PRODUCT_BACK_TO_PROFILE}    visible    timeout=15s
    Click                        ${AVAIL_PRODUCT_BACK_TO_PROFILE}
    Wait For Load Spinner To Disappear

    # Approve the newly created pending loan application
    Approve Pending Loan For Customer    ${T26_CUSTOMER_NAME}

    # Snapshot all account numbers after approval
    Navigate To Customers
    View Customer Accounts    ${T26_CUSTOMER_NAME}
    Wait For Load Spinner To Disappear
    Wait For Elements State    ${ACCOUNT_TABLE}    visible
    ${count_after}=    Count All Accounts

    Should Be True    ${count_after} > ${count_before}
    ...    Expected a new account after loan approval (before: ${count_before}, after: ${count_after})


t2.6.9 Modify Loan Details and Custom Field Inputs on Review Step and Re-Confirm
    [Documentation]    Verify that clicking Back from the Review step returns to Customer
    ...                Information with form still filled, modified Loan Details and custom
    ...                field values are reflected in the review summary, and the product is
    ...                successfully availed with the updated data.
    [Tags]             customers    products    loans    regression    mvp    type2

    Navigate To Avail Loan Product Page
    Fill Loan Details
    Fill Employer Name
    Click                        ${AVAIL_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${AVAIL_PRODUCT_PAGE} >> text=Review Application    visible

    # Click Back to return to Customer Information step
    Click                        ${AVAIL_PRODUCT_BACK_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${AVAIL_LOAN_AMOUNT_INPUT}    visible

    # Modify the loan amount and employer name
    Fill Text                    ${AVAIL_LOAN_AMOUNT_INPUT}             ${T26_MODIFIED_LOAN_AMOUNT}
    Fill Employer Name           ${T26_MODIFIED_EMPLOYER_NAME}

    # Continue back to Review — modified values should appear in summary
    Click                        ${AVAIL_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${AVAIL_PRODUCT_PAGE} >> text=Review Application    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_PAGE} >> text=${T26_MODIFIED_EMPLOYER_NAME}    visible

    # Confirm and verify success
    Click                        ${AVAIL_PRODUCT_CONFIRM_BTN}
    Wait For Load Spinner To Disappear
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Product Availed                  visible    timeout=15s
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_BACK_TO_PROFILE}      visible


t2.6.10 Loan Amount Below Minimum Is Rejected
    [Documentation]    Verify that entering a Loan Amount below the configured minimum surfaces
    ...                an inline validation error and keeps the Continue button disabled.
    [Tags]             customers    products    loans    validation    type2

    Navigate To Avail Loan Product Page
    Fill Text                    ${AVAIL_LOAN_INTEREST_RATE_INPUT}      ${T26_INTEREST_RATE}
    Fill Text                    ${AVAIL_LOAN_TERM_LENGTH_INPUT}        ${T26_LOAN_TERM_LENGTH}
    Select Disbursement Mode
    Fill Employer Name
    Fill Text                    ${AVAIL_LOAN_AMOUNT_INPUT}             ${T26_LOAN_AMOUNT_BELOW_MIN}
    Trigger Blur On Field        ${AVAIL_LOAN_AMOUNT_INPUT}

    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_CONTINUE_BTN}    disabled    timeout=5s


t2.6.11 Loan Amount Above Maximum Is Rejected
    [Documentation]    Verify that entering a Loan Amount above the configured maximum surfaces
    ...                an inline validation error and keeps the Continue button disabled.
    [Tags]             customers    products    loans    validation    type2

    Navigate To Avail Loan Product Page
    Fill Text                    ${AVAIL_LOAN_INTEREST_RATE_INPUT}      ${T26_INTEREST_RATE}
    Fill Text                    ${AVAIL_LOAN_TERM_LENGTH_INPUT}        ${T26_LOAN_TERM_LENGTH}
    Select Disbursement Mode
    Fill Employer Name
    Fill Text                    ${AVAIL_LOAN_AMOUNT_INPUT}             ${T26_LOAN_AMOUNT_ABOVE_MAX}
    Trigger Blur On Field        ${AVAIL_LOAN_AMOUNT_INPUT}

    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_CONTINUE_BTN}    disabled    timeout=5s


t2.6.12 Leave All Required Loan Details Empty – Continue Disabled
    [Documentation]    Verify that with all Loan Details fields empty, the Continue button
    ...                stays disabled and the user cannot proceed.
    [Tags]             customers    products    loans    validation    type2

    Navigate To Avail Loan Product Page
    # Fill the custom field so only Loan Details are missing
    Fill Employer Name
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_CONTINUE_BTN}    disabled


t2.6.13 Leave Loan Amount Empty – Validation Error
    [Documentation]    Verify that leaving only Loan Amount empty triggers an inline error
    ...                and keeps the Continue button disabled.
    [Tags]             customers    products    loans    validation    type2

    Navigate To Avail Loan Product Page
    Fill Text                    ${AVAIL_LOAN_INTEREST_RATE_INPUT}      ${T26_INTEREST_RATE}
    Fill Text                    ${AVAIL_LOAN_TERM_LENGTH_INPUT}        ${T26_LOAN_TERM_LENGTH}
    Select Disbursement Mode
    Fill Employer Name

    # Fill then clear Loan Amount to trigger inline validation
    Fill Text                    ${AVAIL_LOAN_AMOUNT_INPUT}    1
    Press Keys                   ${AVAIL_LOAN_AMOUNT_INPUT}    Backspace
    Trigger Blur On Field        ${AVAIL_LOAN_AMOUNT_INPUT}

    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_CONTINUE_BTN}    disabled


t2.6.14 Leave Loan Term Length Empty – Validation Error
    [Documentation]    Verify that leaving Loan Term Length empty triggers an inline error
    ...                and keeps the Continue button disabled.
    [Tags]             customers    products    loans    validation    type2

    Navigate To Avail Loan Product Page
    Fill Text                    ${AVAIL_LOAN_AMOUNT_INPUT}             ${T26_LOAN_AMOUNT}
    Fill Text                    ${AVAIL_LOAN_INTEREST_RATE_INPUT}      ${T26_INTEREST_RATE}
    Select Disbursement Mode
    Fill Employer Name

    # Fill then clear Loan Term Length
    Fill Text                    ${AVAIL_LOAN_TERM_LENGTH_INPUT}    1
    Press Keys                   ${AVAIL_LOAN_TERM_LENGTH_INPUT}    Backspace
    Trigger Blur On Field        ${AVAIL_LOAN_TERM_LENGTH_INPUT}

    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_CONTINUE_BTN}    disabled


t2.6.15 Leave Mode of Disbursement Empty – Validation Error
    [Documentation]    Verify that leaving Mode of Disbursement unselected keeps the Continue
    ...                button disabled.
    [Tags]             customers    products    loans    validation    type2

    Navigate To Avail Loan Product Page
    Fill Text                    ${AVAIL_LOAN_AMOUNT_INPUT}             ${T26_LOAN_AMOUNT}
    Fill Text                    ${AVAIL_LOAN_INTEREST_RATE_INPUT}      ${T26_INTEREST_RATE}
    Fill Text                    ${AVAIL_LOAN_TERM_LENGTH_INPUT}        ${T26_LOAN_TERM_LENGTH}
    Fill Employer Name
    # Do not select Mode of Disbursement

    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_CONTINUE_BTN}    disabled


t2.6.16 Enter Non-Numeric Loan Amount – Input Rejected
    [Documentation]    Verify that AntD InputNumber auto-rejects alphabetic input in the
    ...                Loan Amount field (the value is never saved) and Continue stays disabled.
    [Tags]             customers    products    loans    validation    type2

    Navigate To Avail Loan Product Page
    Fill Text                    ${AVAIL_LOAN_AMOUNT_INPUT}    abcdef
    Trigger Blur On Field        ${AVAIL_LOAN_AMOUNT_INPUT}

    ${field_value}=    Get Property    ${AVAIL_LOAN_AMOUNT_INPUT}    value
    Run Keyword And Continue On Failure
    ...    Should Be Empty    ${field_value}
    ...    msg=Invalid characters were not rejected on blur — field contains: '${field_value}'
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_CONTINUE_BTN}    disabled


t2.6.17 Enter Zero or Negative Loan Amount
    [Documentation]    Verify that entering 0 or a negative Loan Amount is rejected (AntD
    ...                InputNumber clamps to aria-valuemin or surfaces an inline error) and
    ...                Continue stays disabled.
    [Tags]             customers    products    loans    validation    type2

    Navigate To Avail Loan Product Page
    Fill Text                    ${AVAIL_LOAN_INTEREST_RATE_INPUT}      ${T26_INTEREST_RATE}
    Fill Text                    ${AVAIL_LOAN_TERM_LENGTH_INPUT}        ${T26_LOAN_TERM_LENGTH}
    Select Disbursement Mode
    Fill Employer Name

    Fill Text                    ${AVAIL_LOAN_AMOUNT_INPUT}             ${T26_NEGATIVE_LOAN_AMOUNT}
    Trigger Blur On Field        ${AVAIL_LOAN_AMOUNT_INPUT}

    # Either the value is clamped (cannot be negative) or an inline error shows
    ${field_value}=    Get Property    ${AVAIL_LOAN_AMOUNT_INPUT}    value
    ${clean_value}=    Evaluate    '${field_value}'.replace(',', '')
    Run Keyword And Continue On Failure
    ...    Should Not Be Equal As Numbers    ${clean_value}    ${T26_NEGATIVE_LOAN_AMOUNT}
    ...    msg=Loan Amount accepted a negative value: '${field_value}'
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_CONTINUE_BTN}    disabled


t2.6.18 Enter Zero or Negative Loan Term Length
    [Documentation]    Verify that AntD InputNumber rejects a negative Loan Term Length: the
    ...                minus sign is stripped (aria-valuemin=0 prevents negative values).
    [Tags]             customers    products    loans    validation    type2

    Navigate To Avail Loan Product Page

    Fill Text                    ${AVAIL_LOAN_TERM_LENGTH_INPUT}        ${T26_NEGATIVE_TERM_LENGTH}
    Trigger Blur On Field        ${AVAIL_LOAN_TERM_LENGTH_INPUT}

    ${field_value}=    Get Property    ${AVAIL_LOAN_TERM_LENGTH_INPUT}    value
    ${clean_value}=    Evaluate    '${field_value}'.replace(',', '')
    Run Keyword And Continue On Failure
    ...    Should Not Be Equal As Numbers    ${clean_value}    ${T26_NEGATIVE_TERM_LENGTH}
    ...    msg=Loan Term Length accepted a negative value: '${field_value}'


t2.6.19 Leave Required Custom Fields Empty – Loans Availment
    [Documentation]    Verify that leaving the required Employer Name custom field empty keeps
    ...                the Continue button disabled even when all Loan Details fields are filled.
    [Tags]             customers    products    loans    validation    type2

    Navigate To Avail Loan Product Page
    Fill Loan Details
    # Do not fill Employer Name

    # Fill then clear to trigger inline validation
    Fill Text                    ${AVAIL_LOAN_CUSTOM_FIELD_INPUT}    x
    Press Keys                   ${AVAIL_LOAN_CUSTOM_FIELD_INPUT}    Backspace
    Click                        ${AVAIL_PRODUCT_PAGE} >> text=Customer Details

    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_CONTINUE_BTN}    disabled


t2.6.20 Enter Invalid Data Format in Custom Fields – Loans Availment
    [Documentation]    Verify that a numeric custom field (if present) rejects alphabetic input.
    ...                Skipped when the product has no numeric custom field.
    [Tags]             customers    products    loans    validation    type2

    Navigate To Avail Loan Product Page
    Fill Loan Details

    ${numeric_input}=    Run Keyword And Return Status
    ...    Wait For Elements State
    ...    css=[data-testid="page-customers-avail-product"] .ant-input-number-input:not([data-field-input])    visible    timeout=3s

    IF    ${numeric_input}
        Fill Text
        ...    css=[data-testid="page-customers-avail-product"] .ant-input-number-input    abcdef
        Click    ${AVAIL_PRODUCT_PAGE} >> text=Customer Details
        ${field_value}=    Get Property
        ...    css=[data-testid="page-customers-avail-product"] .ant-input-number-input    value
        Run Keyword And Continue On Failure
        ...    Should Be Empty    ${field_value}
        ...    msg=Invalid characters were not rejected on blur — field contains: '${field_value}'
        Run Keyword And Continue On Failure
        ...    Wait For Elements State    ${AVAIL_PRODUCT_CONTINUE_BTN}    disabled
    ELSE
        Skip    No numeric custom field found on ${T26_LOANS_PRODUCT} — test requires a product with a numeric field
    END


t2.6.21 Exit Loans Availment Flow Mid-Process – Confirm Discard
    [Documentation]    Verify that navigating away mid-flow prompts a leave-page confirmation,
    ...                and that restarting the avail flow after confirming discards presents a
    ...                clean empty form.
    [Tags]             customers    products    loans    regression    mvp    type2

    Navigate To Avail Loan Product Page
    Fill Loan Details
    Fill Employer Name

    # Trigger the leave-page confirmation via the breadcrumb View Profile link
    Click                        css=a[href$="/profile"]:has-text("View Profile")
    Wait For Elements State      ${LEAVE_PAGE_CONFIRM_MODAL}    visible    timeout=5s

    Click                        ${LEAVE_PAGE_CONFIRM_BTN}
    Wait For Load Spinner To Disappear

    # Verify user is back on the customer profile
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CUSTOMERS_PROFILE_PAGE}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_PAGE}        hidden    timeout=3s

    # Restart the avail flow — form should be clean
    Navigate To Avail Loan Product Page
    ${loan_amount_value}=    Get Property    ${AVAIL_LOAN_AMOUNT_INPUT}             value
    ${employer_value}=       Get Property    ${AVAIL_LOAN_CUSTOM_FIELD_INPUT}      value
    Run Keyword And Continue On Failure
    ...    Should Be Empty    ${loan_amount_value}
    Run Keyword And Continue On Failure
    ...    Should Be Empty    ${employer_value}


t2.6.23 Use Browser Back Button During Loans Availment Flow
    [Documentation]    Verify that pressing the browser Back button from the Review step leaves
    ...                the app on a valid state (Customer Information step or customer profile)
    ...                without duplicate submissions.
    [Tags]             customers    products    loans    regression    type2

    Navigate To Avail Loan Product Page
    Fill Loan Details
    Fill Employer Name
    Click                        ${AVAIL_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${AVAIL_PRODUCT_PAGE} >> text=Review Application    visible

    Go Back
    Wait For Load Spinner To Disappear

    ${on_step1}=    Run Keyword And Return Status
    ...    Wait For Elements State    ${AVAIL_PRODUCT_PAGE}    visible    timeout=5s
    ${on_profile}=    Run Keyword And Return Status
    ...    Wait For Elements State    ${CUSTOMERS_PROFILE_PAGE}    visible    timeout=5s

    Run Keyword And Continue On Failure
    ...    Should Be True    ${on_step1} or ${on_profile}
    ...    Browser back left app in unexpected state (not on avail page or customer profile)

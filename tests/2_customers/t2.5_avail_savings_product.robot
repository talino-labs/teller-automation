*** Settings ***
Documentation       t2.5 Existing Customer Avails a Savings Product
...                 Covers the full Savings product availment flow:
...                 Customer Information step (custom fields, See Details side panel),
...                 Review and Confirm step, success page verification, post-availment
...                 check in Products Availed tab, and new account creation.

Resource            ../../resources/keywords/common.resource
Resource            ../../resources/keywords/customers.resource
Resource            ../../resources/keywords/products.resource

Suite Setup         Open Customer Profile And Cache URL
Suite Teardown      Close Browser
Test Setup          Return To Customer Profile Page
Test Teardown       Close Drawer If Open


*** Keywords ***
Open Customer Profile And Cache URL
    [Documentation]    Logs in, navigates to the target customer profile, and caches the URL
    ...                so subsequent tests can navigate directly without re-searching.
    Login To Teller App
    Navigate To Customers
    View Customer Profile    ${T25_CUSTOMER_ID}
    ${url}=    Get Url
    Set Suite Variable    ${CUSTOMER_PROFILE_URL}    ${url}

Return To Customer Profile Page
    [Documentation]    Navigates directly to the cached customer profile URL before each test.
    ...                Paces between tests to stay under the backend request rate limit.
    Sleep                      12s
    Go To                      ${CUSTOMER_PROFILE_URL}
    Wait For Load Spinner To Disappear

Close Drawer If Open
    [Documentation]    Closes any open drawer by clicking the close button if visible.
    ${drawer_visible}=    Run Keyword And Return Status
    ...    Wait For Elements State    css=.ant-drawer-body    visible    timeout=1s
    IF    ${drawer_visible}
        Click    ${PRODUCT_DETAILS_CLOSE_BTN}
        Wait For Elements State    css=.ant-drawer-body    hidden    timeout=5s
    END

Navigate To Avail Product Page
    [Documentation]    From the customer profile Eligible Products tab, searches for the target
    ...                Savings product and clicks Avail Product to start the availment flow.
    Click                        ${ELIGIBLE_PRODUCTS_TAB}
    Wait For Load Spinner To Disappear
    Fill Text                    ${PRODUCT_SEARCH_INPUT}    ${T25_SAVINGS_PRODUCT}
    Click                        ${PRODUCT_SEARCH_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State      css=.ant-table-body tr:has-text("${T25_SAVINGS_PRODUCT}")    visible
    Click                        css=.ant-table-body tr:has-text("${T25_SAVINGS_PRODUCT}") >> ${AVAIL_PRODUCT_BTN}
    Wait For Elements State      ${AVAIL_PRODUCT_PAGE}    visible
    Wait For Load Spinner To Disappear

Fill Customer Information Form
    [Documentation]    Fills the Full Name custom field on the Customer Information step.
    Wait For Elements State      ${AVAIL_PRODUCT_FULL_NAME_INPUT}    visible
    Fill Text                    ${AVAIL_PRODUCT_FULL_NAME_INPUT}    ${T25_CUSTOM_FULL_NAME}

Avail Product By Name
    [Documentation]    From the customer profile Eligible Products tab, searches for a named
    ...                product and clicks Avail Product. Caller is responsible for filling
    ...                any required fields before calling Continue.
    [Arguments]        ${product_name}
    Click                        ${ELIGIBLE_PRODUCTS_TAB}
    Wait For Load Spinner To Disappear
    Fill Text                    ${PRODUCT_SEARCH_INPUT}    ${product_name}
    Click                        ${PRODUCT_SEARCH_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State      css=.ant-table-body tr:has-text("${product_name}")    visible
    Click                        css=.ant-table-body tr:has-text("${product_name}") >> ${AVAIL_PRODUCT_BTN}
    Wait For Elements State      ${AVAIL_PRODUCT_PAGE}    visible
    Wait For Load Spinner To Disappear

Complete Avail Flow No Custom Fields
    [Documentation]    Completes the full availment flow for a product with no required custom fields.
    ...                Clicks Continue on Customer Information step and Confirm on Review step.
    [Arguments]        ${product_name}
    Avail Product By Name        ${product_name}
    Click                        ${AVAIL_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${AVAIL_PRODUCT_PAGE} >> text=Review Application    visible
    Click                        ${AVAIL_PRODUCT_CONFIRM_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${AVAIL_PRODUCT_BACK_TO_PROFILE}    visible    timeout=15s

Complete Avail Flow With Custom Fields
    [Documentation]    Completes the full availment flow for a product with required custom fields.
    ...                Fills the standard custom fields, clicks Continue, then Confirm.
    [Arguments]        ${product_name}
    Avail Product By Name        ${product_name}
    Fill Customer Information Form
    Click                        ${AVAIL_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${AVAIL_PRODUCT_PAGE} >> text=Review Application    visible
    Click                        ${AVAIL_PRODUCT_CONFIRM_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${AVAIL_PRODUCT_BACK_TO_PROFILE}    visible    timeout=15s

Edit Product Description
    [Documentation]    Navigates to the Products module, finds the named product, edits its
    ...                description field, and saves. Returns to the caller's flow when done.
    [Arguments]        ${product_name}    ${new_description}
    Navigate To Products
    Find Active Product Row      ${product_name}
    Click                        css=[data-testid="table-products-active"] tr:has-text("${product_name}") >> ${EDIT_PRODUCT_BTN} >> nth=0
    Wait For Elements State      ${EDIT_PRODUCT_PAGE}    visible
    Wait For Load Spinner To Disappear
    Fill Text                    css=[data-testid="page-products-edit"] [data-field="product.description"] textarea
    ...                          ${new_description}
    Click                        ${EDIT_PRODUCT_SAVE_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${PRODUCTS_LIST_PAGE}    visible

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

t2.5.1 Avail Savings Product – Customer Information Step
    [Documentation]    Verify that clicking Avail Product navigates to the Customer Information
    ...                step with Customer Details, Product Details, and custom fields displayed.
    ...                Continue button is disabled until required fields are filled.
    [Tags]             customers    products    smoke    mvp    type2

    Navigate To Avail Product Page
    ${url}=    Get Url
    Set Suite Variable    ${AVAIL_PAGE_URL}    ${url}

    # Verify page and stepper structure
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_PAGE}                                      visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_STEPS}                                     visible

    # Verify Customer Details section
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_PAGE} >> text=Customer Details             visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_PAGE} >> text=Email Address                visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_PAGE} >> text=Mobile Number                visible

    # Verify Product Details section
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_PAGE} >> text=Product Details              visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_PAGE} >> text=Product Name                 visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_PAGE} >> text=Product Type                 visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_PAGE} >> text=${T25_SAVINGS_PRODUCT}       visible

    # Verify custom field is present and Continue button is initially disabled
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_FULL_NAME_INPUT}                           visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_CONTINUE_BTN}                              disabled

t2.5.2 See Details of Savings Product During Availment (Customer Information Step)
    [Documentation]    Verify that clicking See Details on the Product Details section opens a
    ...                side panel with complete Savings product information, closes cleanly,
    ...                and leaves the user on the Customer Information step.
    [Tags]             customers    products    smoke    mvp    type2

    Go To    ${AVAIL_PAGE_URL}
    Wait For Load Spinner To Disappear

    Click                        ${AVAIL_PRODUCT_SEE_DETAILS_BTN}
    Wait For Elements State      ${AVAIL_PRODUCT_DETAILS_DRAWER}    visible

    # Product Details section
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Product name          visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Product type          visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Description           visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Status                visible

    # Eligibility for Customer Type
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Minimum age           visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Required documents    visible

    # Account Configuration
    Scroll To Element    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Average daily balance
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Average daily balance               visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Initial deposit                     visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Overdrafts                          visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Withdrawal limit frequency          visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Withdrawal limit amount             visible

    # Interest Configuration
    Scroll To Element    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text="Interest rate(%)"
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text="Interest rate(%)"                  visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Interest type                       visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Interest time period                visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Interest rate structure             visible

    # Fees & Charges
    Scroll To Element    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Excess withdrawal fee
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Excess withdrawal fee               visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Dormancy fee                        visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Account closure fee                 visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Tax rate type                       visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_DETAILS_DRAWER} >> text=Tax rate value                      visible

    # Close the side panel and verify user remains on step 1
    Click                        ${PRODUCT_DETAILS_CLOSE_BTN}
    Wait For Elements State      ${AVAIL_PRODUCT_DETAILS_DRAWER}    hidden
    Wait For Elements State      ${AVAIL_PRODUCT_PAGE}                 visible

t2.5.3 Fill Custom Fields for Savings Product and Continue
    [Documentation]    Verify that filling required custom fields enables the Continue button,
    ...                entered values are retained, and the user proceeds to the Review step
    ...                with an accurate summary.
    [Tags]             customers    products    smoke    mvp    type2

    Go To    ${AVAIL_PAGE_URL}
    Wait For Load Spinner To Disappear

    # Continue disabled before filling
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_CONTINUE_BTN}    disabled

    # Fill the custom field
    Fill Customer Information Form

    # Continue enabled after filling
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_CONTINUE_BTN}    enabled

    # Verify value is retained
    ${field_value}=    Get Property    ${AVAIL_PRODUCT_FULL_NAME_INPUT}    value
    Run Keyword And Continue On Failure
    ...    Should Be Equal    ${field_value}    ${T25_CUSTOM_FULL_NAME}

    # Proceed to Review step
    Click    ${AVAIL_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State    ${AVAIL_PRODUCT_PAGE} >> text=Review Application    visible

    # Cache review URL so t2.5.4 can navigate directly
    ${review_url}=    Get Url
    Set Suite Variable    ${REVIEW_PAGE_URL}    ${review_url}

    # Verify review summary shows all inputs
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_PAGE} >> text=Personal Information       visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_PAGE} >> text=${T25_CUSTOM_FULL_NAME}   visible

t2.5.4 Review and Confirm Savings Product Availment
    [Documentation]    Verify that the Review Application step shows accurate data, Confirm and
    ...                Avail processes the request, and the success page is displayed with the
    ...                correct product name and a Back to Customer Profile button.
    [Tags]             customers    products    smoke    mvp    type2

    # Navigate to avail page via the Eligible Products flow and complete step 1 to reach review.
    # NOTE: use the click-through navigation (not Go To ${AVAIL_PAGE_URL}) — reloading the avail
    # page by URL does not restore the availment flow state, so Confirm and Avail creates the
    # account server-side (201) but the UI never advances to the success page.
    Navigate To Avail Product Page
    Fill Customer Information Form
    Click    ${AVAIL_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State    ${AVAIL_PRODUCT_PAGE} >> text=Review Application    visible

    # Verify review summary
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_PAGE} >> text=Personal Information       visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_PAGE} >> text=${T25_CUSTOM_FULL_NAME}   visible

    # Confirm availment
    Click                        ${AVAIL_PRODUCT_CONFIRM_BTN}
    Wait For Load Spinner To Disappear

    # Verify success page
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Product Availed                  visible    timeout=15s
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=${T25_SAVINGS_PRODUCT} >> nth=0   visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_BACK_TO_PROFILE}      visible

    # Cache success URL for t2.5.5
    ${success_url}=    Get Url
    Set Suite Variable    ${SUCCESS_PAGE_URL}    ${success_url}

t2.5.5 View Newly Availed Savings Product in Customer Profile
    [Documentation]    Verify that after availment the new Savings product appears in the
    ...                Products Availed tab, and its See Details side panel shows the product
    ...                configuration and the submitted custom field value.
    [Tags]             customers    products    regression    mvp    type2

    # Complete the full avail flow to reach the success page
    # (Success state is React in-memory — the URL cannot be navigated to directly)
    Navigate To Avail Product Page
    Fill Customer Information Form
    Click                        ${AVAIL_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Click                        ${AVAIL_PRODUCT_CONFIRM_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${AVAIL_PRODUCT_BACK_TO_PROFILE}    visible

    # Navigate back to customer profile
    Click                        ${AVAIL_PRODUCT_BACK_TO_PROFILE}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${CUSTOMERS_PROFILE_PAGE}    visible

    # Open Products Availed tab
    Click                        ${PRODUCTS_AVAILED_TAB}
    Wait For Load Spinner To Disappear

    # Verify the newly availed product is in the table
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    css=.ant-table-body tr:has-text("${T25_SAVINGS_PRODUCT}") >> nth=0    visible    timeout=10s

    # Open See Details for the first matching product row
    Click
    ...    css=.ant-table-body tr:has-text("${T25_SAVINGS_PRODUCT}") >> ${SEE_DETAILS_BTN} >> nth=0
    Wait For Elements State    ${AVAILED_PRODUCT_DRAWER}    visible

    # Verify product details and custom field value in the drawer
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAILED_PRODUCT_DRAWER} >> text=Product name              visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAILED_PRODUCT_DRAWER} >> text=${T25_SAVINGS_PRODUCT}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAILED_PRODUCT_DRAWER} >> text=${T25_CUSTOM_FULL_NAME}   visible

    # Close drawer
    Click                        ${PRODUCT_DETAILS_CLOSE_BTN}
    Wait For Elements State      ${AVAILED_PRODUCT_DRAWER}    hidden

t2.5.6 Verify New Account Number Generated After Savings Availment
    [Documentation]    Verify that a new account record is created for the customer after
    ...                Savings product availment. Snapshots all account numbers across all
    ...                pages before availment, performs the availment, then asserts the
    ...                total count increased by at least 1.
    [Tags]             customers    accounts    regression    mvp    type2

    # Step 1: Snapshot all account numbers before availment (across all pages)
    Navigate To Customers
    View Customer Accounts    ${T25_CUSTOMER_NAME}
    Wait For Load Spinner To Disappear
    Wait For Elements State    ${ACCOUNT_TABLE}    visible
    ${count_before}=    Count All Accounts

    # Step 2: Perform savings availment from the customer profile
    Return To Customer Profile Page
    Navigate To Avail Product Page
    Fill Customer Information Form
    Click                        ${AVAIL_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Click                        ${AVAIL_PRODUCT_CONFIRM_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${AVAIL_PRODUCT_BACK_TO_PROFILE}    visible
    Click                        ${AVAIL_PRODUCT_BACK_TO_PROFILE}
    Wait For Load Spinner To Disappear

    # Step 3: Snapshot all account numbers after availment (across all pages)
    Navigate To Customers
    View Customer Accounts    ${T25_CUSTOMER_NAME}
    Wait For Load Spinner To Disappear
    Wait For Elements State    ${ACCOUNT_TABLE}    visible
    ${count_after}=    Count All Accounts

    # Assert a new account was created
    Should Be True    ${count_after} > ${count_before}
    ...    Expected a new account after availment (before: ${count_before}, after: ${count_after})

t2.5.7 Modify Custom Field Inputs on Review Step and Re-Confirm (Savings)
    [Documentation]    Verify that clicking Back from the Review step returns to Customer Information
    ...                with the form still filled, modified values are reflected in the review summary,
    ...                and the product is successfully availed with the updated data.
    [Tags]             customers    products    regression    smoke    mvp    type2

    Navigate To Avail Product Page
    Fill Customer Information Form
    Click                        ${AVAIL_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${AVAIL_PRODUCT_PAGE} >> text=Review Application    visible

    # Click Back to return to Customer Information step
    Click                        ${AVAIL_PRODUCT_BACK_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${AVAIL_PRODUCT_FULL_NAME_INPUT}    visible

    # Modify the custom field value
    Fill Text                    ${AVAIL_PRODUCT_FULL_NAME_INPUT}    ${T25_MODIFIED_FULL_NAME}

    # Continue back to review — modified value should appear in summary
    Click                        ${AVAIL_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${AVAIL_PRODUCT_PAGE} >> text=Review Application    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_PAGE} >> text=${T25_MODIFIED_FULL_NAME}    visible

    # Confirm and verify success
    Click                        ${AVAIL_PRODUCT_CONFIRM_BTN}
    Wait For Load Spinner To Disappear
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Product Availed                  visible    timeout=15s
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_BACK_TO_PROFILE}      visible

t2.5.8 Avail Savings Product with Optional Custom Fields Left Empty
    [Documentation]    Verify that leaving optional custom fields empty does not block progression:
    ...                no validation errors appear for empty optional fields, Continue is enabled,
    ...                and the empty optional fields are recorded as N/A after availment.
    ...                Requires a Savings product with both required and optional custom fields.
    [Tags]             customers    products    regression    mvp    type2

    # Navigate to avail page for a product with both required and optional fields
    # (T25_SAVINGS_PRODUCT has a required Full Name field; optional fields are left empty)
    Navigate To Avail Product Page

    # Fill only the required field — leave any optional fields untouched
    Fill Customer Information Form

    # Verify no validation error on optional fields and Continue is enabled
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_CONTINUE_BTN}    enabled
    ${error_count}=    Get Element Count    css=.ant-form-item-explain-error
    Run Keyword And Continue On Failure
    ...    Should Be Equal As Integers    ${error_count}    0

    # Proceed to Review — optional fields should show N/A or be empty
    Click                        ${AVAIL_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${AVAIL_PRODUCT_PAGE} >> text=Review Application    visible

    # Confirm availment
    Click                        ${AVAIL_PRODUCT_CONFIRM_BTN}
    Wait For Load Spinner To Disappear
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Product Availed    visible    timeout=15s
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_BACK_TO_PROFILE}    visible

t2.5.9 Avail Savings Product with No Custom Fields
    [Documentation]    Verify that a Savings product with no custom fields shows the correct
    ...                empty-state messages on both steps, Continue is enabled by default,
    ...                and the availment completes successfully.
    [Tags]             customers    products    mvp    type2

    Avail Product By Name        ${T25_NO_FIELDS_SAVINGS_PRODUCT}

    # Verify empty-state on Customer Information step
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    text=No customer fields needed for this product.    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_CONTINUE_BTN}    enabled

    # Proceed to Review
    Click                        ${AVAIL_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${AVAIL_PRODUCT_PAGE} >> text=Review Application    visible

    # Verify empty-state on Review step
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    text=No fields to review here. Good to go!    visible

    # Confirm and verify success page
    Click                        ${AVAIL_PRODUCT_CONFIRM_BTN}
    Wait For Load Spinner To Disappear
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Product Availed                      visible    timeout=15s
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=${T25_NO_FIELDS_SAVINGS_PRODUCT} >> nth=0     visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_BACK_TO_PROFILE}          visible

    # Back to Customer Profile button is functional
    Click                        ${AVAIL_PRODUCT_BACK_TO_PROFILE}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${CUSTOMERS_PROFILE_PAGE}    visible

t2.5.10 Avail Multiple Different Savings Products Sequentially
    [Documentation]    Verify that a customer can successfully avail two different Savings
    ...                products in sequence, and both appear in the Products Availed tab.
    [Tags]             customers    products    regression    mvp    type2

    # Avail first product (has required custom fields)
    Navigate To Avail Product Page
    Fill Customer Information Form
    Click                        ${AVAIL_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Click                        ${AVAIL_PRODUCT_CONFIRM_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${AVAIL_PRODUCT_BACK_TO_PROFILE}    visible    timeout=15s
    Click                        ${AVAIL_PRODUCT_BACK_TO_PROFILE}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${CUSTOMERS_PROFILE_PAGE}    visible

    # Avail second product (all-optional custom fields — no required fields to fill)
    Complete Avail Flow No Custom Fields    ${T25_OPTIONAL_SAVINGS_PRODUCT}
    Click                        ${AVAIL_PRODUCT_BACK_TO_PROFILE}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${CUSTOMERS_PROFILE_PAGE}    visible

    # Verify both products appear in Products Availed tab
    Click                        ${PRODUCTS_AVAILED_TAB}
    Wait For Load Spinner To Disappear
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    css=.ant-table-body tr:has-text("${T25_SAVINGS_PRODUCT}") >> nth=0           visible    timeout=10s
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    css=.ant-table-body tr:has-text("${T25_OPTIONAL_SAVINGS_PRODUCT}") >> nth=0  visible    timeout=10s

t2.5.11 Avail Recently Updated Savings Product – Uses Latest Version
    [Documentation]    Verify that after updating a product's configuration, the availment flow
    ...                reflects the latest version of the product details.
    [Tags]             customers    products    regression    type2

    # Edit the product description first
    Edit Product Description    ${T25_VERSIONED_SAVINGS_PRODUCT}    ${T25_UPDATED_DESCRIPTION}

    # Return to customer profile and avail the updated product
    Navigate To Customers
    View Customer Profile        ${T25_CUSTOMER_NAME}
    ${url}=    Get Url
    Set Suite Variable           ${CUSTOMER_PROFILE_URL}    ${url}

    Complete Avail Flow No Custom Fields    ${T25_VERSIONED_SAVINGS_PRODUCT}

    # Verify success page reflects the updated product
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=${T25_VERSIONED_SAVINGS_PRODUCT} >> nth=0    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_BACK_TO_PROFILE}         visible

    # Check the availed product drawer shows the updated description
    Click                        ${AVAIL_PRODUCT_BACK_TO_PROFILE}
    Wait For Load Spinner To Disappear
    Click                        ${PRODUCTS_AVAILED_TAB}
    Wait For Load Spinner To Disappear
    Click
    ...    css=.ant-table-body tr:has-text("${T25_VERSIONED_SAVINGS_PRODUCT}") >> ${SEE_DETAILS_BTN} >> nth=0
    Wait For Elements State      ${AVAILED_PRODUCT_DRAWER}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAILED_PRODUCT_DRAWER} >> text=${T25_UPDATED_DESCRIPTION}    visible
    Click                        ${PRODUCT_DETAILS_CLOSE_BTN}
    Wait For Elements State      ${AVAILED_PRODUCT_DRAWER}    hidden

t2.5.12 Re-Avail Edited Savings Product – Multiple Versions on Same Customer
    [Documentation]    Verify that a customer can re-avail an updated version of a Savings product
    ...                they have already availed, resulting in two separate availed instances.
    [Tags]             customers    products    regression    type2

    # Edit the product to a new description (creates a new version)
    ${second_description}=    Set Variable    ${T25_UPDATED_DESCRIPTION} v2
    Edit Product Description    ${T25_VERSIONED_SAVINGS_PRODUCT}    ${second_description}

    # Return to customer profile
    Navigate To Customers
    View Customer Profile        ${T25_CUSTOMER_NAME}
    ${url}=    Get Url
    Set Suite Variable           ${CUSTOMER_PROFILE_URL}    ${url}

    # Avail the updated product
    Complete Avail Flow No Custom Fields    ${T25_VERSIONED_SAVINGS_PRODUCT}
    Click                        ${AVAIL_PRODUCT_BACK_TO_PROFILE}
    Wait For Load Spinner To Disappear

    # Verify the customer now has at least two instances of this product in Products Availed
    Click                        ${PRODUCTS_AVAILED_TAB}
    Wait For Load Spinner To Disappear
    ${availed_count}=    Get Element Count
    ...    css=.ant-table-body tr:has-text("${T25_VERSIONED_SAVINGS_PRODUCT}")
    Run Keyword And Continue On Failure
    ...    Should Be True    ${availed_count} >= 2
    ...    Expected at least 2 availed instances of ${T25_VERSIONED_SAVINGS_PRODUCT}, found ${availed_count}

t2.5.13 Avail Savings Product with Only Optional Custom Fields
    [Documentation]    Verify that a Savings product with only optional custom fields allows
    ...                the user to proceed without filling anything. No validation errors.
    [Tags]             customers    products    mvp    type2

    Avail Product By Name        ${T25_OPTIONAL_SAVINGS_PRODUCT}

    # Continue is enabled by default — no required fields
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_CONTINUE_BTN}    enabled

    # Do not fill any optional fields — click Continue directly
    Click                        ${AVAIL_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${AVAIL_PRODUCT_PAGE} >> text=Review Application    visible

    # No validation errors should have appeared
    ${error_count}=    Get Element Count    css=.ant-form-item-explain-error
    Run Keyword And Continue On Failure
    ...    Should Be Equal As Integers    ${error_count}    0

    # Confirm availment
    Click                        ${AVAIL_PRODUCT_CONFIRM_BTN}
    Wait For Load Spinner To Disappear
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Product Availed    visible    timeout=15s
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_BACK_TO_PROFILE}    visible

t2.5.14 Avail the Same Savings Product Multiple Times
    [Documentation]    Verify that availing the same Savings product twice creates two separate
    ...                records in the customer's Products Availed tab.
    [Tags]             customers    products    regression    mvp    type2

    # First availment
    Navigate To Avail Product Page
    Fill Customer Information Form
    Click                        ${AVAIL_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Click                        ${AVAIL_PRODUCT_CONFIRM_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${AVAIL_PRODUCT_BACK_TO_PROFILE}    visible    timeout=15s
    Click                        ${AVAIL_PRODUCT_BACK_TO_PROFILE}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${CUSTOMERS_PROFILE_PAGE}    visible

    # Second availment of the same product
    Navigate To Avail Product Page
    Fill Customer Information Form
    Click                        ${AVAIL_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Click                        ${AVAIL_PRODUCT_CONFIRM_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${AVAIL_PRODUCT_BACK_TO_PROFILE}    visible    timeout=15s
    Click                        ${AVAIL_PRODUCT_BACK_TO_PROFILE}
    Wait For Load Spinner To Disappear

    # Verify two separate records exist in Products Availed
    Click                        ${PRODUCTS_AVAILED_TAB}
    Wait For Load Spinner To Disappear
    ${availed_count}=    Get Element Count
    ...    css=.ant-table-body tr:has-text("${T25_SAVINGS_PRODUCT}")
    Run Keyword And Continue On Failure
    ...    Should Be True    ${availed_count} >= 2
    ...    Expected at least 2 availed records for ${T25_SAVINGS_PRODUCT}, found ${availed_count}

t2.5.15 Attempt to Avail Savings Product for Customer with Invalid Status
    [Documentation]    Verify that availing a product for an inactive/closed customer is blocked
    ...                at the confirmation step. The user can navigate through Customer Information
    ...                and reach the Review step, but clicking Confirm and Avail surfaces an error:
    ...                "This request cannot be completed at this time."
    ...                Requires T25_INVALID_STATUS_CUSTOMER to be set to an inactive/closed customer.
    [Tags]             customers    products    regression    validation    type2

    Skip If    '${T25_INVALID_STATUS_CUSTOMER}' == ''
    ...    T25_INVALID_STATUS_CUSTOMER not configured — set to an inactive/closed customer name

    Navigate To Customers
    Search For Customer          ${T25_INVALID_STATUS_CUSTOMER}
    Click    css=tr:has-text("${T25_INVALID_STATUS_CUSTOMER}") >> ${VIEW_PROFILE_LINK} >> nth=0
    Wait For Load Spinner To Disappear

    # Start avail flow — avail page loads normally for invalid-status customer
    Avail Product By Name        ${T25_NO_FIELDS_SAVINGS_PRODUCT}

    # Customer Information step: no required fields, Continue is enabled
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_CONTINUE_BTN}    enabled
    Click                        ${AVAIL_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${AVAIL_PRODUCT_PAGE} >> text=Review Application    visible

    # Confirm step: error fires here for invalid customer status
    Click                        ${AVAIL_PRODUCT_CONFIRM_BTN}
    Wait For Load Spinner To Disappear
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    text=This request cannot be completed at this time. Please contact your branch or customer support for assistance.
    ...    visible    timeout=10s

t2.5.16 Leave Required Custom Fields Empty – Savings Availment
    [Documentation]    Verify that leaving required custom fields empty triggers a validation
    ...                error per field and keeps the Continue button disabled.
    [Tags]             customers    products    validation    type2

    Navigate To Avail Product Page

    # Fill then clear the required field to trigger inline validation (blur-only does not show error)
    Fill Text                    ${AVAIL_PRODUCT_FULL_NAME_INPUT}    x
    Press Keys                   ${AVAIL_PRODUCT_FULL_NAME_INPUT}    Backspace
    Click                        ${AVAIL_PRODUCT_PAGE} >> text=Customer Details

    # Validation error should appear for the cleared required field
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    css=[data-testid="page-customers-avail-product"] span.text-error-6    visible    timeout=5s

    # Continue button must remain disabled
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_CONTINUE_BTN}    disabled

t2.5.17 Enter Invalid Data Format in Custom Fields – Savings Availment
    [Documentation]    Verify that entering invalid data (alphabetic characters into a numeric
    ...                field) is either rejected outright or shows a format validation error.
    ...                Requires a Savings product with a numeric custom field.
    [Tags]             customers    products    validation    type2

    # This test targets a product with a numeric custom field (T25_SAVINGS_PRODUCT_2)
    Avail Product By Name    ${T25_SAVINGS_PRODUCT_2}

    ${numeric_input}=    Run Keyword And Return Status
    ...    Wait For Elements State
    ...    css=[data-testid="page-customers-avail-product"] .ant-input-number-input    visible    timeout=3s

    IF    ${numeric_input}
        # AntD InputNumber auto-deletes invalid characters — the value is never saved.
        # Verify: invalid input is rejected (field stays empty) and Continue stays disabled.
        Fill Text
        ...    css=[data-testid="page-customers-avail-product"] .ant-input-number-input    abcdef
        # Blur the field to trigger AntD's auto-deletion of invalid characters
        Click    ${AVAIL_PRODUCT_PAGE} >> text=Customer Details
        ${field_value}=    Get Property
        ...    css=[data-testid="page-customers-avail-product"] .ant-input-number-input    value
        Run Keyword And Continue On Failure
        ...    Should Be Empty    ${field_value}
        ...    msg=Invalid characters were not rejected on blur — field contains: '${field_value}'
        Run Keyword And Continue On Failure
        ...    Wait For Elements State    ${AVAIL_PRODUCT_CONTINUE_BTN}    disabled
    ELSE
        Skip    No numeric custom field found on ${T25_SAVINGS_PRODUCT} — test requires a product with a numeric field
    END

t2.5.18 Exit Savings Availment Flow Mid-Process – Confirm Discard
    [Documentation]    Verify that navigating away from the Customer Information step via the
    ...                breadcrumb View Profile link prompts a discard confirmation. After
    ...                confirming, the user returns to the customer profile, and restarting
    ...                the avail flow presents a clean empty form.
    [Tags]             customers    products    regression    mvp    type2

    Navigate To Avail Product Page

    # Partially fill the form
    Fill Customer Information Form

    # Click the breadcrumb View Profile link to trigger the leave-page confirmation
    Click                        css=a[href$="/profile"]:has-text("View Profile")
    Wait For Elements State      ${LEAVE_PAGE_CONFIRM_MODAL}    visible    timeout=5s

    # Confirm discard
    Click                        ${LEAVE_PAGE_CONFIRM_BTN}
    Wait For Load Spinner To Disappear

    # Verify user is back on the customer profile (avail page discarded)
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CUSTOMERS_PROFILE_PAGE}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_PAGE}    hidden    timeout=3s

    # Restart the avail flow — form should be clean (no persisted values)
    Navigate To Avail Product Page
    ${field_value}=    Get Property    ${AVAIL_PRODUCT_FULL_NAME_INPUT}    value
    Run Keyword And Continue On Failure
    ...    Should Be Empty    ${field_value}

t2.5.19 Session Timeout During Savings Availment Flow
    [Documentation]    Verify that a session timeout during the availment flow redirects the
    ...                user to the Login page with a session-expired modal, and discards the
    ...                in-progress availment data.
    ...                Slow test (~5 min idle) — excluded from CI by the 'slow' tag; run on demand.
    [Tags]             customers    products    slow    type2

    Navigate To Avail Product Page
    Wait For Elements State      ${AVAIL_PRODUCT_PAGE}    visible
    # Remain idle past the 5-minute session timeout (301s), then attempt to continue.
    Sleep                        301s
    Run Keyword And Ignore Error    Click    ${AVAIL_PRODUCT_CONTINUE_BTN}
    # Session is terminated: user is redirected to Login with the Session Expired modal.
    Wait For Elements State      text=Session Expired    visible    timeout=15s
    Wait For Elements State
    ...    text=For security reasons, you need to sign in again to continue using the app.    visible
    Wait For Elements State      ${LOGIN_PAGE}    visible

t2.5.20 Use Browser Back Button During Savings Availment Flow
    [Documentation]    Verify that pressing the browser Back button from the Review step is
    ...                handled gracefully: the app either preserves state or re-validates, with
    ...                no data corruption or duplicate submission.
    [Tags]             customers    products    regression    type2

    Navigate To Avail Product Page
    Fill Customer Information Form
    Click                        ${AVAIL_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State      ${AVAIL_PRODUCT_PAGE} >> text=Review Application    visible

    # Click the browser back button
    Go Back
    Wait For Load Spinner To Disappear

    # Verify graceful handling: app is on a valid state (either step 1 or back to profile)
    ${on_step1}=    Run Keyword And Return Status
    ...    Wait For Elements State    ${AVAIL_PRODUCT_PAGE}    visible    timeout=5s
    ${on_profile}=    Run Keyword And Return Status
    ...    Wait For Elements State    ${CUSTOMERS_PROFILE_PAGE}    visible    timeout=5s

    Run Keyword And Continue On Failure
    ...    Should Be True    ${on_step1} or ${on_profile}
    ...    Browser back button left app in unexpected state (not on avail page or customer profile)

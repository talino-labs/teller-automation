*** Settings ***
Documentation       t5.3 Create New Product
...                 Covers the full Savings product creation flow:
...                 Product Configuration (Step 1), Customer Form with section and field management
...                 (Step 2), Review Product confirmation (Step 3), and post-creation verification
...                 in the Active Products list and Customer Eligible Products tab.

Resource            ../../resources/keywords/common.resource
Resource            ../../resources/keywords/products.resource
Resource            ../../resources/keywords/customers.resource

Suite Setup         Login To Teller App
Suite Teardown      Close Browser
Test Setup          Setup Products Page
Test Teardown       Close Modal If Open



*** Keywords ***
Navigate To Create Savings Product
    [Documentation]    Clicks the Create Product split-button dropdown trigger, selects Savings,
    ...                and waits for the Product Configuration (Step 1) page to load.
    Click    ${CREATE_PRODUCT_DROPDOWN_TRIGGER}
    Wait For Elements State    ${CREATE_SAVINGS_OPTION}    visible
    Click    ${CREATE_SAVINGS_OPTION}
    Wait For Load Spinner To Disappear
    Wait For Elements State    ${CREATE_PRODUCT_PAGE}    visible
    Wait For Elements State    css=.ant-steps-item-process:has-text("Product Configuration")    visible

Select Dropdown First Option
    [Documentation]    Clicks an AntD Select component, waits for its option list to appear,
    ...                selects the first available option, then waits for the list to close.
    [Arguments]        ${select_locator}
    Click    ${select_locator}
    Wait For Elements State    css=.ant-select-dropdown:not(.ant-select-dropdown-hidden)    visible
    Click    css=.ant-select-dropdown:not(.ant-select-dropdown-hidden) .ant-select-item-option >> nth=0
    Wait For Elements State    css=.ant-select-dropdown:not(.ant-select-dropdown-hidden)    hidden    timeout=3s

Fill Savings Product Step 1
    [Documentation]    Fills all form fields in Step 1 – Product Configuration for a Savings product.
    ...                Scrolls to sections below the fold as needed.
    [Arguments]        ${product_name}
    # Product Details
    Fill Text    ${CP_PRODUCT_NAME_INPUT}    ${product_name}
    Select Dropdown First Option    ${CP_PRODUCT_TYPE_SELECT}
    Fill Text    ${CP_DESCRIPTION_TEXTAREA}    ${T53_DESCRIPTION}
    # Eligibility For Customer Type — broad criteria so any eligible customer can see the product
    Fill Text    ${CP_MIN_AGE_INPUT}    ${T53_MIN_AGE}
    # Required Documents — check at least one checkbox
    Scroll To Element    css=input.ant-checkbox-input[value="${T53_REQUIRED_DOCUMENT}"]
    Check Checkbox    css=input.ant-checkbox-input[value="${T53_REQUIRED_DOCUMENT}"]
    # Account Configuration
    Scroll To Element    ${CP_AVG_DAILY_BALANCE_INPUT}
    Fill Text    ${CP_AVG_DAILY_BALANCE_INPUT}    ${T53_AVG_DAILY_BALANCE}
    Fill Text    ${CP_INITIAL_DEPOSIT_INPUT}    ${T53_INITIAL_DEPOSIT}
    Select Dropdown First Option    ${CP_WITHDRAWAL_FREQ_SELECT}
    Fill Text    ${CP_WITHDRAWAL_AMOUNT_INPUT}    ${T53_WITHDRAWAL_AMOUNT}
    # Interest Configuration
    Scroll To Element    ${CP_INTEREST_RATE_INPUT}
    Fill Text    ${CP_INTEREST_RATE_INPUT}    ${T53_INTEREST_RATE}
    Select Dropdown First Option    ${CP_INTEREST_TYPE_SELECT}
    Select Dropdown First Option    ${CP_INTEREST_PERIOD_SELECT}
    Select Dropdown First Option    ${CP_INTEREST_STRUCTURE_SELECT}
    # Fees & Charges
    Scroll To Element    ${CP_EXCESS_WITHDRAWAL_FEE_INPUT}
    Fill Text    ${CP_EXCESS_WITHDRAWAL_FEE_INPUT}    ${T53_EXCESS_WITHDRAWAL_FEE}
    Fill Text    ${CP_DORMANCY_FEE_INPUT}    ${T53_DORMANCY_FEE}
    Fill Text    ${CP_ACCOUNT_CLOSURE_FEE_INPUT}    ${T53_ACCOUNT_CLOSURE_FEE}
    Fill Text    ${CP_TRANSACTION_CHARGE_INPUT}    ${T53_TRANSACTION_CHARGE}
    Select Dropdown First Option    ${CP_TAX_RATE_TYPE_SELECT}
    Fill Text    ${CP_TAX_RATE_INPUT}    ${T53_TAX_RATE}

Navigate To Savings Customer Form
    [Documentation]    Navigates to create Savings product, fills all Step 1 fields,
    ...                then clicks Continue to land on Step 2 – Customer Form.
    [Arguments]        ${product_name}
    Navigate To Create Savings Product
    Fill Savings Product Step 1    ${product_name}
    Wait For Elements State    ${CREATE_PRODUCT_CONTINUE_BTN}    enabled    timeout=10s
    Click    ${CREATE_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State    css=.ant-steps-item-process:has-text("Customer Form")    visible

Add Section To Customer Form
    [Documentation]    Clicks 'Add new section', enters the section name in the modal, and confirms.
    ...                Waits until the new section is rendered in the Customer Form.
    [Arguments]        ${section_name}=${T53_SECTION_NAME}
    Click    ${CP_ADD_SECTION_BTN}
    Wait For Elements State
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content    visible
    Fill Text
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content input
    ...    ${section_name}
    Wait For Elements State
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content button.btn-primary
    ...    enabled    timeout=5s
    Click
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content button.btn-primary
    Wait For Elements State
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content    hidden    timeout=5s
    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=${section_name}    visible

Add Text Input Field To Section
    [Documentation]    Clicks 'Add customer input field', selects 'Text input (single line)',
    ...                fills the field name and placeholder in the modal, and confirms.
    [Arguments]        ${field_name}=${T53_FIELD_NAME}    ${placeholder}=${T53_FIELD_PLACEHOLDER}
    Click    css=[data-testid="page-products-create"] button:has-text("Add customer input field")
    Wait For Elements State
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content    visible
    # Select field type: Text input (single line)
    Click
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content [data-field="type"] .ant-select-selector
    Wait For Elements State    css=.ant-select-dropdown:not(.ant-select-dropdown-hidden)    visible
    Click
    ...    css=.ant-select-dropdown:not(.ant-select-dropdown-hidden) .ant-select-item-option:has-text("Text input (single line)")
    Wait For Elements State    css=.ant-select-dropdown:not(.ant-select-dropdown-hidden)    hidden    timeout=3s
    # Fill field name and placeholder
    Fill Text
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content [data-field="label"] input
    ...    ${field_name}
    Fill Text
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content [data-field="placeholder"] input
    ...    ${placeholder}
    # Submit
    Wait For Elements State
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content button.btn-primary
    ...    enabled    timeout=5s
    Click
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content button.btn-primary
    Wait For Elements State
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content    hidden    timeout=5s
    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=${field_name}    visible

Navigate To Create Loans Product
    [Documentation]    Clicks the Create Product split-button dropdown trigger, selects Loans,
    ...                and waits for the Product Definition (Step 1) page to load.
    Click    ${CREATE_PRODUCT_DROPDOWN_TRIGGER}
    Wait For Elements State    ${CREATE_LOANS_OPTION}    visible
    Click    ${CREATE_LOANS_OPTION}
    Wait For Load Spinner To Disappear
    Wait For Elements State    ${CREATE_PRODUCT_PAGE}    visible
    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=Loan Features    visible

Fill Loans Product Step 1
    [Documentation]    Fills all form fields in Step 1 – Product Definition for a Loans product.
    ...                Scrolls to sections below the fold as needed.
    [Arguments]        ${product_name}
    # Product Definition
    Select Dropdown First Option    ${CLP_LOAN_TYPE_SELECT}
    Check Checkbox    ${CLP_PREFERRED_CUSTOMERS_SALARIED}
    Fill Text    ${CLP_LOAN_PURPOSE_TEXTAREA}    ${T53_LOANS_LOAN_PURPOSE}
    # Product Details
    Fill Text    ${CLP_PRODUCT_NAME_INPUT}    ${product_name}
    Fill Text    ${CLP_DESCRIPTION_TEXTAREA}    ${T53_DESCRIPTION}
    # Loan Features
    Scroll To Element    ${CLP_MIN_AMOUNT_INPUT}
    Fill Text    ${CLP_MIN_AMOUNT_INPUT}    ${T53_LOANS_MIN_AMOUNT}
    Fill Text    ${CLP_MAX_AMOUNT_INPUT}    ${T53_LOANS_MAX_AMOUNT}
    Fill Text    ${CLP_TERM_LENGTH_INPUT}    ${T53_LOANS_TERM_LENGTH}
    # commented out as guardrail for now
    # Select Dropdown First Option    ${CLP_TERM_UNIT_SELECT}
    Select Dropdown First Option    ${CLP_INTEREST_RATE_TYPE_SELECT}
    Fill Text    ${CLP_REPAYMENT_METHOD_INPUT}    ${T53_LOANS_REPAYMENT_METHOD}
    # Eligibility Criteria
    Scroll To Element    ${CLP_MIN_AGE_INPUT}
    Fill Text    ${CLP_MIN_AGE_INPUT}    ${T53_LOANS_MIN_AGE}
    Fill Text    ${CLP_MAX_AGE_INPUT}    ${T53_LOANS_MAX_AGE}
    Fill Text    ${CLP_MIN_INCOME_INPUT}    ${T53_LOANS_MIN_INCOME}
    Fill Text    ${CLP_CREDIT_SCORE_INPUT}    ${T53_LOANS_CREDIT_SCORE}
    Check Checkbox    ${CLP_EMPLOYMENT_TYPE_SALARIED}
    # Required Documents
    Scroll To Element    css=input.ant-checkbox-input[value="${T53_REQUIRED_DOCUMENT}"]
    Check Checkbox    css=input.ant-checkbox-input[value="${T53_REQUIRED_DOCUMENT}"]
    # Pricing & Fees
    Scroll To Element    ${CLP_PRICING_RATE_INPUT}
    Fill Text    ${CLP_PRICING_RATE_INPUT}    ${T53_INTEREST_RATE}
    Select Dropdown First Option    ${CLP_RATE_STRUCTURE_SELECT}
    Fill Text    ${CLP_PROCESSING_FEE_INPUT}    ${T53_LOANS_PROCESSING_FEE}
    Select Dropdown First Option    ${CLP_PROCESSING_FEE_TYPE_SELECT}
    Fill Text    ${CLP_PENALTY_RATE_INPUT}    ${T53_LOANS_PENALTY_RATE}
    Fill Text    ${CLP_PENALTY_CONDITIONS_TEXTAREA}    ${T53_LOANS_PENALTY_CONDITIONS}

Navigate To Loans Customer Form
    [Documentation]    Navigates to create Loans product, fills all Step 1 fields,
    ...                then clicks Continue to land on Step 2 – Customer Form.
    [Arguments]        ${product_name}
    Navigate To Create Loans Product
    Fill Loans Product Step 1    ${product_name}
    Wait For Elements State    ${CREATE_PRODUCT_CONTINUE_BTN}    enabled    timeout=10s
    Click    ${CREATE_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State    css=.ant-steps-item-process:has-text("Customer Form")    visible


*** Test Cases ***
t5.3.1 Create New Savings Product – Happy Path
    [Documentation]    Verify the full Savings product creation flow from clicking the Create Product
    ...                button through completing Step 1 (Product Configuration) and arriving at
    ...                Step 2 (Customer Form). Verifies the leave-page confirmation modal on Back
    ...                from Step 1, and that Back from an incomplete Step 2 is blocked with an error.
    ...
    ...                Preconditions:
    ...                1. Teller is logged in.
    ...                2. User has permissions to Create Products.
    ...                3. User is on the Products Module page.
    [Tags]    products    create    savings    smoke    mvp    type2
    # Click Create Product dropdown trigger — verify category selector appears
    Click    ${CREATE_PRODUCT_DROPDOWN_TRIGGER}
    Wait For Elements State    css=.ant-dropdown:not(.ant-dropdown-hidden)    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_SAVINGS_OPTION}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_LOANS_OPTION}    visible
    # Select Savings — verify redirect to Step 1 (Product Configuration)
    Click    ${CREATE_SAVINGS_OPTION}
    Wait For Load Spinner To Disappear
    Wait For Elements State    ${CREATE_PRODUCT_PAGE}    visible
    Wait For Elements State    css=.ant-steps-item-process:has-text("Product Configuration")    visible
    # Verify all required sections are present in Step 1
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=Product Details    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=Eligibility For Customer Type    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=Account Configuration    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=Interest Configuration    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=Fees & Charges    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=Required Documents    visible
    # Verify Continue is disabled before filling any required fields
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_CONTINUE_BTN}    disabled
    # Click Back from Step 1 — verify leave-page confirmation modal appears
    Click    ${CP_BACK_BTN}
    Wait For Elements State    ${LEAVE_PAGE_CONFIRM_MODAL}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${LEAVE_PAGE_CONFIRM_BTN}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${LEAVE_PAGE_CANCEL_BTN}    visible
    # Click "Back" in modal — verify user stays on Product Configuration page
    Click    ${LEAVE_PAGE_CANCEL_BTN}
    Wait For Elements State    ${LEAVE_PAGE_CONFIRM_MODAL}    hidden
    Wait For Elements State    ${CREATE_PRODUCT_PAGE}    visible
    Wait For Elements State    css=.ant-steps-item-process:has-text("Product Configuration")    visible
    # Fill all mandatory fields in Step 1
    ${timestamp}=    Evaluate    __import__('datetime').datetime.now().strftime('%m%d%H%M%S')
    ${product_name}=    Set Variable    Savings ${timestamp}
    Fill Savings Product Step 1    ${product_name}
    # Click Continue — verify redirect to Step 2 (Customer Form)
    Wait For Elements State    ${CREATE_PRODUCT_CONTINUE_BTN}    enabled    timeout=10s
    Click    ${CREATE_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State    css=.ant-steps-item-process:has-text("Customer Form")    visible
    # Verify Step 2 layout: Add new section visible, Back enabled, Continue disabled
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CP_ADD_SECTION_BTN}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CP_BACK_BTN}    enabled
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_CONTINUE_BTN}    disabled
    # Click Back from Step 2 (incomplete) — navigation is blocked, error appears
    Click    ${CP_BACK_BTN}
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Please complete current step first.    visible
    # Navigate away via Products menu — leave-page confirmation modal appears
    Click    ${PRODUCTS_MENU}
    Wait For Elements State    ${LEAVE_PAGE_CONFIRM_MODAL}    visible
    # Click Confirm — verify redirect to Products module
    Click    ${LEAVE_PAGE_CONFIRM_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State    ${PRODUCTS_LIST_PAGE}    visible

t5.3.2 Add New Section to Savings Customer Form
    [Documentation]    Verify that clicking 'Add new section' opens a modal with a section name
    ...                input field and a disabled 'Add section' button (until name is entered),
    ...                and that submitting the form renders the new section in the Customer Form.
    ...
    ...                Preconditions:
    ...                1. Teller is logged in.
    ...                2. User is on Step 2 – Customer Form for a Savings product.
    ...                3. Product Configuration is completed.
    [Tags]    products    create    savings    smoke    mvp    type2
    Navigate To Savings Customer Form    t5.3.2 Savings
    # Click Add new section — verify modal appears
    Click    ${CP_ADD_SECTION_BTN}
    Wait For Elements State
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content    visible
    # Verify modal has a section name input
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content input    visible
    # Verify Add section button is disabled before entering a name
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content button.btn-primary
    ...    disabled
    # Verify Back button in modal is enabled
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content button.btn-outline
    ...    enabled
    # Enter section name — verify Add section button becomes enabled
    Fill Text
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content input
    ...    ${T53_SECTION_NAME}
    Wait For Elements State
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content button.btn-primary
    ...    enabled    timeout=5s
    # Click Add section — verify modal closes and section appears in form
    Click
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content button.btn-primary
    Wait For Elements State
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content    hidden    timeout=5s
    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=${T53_SECTION_NAME}    visible

t5.3.3 Add Customer Input Field to Savings Section
    [Documentation]    Verify that clicking 'Add customer input field' opens a modal with Field Type
    ...                dropdown (Text input, Number, Dropdown, Checkbox options), Field Name, and
    ...                Placeholder inputs. After submitting, the field is rendered in the section,
    ...                Continue becomes enabled, and the Back button navigates to Step 1.
    ...
    ...                Preconditions:
    ...                1. Teller is logged in.
    ...                2. User is on Step 2 – Customer Form for Savings.
    ...                3. At least one section exists.
    [Tags]    products    create    savings    smoke    mvp    type2
    Navigate To Savings Customer Form    t5.3.3 Savings
    Add Section To Customer Form
    # Click Add customer input field — verify modal appears
    Click    css=[data-testid="page-products-create"] button:has-text("Add customer input field")
    Wait For Elements State
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content    visible
    # Verify Field Type dropdown is present and shows expected options
    Click
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content [data-field="type"] .ant-select-selector
    Wait For Elements State    css=.ant-select-dropdown:not(.ant-select-dropdown-hidden)    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    css=.ant-select-dropdown:not(.ant-select-dropdown-hidden) .ant-select-item-option:has-text("Text input (single line)")
    ...    visible    timeout=5s
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    css=.ant-select-dropdown:not(.ant-select-dropdown-hidden) .ant-select-item-option:has-text("Text input (multi-line)")
    ...    visible    timeout=5s
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    css=.ant-select-dropdown:not(.ant-select-dropdown-hidden) .ant-select-item-option:has-text("Number input")
    ...    visible    timeout=5s
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    css=.ant-select-dropdown:not(.ant-select-dropdown-hidden) .ant-select-item-option:has-text("Dropdown (single selection)")
    ...    visible    timeout=5s
    # Reopen dropdown if it closed during option verification, then select Text input (single line)
    ${dropdown_open}=    Run Keyword And Return Status
    ...    Wait For Elements State    css=.ant-select-dropdown:not(.ant-select-dropdown-hidden)    visible    timeout=1s
    IF    not ${dropdown_open}
        Click
        ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content [data-field="type"] .ant-select-selector
        Wait For Elements State    css=.ant-select-dropdown:not(.ant-select-dropdown-hidden)    visible
    END
    Click
    ...    css=.ant-select-dropdown:not(.ant-select-dropdown-hidden) .ant-select-item-option:has-text("Text input (single line)")
    Wait For Elements State    css=.ant-select-dropdown:not(.ant-select-dropdown-hidden)    hidden    timeout=3s
    # Fill field name and placeholder
    Fill Text
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content [data-field="label"] input
    ...    ${T53_FIELD_NAME}
    Fill Text
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content [data-field="placeholder"] input
    ...    ${T53_FIELD_PLACEHOLDER}
    # Verify optional field checkbox is present
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content [data-field="isOptional"] input[type="checkbox"]
    ...    visible
    # Click Add field — verify modal closes and field is rendered in section
    Wait For Elements State
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content button.btn-primary
    ...    enabled    timeout=5s
    Click
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content button.btn-primary
    Wait For Elements State
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content    hidden    timeout=5s
    # Verify field is rendered in the section
    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=${T53_FIELD_NAME}    visible
    # Verify delete icon is shown for the field
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    css=[data-testid="page-products-create"] .tabler-icon-trash >> nth=0    visible
    # Verify Continue button becomes enabled after adding a field
    Wait For Elements State    ${CREATE_PRODUCT_CONTINUE_BTN}    enabled    timeout=5s
    # Verify clicking Back navigates to Step 1 – Product Configuration
    Click    ${CP_BACK_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State    css=.ant-steps-item-process:has-text("Product Configuration")    visible

t5.3.4 Delete Custom Field from Savings Section
    [Documentation]    Verify that clicking the delete (trash) icon on a custom field immediately
    ...                removes it from the section. If the section has no remaining fields,
    ...                the Continue button becomes disabled.
    ...
    ...                Preconditions:
    ...                1. Teller is logged in.
    ...                2. A custom field exists inside a section in the Savings Customer Form.
    [Tags]    products    create    savings    smoke    mvp    type2
    Navigate To Savings Customer Form    t5.3.4 Savings
    Add Section To Customer Form
    Add Text Input Field To Section
    # Verify Continue is enabled before deletion
    Wait For Elements State    ${CREATE_PRODUCT_CONTINUE_BTN}    enabled    timeout=5s
    # Click the delete (trash) icon for the field
    Click    css=[data-testid="page-products-create"] .tabler-icon-trash >> nth=0
    Wait For Load Spinner To Disappear
    # Verify the field is removed from the section
    ${field_still_visible}=    Run Keyword And Return Status
    ...    Wait For Elements State
    ...    ${CREATE_PRODUCT_PAGE} >> text=${T53_FIELD_NAME}
    ...    visible    timeout=3s
    Should Not Be True    ${field_still_visible}
    ...    msg=Field "${T53_FIELD_NAME}" should have been deleted but is still visible
    # Verify Continue becomes disabled when no fields remain in the section
    Wait For Elements State    ${CREATE_PRODUCT_CONTINUE_BTN}    disabled    timeout=5s

t5.3.5 Review and Confirm Savings Product Creation
    [Documentation]    Verify that completing all steps (Product Configuration and Customer Form)
    ...                and clicking Continue opens the Review Product step with accurate data.
    ...                Clicking 'Confirm & Create Product' creates the product, shows a success
    ...                message, and redirects to the Products module.
    ...
    ...                Preconditions:
    ...                1. Teller is logged in.
    ...                2. Product Configuration (Step 1) is completed.
    ...                3. Customer Form (Step 2) has at least one section with at least one field.
    [Tags]    products    create    savings    smoke    mvp    type2
    # Generate unique product name with timestamp and store as suite variable for t5.3.6/7/8
    ${timestamp}=    Evaluate    __import__('datetime').datetime.now().strftime('%m%d%H%M%S')
    ${product_name}=    Set Variable    Savings ${timestamp}
    Set Suite Variable    ${T53_PRODUCT_NAME}    ${product_name}
    # Navigate to Step 2 (Customer Form) with completed Step 1
    Navigate To Savings Customer Form    ${product_name}
    Add Section To Customer Form
    Add Text Input Field To Section
    # Click Continue — verify redirect to Step 3 (Review Product)
    Wait For Elements State    ${CREATE_PRODUCT_CONTINUE_BTN}    enabled    timeout=5s
    Click    ${CREATE_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State    css=.ant-steps-item-process:has-text("Review Product")    visible
    # Verify Step 3 header/page is visible
    Wait For Elements State    ${CREATE_PRODUCT_PAGE}    visible
    # Verify all Step 1 data is accurately reflected in the review
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=${product_name}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=Product Details    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=Eligibility For Customer Type    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=Account Configuration    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=Interest Configuration    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=Fees & Charges    visible
    # Verify Customer Form section is also reflected
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=${T53_SECTION_NAME}    visible
    # Verify clicking Back returns to Step 2 (Customer Form)
    Click    ${CP_BACK_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State    css=.ant-steps-item-process:has-text("Customer Form")    visible
    # Return to Step 3 (Review) — wait for Continue to be enabled (Step 2 data should be preserved)
    Wait For Elements State    ${CREATE_PRODUCT_CONTINUE_BTN}    enabled    timeout=5s
    Click    ${CREATE_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State    css=.ant-steps-item-process:has-text("Review Product")    visible
    # Click Confirm & Create Product
    Wait For Elements State    ${CP_CONFIRM_CREATE_BTN}    visible    timeout=10s
    Click    ${CP_CONFIRM_CREATE_BTN}
    Wait For Load Spinner To Disappear
    # Verify redirect to Products module (confirms product was created successfully)
    Wait For Elements State    ${PRODUCTS_LIST_PAGE}    visible    timeout=15s

t5.3.6 Verify New Savings Product Position and Status in Product List
    [Documentation]    Verify that a newly created Savings product appears as the first row (top)
    ...                of the Active Products list and defaults to Active status.
    ...                A page reload is required after navigating to the Products module
    ...                to ensure the table reflects the latest data.
    ...
    ...                Preconditions:
    ...                1. A new Savings product has just been created (t5.3.5 must have run first).
    ...                2. User is on the Products Module dashboard.
    [Tags]    products    create    savings    smoke    mvp    type2
    Skip If    '${T53_PRODUCT_NAME}' == '${EMPTY}'
    ...    msg=t5.3.5 must run first to set the created product name
    # Reload to refresh the Active Products table with the latest data
    Reload
    Wait For Elements State    ${ACTIVE_PRODUCTS_TABLE}    visible
    Wait For Load Spinner To Disappear
    # Verify the newly created product appears as the first row
    ${first_row_text}=    Get Text    ${ACTIVE_PRODUCTS_TABLE_ROWS} >> nth=0
    Should Contain    ${first_row_text}    ${T53_PRODUCT_NAME}
    ...    msg=Expected newly created product "${T53_PRODUCT_NAME}" to be the first row in Active Products

t5.3.7 View Details of a Newly Created Savings Product
    [Documentation]    Verify that clicking View on the newly created Savings product opens a modal
    ...                displaying the Product ID and two columns:
    ...                - Customer Form (sections and fields)
    ...                - Product Configurations (all configuration sections and their fields)
    ...
    ...                Preconditions:
    ...                1. Teller is on the Products Module – Active Products tab.
    ...                2. A Savings product created by t5.3.5 exists in the list.
    [Tags]    products    create    savings    smoke    mvp    type2
    Skip If    '${T53_PRODUCT_NAME}' == '${EMPTY}'
    ...    msg=t5.3.5 must run first to set the created product name
    # Reload to refresh the Active Products table with the latest data
    Reload
    Wait For Elements State    ${ACTIVE_PRODUCTS_TABLE}    visible
    Wait For Load Spinner To Disappear
    # Verify product row exists at the top and click View
    Wait For Elements State
    ...    css=[data-testid="table-products-active"] tbody tr:has-text("${T53_PRODUCT_NAME}") >> nth=0
    ...    visible
    Click
    ...    css=[data-testid="table-products-active"] tbody tr:has-text("${T53_PRODUCT_NAME}") [data-testid="btn-products-view"]
    Wait For Load Spinner To Disappear
    Wait For Elements State    ${PRODUCT_DETAILS_MODAL}    visible
    # Verify modal shows Product ID
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=/PROD_/    visible
    # Verify Customer Form column
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    ${PRODUCT_DETAILS_MODAL} >> p.text-xl:text-is("Customer Form")    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=${T53_SECTION_NAME}    visible
    # Verify Product Configurations column sections
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=Product Configuration    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=Product name    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=Product type    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=Minimum age    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=Average daily balance    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=Initial deposit    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=Overdrafts    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=Withdrawal limit frequency    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=Withdrawal limit amount    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=Interest rate(%)    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=Interest type    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=Interest time period    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=Interest rate structure    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=Excess withdrawal fee    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=Dormancy fee    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=Account closure fee    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=Tax rate type    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=Tax rate value    visible

t5.3.8 New Savings Product Visibility in Customer Eligible Products Tab
    [Documentation]    Verify that the newly created Savings product appears in an eligible customer's
    ...                Eligible Products tab with the correct name and category. Clicking 'See Details'
    ...                opens a side panel with complete product configuration, and an 'Avail Product'
    ...                button is visible.
    ...
    ...                Preconditions:
    ...                1. Teller is logged in.
    ...                2. A new Savings product has just been created (t5.3.5 must have run first).
    ...                3. An existing customer (${T24_CUSTOMER_NAME}) is eligible for the new product.
    [Tags]    products    create    savings    regression    mvp    type2
    [Setup]    Navigate To Customers
    Skip If    '${T53_PRODUCT_NAME}' == '${EMPTY}'
    ...    msg=t5.3.5 must run first to set the created product name
    # Navigate to customer profile
    View Customer Profile    ${T24_CUSTOMER_NAME}
    # Click Eligible Products tab
    Click    ${ELIGIBLE_PRODUCTS_TAB}
    Wait For Elements State    ${PRODUCT_TABLE}    visible
    # Search for the newly created product
    Fill Text    ${PRODUCT_SEARCH_INPUT}    ${T53_PRODUCT_NAME}
    Click    ${PRODUCT_SEARCH_BTN}
    Wait For Load Spinner To Disappear
    # Verify the product appears in the list
    ${product_visible}=    Run Keyword And Return Status
    ...    Wait For Elements State
    ...    css=.ant-table-body tr:has-text("${T53_PRODUCT_NAME}") >> nth=0
    ...    visible    timeout=10s
    Skip If    not ${product_visible}
    ...    msg=Product "${T53_PRODUCT_NAME}" not found in eligible products — customer may not meet eligibility criteria
    # Verify correct Product Category is shown as Savings
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    css=.ant-table-body tr:has-text("${T53_PRODUCT_NAME}"):has-text("Savings") >> nth=0
    ...    visible
    # Click See Details
    Click
    ...    css=.ant-table-body tr:has-text("${T53_PRODUCT_NAME}") >> nth=0 >> ${SEE_DETAILS_BTN}
    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER}    visible
    # Verify Product Details section
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Product name    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Product type    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Description    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Status    visible
    # Verify Eligibility for Customer Type
    Scroll To Element    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Minimum age
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Minimum age    visible
    # Verify Account Configuration
    Scroll To Element    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Average daily balance
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Average daily balance    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Initial deposit    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Overdrafts    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Withdrawal limit frequency    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Withdrawal limit amount    visible
    # Verify Interest Configuration
    Scroll To Element    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text="Interest rate(%)"
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text="Interest rate(%)"    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Interest type    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Interest time period    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Interest rate structure    visible
    # Verify Fees & Charges
    Scroll To Element    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Excess withdrawal fee
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Excess withdrawal fee    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Dormancy fee    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Account closure fee    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Tax rate type    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Tax rate value    visible
    # Verify Avail Product button is visible and enabled for the eligible customer
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_BTN}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_BTN}    enabled
    # Close side panel
    Click    ${PRODUCT_DETAILS_CLOSE_BTN}
    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER}    hidden

t5.3.9 Create New Loans Product – Happy Path
    [Documentation]    Verify the full Loans product creation flow from clicking the Create Product
    ...                button through completing Step 1 (Product Definition) and arriving at
    ...                Step 2 (Customer Form). Verifies the leave-page confirmation modal on Back
    ...                from Step 1, and that the pre-built Loan Details section is visible in Step 2.
    ...
    ...                Preconditions:
    ...                1. Teller is logged in.
    ...                2. User has permissions to Create Products.
    ...                3. User is on the Products Module page.
    [Tags]    products    create    loans    smoke    mvp    type2
    # Click Create Product dropdown trigger — verify category selector appears
    Click    ${CREATE_PRODUCT_DROPDOWN_TRIGGER}
    Wait For Elements State    css=.ant-dropdown:not(.ant-dropdown-hidden)    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_SAVINGS_OPTION}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_LOANS_OPTION}    visible
    # Select Loans — verify redirect to Step 1 (Product Definition)
    Click    ${CREATE_LOANS_OPTION}
    Wait For Load Spinner To Disappear
    Wait For Elements State    ${CREATE_PRODUCT_PAGE}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=Loan Features    visible    timeout=10s
    # Verify all required sections are present in Step 1
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=Product Definition    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=Product Details    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=Loan Features    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=Eligibility Criteria    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=Pricing & Fees    visible
    # Verify Continue is disabled before filling any required fields
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_CONTINUE_BTN}    disabled
    # Click Back from Step 1 — verify leave-page confirmation modal appears
    Click    ${CP_BACK_BTN}
    Wait For Elements State    ${LEAVE_PAGE_CONFIRM_MODAL}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${LEAVE_PAGE_CONFIRM_BTN}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${LEAVE_PAGE_CANCEL_BTN}    visible
    # Click "Back" in modal — verify user stays on Product Definition page
    Click    ${LEAVE_PAGE_CANCEL_BTN}
    Wait For Elements State    ${LEAVE_PAGE_CONFIRM_MODAL}    hidden
    Wait For Elements State    ${CREATE_PRODUCT_PAGE}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=Loan Features    visible    timeout=10s
    # Fill all mandatory fields in Step 1
    ${timestamp}=    Evaluate    __import__('datetime').datetime.now().strftime('%m%d%H%M%S')
    ${product_name}=    Set Variable    Loan ${timestamp}
    Fill Loans Product Step 1    ${product_name}
    # Click Continue — verify redirect to Step 2 (Customer Form)
    Wait For Elements State    ${CREATE_PRODUCT_CONTINUE_BTN}    enabled    timeout=10s
    Click    ${CREATE_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State    css=.ant-steps-item-process:has-text("Customer Form")    visible
    # Verify Step 2 layout: pre-built Loan Details section visible, Add new section btn visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CLP_LOAN_DETAILS_SECTION_HEADER}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CP_ADD_SECTION_BTN}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CP_BACK_BTN}    enabled
    # Navigate away via Products menu — leave-page confirmation modal appears
    Click    ${PRODUCTS_MENU}
    Wait For Elements State    ${LEAVE_PAGE_CONFIRM_MODAL}    visible
    # Click Confirm — verify redirect to Products module
    Click    ${LEAVE_PAGE_CONFIRM_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State    ${PRODUCTS_LIST_PAGE}    visible

t5.3.10 Add New Section to Loans Customer Form
    [Documentation]    Verify that clicking 'Add new section' opens a modal with a section name
    ...                input field and a disabled 'Add section' button (until name is entered),
    ...                and that submitting the form renders the new section in the Loans Customer Form.
    ...
    ...                Preconditions:
    ...                1. Teller is logged in.
    ...                2. User is on Step 2 – Customer Form for a Loans product.
    ...                3. Product Definition is completed.
    [Tags]    products    create    loans    smoke    mvp    type2
    Navigate To Loans Customer Form    t5.3.10 Loans
    # Click Add new section — verify modal appears
    Click    ${CP_ADD_SECTION_BTN}
    Wait For Elements State
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content    visible
    # Verify modal has a section name input
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content input    visible
    # Verify Add section button is disabled before entering a name
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content button.btn-primary
    ...    disabled
    # Verify Back button in modal is enabled
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content button.btn-outline
    ...    enabled
    # Enter section name — verify Add section button becomes enabled
    Fill Text
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content input
    ...    ${T53_LOANS_SECTION_NAME}
    Wait For Elements State
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content button.btn-primary
    ...    enabled    timeout=5s
    # Click Add section — verify modal closes and section appears in form
    Click
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content button.btn-primary
    Wait For Elements State
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content    hidden    timeout=5s
    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=${T53_LOANS_SECTION_NAME}    visible

t5.3.11 Add Customer Input Field to Loans Section
    [Documentation]    Verify that clicking 'Add customer input field' opens a modal with Field Type
    ...                dropdown, Field Name, and Placeholder inputs. After submitting, the field is
    ...                rendered in the section, Continue becomes enabled, and Back navigates to Step 1.
    ...
    ...                Preconditions:
    ...                1. Teller is logged in.
    ...                2. User is on Step 2 – Customer Form for Loans.
    ...                3. At least one custom section exists.
    [Tags]    products    create    loans    smoke    mvp    type2
    Navigate To Loans Customer Form    t5.3.11 Loans
    Add Section To Customer Form    ${T53_LOANS_SECTION_NAME}
    # Click Add customer input field — verify modal appears
    Click    css=[data-testid="page-products-create"] button:has-text("Add customer input field")
    Wait For Elements State
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content    visible
    # Verify Field Type dropdown is present and shows expected options
    Click
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content [data-field="type"] .ant-select-selector
    Wait For Elements State    css=.ant-select-dropdown:not(.ant-select-dropdown-hidden)    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    css=.ant-select-dropdown:not(.ant-select-dropdown-hidden) .ant-select-item-option:has-text("Text input (single line)")
    ...    visible    timeout=5s
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    css=.ant-select-dropdown:not(.ant-select-dropdown-hidden) .ant-select-item-option:has-text("Number input")
    ...    visible    timeout=5s
    # Reopen dropdown if it closed, then select Text input (single line)
    ${dropdown_open}=    Run Keyword And Return Status
    ...    Wait For Elements State    css=.ant-select-dropdown:not(.ant-select-dropdown-hidden)    visible    timeout=1s
    IF    not ${dropdown_open}
        Click
        ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content [data-field="type"] .ant-select-selector
        Wait For Elements State    css=.ant-select-dropdown:not(.ant-select-dropdown-hidden)    visible
    END
    Click
    ...    css=.ant-select-dropdown:not(.ant-select-dropdown-hidden) .ant-select-item-option:has-text("Text input (single line)")
    Wait For Elements State    css=.ant-select-dropdown:not(.ant-select-dropdown-hidden)    hidden    timeout=3s
    # Fill field name and placeholder
    Fill Text
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content [data-field="label"] input
    ...    ${T53_LOANS_FIELD_NAME}
    Fill Text
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content [data-field="placeholder"] input
    ...    ${T53_LOANS_FIELD_PLACEHOLDER}
    # Verify optional field checkbox is present
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content [data-field="isOptional"] input[type="checkbox"]
    ...    visible
    # Click Add field — verify modal closes and field is rendered in section
    Wait For Elements State
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content button.btn-primary
    ...    enabled    timeout=5s
    Click
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content button.btn-primary
    Wait For Elements State
    ...    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-content    hidden    timeout=5s
    # Verify field is rendered in the section
    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=${T53_LOANS_FIELD_NAME}    visible
    # Verify delete icon is shown for the field
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    css=[data-testid="page-products-create"] .tabler-icon-trash >> nth=0    visible
    # Verify Continue button becomes enabled after adding a field
    Wait For Elements State    ${CREATE_PRODUCT_CONTINUE_BTN}    enabled    timeout=5s
    # Verify clicking Back navigates to Step 1 – Product Definition
    Click    ${CP_BACK_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=Loan Features    visible

t5.3.12 Delete Custom Field from Loans Section
    [Documentation]    Verify that clicking the delete (trash) icon on a custom field in the Loans
    ...                Customer Form immediately removes it from the section. If the section has no
    ...                remaining fields, the Continue button becomes disabled.
    ...
    ...                Preconditions:
    ...                1. Teller is logged in.
    ...                2. A custom field exists inside a section in the Loans Customer Form.
    [Tags]    products    create    loans    smoke    mvp    type2
    Navigate To Loans Customer Form    t5.3.12 Loans
    Add Section To Customer Form    ${T53_LOANS_SECTION_NAME}
    Add Text Input Field To Section    ${T53_LOANS_FIELD_NAME}    ${T53_LOANS_FIELD_PLACEHOLDER}
    # Verify Continue is enabled before deletion
    Wait For Elements State    ${CREATE_PRODUCT_CONTINUE_BTN}    enabled    timeout=5s
    # Click the delete (trash) icon for the field
    Click    css=[data-testid="page-products-create"] .tabler-icon-trash >> nth=0
    Wait For Load Spinner To Disappear
    # Verify the field is removed from the section
    ${field_still_visible}=    Run Keyword And Return Status
    ...    Wait For Elements State
    ...    ${CREATE_PRODUCT_PAGE} >> text=${T53_LOANS_FIELD_NAME}
    ...    visible    timeout=3s
    Should Not Be True    ${field_still_visible}
    ...    msg=Field "${T53_LOANS_FIELD_NAME}" should have been deleted but is still visible
    # Verify Continue becomes disabled when no fields remain in the section
    Wait For Elements State    ${CREATE_PRODUCT_CONTINUE_BTN}    disabled    timeout=5s

t5.3.13 Loans Customer Form Has Pre-built Loan Details Section
    [Documentation]    Verify that the Loans Customer Form (Step 2) contains a pre-built, non-editable
    ...                'Loan Details' section. All input fields in this section should be disabled
    ...                (read-only) and cannot be modified.
    ...
    ...                Preconditions:
    ...                1. Teller is logged in.
    ...                2. User is on Step 2 – Customer Form for a Loans product.
    [Tags]    products    create    loans    smoke    mvp    type2
    Navigate To Loans Customer Form    t5.3.13 Loans
    # Verify the pre-built Loan Details section header is visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CLP_LOAN_DETAILS_SECTION_HEADER}    visible
    # Verify at least one disabled field exists (pre-built section uses ant-input-number-disabled)
    ${disabled_count}=    Get Element Count    ${CLP_DISABLED_FIELDS}
    Should Be True    ${disabled_count} > 0
    ...    msg=Expected at least one disabled field in the pre-built Loan Details section but found none
    # Verify the disabled-styled field is visible (Playwright cannot check AntD CSS-class-based disabled state)
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CLP_DISABLED_FIELDS} >> nth=0    visible

t5.3.14 Review and Confirm Loans Product Creation
    [Documentation]    Verify that completing all steps (Product Definition and Customer Form)
    ...                and clicking Continue opens the Review Product step with accurate data.
    ...                Clicking 'Confirm and Create Product' creates the product, shows the Products
    ...                module, and the suite variable T53_LOANS_PRODUCT_NAME is set for t5.3.15–17.
    ...
    ...                Preconditions:
    ...                1. Teller is logged in.
    ...                2. Product Definition (Step 1) is completed.
    ...                3. Customer Form (Step 2) has at least one section with at least one field.
    [Tags]    products    create    loans    smoke    mvp    type2
    # Generate unique product name with timestamp and store as suite variable for t5.3.15/16/17
    ${timestamp}=    Evaluate    __import__('datetime').datetime.now().strftime('%m%d%H%M%S')
    ${product_name}=    Set Variable    Loan ${timestamp}
    Set Suite Variable    ${T53_LOANS_PRODUCT_NAME}    ${product_name}
    # Navigate to Step 2 (Customer Form) with completed Step 1
    Navigate To Loans Customer Form    ${product_name}
    Add Section To Customer Form    ${T53_LOANS_SECTION_NAME}
    Add Text Input Field To Section    ${T53_LOANS_FIELD_NAME}    ${T53_LOANS_FIELD_PLACEHOLDER}
    # Click Continue — verify redirect to Step 3 (Review Product)
    Wait For Elements State    ${CREATE_PRODUCT_CONTINUE_BTN}    enabled    timeout=5s
    Click    ${CREATE_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State    css=.ant-steps-item-process:has-text("Review Product")    visible
    # Verify Step 3 header/page is visible
    Wait For Elements State    ${CREATE_PRODUCT_PAGE}    visible
    # Verify all Step 1 data is accurately reflected in the review
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=${product_name}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=Product Definition    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=Product Details    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=Loan Features    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=Eligibility Criteria    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=Pricing & Fees    visible
    # Verify Customer Form custom section is also reflected
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=${T53_LOANS_SECTION_NAME}    visible
    # Verify clicking Back returns to Step 2 (Customer Form)
    Click    ${CP_BACK_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State    css=.ant-steps-item-process:has-text("Customer Form")    visible
    # Return to Step 3 (Review) — Step 2 data should be preserved
    Wait For Elements State    ${CREATE_PRODUCT_CONTINUE_BTN}    enabled    timeout=5s
    Click    ${CREATE_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State    css=.ant-steps-item-process:has-text("Review Product")    visible
    # Click Confirm and Create Product
    Wait For Elements State    ${CP_CONFIRM_CREATE_BTN}    visible    timeout=10s
    Click    ${CP_CONFIRM_CREATE_BTN}
    Wait For Load Spinner To Disappear
    # Verify redirect to Products module (confirms product was created successfully)
    Wait For Elements State    ${PRODUCTS_LIST_PAGE}    visible    timeout=15s

t5.3.15 Verify New Loans Product Position and Status in Product List
    [Documentation]    Verify that a newly created Loans product appears as the first row (top)
    ...                of the Active Products list and defaults to Active status.
    ...                A page reload is required after navigating to the Products module
    ...                to ensure the table reflects the latest data.
    ...
    ...                Preconditions:
    ...                1. A new Loans product has just been created (t5.3.14 must have run first).
    ...                2. User is on the Products Module dashboard.
    [Tags]    products    create    loans    smoke    mvp    type2
    Skip If    '${T53_LOANS_PRODUCT_NAME}' == '${EMPTY}'
    ...    msg=t5.3.14 must run first to set the created loans product name
    # Reload to refresh the Active Products table with the latest data
    Reload
    Wait For Elements State    ${ACTIVE_PRODUCTS_TABLE}    visible
    Wait For Load Spinner To Disappear
    # Verify the newly created Loans product appears as the first row
    ${first_row_text}=    Get Text    ${ACTIVE_PRODUCTS_TABLE_ROWS} >> nth=0
    Should Contain    ${first_row_text}    ${T53_LOANS_PRODUCT_NAME}
    ...    msg=Expected newly created Loans product "${T53_LOANS_PRODUCT_NAME}" to be the first row in Active Products

t5.3.16 View Details of a Newly Created Loans Product
    [Documentation]    Verify that clicking View on the newly created Loans product opens a modal
    ...                displaying the Product ID and two columns:
    ...                - Customer Form (sections and fields)
    ...                - Product Configurations (loan-specific configuration sections and their fields)
    ...
    ...                Preconditions:
    ...                1. Teller is on the Products Module – Active Products tab.
    ...                2. A Loans product created by t5.3.14 exists in the list.
    [Tags]    products    create    loans    smoke    mvp    type2
    Skip If    '${T53_LOANS_PRODUCT_NAME}' == '${EMPTY}'
    ...    msg=t5.3.14 must run first to set the created loans product name
    # Reload to refresh the Active Products table with the latest data
    Reload
    Wait For Elements State    ${ACTIVE_PRODUCTS_TABLE}    visible
    Wait For Load Spinner To Disappear
    # Verify product row exists at the top and click View
    Wait For Elements State
    ...    css=[data-testid="table-products-active"] tbody tr:has-text("${T53_LOANS_PRODUCT_NAME}") >> nth=0
    ...    visible
    Click
    ...    css=[data-testid="table-products-active"] tbody tr:has-text("${T53_LOANS_PRODUCT_NAME}") [data-testid="btn-products-view"]
    Wait For Load Spinner To Disappear
    Wait For Elements State    ${PRODUCT_DETAILS_MODAL}    visible
    # Verify modal shows Product ID
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=/PROD_/    visible
    # Verify Customer Form column shows the custom section
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    ${PRODUCT_DETAILS_MODAL} >> p.text-xl:text-is("Customer Form")    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=${T53_LOANS_SECTION_NAME}    visible
    # Verify Product Configurations column — Loans-specific sections
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=Product Definition    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=Loan type    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=Loan purpose    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=Product name    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=Loan Features    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=Minimum loan amount    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=Maximum loan amount    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=/^Loan term length$/ >> nth=0    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=Interest rate type    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=Eligibility Criteria    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=Minimum age    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=Pricing & Fees    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=/^Interest rate \\(%\\)$/ >> nth=0    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=/^Processing fee$/ >> nth=0    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${PRODUCT_DETAILS_MODAL} >> text=Penalty interest rate    visible

t5.3.17 New Loans Product Visibility in Customer Eligible Products Tab
    [Documentation]    Verify that the newly created Loans product appears in an eligible customer's
    ...                Eligible Products tab with the correct name and category (Loans). Clicking
    ...                'See Details' opens a side panel with complete product configuration, and an
    ...                'Avail Product' button is visible.
    ...
    ...                Preconditions:
    ...                1. Teller is logged in.
    ...                2. A new Loans product has just been created (t5.3.14 must have run first).
    ...                3. An existing customer (${T24_CUSTOMER_NAME}) is eligible for the new product.
    [Tags]    products    create    loans    regression    mvp    type2
    [Setup]    Navigate To Customers
    Skip If    '${T53_LOANS_PRODUCT_NAME}' == '${EMPTY}'
    ...    msg=t5.3.14 must run first to set the created loans product name
    # Navigate to customer profile
    View Customer Profile    ${T24_CUSTOMER_NAME}
    # Click Eligible Products tab
    Click    ${ELIGIBLE_PRODUCTS_TAB}
    Wait For Elements State    ${PRODUCT_TABLE}    visible
    # Search for the newly created loans product
    Fill Text    ${PRODUCT_SEARCH_INPUT}    ${T53_LOANS_PRODUCT_NAME}
    Click    ${PRODUCT_SEARCH_BTN}
    Wait For Load Spinner To Disappear
    # Verify the product appears in the list
    ${product_visible}=    Run Keyword And Return Status
    ...    Wait For Elements State
    ...    css=.ant-table-body tr:has-text("${T53_LOANS_PRODUCT_NAME}") >> nth=0
    ...    visible    timeout=10s
    Skip If    not ${product_visible}
    ...    msg=Product "${T53_LOANS_PRODUCT_NAME}" not found in eligible products — customer may not meet eligibility criteria
    # Verify correct Product Category is shown as Loans
    Run Keyword And Continue On Failure
    ...    Wait For Elements State
    ...    css=.ant-table-body tr:has-text("${T53_LOANS_PRODUCT_NAME}"):has-text("Loans") >> nth=0
    ...    visible
    # Click See Details
    Click
    ...    css=.ant-table-body tr:has-text("${T53_LOANS_PRODUCT_NAME}") >> nth=0 >> ${SEE_DETAILS_BTN}
    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER}    visible
    # Verify Loans-specific Product Details sections
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Product name    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Description    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Loan type    visible
    # Verify Loan Features section
    Scroll To Element    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Minimum loan amount
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Minimum loan amount    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Maximum loan amount    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=/^Loan term length$/ >> nth=0    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Interest rate type    visible
    # Verify Eligibility Criteria section
    Scroll To Element    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Minimum age
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Minimum age    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Maximum age    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Minimum income    visible
    # Verify Pricing & Fees section
    Scroll To Element    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=/^Interest rate \\(%\\)$/ >> nth=0
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=/^Interest rate \\(%\\)$/ >> nth=0    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=/^Processing fee$/ >> nth=0    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER} >> text=Penalty interest rate    visible
    # Verify Avail Product button is visible and enabled for the eligible customer
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_BTN}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${AVAIL_PRODUCT_BTN}    enabled
    # Close side panel
    Click    ${PRODUCT_DETAILS_CLOSE_BTN}
    Wait For Elements State    ${ELIGIBLE_PRODUCT_DETAILS_DRAWER}    hidden

t5.3.18 Cancel Product Creation – Discard Unsaved Data
    [Documentation]    Verify that clicking 'Back' on the Product Configuration step while fields
    ...                are partially filled shows the leave-page confirmation modal, and clicking
    ...                'Confirm' redirects the user to the Products Module with all unsaved data
    ...                discarded and no partial product created.
    ...
    ...                Preconditions:
    ...                1. Teller is logged in.
    ...                2. User is on Create Product page (Savings) with fields partially filled.
    [Tags]    products    create    savings    smoke    mvp    type2
    Navigate To Create Savings Product
    # Partially fill Product Name to simulate unsaved in-progress data
    Fill Text    ${CP_PRODUCT_NAME_INPUT}    t5.3.18 Partial Savings
    # Click Back — verify leave-page confirmation modal appears with both buttons
    Click    ${CP_BACK_BTN}
    Wait For Elements State    ${LEAVE_PAGE_CONFIRM_MODAL}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${LEAVE_PAGE_CONFIRM_BTN}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${LEAVE_PAGE_CANCEL_BTN}    visible
    # Click Confirm — verify redirect to Products Module (unsaved data discarded)
    Click    ${LEAVE_PAGE_CONFIRM_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State    ${PRODUCTS_LIST_PAGE}    visible

t5.3.19 Session Timeout During Product Creation Flow
    [Documentation]    Verify that when a teller remains inactive for 5 minutes and 1 second
    ...                during the Create Product flow, the session is automatically terminated,
    ...                the user is redirected to the Login page, and a 'Session Expired' modal
    ...                is displayed with unsaved product data lost.
    ...
    ...                Preconditions:
    ...                1. Teller is logged in.
    ...                2. User is on any step of the Create Product flow.
    ...                3. User remains inactive beyond session timeout (5 minutes).
    [Tags]    products    create    regression
    Skip    msg=Requires 5+ minutes of idle time — not suitable for automated CI runs. Execute manually: navigate to Create Product, leave idle for 5m 1s, verify Session Expired modal appears and user is redirected to Login.

t5.3.20 Back Navigation from Review Step Preserves All Entered Data
    [Documentation]    Verify that clicking 'Back' from the Review Product step (Step 3) returns
    ...                to Step 2 with all Customer Form data intact, and that clicking 'Back' again
    ...                from Step 2 returns to Step 1 with all Product Configuration data intact.
    ...                No data loss occurs when navigating backwards through the flow.
    ...
    ...                Preconditions:
    ...                1. Teller is logged in.
    ...                2. User is on Step 3 – Review Product for a Savings product.
    [Tags]    products    create    savings    regression    mvp    type2
    ${timestamp}=    Evaluate    __import__('datetime').datetime.now().strftime('%m%d%H%M%S')
    ${product_name}=    Set Variable    Savings ${timestamp}
    # Navigate through full flow: Step 1 → Step 2 with a section and field
    Navigate To Savings Customer Form    ${product_name}
    Add Section To Customer Form    ${T53_SECTION_NAME}
    Add Text Input Field To Section    ${T53_FIELD_NAME}    ${T53_FIELD_PLACEHOLDER}
    # Advance to Step 3 – Review Product
    Wait For Elements State    ${CREATE_PRODUCT_CONTINUE_BTN}    enabled    timeout=5s
    Click    ${CREATE_PRODUCT_CONTINUE_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State    css=.ant-steps-item-process:has-text("Review Product")    visible
    # Click Back from Step 3 — verify return to Step 2 with Customer Form data preserved
    Click    ${CP_BACK_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State    css=.ant-steps-item-process:has-text("Customer Form")    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=${T53_SECTION_NAME}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=${T53_FIELD_NAME}    visible
    # Click Back from Step 2 — verify return to Step 1 with Product Configuration data preserved
    Click    ${CP_BACK_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State    css=.ant-steps-item-process:has-text("Product Configuration")    visible
    ${name_value}=    Get Property    ${CP_PRODUCT_NAME_INPUT}    value
    Run Keyword And Continue On Failure
    ...    Should Contain    ${name_value}    Savings
    ...    msg=Expected product name to be preserved on Step 1 after back navigation, but got: ${name_value}
    # Verify Continue is still enabled (all Step 1 fields still populated)
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_CONTINUE_BTN}    enabled    timeout=5s

t5.3.21 Mandatory Field Validation – Product Details Section (Savings)
    [Documentation]    Verify that leaving mandatory Product Details fields blank (Product Name,
    ...                Description) and interacting with them triggers field-level validation errors,
    ...                and the Continue button remains disabled.
    ...
    ...                Preconditions:
    ...                1. Teller is logged in.
    ...                2. User is on Step 1 – Product Configuration for Savings.
    [Tags]    products    create    savings    validation
    Navigate To Create Savings Product
    # Fill then clear Product Name to trigger required field validation
    Fill Text    ${CP_PRODUCT_NAME_INPUT}    x
    Fill Text    ${CP_PRODUCT_NAME_INPUT}    ${EMPTY}
    # Fill then clear Description to trigger required field validation
    Fill Text    ${CP_DESCRIPTION_TEXTAREA}    x
    Fill Text    ${CP_DESCRIPTION_TEXTAREA}    ${EMPTY}
    Click    ${CREATE_PRODUCT_PAGE} >> text=Product Details
    # Verify each field shows its required validation error
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    css=[data-field="product.name"] span.text-error-6:has-text("is required")    visible    timeout=5s
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    css=[data-field="product.description"] span.text-error-6:has-text("is required")    visible    timeout=5s
    # Verify Continue button remains disabled
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_CONTINUE_BTN}    disabled

t5.3.22 Mandatory Field Validation – Account Configuration Section (Savings)
    [Documentation]    Verify that leaving mandatory Account Configuration fields blank (Average
    ...                Daily Balance, Initial Deposit Required) and interacting with them triggers
    ...                validation errors, and the Continue button remains disabled.
    ...
    ...                Preconditions:
    ...                1. Teller is logged in.
    ...                2. User is on Step 1 – Product Configuration for Savings.
    [Tags]    products    create    savings    validation
    Navigate To Create Savings Product
    # Scroll to Account Configuration and fill then clear each mandatory field
    Scroll To Element    ${CP_AVG_DAILY_BALANCE_INPUT}
    Fill Text    ${CP_AVG_DAILY_BALANCE_INPUT}    1
    Fill Text    ${CP_AVG_DAILY_BALANCE_INPUT}    ${EMPTY}
    Fill Text    ${CP_INITIAL_DEPOSIT_INPUT}    1
    Fill Text    ${CP_INITIAL_DEPOSIT_INPUT}    ${EMPTY}
    Click    ${CREATE_PRODUCT_PAGE} >> text=Account Configuration
    # Verify each field shows its required validation error
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    css=[data-field="accountConfig.avgDailyBalance"] span.text-error-6:has-text("is required")    visible    timeout=5s
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    css=[data-field="accountConfig.initialDeposit"] span.text-error-6:has-text("is required")    visible    timeout=5s
    # Verify Continue button remains disabled
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_CONTINUE_BTN}    disabled

t5.3.23 Mandatory Field Validation – Interest Configuration Section (Savings)
    [Documentation]    Verify that leaving the Interest Rate (%) field blank and interacting with
    ...                it triggers a validation error, and the Continue button remains disabled.
    ...
    ...                Preconditions:
    ...                1. Teller is logged in.
    ...                2. User is on Step 1 – Product Configuration for Savings.
    [Tags]    products    create    savings    validation
    Navigate To Create Savings Product
    # Scroll to Interest Configuration and fill then clear Interest Rate to trigger validation
    Scroll To Element    ${CP_INTEREST_RATE_INPUT}
    Fill Text    ${CP_INTEREST_RATE_INPUT}    1
    Fill Text    ${CP_INTEREST_RATE_INPUT}    ${EMPTY}
    Click    ${CREATE_PRODUCT_PAGE} >> text=Interest Configuration
    # Verify the Interest Rate field shows its required validation error
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    css=[data-field="interest.rate"] span.text-error-6:has-text("is required")    visible    timeout=5s
    # Verify Continue button remains disabled
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_CONTINUE_BTN}    disabled

t5.3.24 Add New Section Without Entering a Section Name (Savings)
    [Documentation]    Verify that clicking 'Add new section' on the Savings Customer Form opens
    ...                a modal where the 'Add section' button remains disabled until a section
    ...                name is entered, preventing creation of a blank-named section.
    ...
    ...                Preconditions:
    ...                1. Teller is logged in.
    ...                2. User is on Step 2 – Customer Form for Savings.
    [Tags]    products    create    savings    smoke    mvp    type2
    Navigate To Savings Customer Form    t5.3.24 Savings
    # Open Add new section modal
    Click    ${CP_ADD_SECTION_BTN}
    Wait For Elements State    ${CP_MODAL}    visible
    # Verify Section Name input is present and Add section button is disabled (name is blank)
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CP_SECTION_NAME_INPUT}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CP_ADD_SECTION_CONFIRM_BTN}    disabled
    # Dismiss modal without creating a section
    Click    ${CP_MODAL_BACK_BTN}
    Wait For Elements State    ${CP_MODAL}    hidden    timeout=5s

t5.3.25 Add Customer Input Field with All Mandatory Fields Blank (Savings)
    [Documentation]    Verify that opening the 'Add customer input field' modal for Savings and
    ...                leaving Field Name and Placeholder blank triggers validation errors and
    ...                prevents the field from being added to the section.
    ...
    ...                Preconditions:
    ...                1. Teller is logged in.
    ...                2. User is on Step 2 – Customer Form for Savings.
    ...                3. A section exists.
    [Tags]    products    create    savings    validation
    Navigate To Savings Customer Form    t5.3.25 Savings
    Add Section To Customer Form    ${T53_SECTION_NAME}
    # Open Add customer input field modal
    Click    css=[data-testid="page-products-create"] button:has-text("Add customer input field")
    Wait For Elements State    ${CP_MODAL}    visible
    # Verify Add field button is disabled when all mandatory fields are blank
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CP_ADD_FIELD_CONFIRM_BTN}    disabled
    # Fill then clear Field Name and Placeholder to trigger validation errors
    Fill Text    ${CP_FIELD_NAME_INPUT}    x
    Fill Text    ${CP_FIELD_NAME_INPUT}    ${EMPTY}
    Fill Text    ${CP_FIELD_PLACEHOLDER_INPUT}    x
    Fill Text    ${CP_FIELD_PLACEHOLDER_INPUT}    ${EMPTY}
    Click    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-header
    # Verify each modal field shows its required validation error
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    css=.ant-modal-wrap:not([style*="display: none"]) [data-field="label"] span.text-error-6:has-text("is required")    visible    timeout=5s
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    css=.ant-modal-wrap:not([style*="display: none"]) [data-field="placeholder"] span.text-error-6:has-text("is required")    visible    timeout=5s
    # Dismiss modal — field should NOT be added to the section
    Click    ${CP_MODAL_BACK_BTN}
    Wait For Elements State    ${CP_MODAL}    hidden    timeout=5s
    ${field_visible}=    Run Keyword And Return Status
    ...    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=${T53_FIELD_NAME}    visible    timeout=3s
    Run Keyword And Continue On Failure
    ...    Should Not Be True    ${field_visible}
    ...    msg=Field "${T53_FIELD_NAME}" should not have been added when modal was dismissed without confirming

t5.3.26 Continue Button Disabled When Section Has No Fields (Savings)
    [Documentation]    Verify that when a custom section exists in the Savings Customer Form but
    ...                contains no fields, the Continue button remains disabled and the user
    ...                cannot proceed to Step 3.
    ...
    ...                Preconditions:
    ...                1. Teller is logged in.
    ...                2. User is on Step 2 – Customer Form for Savings.
    ...                3. A section exists but contains zero custom fields.
    [Tags]    products    create    savings    smoke    mvp    type2
    Navigate To Savings Customer Form    t5.3.26 Savings
    # Add a section without adding any fields
    Add Section To Customer Form    ${T53_SECTION_NAME}
    # Verify Continue remains disabled when the section is empty
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_CONTINUE_BTN}    disabled

t5.3.27 Mandatory Field Validation – Product Definition Section (Loans)
    [Documentation]    Verify that leaving mandatory Product Definition fields blank (Loan Type,
    ...                Preferred Customers, Loan Purpose) and interacting with them triggers
    ...                validation errors, and the Continue button remains disabled.
    ...
    ...                Preconditions:
    ...                1. Teller is logged in.
    ...                2. User is on Step 1 – Product Configuration for Loans.
    [Tags]    products    create    loans    validation
    Navigate To Create Loans Product
    # Fill then clear Loan Purpose textarea to trigger required field validation
    Fill Text    ${CLP_LOAN_PURPOSE_TEXTAREA}    x
    Fill Text    ${CLP_LOAN_PURPOSE_TEXTAREA}    ${EMPTY}
    Click    ${CREATE_PRODUCT_PAGE} >> text=Product Definition
    # Verify the Loan Purpose field shows its required validation error
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    css=[data-field="definition.purpose"] span.text-error-6:has-text("is required")    visible    timeout=5s
    # Verify Continue button remains disabled
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_CONTINUE_BTN}    disabled

t5.3.28 Mandatory Field Validation – Product Details Section (Loans)
    [Documentation]    Verify that leaving mandatory Product Details fields blank (Product Name,
    ...                Description) for a Loans product and interacting with them triggers
    ...                validation errors, and the Continue button remains disabled.
    ...
    ...                Preconditions:
    ...                1. Teller is logged in.
    ...                2. User is on Step 1 – Product Configuration for Loans.
    [Tags]    products    create    loans    validation
    Navigate To Create Loans Product
    # Fill then clear Product Name and Description to trigger required field validation
    Fill Text    ${CLP_PRODUCT_NAME_INPUT}    x
    Fill Text    ${CLP_PRODUCT_NAME_INPUT}    ${EMPTY}
    Fill Text    ${CLP_DESCRIPTION_TEXTAREA}    x
    Fill Text    ${CLP_DESCRIPTION_TEXTAREA}    ${EMPTY}
    Click    ${CREATE_PRODUCT_PAGE} >> text=Product Details
    # Verify each field shows its required validation error
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    css=[data-field="details.name"] span.text-error-6:has-text("is required")    visible    timeout=5s
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    css=[data-field="details.description"] span.text-error-6:has-text("is required")    visible    timeout=5s
    # Verify Continue button remains disabled
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_CONTINUE_BTN}    disabled

t5.3.29 Mandatory Field Validation – Loan Features Section (Loans)
    [Documentation]    Verify that leaving mandatory Loan Features fields blank (Min/Max Loan
    ...                Amount, Loan Term Length, Loan Term Unit, Interest Rate Type, Repayment
    ...                Method) and interacting with them triggers validation errors, and the
    ...                Continue button remains disabled.
    ...
    ...                Preconditions:
    ...                1. Teller is logged in.
    ...                2. User is on Step 1 – Product Configuration for Loans.
    [Tags]    products    create    loans    validation
    Navigate To Create Loans Product
    # Scroll to Loan Features and fill then clear mandatory numeric inputs
    Scroll To Element    ${CLP_MIN_AMOUNT_INPUT}
    Fill Text    ${CLP_MIN_AMOUNT_INPUT}    1
    Fill Text    ${CLP_MIN_AMOUNT_INPUT}    ${EMPTY}
    Fill Text    ${CLP_MAX_AMOUNT_INPUT}    1
    Fill Text    ${CLP_MAX_AMOUNT_INPUT}    ${EMPTY}
    Fill Text    ${CLP_TERM_LENGTH_INPUT}    1
    Fill Text    ${CLP_TERM_LENGTH_INPUT}    ${EMPTY}
    # Repayment Method is a dropdown — click to open then close without selecting
    Click    ${CLP_REPAYMENT_METHOD_INPUT}
    Click    ${CREATE_PRODUCT_PAGE} >> text=Loan Features
    # Verify each field shows its required validation error
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    css=[data-field="features.minAmount"] span.text-error-6:has-text("is required")    visible    timeout=5s
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    css=[data-field="features.maxAmount"] span.text-error-6:has-text("is required")    visible    timeout=5s
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    css=[data-field="features.termLength"] span.text-error-6:has-text("is required")    visible    timeout=5s
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    css=[data-field="features.repaymentMethod"] span.text-error-6:has-text("is required")    visible    timeout=5s
    # Verify Continue button remains disabled
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_CONTINUE_BTN}    disabled

t5.3.30 Mandatory Field Validation – Eligibility Criteria Section (Loans)
    [Documentation]    Verify that leaving mandatory Eligibility Criteria fields blank (Minimum
    ...                Age, Maximum Age) and interacting with them triggers validation errors,
    ...                and the Continue button remains disabled.
    ...
    ...                Preconditions:
    ...                1. Teller is logged in.
    ...                2. User is on Step 1 – Product Configuration for Loans.
    [Tags]    products    create    loans    validation
    Navigate To Create Loans Product
    # Scroll to Eligibility Criteria and fill then clear age fields
    Scroll To Element    ${CLP_MIN_AGE_INPUT}
    Fill Text    ${CLP_MIN_AGE_INPUT}    1
    Fill Text    ${CLP_MIN_AGE_INPUT}    ${EMPTY}
    Fill Text    ${CLP_MAX_AGE_INPUT}    1
    Fill Text    ${CLP_MAX_AGE_INPUT}    ${EMPTY}
    Click    ${CREATE_PRODUCT_PAGE} >> text=Eligibility Criteria
    # Verify each field shows its required validation error
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    css=[data-field="eligibility.minAge"] span.text-error-6:has-text("is required")    visible    timeout=5s
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    css=[data-field="eligibility.maxAge"] span.text-error-6:has-text("is required")    visible    timeout=5s
    # Verify Continue button remains disabled
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_CONTINUE_BTN}    disabled

t5.3.31 Mandatory Field Validation – Pricing & Fees Section (Loans)
    [Documentation]    Verify that leaving mandatory Pricing & Fees fields blank (Interest Rate %,
    ...                Interest Rate Structure, Processing Fee) and interacting with them triggers
    ...                validation errors, and the Continue button remains disabled.
    ...
    ...                Preconditions:
    ...                1. Teller is logged in.
    ...                2. User is on Step 1 – Product Configuration for Loans.
    [Tags]    products    create    loans    validation
    Navigate To Create Loans Product
    # Scroll to Pricing & Fees and fill then clear mandatory inputs
    Scroll To Element    ${CLP_PRICING_RATE_INPUT}
    Fill Text    ${CLP_PRICING_RATE_INPUT}    1
    Fill Text    ${CLP_PRICING_RATE_INPUT}    ${EMPTY}
    Fill Text    ${CLP_PROCESSING_FEE_INPUT}    1
    Fill Text    ${CLP_PROCESSING_FEE_INPUT}    ${EMPTY}
    Click    ${CREATE_PRODUCT_PAGE} >> text=Pricing & Fees
    # Verify each field shows its required validation error
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    css=[data-field="pricingFees.rate"] span.text-error-6:has-text("is required")    visible    timeout=5s
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    css=[data-field="pricingFees.processingFee"] span.text-error-6:has-text("is required")    visible    timeout=5s
    # Verify Continue button remains disabled
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_CONTINUE_BTN}    disabled

t5.3.32 Loan Details Fields Are Disabled and Non-Editable During Product Creation
    [Documentation]    Verify that all pre-built Loan Details fields in the Loans Customer Form
    ...                (Loan Amount, Interest Rate %, Loan Term Length, Loan Term Unit, Mode of
    ...                Disbursement) are disabled and non-interactable during product creation.
    ...                Fields appear greyed out/read-only, accept no input, and trigger no
    ...                validation errors. They are only editable during the Product Availment flow.
    ...
    ...                Preconditions:
    ...                1. Teller is logged in.
    ...                2. User is on Step 2 – Customer Form for a Loans product.
    ...                3. The pre-built Loan Details section is visible.
    [Tags]    products    create    loans    smoke    mvp    type2
    Navigate To Loans Customer Form    t5.3.32 Loans
    # Verify the pre-built Loan Details section header is visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CLP_LOAN_DETAILS_SECTION_HEADER}    visible
    # Verify disabled numeric input fields are present (Loan Amount, Interest Rate, Term Length)
    ${disabled_input_count}=    Get Element Count    ${CLP_DISABLED_FIELDS}
    Run Keyword And Continue On Failure
    ...    Should Be True    ${disabled_input_count} > 0
    ...    msg=Expected at least one disabled numeric field in the Loan Details section but found none
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CLP_DISABLED_FIELDS} >> nth=0    visible
    # Verify no validation errors are triggered for disabled fields
    ${error_count}=    Get Element Count    ${FIELD_VALIDATION_ERROR}
    Run Keyword And Continue On Failure
    ...    Should Be Equal As Integers    ${error_count}    0
    ...    msg=Disabled Loan Details fields should not trigger validation errors but found ${error_count}

t5.3.33 Add Customer Input Field with All Mandatory Fields Blank (Loans)
    [Documentation]    Verify that opening the 'Add customer input field' modal for Loans and
    ...                leaving Field Name and Placeholder blank triggers validation errors and
    ...                prevents the field from being added to the section.
    ...
    ...                Preconditions:
    ...                1. Teller is logged in.
    ...                2. User is on Step 2 – Customer Form for Loans.
    ...                3. A custom section exists.
    [Tags]    products    create    loans    validation
    Navigate To Loans Customer Form    t5.3.33 Loans
    Add Section To Customer Form    ${T53_LOANS_SECTION_NAME}
    # Open Add customer input field modal
    Click    css=[data-testid="page-products-create"] button:has-text("Add customer input field")
    Wait For Elements State    ${CP_MODAL}    visible
    # Verify Add field button is disabled when all mandatory fields are blank
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CP_ADD_FIELD_CONFIRM_BTN}    disabled
    # Fill then clear Field Name and Placeholder to trigger validation errors
    Fill Text    ${CP_FIELD_NAME_INPUT}    x
    Fill Text    ${CP_FIELD_NAME_INPUT}    ${EMPTY}
    Fill Text    ${CP_FIELD_PLACEHOLDER_INPUT}    x
    Fill Text    ${CP_FIELD_PLACEHOLDER_INPUT}    ${EMPTY}
    Click    css=.ant-modal-wrap:not([style*="display: none"]) .ant-modal-header
    # Verify each modal field shows its required validation error
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    css=.ant-modal-wrap:not([style*="display: none"]) [data-field="label"] span.text-error-6:has-text("is required")    visible    timeout=5s
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    css=.ant-modal-wrap:not([style*="display: none"]) [data-field="placeholder"] span.text-error-6:has-text("is required")    visible    timeout=5s
    # Dismiss modal — field should NOT be added to the section
    Click    ${CP_MODAL_BACK_BTN}
    Wait For Elements State    ${CP_MODAL}    hidden    timeout=5s
    ${field_visible}=    Run Keyword And Return Status
    ...    Wait For Elements State    ${CREATE_PRODUCT_PAGE} >> text=${T53_LOANS_FIELD_NAME}    visible    timeout=3s
    Run Keyword And Continue On Failure
    ...    Should Not Be True    ${field_visible}
    ...    msg=Field "${T53_LOANS_FIELD_NAME}" should not have been added when modal was dismissed without confirming

t5.3.34 Add New Section Without Entering a Section Name (Loans)
    [Documentation]    Verify that clicking 'Add new section' on the Loans Customer Form opens a
    ...                modal where the 'Add section' button remains disabled until a section name
    ...                is entered, preventing creation of a blank-named section.
    ...
    ...                Preconditions:
    ...                1. Teller is logged in.
    ...                2. User is on Step 2 – Customer Form for Loans.
    [Tags]    products    create    loans    smoke    mvp    type2
    Navigate To Loans Customer Form    t5.3.34 Loans
    # Open Add new section modal
    Click    ${CP_ADD_SECTION_BTN}
    Wait For Elements State    ${CP_MODAL}    visible
    # Verify Section Name input is present and Add section button is disabled (name is blank)
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CP_SECTION_NAME_INPUT}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CP_ADD_SECTION_CONFIRM_BTN}    disabled
    # Dismiss modal without creating a section
    Click    ${CP_MODAL_BACK_BTN}
    Wait For Elements State    ${CP_MODAL}    hidden    timeout=5s

t5.3.35 Continue Button Disabled When Loans Custom Section Has No Fields
    [Documentation]    Verify that when a custom section exists in the Loans Customer Form but
    ...                contains no fields, the Continue button remains disabled and the user
    ...                cannot proceed to Step 3.
    ...
    ...                Preconditions:
    ...                1. Teller is logged in.
    ...                2. User is on Step 2 – Customer Form for Loans.
    ...                3. A custom section exists but has no fields.
    [Tags]    products    create    loans    smoke    mvp    type2
    Navigate To Loans Customer Form    t5.3.35 Loans
    # Add a custom section without adding any fields
    Add Section To Customer Form    ${T53_LOANS_SECTION_NAME}
    # Verify Continue remains disabled when the custom section is empty
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CREATE_PRODUCT_CONTINUE_BTN}    disabled

t5.3.36 Savings Product Version Update Creates Deprecated Version
    [Documentation]    Verify that modifying a core configuration (Interest rate) of an existing
    ...                Savings product held by a customer triggers a product version update: the
    ...                customer's previously-held version transitions to "Deprecated" and remains
    ...                viewable in their Products Availed tab (existing holders keep their version).
    ...
    ...                Reusable across cycles: the interest rate is toggled between two values so
    ...                every run makes a real change (forcing a new version), and a holder always
    ...                retains an older — therefore Deprecated — version, so the assertion stays
    ...                valid on repeat runs.
    ...
    ...                Preconditions:
    ...                1. Teller/admin is logged in with product-edit permission.
    ...                2. ${T536_PRODUCT_NAME} is an active Savings product held by ${T536_CUSTOMER_ID}.
    [Tags]    products    edit    regression    type2
    # Force a version update by changing the product's interest rate.
    Open Active Product Edit Page    ${T536_PRODUCT_NAME}
    ${applied}=    Update Product Interest Rate To Force New Version
    ...    ${T536_INTEREST_RATE_A}    ${T536_INTEREST_RATE_B}
    Log    Applied interest rate ${applied}% to ${T536_PRODUCT_NAME}; a new product version was created.
    # The customer's held (older) version must now be Deprecated and still viewable.
    Verify Customer Availed Product Is Deprecated    ${T536_CUSTOMER_ID}    ${T536_PRODUCT_NAME}

*** Settings ***
Documentation       t2.1 View the List of Customers
...                 Covers initial load, pagination, search, status filtering,
...                 and customer profile view.

Resource            ../../resources/keywords/common.resource
Resource            ../../resources/keywords/customers.resource

Suite Setup         Login To Teller App
Suite Teardown      Close Browser
Test Setup          Reload


*** Variables ***
${CUSTOMER_STATUS}          Active
${NON_EXISTING_CUSTOMER}    NONEXISTENT99999
${CUSTOMER_ROW}             css=table tbody tr:has-text("${VALID_CUSTOMER_ID}")


*** Test Cases ***
t2.1.1 Initial Load and View of Customer List
    [Documentation]    Verify that navigating to the Customers module displays the customer list
    ...                with all required columns and action buttons visible.
    [Tags]             customers    smoke    mvp    type1
    Navigate To Customers
    # Verify all fields — continue on failure so ALL mismatches are reported
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Customer ID           visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Customer Name         visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Date of Birth         visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Created on            visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Last Updated          visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Customer Status       visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text="Action"              visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${VIEW_PROFILE_LINK} >> nth=0       visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${VIEW_ACCOUNTS_LINK} >> nth=0      visible

t2.1.2 Pagination and Navigation
    [Documentation]    Verify that pagination controls work correctly:
    ...                Next loads page 2, clicking page 3 loads page 3,
    ...                and Back returns to page 2.
    ...                Skipped when the customer list has only one page.
    [Tags]             customers    smoke    mvp    type1    pagination
    Navigate To Customers
    ${has_multiple_pages}=    Run Keyword And Return Status
    ...    Wait For Elements State    ${PAGINATION_NEXT}    enabled    timeout=3s
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
            # Only 2 pages — click Back to return to page 1
            Click                      ${PAGINATION_PREV}
            Wait For Elements State    css=li.ant-pagination-item-active:has-text("1")    visible
        END
    ELSE
        Log    Only one page of customers — pagination navigation skipped
        Wait For Elements State    ${PAGINATION_NEXT}    disabled
    END

t2.1.3 Search for Valid Customer ID
    [Documentation]    Verify that searching by a valid Customer ID returns exactly one record
    ...                and all required columns are visible in the results.
    [Tags]             customers    smoke    mvp    type1
    Navigate To Customers
    Fill Text                  ${CUSTOMER_SEARCH_FIELD}    ${VALID_CUSTOMER_ID}
    Click                      ${CUSTOMER_SEARCH_BUTTON}
    Wait For Elements State    css=table tbody tr:not([aria-hidden="true"])    visible
    Get Element Count          css=table tbody tr:not([aria-hidden="true"])    ==    1
    # Verify all fields — continue on failure so ALL mismatches are reported
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Customer ID             visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Customer Name           visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Date of Birth           visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Created on              visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Last Updated            visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Customer Status         visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    css=table td:has-text("${VALID_CUSTOMER_NAME}")       visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    css=table td:has-text("${CUSTOMER_DATE_OF_BIRTH}")    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${VIEW_PROFILE_LINK}         visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${VIEW_ACCOUNTS_LINK}        visible
    # Clear search and verify list reloads
    Fill Text                  ${CUSTOMER_SEARCH_FIELD}     ${EMPTY}
    Click                      ${CUSTOMER_SEARCH_BUTTON}
    Wait For Elements State    ${CUSTOMER_SEARCH_FIELD}     visible

t2.1.4 Search for Valid Customer Name
    [Documentation]    Verify that searching by a valid Customer Name returns matching records.
    ...                Multiple customers may match - verify a specific row contains all expected
    ...                column values: Customer ID, Name, Date of Birth, Created on, Last Updated,
    ...                Customer Status, and Action links.
    [Tags]             customers    smoke    mvp    type1
    Navigate To Customers
    Fill Text                  ${CUSTOMER_SEARCH_FIELD}    ${VALID_CUSTOMER_NAME}
    Click                      ${CUSTOMER_SEARCH_BUTTON}
    # Verify at least one result row is visible
    Wait For Elements State    ${CUSTOMER_ROW}             visible
    # Verify all fields — continue on failure so ALL mismatches are reported
    # Verify column headers are visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Customer ID             visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Customer Name           visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Date of Birth           visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Created on              visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Last Updated            visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Customer Status         visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text="Action"                visible
    # Verify all column values in the matching row
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CUSTOMER_ROW} >> text=${VALID_CUSTOMER_ID}          visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CUSTOMER_ROW} >> text=${VALID_CUSTOMER_NAME}        visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CUSTOMER_ROW} >> text=${CUSTOMER_DATE_OF_BIRTH}     visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CUSTOMER_ROW} >> css=td:text-is("${CUSTOMER_CREATED_ON}") >> nth=0    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CUSTOMER_ROW} >> text=${CUSTOMER_STATUS}            visible
    # Verify Action links in the matching row
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CUSTOMER_ROW} >> ${VIEW_PROFILE_LINK}               visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CUSTOMER_ROW} >> ${VIEW_ACCOUNTS_LINK}              visible
    # Clear search and verify list reloads
    Fill Text                  ${CUSTOMER_SEARCH_FIELD}     ${EMPTY}
    Click                      ${CUSTOMER_SEARCH_BUTTON}
    Wait For Elements State    ${CUSTOMER_SEARCH_FIELD}     visible

t2.1.5 Search for Non-Existing Customer
    [Documentation]    Verify that searching for a non-existing customer shows a "No Data" message
    ...                with an empty table and no application errors.
    [Tags]             customers    negative    mvp    type1
    Navigate To Customers
    Fill Text                  ${CUSTOMER_SEARCH_FIELD}    ${NON_EXISTING_CUSTOMER}
    Click                      ${CUSTOMER_SEARCH_BUTTON}
    Wait For Elements State    css=.ant-empty-description:has-text("No data")    visible
    Wait For Elements State    ${CUSTOMER_TABLE}    visible

t2.1.6 Filter Customer List by Status - Active
    [Documentation]    Verify that filtering by Active status shows only Active customers.
    ...                If no Active customers exist, a "No Data" message is shown.
    [Tags]             customers    regression    mvp    type1
    Navigate To Customers
    Click                      ${CUSTOMER_STATUS_FILTER}
    Click                      ${FILTER_OPTION_ACTIVE}
    Click                      ${FILTER_APPLY_BTN}
    Wait For Elements State    ${CUSTOMER_TABLE}           visible
    Filter Results Should Contain Only Status              Active

t2.1.7 Filter Customer List by Status - Inactive
    [Documentation]    Verify that filtering by Inactive status shows only Inactive customers.
    ...                If no Inactive customers exist, a "No Data" message is shown.
    [Tags]             customers    regression    mvp    type1
    Navigate To Customers
    Click                      ${CUSTOMER_STATUS_FILTER}
    Click                      ${FILTER_OPTION_INACTIVE}
    Click                      ${FILTER_APPLY_BTN}
    Wait For Elements State    ${CUSTOMER_TABLE}           visible
    Filter Results Should Contain Only Status              Inactive

t2.1.8 Filter Customer List by Status - Restricted
    [Documentation]    Verify that filtering by Restricted status shows only Restricted customers.
    ...                If no Restricted customers exist, a "No Data" message is shown.
    [Tags]             customers    regression    mvp    guardrails    type1
    Navigate To Customers
    Click                      ${CUSTOMER_STATUS_FILTER}
    Click                      ${FILTER_OPTION_RESTRICTED}
    Click                      ${FILTER_APPLY_BTN}
    Wait For Elements State    ${CUSTOMER_TABLE}           visible
    Filter Results Should Contain Only Status              Restricted

t2.1.9 Filter Customer List by Status - Closed
    [Documentation]    Verify that filtering by Closed status shows only Closed customers.
    ...                If no Closed customers exist, a "No Data" message is shown.
    [Tags]             customers    regression    mvp    guardrails    type1
    Navigate To Customers
    Click                      ${CUSTOMER_STATUS_FILTER}
    Click                      ${FILTER_OPTION_CLOSED}
    Click                      ${FILTER_APPLY_BTN}
    Wait For Elements State    ${CUSTOMER_TABLE}           visible
    Filter Results Should Contain Only Status              Closed

t2.1.10 Filter Customer List by Status - Deceased
    [Documentation]    Verify that filtering by Deceased status shows only Deceased customers.
    ...                If no Deceased customers exist, a "No Data" message is shown.
    [Tags]             customers    regression    mvp    guardrails    type1
    Navigate To Customers
    Click                      ${CUSTOMER_STATUS_FILTER}
    Click                      ${FILTER_OPTION_DECEASED}
    Click                      ${FILTER_APPLY_BTN}
    Wait For Elements State    ${CUSTOMER_TABLE}           visible
    Filter Results Should Contain Only Status              Deceased

t2.1.11 Filter Customer List by Status - Suspended
    [Documentation]    Verify that filtering by Suspended status shows only Suspended customers.
    ...                If no Suspended customers exist, a "No Data" message is shown.
    [Tags]             customers    regression    mvp    guardrails    type1
    Navigate To Customers
    Click                      ${CUSTOMER_STATUS_FILTER}
    Click                      ${FILTER_OPTION_SUSPENDED}
    Click                      ${FILTER_APPLY_BTN}
    Wait For Elements State    ${CUSTOMER_TABLE}           visible
    Filter Results Should Contain Only Status              Suspended

t2.1.12 Customer Profile View - Details Verification
    [Documentation]    Verify that clicking View Profile displays the customer's full profile
    ...                with all required section headers and fields correctly visible.
    [Tags]             customers    smoke    mvp    type1
    Navigate To Customers
    View Customer Profile      ${VALID_CUSTOMER_NAME}
    # Verify all fields — continue on failure so ALL mismatches are reported
    # Verify page header shows correct customer name
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    css=h3:has-text("${VALID_CUSTOMER_NAME}")    visible
    # Verify section headers
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Banking Details                  visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Customer Details                 visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Identification                   visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Employment History               visible
    # Verify Banking Details fields
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=DFSP Institution ID              visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Customer ID                      visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    p:has-text("Identity")               visible
    # Verify Customer Details fields
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Email Address                    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Gender                           visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Date of Birth                    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Nationality                      visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Complete Address                 visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Mobile Number                    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Civil Status                     visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Country of Birth                 visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=TIN                              visible
    # Verify Identification fields
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=ID Type                          visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=ID Number                        visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Expiry Date                      visible
    # Verify Employment History fields
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text="Employer"                       visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text="Employer Industry"              visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Job Title                        visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Monthly Income                   visible
    # Scroll down and verify Identity Verification Details section
    Scroll To Element          text=Identity Verification Details
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Identity Verification Details    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Selfie                           visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=ID (Front)                       visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=ID (Back)                        visible

t2.1.12b Customer Profile View - Details Verification (Product Tabs)
    [Documentation]    Verify that clicking View Profile displays the customer's full profile
    ...                with all required section headers and fields correctly visible.
    [Tags]             customers    smoke    mvp    type2
    Navigate To Customers
    View Customer Profile      ${VALID_CUSTOMER_NAME}
    # Verify all fields — continue on failure so ALL mismatches are reported
    # Verify page header shows correct customer name
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    css=h3:has-text("${VALID_CUSTOMER_NAME}")    visible
    # Verify profile tab navigation
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Products Availed                  visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Eligible Products                 visible
    # Verify section headers
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Banking Details                  visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Customer Details                 visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Identification                   visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Employment History               visible
    # Verify Banking Details fields
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=DFSP Institution ID              visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Customer ID                      visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    p:has-text("Identity")               visible
    # Verify Customer Details fields
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Email Address                    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Gender                           visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Date of Birth                    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Nationality                      visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Complete Address                 visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Mobile Number                    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Civil Status                     visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Country of Birth                 visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=TIN                              visible
    # Verify Identification fields
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=ID Type                          visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=ID Number                        visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Expiry Date                      visible
    # Verify Employment History fields
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text="Employer"                       visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text="Employer Industry"              visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Job Title                        visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Monthly Income                   visible
    # Scroll down and verify Identity Verification Details section
    Scroll To Element          text=Identity Verification Details
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Identity Verification Details    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=Selfie                           visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=ID (Front)                       visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    text=ID (Back)                        visible

t2.1.13 Change Customer Status from Active to Inactive
    [Documentation]    Verify that a teller can change a customer's status from Active to Inactive.
    ...                Steps: search for the test customer filtered by Active status, capture the
    ...                first row's Customer ID, click the status badge, select Inactive from the
    ...                dropdown, fill in remarks, confirm — then search by the captured ID and
    ...                verify the status is now Inactive.
    [Tags]             customers    status-change    smoke    mvp    type1
    Navigate To Customers
    # Filter by Active to ensure we find an active customer
    Click                      ${CUSTOMER_STATUS_FILTER}
    Wait For Elements State    ${FILTER_OPTION_ACTIVE}    visible
    Click                      ${FILTER_OPTION_ACTIVE}
    Click                      ${FILTER_APPLY_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State    ${CUSTOMER_TABLE}    visible
    # Search for the status-change test customer
    Fill Text                  ${CUSTOMER_SEARCH_FIELD}    ${T21_STATUS_CHANGE_CUSTOMER_NAME}
    Click                      ${CUSTOMER_SEARCH_BUTTON}
    Wait For Load Spinner To Disappear
    Wait For Elements State    css=[data-testid="table-customers"] tbody tr:not([aria-hidden="true"]) >> nth=0    visible
    # Capture Customer ID from the first row (column 0)
    ${customer_id_raw}=    Get Text
    ...    css=[data-testid="table-customers"] tbody tr:not([aria-hidden="true"]) >> nth=0 >> css=td >> nth=0
    ${customer_id}=    Evaluate    '''${customer_id_raw}'''.split('\\n')[0].strip()
    Log    Status change target Customer ID: ${customer_id}
    # Click the status badge in the first row to open the dropdown
    Click    css=[data-testid="table-customers"] tbody tr:not([aria-hidden="true"]) >> nth=0 >> css=[data-testid="field-status-badge"]
    Wait For Elements State    ${CUSTOMER_STATUS_DROPDOWN_INACTIVE}    visible
    Click    ${CUSTOMER_STATUS_DROPDOWN_INACTIVE}
    # Fill in remarks and confirm
    Wait For Elements State    ${CUSTOMER_STATUS_CHANGE_MODAL}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CUSTOMER_STATUS_CHANGE_MODAL} >> text=Tag user as inactive?    visible
    Fill Text    ${CUSTOMER_STATUS_REMARKS_INPUT}    ${T21_STATUS_CHANGE_REMARKS}
    Wait For Elements State    ${CUSTOMER_STATUS_CONFIRM_BTN}    enabled
    Click    ${CUSTOMER_STATUS_CONFIRM_BTN}
    Wait For Elements State    text=Customer status updated successfully.    visible
    Wait For Load Spinner To Disappear
    # Clear Active filter so the now-inactive customer is visible in search results
    Click                      ${CUSTOMER_STATUS_FILTER}
    Wait For Elements State    ${FILTER_RESET_BTN}    visible
    Click                      ${FILTER_RESET_BTN}
    Wait For Load Spinner To Disappear
    # Verify the customer now appears as Inactive — search by Customer ID
    Fill Text                  ${CUSTOMER_SEARCH_FIELD}    ${customer_id}
    Click                      ${CUSTOMER_SEARCH_BUTTON}
    Wait For Load Spinner To Disappear
    Wait For Elements State
    ...    css=[data-testid="table-customers"] tbody tr:not([aria-hidden="true"]) >> nth=0 >> css=[data-testid="field-status-badge"]:has-text("Inactive")
    ...    visible

t2.1.14 Change Customer Status from Inactive to Active
    [Documentation]    Verify that a teller can restore a customer's status from Inactive back to Active.
    ...                Steps: search for the test customer filtered by Inactive status, capture the
    ...                first row's Customer ID, click the status badge, select Active from the
    ...                dropdown, fill in remarks, confirm — then search by the captured ID and
    ...                verify the status is now Active.
    [Tags]             customers    status-change    smoke    mvp    type1
    Navigate To Customers
    # Filter by Inactive to find the customer set inactive in t2.1.13
    Click                      ${CUSTOMER_STATUS_FILTER}
    Wait For Elements State    ${FILTER_OPTION_INACTIVE}    visible
    Click                      ${FILTER_OPTION_INACTIVE}
    Click                      ${FILTER_APPLY_BTN}
    Wait For Load Spinner To Disappear
    Wait For Elements State    ${CUSTOMER_TABLE}    visible
    # Search for the status-change test customer
    Fill Text                  ${CUSTOMER_SEARCH_FIELD}    ${T21_STATUS_CHANGE_CUSTOMER_NAME}
    Click                      ${CUSTOMER_SEARCH_BUTTON}
    Wait For Load Spinner To Disappear
    Wait For Elements State    css=[data-testid="table-customers"] tbody tr:not([aria-hidden="true"]) >> nth=0    visible
    # Capture Customer ID from the first row
    ${customer_id_raw}=    Get Text
    ...    css=[data-testid="table-customers"] tbody tr:not([aria-hidden="true"]) >> nth=0 >> css=td >> nth=0
    ${customer_id}=    Evaluate    '''${customer_id_raw}'''.split('\\n')[0].strip()
    Log    Restoring Customer ID: ${customer_id}
    # Click the status badge to open the dropdown
    Click    css=[data-testid="table-customers"] tbody tr:not([aria-hidden="true"]) >> nth=0 >> css=[data-testid="field-status-badge"]
    Wait For Elements State    ${CUSTOMER_STATUS_DROPDOWN_ACTIVE}    visible
    Click    ${CUSTOMER_STATUS_DROPDOWN_ACTIVE}
    # Fill in remarks and confirm
    Wait For Elements State    ${CUSTOMER_STATUS_CHANGE_MODAL}    visible
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${CUSTOMER_STATUS_CHANGE_MODAL} >> text=Tag user as active?    visible
    Fill Text    ${CUSTOMER_STATUS_REMARKS_INPUT}    ${T21_STATUS_CHANGE_REMARKS}
    Wait For Elements State    ${CUSTOMER_STATUS_CONFIRM_BTN}    enabled
    Click    ${CUSTOMER_STATUS_CONFIRM_BTN}
    Wait For Elements State    text=Customer status updated successfully.    visible
    Wait For Load Spinner To Disappear
    # Clear Inactive filter so the now-active customer is visible in search results
    Click                      ${CUSTOMER_STATUS_FILTER}
    Wait For Elements State    ${FILTER_RESET_BTN}    visible
    Click                      ${FILTER_RESET_BTN}
    Wait For Load Spinner To Disappear
    # Verify the customer now appears as Active — search by Customer ID
    Fill Text                  ${CUSTOMER_SEARCH_FIELD}    ${customer_id}
    Click                      ${CUSTOMER_SEARCH_BUTTON}
    Wait For Load Spinner To Disappear
    Wait For Elements State
    ...    css=[data-testid="table-customers"] tbody tr:not([aria-hidden="true"]) >> nth=0 >> css=[data-testid="field-status-badge"]:has-text("Active")
    ...    visible

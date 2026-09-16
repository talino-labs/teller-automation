*** Settings ***
Library     Browser
Resource    common.resource
Resource    ../locators/customers_locators.resource


*** Keywords ***
Navigate To Customers
    [Documentation]    Navigates to the Customers module via the sidebar.
    ...                Paces between tests to stay under the backend request rate limit
    ...                (bursts of ~13 requests return HTTP 429 for ~1 hour). The sidebar click
    ...                already loads the list, so we don't reload (that doubled the requests).
    Sleep                      12s
    Click                      ${CUSTOMERS_MENU}
    Wait For Elements State    ${CUSTOMER_SEARCH_FIELD}    visible
    Get Url                    contains    /customers
    Wait For Load Spinner To Disappear

View Customer List
    [Documentation]    Verifies the customer list page is loaded and visible
    Wait For Elements State    ${CUSTOMER_TABLE}    visible

Search For Customer
    [Documentation]    Searches for a customer by name or Customer ID
    [Arguments]        ${search_value}
    Fill Text          ${CUSTOMER_SEARCH_FIELD}    ${search_value}
    Click              ${CUSTOMER_SEARCH_BUTTON}
    Wait For Load Spinner To Disappear
    Wait For Elements State    ${CUSTOMER_TABLE}    visible

Clear Customer Search
    [Documentation]    Clears the customer search field and reloads the full list
    Fill Text          ${CUSTOMER_SEARCH_FIELD}    ${EMPTY}
    Click              ${CUSTOMER_SEARCH_BUTTON}
    Wait For Elements State    ${CUSTOMER_TABLE}    visible

Reset Customer Status Filter
    [Documentation]    Resets any applied customer status filter
    ${filter_active}=    Run Keyword And Return Status
    ...                  Wait For Elements State    css=span.ant-table-filter-trigger.active    visible    timeout=1s
    IF    ${filter_active}
        Click                      ${CUSTOMER_STATUS_FILTER}
        Wait For Elements State    ${FILTER_RESET_BTN}    visible
        Click                      ${FILTER_RESET_BTN}
        Sleep    0.5s
    END

View Customer Profile
    [Documentation]    Clicks View Profile for a specific customer row matching the given name.
    ...                Searches for the customer first to ensure visibility regardless of filter state.
    [Arguments]        ${customer_name}
    Search For Customer    ${customer_name}
    Click              css=tr:has-text("${customer_name}") >> ${VIEW_PROFILE_LINK} >> nth=0
    Wait For Elements State    text=Banking Details    visible

View Customer Accounts
    [Documentation]    Clicks View Accounts for a specific customer row matching the given name.
    ...                Searches for the customer first to ensure visibility regardless of filter state.
    [Arguments]        ${customer_name}
    Search For Customer    ${customer_name}
    Click              css=tr:has-text("${customer_name}") >> ${VIEW_ACCOUNTS_LINK} >> nth=0
    Wait For Elements State    ${ACCOUNT_SEARCH_FIELD}    visible

View Customer Account Transactions
    [Documentation]    Clicks View Account Transactions for a specific account row
    [Arguments]        ${account_number}
    Fill Text          ${ACCOUNT_SEARCH_FIELD}    ${account_number}
    Click              ${ACCOUNT_SEARCH_BUTTON}
    Wait For Load Spinner To Disappear
    Click              css=tr:has-text("${account_number}") >> ${VIEW_ACCOUNT_TRANSACTIONS_LINK}
    Wait For Elements State    ${TRANSACTION_SEARCH_FIELD}    visible

Navigate To Customer Account Transactions Page
    [Documentation]    Navigates to the Account Transactions page for the target account
    ...                via Customers → View Accounts → View Account Transactions
    [Arguments]        ${customer_name}    ${account_number}
    Navigate To Customers
    View Customer Accounts              ${customer_name}
    View Customer Account Transactions  ${account_number}
    Wait For Load Spinner To Disappear

Filter Account Results Should Contain Only Status
    [Documentation]    Verifies that all visible rows in the customer accounts table match the expected
    ...                status, or that a "No Data" message is shown if no matching records exist.
    ...                Iterates through all pagination pages to verify each page (max 10 rows per page).
    [Arguments]        ${expected_status}
    Sleep    1s    # Wait for filter to apply
    ${no_data_visible}=    Run Keyword And Return Status
    ...                    Wait For Elements State    css=.ant-empty-description    visible    timeout=3s
    IF    ${no_data_visible}
        Log    No data found for status: ${expected_status}
    ELSE
        ${page}=    Set Variable    1
        WHILE    ${page} <= 100    # Safety limit to prevent infinite loop
            ${total_rows}=      Get Element Count    css=.ant-table-body table tbody tr:not([aria-hidden="true"]):not(:empty)
            ${matching_rows}=   Get Element Count    css=.ant-table-body table tbody tr:not([aria-hidden="true"]):has-text("${expected_status}")
            Should Be Equal    ${total_rows}    ${matching_rows}
            ...    Page ${page}: Expected all ${total_rows} rows to have status "${expected_status}", but only ${matching_rows} matched
            Log    Page ${page}: All ${total_rows} rows contain status "${expected_status}"
            ${next_disabled}=    Run Keyword And Return Status
            ...                  Wait For Elements State    css=.ant-pagination-next.ant-pagination-disabled    visible    timeout=1s
            IF    ${next_disabled}
                Log    Reached last page (page ${page})
                BREAK
            END
            Click    css=.ant-pagination-next button
            Sleep    0.5s    # Wait for page to load
            ${page}=    Evaluate    ${page} + 1
        END
    END

Navigate To Customer Accounts Page
    [Documentation]    Navigates to the View Accounts page for the target customer
    [Arguments]        ${customer_name}
    Navigate To Customers
    View Customer Accounts    ${customer_name}

Filter Results Should Contain Only Status
    [Documentation]    Verifies that all visible rows across all pages match the expected status,
    ...                or that a "No Data" message is shown if no matching records exist.
    ...                Iterates through all pagination pages to verify each page (max 10 rows per page).
    [Arguments]        ${expected_status}
    Sleep    1s    # Wait for filter to apply
    ${no_data_visible}=    Run Keyword And Return Status
    ...                    Wait For Elements State    css=.ant-empty-description    visible    timeout=3s
    IF    ${no_data_visible}
        Log    No data found for status: ${expected_status}
    ELSE
        ${page}=    Set Variable    1
        WHILE    ${page} <= 100    # Safety limit to prevent infinite loop
            # Wait out any loading spinner before reading rows / clicking pagination —
            # the ant-spin blur overlay intercepts pointer events and detaches rows mid-click.
            Wait For Load Spinner To Disappear
            # After a Next click the table briefly shows AntD's empty-state placeholder row;
            # wait for a real data row (.ant-table-row) to settle so we don't read it.
            ${has_rows}=    Run Keyword And Return Status
            ...    Wait For Elements State    css=.ant-table-body table tbody tr.ant-table-row >> nth=0    visible    timeout=15s
            IF    not ${has_rows}
                Wait For Elements State    css=.ant-empty-description    visible    timeout=3s
                Log    Page ${page}: No data on this page — ending pagination.
                BREAK
            END
            # Count only real AntD data rows; the placeholder row is excluded by the class.
            ${total_rows}=      Get Element Count    css=.ant-table-body table tbody tr.ant-table-row
            ${matching_rows}=   Get Element Count    css=.ant-table-body table tbody tr.ant-table-row:has-text("${expected_status}")
            Should Be Equal    ${total_rows}    ${matching_rows}
            ...    Page ${page}: Expected all ${total_rows} rows to have status "${expected_status}", but only ${matching_rows} matched
            Log    Page ${page}: All ${total_rows} rows contain status "${expected_status}"
            # Check if next page button is disabled (last page)
            ${next_disabled}=    Run Keyword And Return Status
            ...                  Wait For Elements State    css=.ant-pagination-next.ant-pagination-disabled    visible    timeout=1s
            IF    ${next_disabled}
                Log    Reached last page (page ${page})
                BREAK
            END
            Click    css=.ant-pagination-next button
            Wait For Load Spinner To Disappear    # Wait for the next page to finish loading
            ${page}=    Evaluate    ${page} + 1
        END
    END

Filter Txn Results Should Contain Only Type
    [Documentation]    Verifies that all visible transaction rows match the expected type.
    ...                If data exists, also clicks the first row's Eye icon and verifies
    ...                the detail modal contains all required field labels, then closes it.
    ...                If no data, verifies the "No Data" message.
    [Arguments]        ${expected_type}
    Wait For Load Spinner To Disappear
    Sleep    1s    # Wait for filter to apply
    ${no_data_visible}=    Run Keyword And Return Status
    ...                    Wait For Elements State    css=.ant-empty-description    visible    timeout=3s
    IF    ${no_data_visible}
        Log    No data found for type: ${expected_type}
    ELSE
        ${total_rows}=      Get Element Count    css=.ant-table-body table tbody tr:not([aria-hidden="true"]):not(:empty)
        ${matching_rows}=   Get Element Count    css=.ant-table-body table tbody tr:not([aria-hidden="true"]):has-text("${expected_type}")
        Should Be Equal    ${total_rows}    ${matching_rows}
        ...    Expected all ${total_rows} rows to have type "${expected_type}", but only ${matching_rows} matched
        Log    All ${total_rows} rows contain type "${expected_type}"
        # Wait for spinner and open first row detail modal
        Wait For Load Spinner To Disappear
        Click    ${VIEW_TXN_BTN} >> nth=0
        Wait For Elements State    ${TXN_DETAIL_MODAL}              visible
        Wait For Elements State    ${TXN_DETAIL_MODAL} >> text=Transaction ID         visible
        Wait For Elements State    ${TXN_DETAIL_MODAL} >> text=Transaction Type       visible
        Wait For Elements State    ${TXN_DETAIL_MODAL} >> text=Transaction Amount     visible
        Wait For Elements State    ${TXN_DETAIL_MODAL} >> text=Service Fee            visible
        Wait For Elements State    ${TXN_DETAIL_MODAL} >> text=Remarks                visible
        Wait For Elements State    ${TXN_DETAIL_MODAL} >> text=Transaction Status     visible
        Wait For Elements State    ${TXN_DETAIL_MODAL} >> text=Debit Account Name     visible
        Wait For Elements State    ${TXN_DETAIL_MODAL} >> text=Credit Account Name    visible
        Wait For Elements State    ${TXN_DETAIL_MODAL} >> text=Debit Account Number   visible
        Wait For Elements State    ${TXN_DETAIL_MODAL} >> text=Credit Account Number  visible
        Wait For Elements State    ${TXN_DETAIL_MODAL} >> text=Created on             visible
        Wait For Elements State    ${TXN_DETAIL_MODAL} >> text=Updated on             visible
        Click    ${TXN_DETAIL_BACK_BTN}
        Wait For Elements State    ${TXN_DETAIL_MODAL}              hidden
    END

Filter Txn Results Should Contain Only Status
    [Documentation]    Verifies that all visible transaction rows match the expected status.
    ...                If data exists, also clicks the first row's Eye icon and verifies
    ...                the detail modal contains all required field labels, then closes it.
    ...                If no data, verifies the "No Data" message.
    [Arguments]        ${expected_status}
    Wait For Load Spinner To Disappear
    Sleep    1s    # Wait for filter to apply
    ${no_data_visible}=    Run Keyword And Return Status
    ...                    Wait For Elements State    css=.ant-empty-description    visible    timeout=3s
    IF    ${no_data_visible}
        Log    No data found for status: ${expected_status}
    ELSE
        ${total_rows}=      Get Element Count    css=.ant-table-body table tbody tr:not([aria-hidden="true"]):not(:empty)
        ${matching_rows}=   Get Element Count    css=.ant-table-body table tbody tr:not([aria-hidden="true"]):has-text("${expected_status}")
        Should Be Equal    ${total_rows}    ${matching_rows}
        ...    Expected all ${total_rows} rows to have status "${expected_status}", but only ${matching_rows} matched
        Log    All ${total_rows} rows contain status "${expected_status}"
        # Wait for spinner and open first row detail modal
        Wait For Load Spinner To Disappear
        Click    ${VIEW_TXN_BTN} >> nth=0
        Wait For Elements State    ${TXN_DETAIL_MODAL}              visible
        Wait For Elements State    ${TXN_DETAIL_MODAL} >> text=Transaction ID         visible
        Wait For Elements State    ${TXN_DETAIL_MODAL} >> text=Transaction Type       visible
        Wait For Elements State    ${TXN_DETAIL_MODAL} >> text=Transaction Amount     visible
        Wait For Elements State    ${TXN_DETAIL_MODAL} >> text=Service Fee            visible
        Wait For Elements State    ${TXN_DETAIL_MODAL} >> text=Remarks                visible
        Wait For Elements State    ${TXN_DETAIL_MODAL} >> text=Transaction Status     visible
        Wait For Elements State    ${TXN_DETAIL_MODAL} >> text=Debit Account Name     visible
        Wait For Elements State    ${TXN_DETAIL_MODAL} >> text=Credit Account Name    visible
        Wait For Elements State    ${TXN_DETAIL_MODAL} >> text=Debit Account Number   visible
        Wait For Elements State    ${TXN_DETAIL_MODAL} >> text=Credit Account Number  visible
        Wait For Elements State    ${TXN_DETAIL_MODAL} >> text=Created on             visible
        Wait For Elements State    ${TXN_DETAIL_MODAL} >> text=Updated on             visible
        Click    ${TXN_DETAIL_BACK_BTN}
        Wait For Elements State    ${TXN_DETAIL_MODAL}              hidden
    END

Verify Txn Dates Within Range
    [Documentation]    Verifies that all visible transaction dates in the Date & Time column
    ...                fall within the specified date range.
    ...                Handles the "DD Mon YYYY\nHH:MM:SS" format displayed in the table.
    [Arguments]        ${date_from}    ${date_to}    ${table_selector}=.ant-table-body table
    ${result}=    Evaluate JavaScript    ${None}
    ...    () => {
    ...        const months = {Jan:0,Feb:1,Mar:2,Apr:3,May:4,Jun:5,Jul:6,Aug:7,Sep:8,Oct:9,Nov:10,Dec:11};
    ...        const parseBoundaryDate = (str) => {
    ...            const p = str.split('-');
    ...            return new Date(parseInt(p[0]), parseInt(p[1]) - 1, parseInt(p[2]));
    ...        };
    ...        const parseTableDate = (str) => {
    ...            const parts = str.split(' ');
    ...            if (parts.length < 3) return new Date(NaN);
    ...            const day = parseInt(parts[0]);
    ...            const mon = parts[1];
    ...            const yearPart = parts[2].split(String.fromCharCode(10))[0];
    ...            const year = parseInt(yearPart);
    ...            if (isNaN(day) || isNaN(year) || !months.hasOwnProperty(mon)) return new Date(NaN);
    ...            return new Date(year, months[mon], day);
    ...        };
    ...        const dateFrom = parseBoundaryDate('${date_from}');
    ...        const dateTo = parseBoundaryDate('${date_to}');
    ...        dateTo.setHours(23, 59, 59, 999);
    ...        const rows = document.querySelectorAll('${table_selector} tbody tr:not([aria-hidden="true"])');
    ...        let total = 0;
    ...        let withinRange = 0;
    ...        let outOfRange = [];
    ...        rows.forEach(row => {
    ...            const cells = row.querySelectorAll('td');
    ...            if (cells.length >= 3) {
    ...                const dateText = cells[2].innerText.trim();
    ...                if (dateText) {
    ...                    total++;
    ...                    const rowDate = parseTableDate(dateText);
    ...                    if (rowDate >= dateFrom && rowDate <= dateTo) {
    ...                        withinRange++;
    ...                    } else {
    ...                        outOfRange.push(dateText);
    ...                    }
    ...                }
    ...            }
    ...        });
    ...        return { total, withinRange, outOfRange };
    ...    }
    Should Be Equal    ${result}[total]    ${result}[withinRange]
    ...    msg=Expected all ${result}[total] transactions to be within date range ${date_from} to ${date_to}, but found ${result}[outOfRange] outside range

Select Date Range From AntD Picker
    [Documentation]    Selects a date range from the AntD dual-panel RangePicker.
    ...                Opens the picker ONCE via the Start Date input and clicks both start
    ...                and end dates without reopening. Expects dates in YYYY-MM-DD format.
    ...                Reads .ant-picker-month-btn and .ant-picker-year-btn separately to
    ...                avoid Get Text concatenating them without a space (e.g. "Feb2026").
    [Arguments]    ${date_from}    ${date_to}
    ${day_from}=      Evaluate    str(int('${date_from}'.split('-')[2]))
    ${day_to}=        Evaluate    str(int('${date_to}'.split('-')[2]))
    ${month_from}=    Evaluate    __import__('datetime').datetime(int('${date_from}'.split('-')[0]), int('${date_from}'.split('-')[1]), 1).strftime('%b %Y')
    ${month_to}=      Evaluate    __import__('datetime').datetime(int('${date_to}'.split('-')[0]), int('${date_to}'.split('-')[1]), 1).strftime('%b %Y')
    # Open the range picker by clicking Start Date input only once
    Click    ${DATE_START_INPUT}
    Sleep    0.5s
    Wait For Elements State    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden)    visible
    # Navigate forward until start month is visible in either panel
    FOR    ${i}    IN RANGE    24
        ${left_month}=     Get Text    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:first-of-type .ant-picker-month-btn
        ${left_year}=      Get Text    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:first-of-type .ant-picker-year-btn
        ${right_month}=    Get Text    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:last-of-type .ant-picker-month-btn
        ${right_year}=     Get Text    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:last-of-type .ant-picker-year-btn
        ${found}=    Evaluate    '${month_from}' in '${left_month} ${left_year}' or '${month_from}' in '${right_month} ${right_year}'
        IF    ${found}    BREAK
        Click    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-header-super-next-btn >> nth=0
        Sleep    0.3s
    END
    # Click start date in the correct panel
    ${left_month}=    Get Text    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:first-of-type .ant-picker-month-btn
    ${left_year}=     Get Text    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:first-of-type .ant-picker-year-btn
    ${in_left}=    Evaluate    '${month_from}' in '${left_month} ${left_year}'
    IF    ${in_left}
        Click    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:first-of-type .ant-picker-cell-in-view:not(.ant-picker-cell-disabled) .ant-picker-cell-inner:text-is("${day_from}")
    ELSE
        Click    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:last-of-type .ant-picker-cell-in-view:not(.ant-picker-cell-disabled) .ant-picker-cell-inner:text-is("${day_from}")
    END
    Sleep    0.3s
    # Navigate forward if end month not yet visible (picker stays open after start date click)
    FOR    ${i}    IN RANGE    24
        ${left_month}=     Get Text    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:first-of-type .ant-picker-month-btn
        ${left_year}=      Get Text    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:first-of-type .ant-picker-year-btn
        ${right_month}=    Get Text    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:last-of-type .ant-picker-month-btn
        ${right_year}=     Get Text    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:last-of-type .ant-picker-year-btn
        ${found}=    Evaluate    '${month_to}' in '${left_month} ${left_year}' or '${month_to}' in '${right_month} ${right_year}'
        IF    ${found}    BREAK
        Click    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-header-super-next-btn >> nth=0
        Sleep    0.3s
    END
    # Click end date in the correct panel (picker is still open)
    ${left_month}=    Get Text    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:first-of-type .ant-picker-month-btn
    ${left_year}=     Get Text    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:first-of-type .ant-picker-year-btn
    ${in_left}=    Evaluate    '${month_to}' in '${left_month} ${left_year}'
    IF    ${in_left}
        Click    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:first-of-type .ant-picker-cell-in-view:not(.ant-picker-cell-disabled) .ant-picker-cell-inner:text-is("${day_to}")
    ELSE
        Click    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:last-of-type .ant-picker-cell-in-view:not(.ant-picker-cell-disabled) .ant-picker-cell-inner:text-is("${day_to}")
    END
    Sleep    0.3s

Verify Customer Availed Product Is Deprecated
    [Documentation]    Opens the given customer's profile, switches to the Products Availed tab,
    ...                opens the See Details drawer for the named product, and asserts the held
    ...                version's status is "Deprecated". Reusable across cycles: a customer keeps
    ...                the exact product version they availed, so once a newer version exists their
    ...                held version stays Deprecated.
    [Arguments]        ${customer_id}    ${product_name}
    Navigate To Customers
    View Customer Profile    ${customer_id}
    Click    ${PRODUCTS_AVAILED_TAB}
    Wait For Load Spinner To Disappear
    Wait For Elements State
    ...    css=[data-testid="table-customers-availed-products"] tr:has-text("${product_name}") >> nth=0
    ...    visible    timeout=10s
    Click
    ...    css=[data-testid="table-customers-availed-products"] tr:has-text("${product_name}") >> ${SEE_DETAILS_BTN} >> nth=0
    Wait For Elements State    ${AVAILED_PRODUCT_DRAWER}    visible
    Wait For Elements State    ${AVAILED_PRODUCT_DRAWER} >> text=Deprecated    visible    timeout=10s
    Click    ${PRODUCT_DETAILS_CLOSE_BTN}
    Wait For Elements State    ${AVAILED_PRODUCT_DRAWER}    hidden    timeout=5s

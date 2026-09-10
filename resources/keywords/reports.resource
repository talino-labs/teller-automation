*** Settings ***
Library     Browser
Library     ../libraries/CsvVerifier.py
Resource    common.resource
Resource    ../locators/reports_locators.resource


*** Keywords ***
Navigate To Reports
    [Documentation]    Navigates to the Reports module via the sidebar and waits for page to load
    Click                      ${REPORTS_MENU}
    Wait For Load Spinner To Disappear
    Get Url                    contains    /reports
    Wait For Elements State    ${EOD_BALANCE_BTN}    visible

Setup Reports Page
    [Documentation]    Navigates to the Reports module and ensures a clean state
    Navigate To Reports
    Reload
    Wait For Load Spinner To Disappear
    Wait For Elements State    ${EOD_BALANCE_BTN}    visible

Select Closing Date From AntD Picker
    [Documentation]    Selects a single closing date from the AntD DatePicker (End of Day Balance).
    ...                Opens the picker via the closing date input, navigates backwards to the target
    ...                month using the prev-month arrow, and clicks the target date.
    ...                Future dates are disabled by the application.
    ...                Expects date in YYYY-MM-DD format.
    [Arguments]    ${date}
    ${day}=       Evaluate    str(int('${date}'.split('-')[2]))
    ${month}=     Evaluate    __import__('datetime').datetime(int('${date}'.split('-')[0]), int('${date}'.split('-')[1]), 1).strftime('%b %Y')
    Click    ${CLOSING_DATE_INPUT}
    Sleep    0.5s
    Wait For Elements State    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden)    visible
    FOR    ${i}    IN RANGE    24
        ${cur_month}=    Get Text    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-month-btn
        ${cur_year}=     Get Text    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-year-btn
        ${found}=    Evaluate    '${month}' in '${cur_month} ${cur_year}'
        IF    ${found}    BREAK
        Click    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-header-prev-btn
        Sleep    0.3s
    END
    Click    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-cell-in-view:not(.ant-picker-cell-disabled) .ant-picker-cell-inner:text-is("${day}")
    Sleep    0.3s

Select Report Date Range From AntD Picker
    [Documentation]    Selects a date range from the AntD RangePicker (Total Balance).
    ...                Navigates forward to the target start month, clicks the start date,
    ...                then navigates to the end month and clicks the end date.
    ...                Expects dates in YYYY-MM-DD format.
    [Arguments]    ${date_from}    ${date_to}
    ${day_from}=      Evaluate    str(int('${date_from}'.split('-')[2]))
    ${day_to}=        Evaluate    str(int('${date_to}'.split('-')[2]))
    ${month_from}=    Evaluate    __import__('datetime').datetime(int('${date_from}'.split('-')[0]), int('${date_from}'.split('-')[1]), 1).strftime('%b %Y')
    ${month_to}=      Evaluate    __import__('datetime').datetime(int('${date_to}'.split('-')[0]), int('${date_to}'.split('-')[1]), 1).strftime('%b %Y')
    # Open range picker via Start Date input
    Click    ${DATE_RANGE_START_INPUT}
    Sleep    0.5s
    Wait For Elements State    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden)    visible
    # Navigate to the start month (backward or forward as needed)
    FOR    ${i}    IN RANGE    24
        ${left_month}=     Get Text    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:first-of-type .ant-picker-month-btn
        ${left_year}=      Get Text    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:first-of-type .ant-picker-year-btn
        ${right_month}=    Get Text    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:last-of-type .ant-picker-month-btn
        ${right_year}=     Get Text    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:last-of-type .ant-picker-year-btn
        ${found}=    Evaluate    '${month_from}' in '${left_month} ${left_year}' or '${month_from}' in '${right_month} ${right_year}'
        IF    ${found}    BREAK
        # Navigate backward if target is before current left panel, else forward
        ${target_dt}=    Evaluate    __import__('datetime').datetime.strptime('${month_from}', '%b %Y')
        ${cur_dt}=       Evaluate    __import__('datetime').datetime.strptime('${left_month} ${left_year}', '%b %Y')
        # Use $var (object) not ${var} (string) — inlining the datetime's str form
        # produces an unparseable expression (e.g. 2026-05-01 00:00:00 → leading-zero int).
        IF    $target_dt < $cur_dt
            Click    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-header-prev-btn >> nth=0
        ELSE
            Click    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-header-super-next-btn >> nth=0
        END
        Sleep    0.3s
    END
    # Click the start date in the correct panel
    ${left_month}=    Get Text    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:first-of-type .ant-picker-month-btn
    ${left_year}=     Get Text    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:first-of-type .ant-picker-year-btn
    ${in_left}=    Evaluate    '${month_from}' in '${left_month} ${left_year}'
    IF    ${in_left}
        Click    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:first-of-type .ant-picker-cell-in-view:not(.ant-picker-cell-disabled) .ant-picker-cell-inner:text-is("${day_from}")
    ELSE
        Click    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:last-of-type .ant-picker-cell-in-view:not(.ant-picker-cell-disabled) .ant-picker-cell-inner:text-is("${day_from}")
    END
    Sleep    0.3s
    # Navigate to the end month (backward or forward as needed)
    FOR    ${i}    IN RANGE    24
        ${left_month}=     Get Text    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:first-of-type .ant-picker-month-btn
        ${left_year}=      Get Text    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:first-of-type .ant-picker-year-btn
        ${right_month}=    Get Text    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:last-of-type .ant-picker-month-btn
        ${right_year}=     Get Text    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:last-of-type .ant-picker-year-btn
        ${found}=    Evaluate    '${month_to}' in '${left_month} ${left_year}' or '${month_to}' in '${right_month} ${right_year}'
        IF    ${found}    BREAK
        ${target_dt}=    Evaluate    __import__('datetime').datetime.strptime('${month_to}', '%b %Y')
        ${cur_dt}=       Evaluate    __import__('datetime').datetime.strptime('${left_month} ${left_year}', '%b %Y')
        # Use $var (object) not ${var} (string) — see note above.
        IF    $target_dt < $cur_dt
            Click    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-header-prev-btn >> nth=0
        ELSE
            Click    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-header-super-next-btn >> nth=0
        END
        Sleep    0.3s
    END
    # Click the end date in the correct panel
    ${left_month}=    Get Text    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:first-of-type .ant-picker-month-btn
    ${left_year}=     Get Text    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:first-of-type .ant-picker-year-btn
    ${in_left}=    Evaluate    '${month_to}' in '${left_month} ${left_year}'
    IF    ${in_left}
        Click    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:first-of-type .ant-picker-cell-in-view:not(.ant-picker-cell-disabled) .ant-picker-cell-inner:text-is("${day_to}")
    ELSE
        Click    css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden) .ant-picker-panel:last-of-type .ant-picker-cell-in-view:not(.ant-picker-cell-disabled) .ant-picker-cell-inner:text-is("${day_to}")
    END
    Sleep    0.3s

Download Report CSV
    [Documentation]    Intercepts the browser file download triggered by clicking the Download CSV button.
    ...                Saves the file to the given path and returns the browser-suggested filename.
    ...                The Browser context must have acceptDownloads=True (set in Open Teller App).
    [Arguments]    ${save_path}
    # The app builds the CSV client-side (Blob + createObjectURL) and revokes the blob URL
    # ~100ms after triggering the download, which races Playwright's download capture and
    # causes "waitForEvent download" to time out. Neutralize revokeObjectURL on this page so
    # the blob stays alive long enough for Playwright to save the file.
    Evaluate JavaScript    ${None}    () => { window.URL.revokeObjectURL = () => {}; }
    ${promise}=    Promise To Wait For Download    saveAs=${save_path}
    # Redesigned flow: "Generate Report" opens a "Preparing your download" modal that
    # shows "Generating reports for <date>", then "Your download is ready" once the
    # backend has built the file — the download fires itself at that point.
    Click    ${GENERATE_REPORT_BTN}
    # Fail fast with a clear message if the backend returns a "Failed to generate report"
    # error toast, instead of blindly waiting out the full download timeout.
    ${server_failed}=    Run Keyword And Return Status
    ...    Wait For Elements State    text=Failed to generate report    visible    timeout=8s
    IF    ${server_failed}
        Fail    App returned "Failed to generate report" — the backend did not produce the report (server-side error, not a test issue).
    END
    # Generation is server-side and can take a while, so allow a generous window.
    Run Keyword And Continue On Failure
    ...    Wait For Elements State    ${DOWNLOAD_READY_MSG}    visible    timeout=60s
    ${download}=    Wait For    ${promise}
    RETURN    ${download}[suggestedFilename]

Close Download Modal
    [Documentation]    Dismisses the "Preparing your download" modal via Back so the next
    ...                report type can be selected from a clean page.
    ${open}=    Run Keyword And Return Status
    ...    Wait For Elements State    ${DOWNLOAD_MODAL}    visible    timeout=3s
    IF    ${open}
        Click                      ${DOWNLOAD_MODAL_BACK_BTN}
        Wait For Elements State    ${DOWNLOAD_MODAL}    hidden    timeout=10s
    END

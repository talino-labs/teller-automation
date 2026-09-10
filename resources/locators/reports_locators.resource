*** Variables ***
# ============================================================
# Reports Module Locators
# data-testid: reports.*
# ============================================================

# Navigation
${REPORTS_MENU}                     css=[data-testid="nav-sidebar-reports"]

# Reports Page
${REPORTS_PAGE}                     css=[data-testid="page-reports"]

# Report Type Buttons (sidebar list)
${EOD_BALANCE_BTN}                  css=div.cursor-pointer:has-text("End of Day Balance")
${TOTAL_BALANCE_BTN}                css=div.cursor-pointer:has-text("Total Balance")

# Filters
${REPORTS_FILTER_TEXT}              css=[data-testid="input-reports-filter-text"]

# End of Day — Single Closing Date Picker
${CLOSING_DATE_INPUT}               css=input[placeholder="DD MMM YYYY"]

# Total Balance — Date Range Picker
${DATE_RANGE_START_INPUT}           css=input[placeholder="Start date"][date-range="start"]
${DATE_RANGE_END_INPUT}             css=input[placeholder="End date"][date-range="end"]

# Download — the Reports module was redesigned: there is no longer a "Download CSV"
# button that simply enables once a date is picked. You now click "Generate Report",
# a "Preparing your download" modal appears ("Generating reports for <date>"), and
# when it finishes it shows "Your download is ready" and the file downloads itself.
${GENERATE_REPORT_BTN}              css=button:has-text("Generate Report")
${DOWNLOAD_MODAL}                   css=.ant-modal-content:has-text("Preparing your download")
${DOWNLOAD_GENERATING_MSG}          text=Generating reports for
${DOWNLOAD_READY_MSG}               text=Your download is ready
${DOWNLOAD_FALLBACK_LINK}           text=Click here if your download has not started
${DOWNLOAD_MODAL_BACK_BTN}          css=.ant-modal-content button:has-text("Back")

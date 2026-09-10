#!/bin/bash
# ============================================================
# run_full_regression_batched.sh — Full regression, run in batches
#
# Runs EVERY test (no --include tag filter; only `skip` is excluded)
# against a Type 2 bank, split into batches so a failure or a rate-limit
# block in one module can't poison the rest of the run.
#
# Why no tag filter: type1/type2 are bank-CAPABILITY tags, not depth tags.
# San Antonio is a Type 2 bank, so type2 tests apply. A smoke+type1 union
# drops 94 applicable tests, and 15 tests in t5.1/t5.3 carry neither
# capability tag, so no tag union reaches them. See REGRESSION_SCOPE.md.
#
# Batch order is by rate-limit risk, lowest first. Auth is LAST and alone:
# t1.x is 73 tests, mostly negative-credential and OTP paths, against a
# 10-attempt/15-min IP block. It is expected to trip that block partway
# through; keeping it last means the other ~320 tests are already banked.
#
# t8.1 (interest) is excluded — every T81_* variable is still an empty
# TODO, so its tests would only emit Skips.
#
# Usage:
#   bash run_full_regression_batched.sh                  # all batches, in order
#   bash run_full_regression_batched.sh 1                # just batch 1
#   bash run_full_regression_batched.sh 1 2 3            # batches 1-3, skip auth
#   bash run_full_regression_batched.sh --bank alegre-SBX 2
#   bash run_full_regression_batched.sh --list           # show batches, run nothing
#
# Publish when done:
#   bash publish_reports.sh --timestamp <RUN_NAME> --title "Full Regression testing"
# ============================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOLD='\033[1m'; CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

BANK_ID="rural-bank-san-antonio"
RUN_NAME="2026-09_full-regression"
# Pacing between TC files. ITG throttles (~429 after 13 rapid requests), so the
# non-auth batches idle 20s between TC files; auth idles 90s between suites,
# above the 60s run_config.yaml prescribes for auth regression.
SLEEP_DEFAULT=20
SLEEP_AUTH=90
LIST_ONLY=false
# Force headless for every batch. Variable files set HEADLESS: False; a visible
# Chromium is heavy enough to get long runs OOM-killed on a loaded machine.
HEADLESS=false
WANT_BATCHES=()

while [[ $# -gt 0 ]]; do
  case $1 in
    --bank)  BANK_ID="$2"; shift 2 ;;
    --run)   RUN_NAME="$2"; shift 2 ;;
    --sleep) SLEEP_DEFAULT="$2"; shift 2 ;;
    --sleep-auth) SLEEP_AUTH="$2"; shift 2 ;;
    --list)  LIST_ONLY=true; shift ;;
    --headless) HEADLESS=true; shift ;;
    [1-4])   WANT_BATCHES+=("$1"); shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Batch definitions — name | pacing | TC files
BATCH_1_NAME="Reports + Customers"
BATCH_1_TCS=(t6.1 t2.1 t2.2 t2.3 t2.4 t2.5 t2.6)
BATCH_2_NAME="Accounts + Transactions"
BATCH_2_TCS=(t3.1 t3.2 t4.1 t4.2 t4.3)
BATCH_3_NAME="Products + Loans"
BATCH_3_TCS=(t5.1 t5.2 t5.3 t7.1 t7.2 t7.3 t7.4 t7.5 t7.6)
BATCH_4_NAME="Auth (rate-limit sensitive — runs last, alone)"
BATCH_4_TCS=(t1.2 t1.3 t1.4 t1.1)

[[ ${#WANT_BATCHES[@]} -eq 0 ]] && WANT_BATCHES=(1 2 3 4)

if [[ "$LIST_ONLY" == true ]]; then
  echo ""
  echo "Full regression batches — bank: ${BANK_ID}, run: ${RUN_NAME}"
  for b in 1 2 3 4; do
    name_var="BATCH_${b}_NAME"; tcs_var="BATCH_${b}_TCS[@]"
    echo -e "  ${BOLD}Batch ${b}${NC}  ${!name_var}"
    echo "            ${!tcs_var}"
  done
  echo ""
  exit 0
fi

OVERALL=0
for b in "${WANT_BATCHES[@]}"; do
  name_var="BATCH_${b}_NAME"; tcs_var="BATCH_${b}_TCS[@]"
  TCS=("${!tcs_var}")
  if [[ "$b" == "4" ]]; then SLEEP="$SLEEP_AUTH"; else SLEEP="$SLEEP_DEFAULT"; fi

  echo ""
  echo -e "${BOLD}############################################################${NC}"
  echo -e "${BOLD}#  BATCH ${b} — ${!name_var}${NC}"
  echo    "#  TCs   : ${TCS[*]}"
  echo    "#  Pace  : ${SLEEP}s between TC files"
  echo -e "${BOLD}############################################################${NC}"

  HEADLESS_FLAG=()
  [[ "$HEADLESS" == true ]] && HEADLESS_FLAG+=(--headless)

  bash "${SCRIPT_DIR}/run_july_regression.sh" \
    --bank "${BANK_ID}" --run "${RUN_NAME}" \
    --all-tags "${HEADLESS_FLAG[@]+"${HEADLESS_FLAG[@]}"}" --sleep "${SLEEP}" "${TCS[@]}"
  rc=$?
  if [[ $rc -eq 0 ]]; then
    echo -e "  ${GREEN}Batch ${b} finished with no failing TC files.${NC}"
  else
    echo -e "  ${RED}Batch ${b} finished with failures (see summary above).${NC}"
    OVERALL=1
  fi
done

echo ""
echo "============================================================"
echo "  Batches run: ${WANT_BATCHES[*]}"
echo "  Results    : results/${RUN_NAME}/<tc>/"
echo "  Publish    :"
echo "    bash publish_reports.sh --timestamp ${RUN_NAME} --title \"Full Regression testing\""
echo "============================================================"
exit $OVERALL

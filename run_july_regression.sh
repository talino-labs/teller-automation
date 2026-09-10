#!/bin/bash
# ============================================================
# run_july_regression.sh — Run regression per TEST CASE FILE
#
# Produces one report per TC (t2.1, t6.1, t7.1, ...) so the
# published index shows them individually under the banner:
#
#     July Regression testing
#       t2.1  report ->
#       t6.1  report ->
#       ...
#
# Output layout:
#   results/July-Regression/<tc>/report.html
#
# Usage:
#   bash run_july_regression.sh                         # all TCs, rural-bank-san-antonio
#   bash run_july_regression.sh --bank <bank-id>        # different bank
#   bash run_july_regression.sh --exclude 7_loans       # skip a module dir (repeatable)
#   bash run_july_regression.sh t6.1 t7.1               # only these TC(s)
#   bash run_july_regression.sh --all-tags              # no --include filter (every test)
#   bash run_july_regression.sh --headless              # force headless (variable files set HEADLESS: False)
#
# After it finishes, publish with the banner title:
#   bash publish_reports.sh --timestamp July-Regression --title "July Regression testing"
# ============================================================

set -uo pipefail

# Auto-activate .venv if robot is not already from the venv
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/.venv/bin/activate" && "$(which robot)" != "${SCRIPT_DIR}/.venv/bin/robot" ]]; then
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/.venv/bin/activate"
fi

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

BANK_ID="rural-bank-san-antonio"
RUN_NAME="2026-07_regression-pre-deployment-to-sbx"
EXCLUDES=()
ONLY_TCS=()
# Tags to include. These suites tag tests by type (smoke/type1), not "regression",
# so default to the same set the manual commands use. Override with --tag (repeatable).
INCLUDE_TAGS=("smoke" "type1")
TAG_OVERRIDE=()
# --all-tags drops the --include filter entirely so EVERY test in the file runs
# (only --exclude still applies). Needed for a true full regression: type1/type2
# are bank-CAPABILITY tags, not depth tags, and 15 tests carry neither, so any
# tag union silently drops applicable tests on a Type 2 bank.
ALL_TAGS=false
# Variable files all ship HEADLESS: False, so runs launch a visible Chromium.
# On a memory-constrained machine that is enough to get the run OOM-killed
# mid-suite. --headless passes -v HEADLESS:True, which outranks the -V file.
HEADLESS_OVERRIDE=false
# When true, nest output under a per-bank sub-folder: results/<run>/<bank>/<tc>/
# Lets several banks share one run folder (multi-bank smoke). Off by default so
# the single-bank regression layout (results/<run>/<tc>/) is unchanged.
NEST_BANK=false
# Seconds to pause between TC-file executions (rate-limit protection for
# throttled envs like ITG/SIT). 0 = no gap. Matches the pacing used for the
# San Antonio ITG runs. Intra-suite pacing already lives in the resource files.
SLEEP_BETWEEN=0
# Robot tags to exclude at run time (repeatable), e.g. --exclude-tag status-change.
# Out-of-scope tests are then never EXECUTED (not just hidden) — important for
# mutating tests (status change) that would otherwise corrupt shared test data.
EXCLUDE_TAGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    --bank)        BANK_ID="$2"; shift 2 ;;
    --run)         RUN_NAME="$2"; shift 2 ;;
    --exclude)     EXCLUDES+=("$2"); shift 2 ;;
    --tag)         TAG_OVERRIDE+=("$2"); shift 2 ;;
    --all-tags)    ALL_TAGS=true; shift ;;
    --headless)    HEADLESS_OVERRIDE=true; shift ;;
    --exclude-tag) EXCLUDE_TAGS+=("$2"); shift 2 ;;
    --nest-bank)   NEST_BANK=true; shift ;;
    --sleep)       SLEEP_BETWEEN="$2"; shift 2 ;;
    t[0-9]*)       ONLY_TCS+=("$1"); shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Apply tag override if provided
[[ ${#TAG_OVERRIDE[@]} -gt 0 ]] && INCLUDE_TAGS=("${TAG_OVERRIDE[@]}")
# --all-tags wins over any --tag
[[ "$ALL_TAGS" == true ]] && INCLUDE_TAGS=()

# Build --include flags (none when --all-tags)
INCLUDE_FLAGS=()
for t in "${INCLUDE_TAGS[@]+"${INCLUDE_TAGS[@]}"}"; do INCLUDE_FLAGS+=(--include "$t"); done
if [[ ${#INCLUDE_TAGS[@]} -eq 0 ]]; then
  TAG_LABEL="(all — no include filter)"
else
  TAG_LABEL="${INCLUDE_TAGS[*]}"
fi

# Build --exclude flags (robot tags). 'skip' is always excluded; add any --exclude-tag values.
EXCLUDE_TAG_FLAGS=(--exclude skip)
for t in "${EXCLUDE_TAGS[@]+"${EXCLUDE_TAGS[@]}"}"; do EXCLUDE_TAG_FLAGS+=(--exclude "$t"); done

# -v beats -V in Robot's variable precedence, so this wins over the file value.
CLI_VARS=()
[[ "$HEADLESS_OVERRIDE" == true ]] && CLI_VARS+=(-v HEADLESS:True)

VAR_FILE="${SCRIPT_DIR}/resources/variables/${BANK_ID}.yaml"
[[ -f "$VAR_FILE" ]] || { echo -e "${RED}Variable file not found: ${VAR_FILE}${NC}"; exit 1; }

OUT_ROOT="${SCRIPT_DIR}/results/${RUN_NAME}"

echo ""
echo "============================================================"
echo "  July Regression testing — per-TC run"
echo "  Bank   : ${BANK_ID}"
echo "  Output : results/${RUN_NAME}/<tc>/"
echo "  Tags   : ${TAG_LABEL}"
[[ ${#EXCLUDES[@]} -gt 0 ]] && echo "  Skip   : ${EXCLUDES[*]}"
[[ ${#ONLY_TCS[@]} -gt 0 ]] && echo "  Only   : ${ONLY_TCS[*]}"
echo "============================================================"

# Emit test files in execution order. When explicit TCs are given, honour the
# order they were passed rather than filesystem sort order — auth depends on it
# (t1.1 reset-password is the most OTP-sensitive suite and must run LAST, or it
# burns the 10-attempt/15-min budget before the login suites get a turn).
ordered_test_files() {
  local all=()
  while IFS= read -r f; do all+=("$f"); done \
    < <(find "${SCRIPT_DIR}/tests" -name 't*.robot' | sort)

  if [[ ${#ONLY_TCS[@]} -eq 0 ]]; then
    printf '%s\n' "${all[@]}"
    return
  fi

  local want f base tc
  for want in "${ONLY_TCS[@]}"; do
    for f in "${all[@]}"; do
      base="$(basename "$f")"
      tc="$(echo "$base" | grep -oE '^t[0-9]+\.[0-9]+')"
      [[ "$tc" == "$want" ]] && printf '%s\n' "$f"
    done
  done
}

PASS_TCS=(); FAIL_TCS=(); SKIP_TCS=()

# Discover all test files, sorted
while IFS= read -r file; do
  base="$(basename "$file")"
  tc="$(echo "$base" | grep -oE '^t[0-9]+\.[0-9]+')"
  [[ -z "$tc" ]] && continue

  # --only filter
  if [[ ${#ONLY_TCS[@]} -gt 0 ]]; then
    match=0
    for want in "${ONLY_TCS[@]}"; do [[ "$tc" == "$want" ]] && match=1; done
    [[ $match -eq 0 ]] && continue
  fi

  # --exclude filter (matches any path substring, e.g. a module dir)
  skip=0
  for ex in "${EXCLUDES[@]+"${EXCLUDES[@]}"}"; do
    [[ "$file" == *"$ex"* ]] && skip=1
  done
  if [[ $skip -eq 1 ]]; then
    echo -e "  ${CYAN}[skip]${NC}   ${tc} (excluded)"
    SKIP_TCS+=("$tc"); continue
  fi

  # Pacing gap between executions (skipped before the first run)
  if [[ "$SLEEP_BETWEEN" -gt 0 && "${RAN_ONCE:-false}" == true ]]; then
    echo -e "  ${CYAN}[pace]${NC}   sleeping ${SLEEP_BETWEEN}s before next TC (rate-limit protection)..."
    sleep "$SLEEP_BETWEEN"
  fi
  RAN_ONCE=true

  # Output dir — optionally nested under the bank for multi-bank runs
  if [[ "$NEST_BANK" == true ]]; then
    TC_OUT="${OUT_ROOT}/${BANK_ID}/${tc}"
  else
    TC_OUT="${OUT_ROOT}/${tc}"
  fi

  echo ""
  echo -e "  ${BOLD}[run]${NC}    ${tc}  (${base})"
  if robot -V "$VAR_FILE" "${CLI_VARS[@]+"${CLI_VARS[@]}"}" "${INCLUDE_FLAGS[@]+"${INCLUDE_FLAGS[@]}"}" "${EXCLUDE_TAG_FLAGS[@]}" -d "${TC_OUT}" "$file"; then
    PASS_TCS+=("$tc")
  else
    code=$?
    # robot exit 252 = no tests matched the tag; treat as skipped, not failed
    if [[ $code -eq 252 ]]; then
      echo -e "  ${CYAN}[skip]${NC}   ${tc} (no tests matching tags: ${TAG_LABEL})"
      rm -rf "${TC_OUT}"
      SKIP_TCS+=("$tc")
    else
      FAIL_TCS+=("$tc")
    fi
  fi
done < <(ordered_test_files)

echo ""
echo "============================================================"
echo -e "  ${GREEN}Passed${NC}  : ${PASS_TCS[*]:-none}"
echo -e "  ${RED}Failed${NC}  : ${FAIL_TCS[*]:-none}"
echo -e "  ${CYAN}Skipped${NC} : ${SKIP_TCS[*]:-none}"
echo "============================================================"
echo "  Publish with:"
echo "    bash publish_reports.sh --timestamp ${RUN_NAME} --title \"July Regression testing\""
echo "============================================================"
echo ""

[[ ${#FAIL_TCS[@]} -eq 0 ]]

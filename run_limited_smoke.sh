#!/bin/bash
# ============================================================
# run_limited_smoke.sh — Scoped smoke for limited-module SBX banks
#
# Some SBX tenants (e.g. SNR-SBX, Guagua-SBX) expose only the Customers,
# Accounts, Transactions and Reports modules — no Products or Loans, and
# no cash deposit/withdrawal, external-transfer, or loan/interest
# transaction data. Running the full smoke suite yields ~140
# not-applicable failures.
#
# This wrapper runs ONLY the in-scope TC files, excludes the mutating
# status-change tests at run time (they share the account other tests
# verify as Active, so executing them corrupts state), and filters the
# remaining read-only out-of-scope sub-tests from the report.
#
# In scope: t1.2-1.4 (auth), t2.1-2.3 (customers), t3.1-3.2 (accounts),
#           t4.1 (transactions view), t6.1 (reports).
# See REGRESSION_SCOPE.md -> "SNR-SBX (limited-module) smoke scope".
#
# Usage:
#   bash run_limited_smoke.sh <BANK> [RUN_NAME]
#   e.g.  bash run_limited_smoke.sh Guagua-SBX
# ============================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BANK="${1:?Usage: bash run_limited_smoke.sh <BANK> [RUN_NAME]}"
RUN_NAME="${2:-Teller_SBX_and_SIT_July2026_Smoke_Testing}"

# In-scope TC files
IN_SCOPE_TCS=(t1.2 t1.3 t1.4 t2.1 t2.2 t2.3 t3.1 t3.2 t4.1 t6.1)

echo "Limited-scope smoke: ${BANK} -> results/${RUN_NAME}/${BANK}/"
# status-change tests are excluded at RUN time (not just filtered): they are
# mutating and share the account other tests verify as Active, so executing them
# corrupts state. --exclude-tag keeps them from running at all.
bash "${SCRIPT_DIR}/run_july_regression.sh" --bank "${BANK}" --run "${RUN_NAME}" \
  --tag smoke --nest-bank --sleep 15 --exclude-tag status-change "${IN_SCOPE_TCS[@]}"

echo ""
echo "Filtering read-only out-of-scope sub-tests from the ${BANK} report..."
python3 - "${SCRIPT_DIR}" "${RUN_NAME}" "${BANK}" <<'PY'
import sys, os, tempfile, shutil, subprocess, xml.etree.ElementTree as ET
script_dir, run, bank = sys.argv[1], sys.argv[2], sys.argv[3]
ROOT = os.path.join(script_dir, 'results', run, bank)
# Read-only sub-tests to drop from the report, matched on the exact "tX.Y.N " prefix.
# (status-change tests are already excluded at run time via --exclude-tag.)
EXCLUDE = {
    't2.1': ['t2.1.12b '],                                                # product-tabs variant only (needs Products module); the type1 variant is kept
    't2.3': ['t2.3.10 ', 't2.3.11 ', 't2.3.12 ', 't2.3.13 ', 't2.3.14 '], # cash/interest/loan type filters
    't3.2': ['t3.2.9 ', 't3.2.10 ', 't3.2.11 ', 't3.2.12 ', 't3.2.13 '],  # cash/interest/loan type filters
    't4.1': ['t4.1.5 ', 't4.1.9 ', 't4.1.10 ', 't4.1.11 ', 't4.1.12 ', 't4.1.13 '],  # external search + type filters
}
for tc, prefixes in EXCLUDE.items():
    x = os.path.join(ROOT, tc, 'output.xml')
    if not os.path.exists(x):
        print(f'  {tc}: no output.xml, skipped'); continue
    keep = [t.get('name') for t in ET.parse(x).getroot().iter('test')
            if not any(t.get('name').startswith(p) for p in prefixes)]
    tmp = tempfile.mkdtemp()
    args = ['rebot', '--outputdir', tmp, '--output', 'output.xml', '--log', 'log.html',
            '--report', 'report.html', '--nostatusrc', '--name', tc.upper()]
    for n in keep:
        args += ['--test', n]
    args.append(x)
    subprocess.run(args, capture_output=True, text=True)
    for fn in ('output.xml', 'log.html', 'report.html'):
        s = os.path.join(tmp, fn)
        if os.path.exists(s):
            shutil.move(s, os.path.join(ROOT, tc, fn))
    print(f'  {tc}: kept {len(keep)} in-scope test(s)')
PY

echo ""
echo "Done. Publish with:"
echo "  bash publish_reports.sh --timestamp ${RUN_NAME} --title \"Teller SBX and SIT July 2026 Smoke Testing\""

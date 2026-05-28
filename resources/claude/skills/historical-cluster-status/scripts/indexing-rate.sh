#!/usr/bin/env bash
# Per-index indexing stats for the last N days (default 30).
# Usage: indexing-rate.sh [days]
#
# Surfaces:
#   - docs indexed (cumulative since index creation)
#   - avg ms per indexing op (low = fast, > 5ms = slow)
#   - current in-flight ops (non-zero = backpressure)
#   - throttle_ms on the index itself (rare; usually 0)

set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_es.sh
source "$DIR/_es.sh"
require_es

DAYS="${1:-30}"

# Build the index pattern: last N days, comma-separated.
PATTERN=$(python3 -c "
import datetime
days = int('$DAYS')
today = datetime.date.today()
parts = []
for i in range(days):
    d = today - datetime.timedelta(days=i)
    parts.append(f'history_{d:%Y-%m-%d}')
print(','.join(parts))
")

response=$(es_get "${PATTERN}/_stats/indexing?pretty") || exit $?
python3 -c "
import json, sys
d = json.load(sys.stdin)
indices = d.get('indices', {})
if not indices:
    print('(no matching history_* indices for the requested window)')
    sys.exit(0)
print(f'{\"index\":25} {\"index_total\":>14} {\"avg_ms/doc\":>11} {\"current_ops\":>12} {\"throttle_ms\":>12}')
rows = []
for name in sorted(indices.keys(), reverse=True):
    info = indices[name]
    p = info.get('primaries', {}).get('indexing', {})
    total = p.get('index_total', 0)
    ms = p.get('index_time_in_millis', 0)
    cur = p.get('index_current', 0)
    thr = p.get('throttle_time_in_millis', 0)
    avg = (ms/total) if total else 0
    rows.append((name, total, avg, cur, thr))
for r in rows:
    print(f'{r[0]:25} {r[1]:14,} {r[2]:11.2f} {r[3]:12} {r[4]:12}')

print()
slow = [r for r in rows if r[2] > 5 and r[1] > 1000]
backpressure = [r for r in rows if r[3] > 0]
if slow:
    print(f'FLAG: {len(slow)} indices with avg/doc > 5ms (active days only):')
    for r in sorted(slow, key=lambda x:-x[2])[:5]:
        print(f'  - {r[0]}: {r[2]:.1f} ms/doc on {r[1]:,} docs')
if backpressure:
    print(f'FLAG: {len(backpressure)} indices with in-flight ops > 0 (backpressure right now):')
    for r in backpressure[:5]:
        print(f'  - {r[0]}: {r[3]} current ops')
" <<< "$response"

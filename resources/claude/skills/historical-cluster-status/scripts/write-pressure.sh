#!/usr/bin/env bash
# Write capacity signal: bulk thread pool + store throttle.
# - Bulk active/queue/rejected: live indicator of saturation now
# - Store throttle: cumulative time spent throttling merges/stores per node
# In ES 1.x the user-facing "indexing throttling" lives under indices.store.

set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_es.sh
source "$DIR/_es.sh"
require_es

echo "--- Bulk thread pool (right now) ---"
es_get "_nodes/stats/thread_pool?pretty" | python3 -c "
import json, sys
d = json.load(sys.stdin)
nodes = d.get('nodes', {})
rows = []
for nid, n in nodes.items():
    tp = n.get('thread_pool', {}).get('bulk', {})
    rows.append((n.get('name','?'), tp.get('active',0), tp.get('queue',0), tp.get('rejected',0), tp.get('largest',0)))
tot_active = sum(r[1] for r in rows)
tot_queue  = sum(r[2] for r in rows)
tot_rej    = sum(r[3] for r in rows)
tot_largest= sum(r[4] for r in rows)
print(f'TOTAL: active={tot_active}  queue={tot_queue}  rejected_cumulative={tot_rej}  largest_total={tot_largest}')
print('NOTE: rejected is cumulative since node start; check uptime before treating as a current problem.')
hot = [r for r in rows if r[1] > 0 or r[2] > 0]
if hot:
    print()
    print(f'{\"node\":30} {\"active\":>7} {\"queue\":>7} {\"rejected_cum\":>13}')
    for r in sorted(hot, key=lambda x:-(x[1]+x[2])):
        print(f'{r[0]:30} {r[1]:7} {r[2]:7} {r[3]:13}')
"

echo
echo "--- Store throttle (cumulative, top 15 nodes) ---"
es_get "_nodes/stats/indices/store?pretty" | python3 -c "
import json, sys
d = json.load(sys.stdin)
nodes = d.get('nodes', {})
rows = []
for nid, n in nodes.items():
    name = n.get('name','?')
    s = n.get('indices', {}).get('store', {})
    rows.append((name, s.get('size_in_bytes',0)/(1024**3), s.get('throttle_time_in_millis',0)))
print(f'{\"node\":30} {\"store_GB\":>10} {\"throttle_min\":>13}')
for r in sorted(rows, key=lambda x:-x[2])[:15]:
    print(f'{r[0]:30} {r[1]:10.1f} {r[2]/60000:13.1f}')
total_min = sum(r[2] for r in rows) / 60000
print()
print(f'cluster total store throttle: {total_min:.0f} min ({total_min/60:.1f} h / {total_min/60/24:.2f} d)')
hot_share = sum(r[2] for r in rows if 'hot' in r[0].lower())
print(f'  share on \"hot\" nodes: {hot_share/60000:.0f} min ({(hot_share/sum(r[2] for r in rows)*100) if sum(r[2] for r in rows) else 0:.1f}%)')
"

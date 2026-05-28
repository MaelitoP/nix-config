#!/usr/bin/env bash
# Segment count + merge activity per node.
# Lots of segments + slow merges → indexing throttle → write lag.

set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_es.sh
source "$DIR/_es.sh"
require_es

response=$(es_get "_nodes/stats/indices/merges,segments?pretty") || exit $?
python3 -c "
import json, sys
d = json.load(sys.stdin)
nodes = d.get('nodes', {})
rows = []
for nid, n in nodes.items():
    name = n.get('name', '?')
    idx = n.get('indices', {})
    merges = idx.get('merges', {})
    segs = idx.get('segments', {})
    rows.append({
        'name': name,
        'seg_count': segs.get('count', 0),
        'seg_mem_mb': segs.get('memory_in_bytes', 0) / (1024**2),
        'merge_cur': merges.get('current', 0),
        'merge_cur_mb': merges.get('current_size_in_bytes', 0) / (1024**2),
        'merge_total': merges.get('total', 0),
        'merge_total_ms': merges.get('total_time_in_millis', 0),
    })
total_segs = sum(r['seg_count'] for r in rows)
total_active = sum(r['merge_cur'] for r in rows)
print(f'CLUSTER: total_segments={total_segs:,}  active_merges_now={total_active}')

print()
print('--- Top 15 nodes by segment count ---')
print(f'{\"node\":30} {\"segments\":>9} {\"seg_mem_MB\":>11} {\"merge_total\":>12} {\"merge_total_h\":>14}')
for r in sorted(rows, key=lambda x:-x['seg_count'])[:15]:
    print(f\"{r['name']:30} {r['seg_count']:9} {r['seg_mem_mb']:11.1f} {r['merge_total']:12} {r['merge_total_ms']/3600000:14.2f}\")

active = [r for r in rows if r['merge_cur'] > 0]
print()
print(f'--- Nodes with active merges right now: {len(active)} ---')
if active:
    print(f'{\"node\":30} {\"merge_cur\":>10} {\"merge_cur_MB\":>13}')
    for r in sorted(active, key=lambda x:-x['merge_cur']):
        print(f\"{r['name']:30} {r['merge_cur']:10} {r['merge_cur_mb']:13.0f}\")
else:
    print('(no merges in flight in this snapshot)')
" <<< "$response"

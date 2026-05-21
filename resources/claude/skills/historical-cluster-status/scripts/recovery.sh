#!/usr/bin/env bash
# Recovery state: who has unassigned shards, why, and which nodes "left".
# Combines _cluster/health (per-index) with _cluster/state/routing_table.

set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_es.sh
source "$DIR/_es.sh"
require_es

echo "--- Indices health summary ---"
es_get "_cluster/health?level=indices&pretty" | python3 -c "
import json, sys
d = json.load(sys.stdin)
idx = d.get('indices', {})
buckets = {'green':0, 'yellow':0, 'red':0}
for v in idx.values():
    buckets[v.get('status','green')] = buckets.get(v.get('status','green'), 0) + 1
print(f'green: {buckets[\"green\"]}  yellow: {buckets[\"yellow\"]}  red: {buckets[\"red\"]}')

red = {k:v for k,v in idx.items() if v.get('status')=='red'}
if red:
    print('Red indices:')
    for k,v in list(red.items())[:20]:
        print(f'  {k}: unassigned={v.get(\"unassigned_shards\",0)} init={v.get(\"initializing_shards\",0)}')
"

echo
echo "--- Unassigned shards: reasons and origin nodes ---"
es_get "_cluster/state/routing_table?pretty" | python3 -c "
import json, sys
from collections import Counter
d = json.load(sys.stdin)
rt = d.get('routing_table', {}).get('indices', {})
reasons = Counter()
left_nodes = Counter()
example_per_node = {}
total_unassigned = 0
for idx_name, idx in rt.items():
    for shard_num, shards in idx.get('shards', {}).items():
        for s in shards:
            if s.get('state') == 'UNASSIGNED':
                total_unassigned += 1
                ui = s.get('unassigned_info', {})
                reasons[ui.get('reason','?')] += 1
                details = ui.get('details', '') or ''
                if 'node_left[' in details:
                    nid = details.split('node_left[',1)[1].split(']',1)[0]
                    left_nodes[nid] += 1
                    example_per_node.setdefault(nid, f'{idx_name}[{shard_num}]')
print(f'total unassigned: {total_unassigned}')
print()
print('by reason:')
for r, c in reasons.most_common():
    print(f'  {r}: {c}')
print()
if left_nodes:
    print('by departed node (NODE_LEFT details):')
    print(f'  {\"node_id\":28} {\"shards\":>8}  example')
    for nid, c in left_nodes.most_common():
        print(f'  {nid:28} {c:8}  {example_per_node[nid]}')
"

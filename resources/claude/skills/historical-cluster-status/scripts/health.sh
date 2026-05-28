#!/usr/bin/env bash
# Cluster-wide health one-liner + count of pending tasks.
# Also surfaces the unique node IDs referenced by recent NODE_LEFT events
# (i.e. who flapped lately), because that's almost always what we want next.

set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_es.sh
source "$DIR/_es.sh"
require_es

response=$(es_get "_cluster/health?pretty") || exit $?
python3 -c "
import json, sys
h = json.load(sys.stdin)
print(f\"cluster: {h['cluster_name']}  status: {h['status']}\")
print(f\"nodes: {h['number_of_nodes']} ({h['number_of_data_nodes']} data)\")
print(f\"shards: active={h['active_shards']} primary={h['active_primary_shards']} init={h['initializing_shards']} reloc={h['relocating_shards']} unassigned={h['unassigned_shards']}\")
print(f\"pending_tasks: {h['number_of_pending_tasks']}\")
print(f\"delayed_unassigned: {h['delayed_unassigned_shards']}  in_flight_fetch: {h['number_of_in_flight_fetch']}\")
" <<< "$response"

echo
echo "--- Recent NODE_LEFT events (extracted from pending_tasks) ---"
response=$(es_get "_cluster/pending_tasks?pretty") || exit $?
python3 -c "
import json, re, sys
from collections import Counter
d = json.load(sys.stdin)
tasks = d.get('tasks', [])
leaver = Counter()
unique_indices = set()
for t in tasks:
    src = t.get('source', '')
    m = re.search(r'node_left\[([\w-]+)\]', src)
    if m:
        leaver[m.group(1)] += 1
    m2 = re.search(r'\[(history_[0-9-]+)\]', src)
    if m2:
        unique_indices.add(m2.group(1))
if not leaver:
    print('(no node_left references in current pending tasks)')
else:
    print(f'{\"node_id\":28} {\"mentions\":>10}')
    for nid, c in leaver.most_common():
        print(f'{nid:28} {c:10}')
print(f'pending_tasks total: {len(tasks)}')
print(f'distinct indices mentioned: {len(unique_indices)}')
" <<< "$response"

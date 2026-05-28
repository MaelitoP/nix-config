#!/usr/bin/env bash
# Deep-dive on a single index: per-shard placement, segments, doc/deleted counts,
# and indexing stats. Useful when a particular index shows up in logs (e.g.
# the throttle line from index.engine) or in the recovery queue.
# Usage: index-detail.sh <index-name>

set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_es.sh
source "$DIR/_es.sh"
require_es

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <index-name>" >&2
    echo "Example: $0 history_2024-11-06" >&2
    exit 1
fi
INDEX="$1"

echo "=== ${INDEX} : per-shard segments & placement ==="
response=$(es_get "${INDEX}/_segments?pretty") || exit $?
python3 -c "
import json, sys
d = json.load(sys.stdin)
indices = d.get('indices', {})
if not indices:
    print('Index not found.')
    sys.exit(1)
for idx_name, idx in indices.items():
    shards = idx.get('shards', {})
    print(f'{\"shard\":>5} {\"prim\":>5} {\"node\":>10} {\"state\":>10} {\"segs\":>5} {\"commit\":>7} {\"docs\":>14} {\"deleted\":>10}')
    for shard_id in sorted(shards.keys(), key=int):
        for copy in shards[shard_id]:
            routing = copy.get('routing', {})
            segs = copy.get('segments', {})
            n_segs = len(segs)
            n_docs = sum(s.get('num_docs', 0) for s in segs.values())
            n_del = sum(s.get('deleted_docs', 0) for s in segs.values())
            committed = sum(1 for s in segs.values() if s.get('committed'))
            print(f\"{shard_id:>5} {str(routing.get('primary')):>5} {routing.get('node','?')[:8]:>10} {routing.get('state','?'):>10} {n_segs:>5} {committed:>7} {n_docs:>14,} {n_del:>10,}\")
" <<< "$response"

echo
echo "=== ${INDEX} : indexing stats ==="
response=$(es_get "${INDEX}/_stats/indexing,store?pretty") || exit $?
python3 -c "
import json, sys
d = json.load(sys.stdin)
indices = d.get('indices', {})
for name, info in indices.items():
    p = info.get('primaries', {})
    t = info.get('total', {})
    ip = p.get('indexing', {})
    sp = p.get('store', {})
    print(f'index: {name}')
    print(f'  primaries: docs={ip.get(\"index_total\",0):,} avg_ms/doc={(ip.get(\"index_time_in_millis\",0)/ip.get(\"index_total\",1)) if ip.get(\"index_total\") else 0:.2f}  current_ops={ip.get(\"index_current\",0)}')
    print(f'             throttle_ms={ip.get(\"throttle_time_in_millis\",0)}  delete_total={ip.get(\"delete_total\",0):,}')
    print(f'  store: size={sp.get(\"size_in_bytes\",0)/(1024**3):.2f} GB  throttle={sp.get(\"throttle_time_in_millis\",0)/60000:.1f} min')
" <<< "$response"

echo
echo "=== ${INDEX} : settings (refresh_interval / merge policy) ==="
response=$(es_get "${INDEX}/_settings?pretty") || exit $?
python3 -c "
import json, sys
d = json.load(sys.stdin)
for name, info in d.items():
    s = info.get('settings', {}).get('index', {})
    print(f'  refresh_interval: {s.get(\"refresh_interval\", \"<default 1s>\")}')
    print(f'  number_of_shards: {s.get(\"number_of_shards\", \"?\")}')
    print(f'  number_of_replicas: {s.get(\"number_of_replicas\", \"?\")}')
    mp = s.get('merge', {})
    if mp:
        print(f'  merge: {json.dumps(mp)}')
" <<< "$response"

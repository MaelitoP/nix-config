#!/usr/bin/env bash
# Deep-dive on a single node: heap/GC, load, thread pool, store, merges.
# Usage: node-detail.sh <node-name>

set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_es.sh
source "$DIR/_es.sh"
require_es

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <node-name>" >&2
    echo "Example: $0 es4-148-gra2" >&2
    exit 1
fi
NODE="$1"

es_get "_nodes/${NODE}/stats/jvm,os,process,thread_pool,indices?pretty" | python3 -c "
import json, sys
d = json.load(sys.stdin)
nodes = d.get('nodes', {})
if not nodes:
    print(f'No node matched: \"$NODE\"')
    sys.exit(1)

for nid, n in nodes.items():
    name = n.get('name', '?')
    print(f'=== {name} (id={nid}) ===')

    jvm = n.get('jvm', {})
    mem = jvm.get('mem', {})
    used = mem.get('heap_used_in_bytes', 0)
    maxb = mem.get('heap_max_in_bytes', 0)
    pct = (used/maxb*100) if maxb else 0
    print(f'heap: {used/(1024**3):.2f} GB / {maxb/(1024**3):.2f} GB ({pct:.1f}%)')

    gc = jvm.get('gc', {}).get('collectors', {})
    old_n = gc.get('old', {}).get('collection_count', 0)
    old_ms = gc.get('old', {}).get('collection_time_in_millis', 0)
    young_n = gc.get('young', {}).get('collection_count', 0)
    young_ms = gc.get('young', {}).get('collection_time_in_millis', 0)
    avg_old = (old_ms/old_n) if old_n else 0
    print(f'old_gc: {old_n} events, total={old_ms/1000:.1f}s, avg={avg_old/1000:.2f}s/pause')
    print(f'young_gc: {young_n} events, total={young_ms/1000:.1f}s')

    import time
    start_ms = jvm.get('start_time_in_millis', 0)
    if start_ms:
        uptime_h = (time.time()*1000 - start_ms) / 3600000
        print(f'jvm uptime: {uptime_h/24:.1f} days')

    load = n.get('os', {}).get('load_average', [0])
    if isinstance(load, list):
        print(f'load: {load}')
    else:
        print(f'load1: {load}')

    proc = n.get('process', {})
    cpu = proc.get('cpu', {})
    if cpu:
        print(f'process cpu: {cpu.get(\"percent\",\"?\")}%')

    print()
    print('--- Thread pool (selected) ---')
    tp = n.get('thread_pool', {})
    for pool_name in ('bulk', 'index', 'search', 'merge'):
        p = tp.get(pool_name)
        if p:
            print(f'  {pool_name:8} active={p.get(\"active\",0)} queue={p.get(\"queue\",0)} rejected_cum={p.get(\"rejected\",0)} largest={p.get(\"largest\",0)}')

    print()
    print('--- Indices stats on this node ---')
    idx = n.get('indices', {})
    docs = idx.get('docs', {})
    store = idx.get('store', {})
    segs = idx.get('segments', {})
    merges = idx.get('merges', {})
    print(f'  docs: {docs.get(\"count\",0):,} (+{docs.get(\"deleted\",0):,} deleted)')
    print(f'  store: {store.get(\"size_in_bytes\",0)/(1024**3):.1f} GB  throttle={store.get(\"throttle_time_in_millis\",0)/60000:.1f} min')
    print(f'  segments: count={segs.get(\"count\",0):,}  memory={segs.get(\"memory_in_bytes\",0)/(1024**2):.1f} MB')
    print(f'  merges: current={merges.get(\"current\",0)} cur_size={merges.get(\"current_size_in_bytes\",0)/(1024**2):.0f}MB total={merges.get(\"total\",0)} total_time={merges.get(\"total_time_in_millis\",0)/3600000:.2f}h')
"

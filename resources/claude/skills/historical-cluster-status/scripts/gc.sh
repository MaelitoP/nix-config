#!/usr/bin/env bash
# JVM heap pressure + GC pauses per node.
# Sorts by AVG OLD-GC PAUSE (descending) — that's the metric that explains
# cluster flapping. A node with a 60s avg Full GC pause WILL fail master
# heartbeat and be evicted.

set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_es.sh
source "$DIR/_es.sh"
require_es

response=$(es_get "_nodes/stats/jvm,os?pretty") || exit $?
python3 -c "
import json, sys
d = json.load(sys.stdin)
nodes = d.get('nodes', {})
rows = []
for nid, n in nodes.items():
    name = n.get('name','?')
    mem = n.get('jvm', {}).get('mem', {})
    used = mem.get('heap_used_in_bytes', 0)
    maxb = mem.get('heap_max_in_bytes', 0)
    pct = (used/maxb*100) if maxb else 0
    gc = n.get('jvm', {}).get('gc', {}).get('collectors', {})
    old_n = gc.get('old', {}).get('collection_count', 0)
    old_ms = gc.get('old', {}).get('collection_time_in_millis', 0)
    young_n = gc.get('young', {}).get('collection_count', 0)
    young_ms = gc.get('young', {}).get('collection_time_in_millis', 0)
    load = n.get('os', {}).get('load_average', [0])
    load1 = load[0] if isinstance(load, list) and load else (load if isinstance(load,(int,float)) else 0)
    rows.append({
        'name': name, 'pct': pct,
        'used_gb': used/(1024**3), 'max_gb': maxb/(1024**3),
        'old_n': old_n, 'old_ms': old_ms,
        'old_avg': (old_ms/old_n) if old_n else 0,
        'young_n': young_n, 'load1': load1,
    })

print(f'{\"node\":30} {\"heap%\":>6} {\"used_gb\":>8} {\"old_n\":>6} {\"old_total_min\":>14} {\"avg_pause_s\":>12} {\"young_n\":>10} {\"load1\":>7}')
# Sort by avg pause descending — surfaces catastrophic Full GCs
for r in sorted(rows, key=lambda x:-x['old_avg'])[:25]:
    print(f\"{r['name']:30} {r['pct']:6.1f} {r['used_gb']:8.2f} {r['old_n']:6} {r['old_ms']/60000:14.1f} {r['old_avg']/1000:12.2f} {r['young_n']:10} {r['load1']:7.2f}\")

bad_avg = [r for r in rows if r['old_avg'] > 10000]
high_heap = [r for r in rows if r['pct'] > 85]
print()
print(f'Total nodes: {len(rows)}')
print(f'Nodes with avg old-GC pause > 10s: {len(bad_avg)}   > 30s: {len([r for r in rows if r[\"old_avg\"]>30000])}')
print(f'Nodes with heap > 85%: {len(high_heap)}   > 90%: {len([r for r in rows if r[\"pct\"]>90])}')
if bad_avg:
    print()
    print('FLAG: candidates for rolling restart (long Full GC pauses):')
    for r in sorted(bad_avg, key=lambda x:-x['old_avg'])[:10]:
        print(f\"  - {r['name']}: avg pause {r['old_avg']/1000:.1f}s, heap {r['pct']:.0f}%, {r['old_n']} old-GC events\")
" <<< "$response"

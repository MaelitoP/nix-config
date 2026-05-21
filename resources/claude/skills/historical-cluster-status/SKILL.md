---
name: historical-cluster-status
description: Diagnose the historical Elasticsearch cluster (mention-es4 — the cluster behind SearchHistoryIndexCommand, accessed via dev-env envoy on port 1064). Loads a baseline (health, recovery, write-pressure) at invocation and gives an analytical summary. Use this when the user asks about the historical/history ES cluster's health, write performance, GC pauses, merge throttling, indexing lag, or any operational signal on it. Trigger phrases include "comment va le cluster historique", "le cluster history va-t-il bien", "is the historical cluster ok", "diagnose historical ES", "merge throttle on history".
allowed-tools: Bash(docker exec *) Bash(${CLAUDE_SKILL_DIR}/scripts/*)
---

# Historical cluster status — mention-es4

Targets the **Mention historical ES cluster** (`mention-es4`), the one where `mention:search:history:index` writes `history_YYYY-MM-DD` indices. This is **not** the platform-ingestor OpenSearch `historical` cluster (different infra, accessed differently).

## Baseline (auto-injected)

### Cluster health
```!
${CLAUDE_SKILL_DIR}/scripts/health.sh
```

### Recovery state
```!
${CLAUDE_SKILL_DIR}/scripts/recovery.sh
```

### Write pressure
```!
${CLAUDE_SKILL_DIR}/scripts/write-pressure.sh
```

## Interpretive rubric

Read the baseline above first, then apply this rubric to decide whether to drill deeper:

- **status: green + no pending tasks** → cluster is healthy. Report "RAS" with a one-line confirmation.
- **status: yellow + unassigned > 0** → recovery in progress, no data loss risk. Identify the nodes named under `NODE_LEFT details` in the recovery section. These are nodes that recently flapped. Almost always run `gc.sh` next: a Full GC pause > 30s causes the master to evict the node, which produces the `NODE_LEFT` you see here.
- **status: red** → primary shards missing somewhere. Show which indices are red. Investigation goes via `recovery.sh` then `index-detail.sh` on the affected indices.
- **bulk rejected cumulative is huge** (millions) **but `active`/`queue` are low right now** → the rejections were spread over months of uptime; not a current problem. Don't alarm-flag this.
- **store_throttle > a few hours cumulative AND concentrated on hot nodes** → merges falling behind. Run `merge.sh` to see segment counts, then `indexing-rate.sh` to see if active days have high `avg_ms/doc` or non-zero `current_ops` (= live backpressure).
- **avg old-GC pause > 10s on any node** → chronic Full GC, candidate for rolling restart. Long JVM uptime + CMS + heap near 22-25GB is the typical recipe (fragmentation). Surface in the recommendations.

## Drill-down scripts

Run via Bash when the rubric points there. All are in `${CLAUDE_SKILL_DIR}/scripts/`:

| Script | When to run |
|---|---|
| `gc.sh` | Whenever cluster is yellow with NODE_LEFT, or whenever an operator suspects flapping |
| `merge.sh` | When store_throttle is high or active merges count is elevated |
| `indexing-rate.sh [days]` | When you want to see indexing latency / backpressure per recent index. Default 30 days |
| `node-detail.sh <node>` | After identifying a suspect node (e.g. one in NODE_LEFT, or with high GC). Pass the node name like `es4-148-gra2`, not the node id |
| `index-detail.sh <index>` | When a specific index is mentioned in logs (e.g. throttle line) or in the recovery queue. Pass full name like `history_2024-11-06` |

## Response format

When done analyzing, write the user-facing report in this shape:

1. **Status line** (1–2 sentences): overall verdict — healthy, yellow-in-recovery, write-throttled, etc. Include the cluster status and the headline number.
2. **What's going on** (3–6 bullets): the actual anomalies found, with concrete numbers (e.g. "245 unassigned shards on cold storage, caused by 2 nodes that flapped (es4-122-gra2, es4-148-gra2) — both showed Full GC pauses of 20s and 60s respectively").
3. **Why it matters / what's at risk** (optional, only if non-trivial): downstream effects worth flagging (e.g. risk of cascading flap if write load grows).
4. **Recommendations** (1–3 actions): only the ones supported by evidence we just saw. Cite the specific node/index/metric.

Do not dump raw script output. Synthesize.

## Conventions

- Container: `ingestor-php_fpm-1`. Proxy: `http://envoy:1064`. Override via env (`CONTAINER_NAME`, `ES_PROXY`) if needed.
- Scripts are read-only HTTP GETs. Safe to run repeatedly.
- All scripts exit cleanly with a clear message if the container is down.

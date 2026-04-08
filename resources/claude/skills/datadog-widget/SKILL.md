---
name: datadog-widget
description: Generate correct, production-ready Datadog widget JSON for timeseries, query table, and sunburst visualizations. Use this skill whenever the user asks for a Datadog dashboard widget, says "give me the JSON for...", pastes a widget JSON for review or improvement, or describes a metric they want to graph. Handles all the tricky correctness details: aggregator per metric type, rollup for sparse gauges, aliases, number formats, palette choices, markers, and formula operator precedence.
---

# Datadog Widget JSON Generator

Generate production-ready Datadog widget JSON. The most common source of broken graphs is wrong aggregator or missing rollup — always identify the metric type first.

## Step 1 — Identify the metric type

### Counter (`Metrics::increment()`)
- Aggregator: `sum`
- Always append `.as_count()`
- Display: `bars`
- Unit: `occurrence`

```
sum:my.metric{*}.as_count()
```

### Gauge (`Metrics::measure()`)
- Aggregator: `max`
- NO `.as_count()`
- If emitted **once per cron run** (sparse): add `.as_count().rollup(max, <interval_seconds>)`
  - Hourly cron → `.rollup(max, 3600)`
  - 5-min cron → `.rollup(max, 300)`
- Without rollup, Datadog averages sparse values across empty intervals → shows 0.002 instead of 5
- Display: `line`

```
max:my.metric{*}.as_count().rollup(max, 3600)
```

### Distribution (`Metrics::distribution()`)
- If percentiles **enabled**: use `p50`, `p95`, `p99`
- If percentiles **not enabled**: use `avg` + `max` as two separate request blocks
  - `avg` → solid green (trend)
  - `max` → dashed thin warm (outliers)
- Display: `line`

---

## Step 2 — Rules that apply to every widget

1. **Add `alias` to every formula** — without it the legend shows the raw metric name
2. **Add `yaxis: { "min": "0", "include_zero": true }`** — always
3. **Remove `"order_by": "values"`** from `style` on single-series graphs — no effect

---

## Common mistakes

| Mistake | Fix |
|---|---|
| `avg` + `.as_count()` | `.as_count()` only with `sum` |
| Sparse gauge without `.rollup()` | Add `.as_count().rollup(max, <interval>)` |
| `canonical_unit` with `%` → shows `%s` | Use `custom_unit_label` with `label: "%"` or omit `number_format` |
| `query1 / (query1 + query2 * 100)` | Wrong precedence → `(query1 / (query1 + query2)) * 100` |
| 4 formulas in sunburst → 4 slices | Only include formulas you want rendered as slices |
| `"legend": { "type": "none" }` in sunburst | Use `"automatic"` — `none` removes all labels |
| `"order_by": "values"` on single-series | Remove it |

---

## Number format reference

| Use case | Config |
|---|---|
| Duration (ms) | `{ "type": "canonical_unit", "unit_name": "millisecond" }` |
| Count / events | `{ "type": "canonical_unit", "unit_name": "occurrence" }` |
| Percentage | `{ "type": "custom_unit_label", "label": "%" }` or omit entirely |
| Custom label | `{ "type": "custom_unit_label", "label": "quota units" }` |
| Rate per hour | `{ "type": "custom_unit_label", "label": "units/hour" }` |

---

## Palette guidelines

| Use case | Palette |
|---|---|
| Health / success | `green` |
| Errors / failures | `warm` |
| Critical errors | `red` |
| Distribution avg | `green` (solid) |
| Distribution max | `warm` (dashed thin) |
| Multi-series by tag | `datadog16` |
| General / neutral | `dog_classic` |

---

## Marker `display_type` values

| Intent | Value |
|---|---|
| Hard limit | `"error solid"` |
| Near-limit | `"error dashed"` |
| Soft warning | `"warning dashed"` |
| Healthy target | `"ok dashed"` |

---

## Widget templates

### Counter — bars
```json
{
    "title": "...",
    "type": "timeseries",
    "requests": [
        {
            "response_format": "timeseries",
            "queries": [
                {
                    "name": "query1",
                    "data_source": "metrics",
                    "query": "sum:my.metric{*}.as_count()"
                }
            ],
            "formulas": [
                {
                    "alias": "Human readable name",
                    "formula": "query1",
                    "number_format": {
                        "unit": { "type": "canonical_unit", "unit_name": "occurrence" }
                    }
                }
            ],
            "style": { "palette": "green", "line_type": "solid", "line_width": "normal" },
            "display_type": "bars"
        }
    ],
    "yaxis": { "min": "0", "include_zero": true }
}
```

### Sparse gauge — line with rollup
```json
{
    "title": "...",
    "type": "timeseries",
    "requests": [
        {
            "response_format": "timeseries",
            "queries": [
                {
                    "name": "query1",
                    "data_source": "metrics",
                    "query": "max:my.metric{*}.as_count().rollup(max, 3600)"
                }
            ],
            "formulas": [
                {
                    "alias": "Human readable name",
                    "formula": "query1",
                    "number_format": {
                        "unit": { "type": "custom_unit_label", "label": "buckets" }
                    }
                }
            ],
            "style": { "palette": "dog_classic", "line_type": "solid", "line_width": "normal" },
            "display_type": "line"
        }
    ],
    "yaxis": { "min": "0", "include_zero": true }
}
```

### Distribution — avg + max (no percentiles)
```json
{
    "title": "...",
    "type": "timeseries",
    "requests": [
        {
            "response_format": "timeseries",
            "queries": [
                { "name": "avg_q", "data_source": "metrics", "query": "avg:my.metric{*}" }
            ],
            "formulas": [
                {
                    "alias": "Avg duration",
                    "formula": "avg_q",
                    "number_format": { "unit": { "type": "canonical_unit", "unit_name": "millisecond" } }
                }
            ],
            "style": { "palette": "green", "line_type": "solid", "line_width": "normal" },
            "display_type": "line"
        },
        {
            "response_format": "timeseries",
            "queries": [
                { "name": "max_q", "data_source": "metrics", "query": "max:my.metric{*}" }
            ],
            "formulas": [
                {
                    "alias": "Max duration",
                    "formula": "max_q",
                    "number_format": { "unit": { "type": "canonical_unit", "unit_name": "millisecond" } }
                }
            ],
            "style": { "palette": "warm", "line_type": "dashed", "line_width": "thin" },
            "display_type": "line"
        }
    ],
    "yaxis": { "min": "0", "include_zero": true }
}
```

### Timeseries with threshold markers
```json
{
    "title": "...",
    "type": "timeseries",
    "requests": [...],
    "yaxis": { "min": "0", "max": "15150000" },
    "markers": [
        { "label": " Hard limit ", "value": "y = 15150000", "display_type": "error solid" },
        { "label": " 92% ",        "value": "y = 13938000", "display_type": "error dashed" },
        { "label": " 79% ",        "value": "y = 12000000", "display_type": "warning dashed" }
    ]
}
```

### Success rate formula
```json
{
    "title": "... success rate",
    "type": "timeseries",
    "requests": [
        {
            "response_format": "timeseries",
            "queries": [
                { "name": "succeeded", "data_source": "metrics", "query": "sum:my.succeeded{*}.as_count()" },
                { "name": "failed",    "data_source": "metrics", "query": "sum:my.failed{*}.as_count()" }
            ],
            "formulas": [
                {
                    "alias": "Success rate",
                    "formula": "(succeeded / (succeeded + failed)) * 100"
                }
            ],
            "style": { "palette": "green", "line_type": "solid", "line_width": "normal" },
            "display_type": "line"
        }
    ],
    "yaxis": { "min": "0", "max": "100" },
    "markers": [
        { "label": " 100% ", "value": "y = 100", "display_type": "ok dashed" },
        { "label": " 95% ",  "value": "y = 95",  "display_type": "warning dashed" }
    ]
}
```

### Query table (HTTP codes, top lists)
```json
{
    "title": "...",
    "type": "query_table",
    "requests": [
        {
            "queries": [
                {
                    "name": "query1",
                    "data_source": "metrics",
                    "query": "sum:my.metric{*} by {tag}.as_count()",
                    "aggregator": "sum"
                }
            ],
            "response_format": "scalar",
            "sort": {
                "count": 500,
                "order_by": [{ "type": "formula", "index": 0, "order": "desc" }]
            },
            "formulas": [
                {
                    "formula": "query1",
                    "alias": "Human readable name",
                    "cell_display_mode": "bar"
                }
            ]
        }
    ],
    "has_search_bar": "auto"
}
```

### Sunburst (split by weighted cost)
```json
{
    "title": "...",
    "type": "sunburst",
    "requests": [
        {
            "response_format": "scalar",
            "queries": [
                { "name": "q1", "data_source": "metrics", "query": "sum:my.metric{tag:a}.as_count()", "aggregator": "sum" },
                { "name": "q2", "data_source": "metrics", "query": "sum:my.metric{tag:b}.as_count()", "aggregator": "sum" }
            ],
            "formulas": [
                { "alias": "Slice A", "formula": "q1 * 100" },
                { "alias": "Slice B", "formula": "q2" }
            ],
            "sort": { "count": 500, "order_by": [{ "type": "formula", "index": 0, "order": "desc" }] },
            "style": { "palette": "datadog16" }
        }
    ],
    "legend": { "type": "automatic" }
}
```

---

## Derivative / burn rate

`derivative()` returns units/second. Multiply to match the title:

```json
"formula": "derivative(query1) * 3600"
```

- `* 3600` → units/hour
- `* 60` → units/minute

---

## Grouped metrics (`by {tag}`)

Adding `by {tag}` produces one series per tag value automatically. Use `datadog16` palette. Filter with `{tag:value}` to include or `{!tag:value}` to exclude:

```
sum:my.metric{!outcome:success} by {http_status}.as_count()
```

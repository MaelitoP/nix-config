usage() {
  cat >&2 <<'EOF'
Usage:
  grafana render <target> [from] [until]   Graphite series as JSON (from: -1h, until: now)
  grafana find <query>                     Graphite metric names matching a glob
  grafana get <path>                       Read-only Grafana API call, e.g. /api/search?query=Augmenter
EOF
  exit 2
}

request() {
  {
    printf 'cert = %s\n' "$(jq -n --arg v "$P12_PATH" '$v')"
    printf 'cert-type = "P12"\n'
    printf 'pass = %s\n' "$(jq -Rs 'rtrimstr("\n")' "$P12_PASSWORD_FILE")"
    printf 'header = %s\n' "$(jq -Rs '"Authorization: Bearer " + rtrimstr("\n")' "$TOKEN_FILE")"
  } | curl --silent --show-error --fail-with-body --config - "$@"
}

graphite="$GRAFANA_URL/api/datasources/proxy/uid/$GRAPHITE_UID"

case "${1:-}" in
  render)
    [ $# -ge 2 ] || usage
    request --get "$graphite/render" \
      --data-urlencode "target=$2" \
      --data-urlencode "from=${3:--1h}" \
      --data-urlencode "until=${4:-now}" \
      --data-urlencode "format=json"
    ;;
  find)
    [ $# -eq 2 ] || usage
    request --get "$graphite/metrics/find" --data-urlencode "query=$2"
    ;;
  get)
    [ $# -eq 2 ] || usage
    case "$2" in
      /api/*) request "$GRAFANA_URL$2" ;;
      *) usage ;;
    esac
    ;;
  *)
    usage
    ;;
esac

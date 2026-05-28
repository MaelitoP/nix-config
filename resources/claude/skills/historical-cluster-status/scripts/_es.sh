#!/usr/bin/env bash
# Source-only helper for the cluster-status skill.
# Defines:
#   - es_get <path>       wraps `docker exec ... curl http://envoy:1064/<path>`
#   - require_es          aborts if the container isn't reachable
#
# All cluster-status scripts source this file so the docker/curl plumbing
# stays in one place.

set -euo pipefail

ES_PROXY="${ES_PROXY:-http://envoy:1064}"
CONTAINER_NAME="${CONTAINER_NAME:-ingestor-php_fpm-1}"

es_get() {
    local path="$1"
    local body status attempt
    # Retry on 5xx (envoy 503 "overflow" trips on concurrent calls when the
    # skill injects multiple scripts in parallel). 1 attempt + 3 retries.
    local delays=("" "0.2" "0.5" "1.0")
    for delay in "${delays[@]}"; do
        [[ -n "$delay" ]] && sleep "$delay"
        body="$(docker exec "$CONTAINER_NAME" curl -sS -XGET -w $'\n%{http_code}' "${ES_PROXY}/${path}")" \
            || { echo "ERROR: curl failed for ${path}" >&2; return 3; }
        status="${body##*$'\n'}"
        body="${body%$'\n'*}"
        if [[ "$status" == 2* ]] && [[ -n "$body" ]]; then
            printf '%s' "$body"
            return 0
        fi
        # 4xx: client error, no point retrying.
        if [[ "$status" == 4* ]]; then
            echo "ERROR: ES request failed for ${path}: HTTP ${status}, body=${body:0:200}" >&2
            return 3
        fi
        # 5xx / other: fall through to next delay or exit loop.
    done
    echo "ERROR: ES request failed for ${path} after retries: HTTP ${status:-?}, body=${body:0:200}" >&2
    return 3
}

require_es() {
    if ! docker exec "$CONTAINER_NAME" true 2>/dev/null; then
        echo "ERROR: container '$CONTAINER_NAME' not running." >&2
        echo "Start dev-env (./devenv.sh up) or set CONTAINER_NAME=<your-container>." >&2
        exit 2
    fi
}

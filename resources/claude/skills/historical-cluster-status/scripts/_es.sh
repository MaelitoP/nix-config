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
    docker exec "$CONTAINER_NAME" curl -s -XGET "${ES_PROXY}/${path}"
}

require_es() {
    if ! docker exec "$CONTAINER_NAME" true 2>/dev/null; then
        echo "ERROR: container '$CONTAINER_NAME' not running." >&2
        echo "Start dev-env (./devenv.sh up) or set CONTAINER_NAME=<your-container>." >&2
        exit 2
    fi
}

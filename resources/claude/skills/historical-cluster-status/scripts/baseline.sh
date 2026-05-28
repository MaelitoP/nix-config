#!/usr/bin/env bash
# Sequentially runs the 3 baseline scripts and prints their output under
# section headers. Sequential is intentional: running them concurrently
# trips envoy's circuit breaker ("overflow") on the way out of php_fpm.

set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"

echo "### Cluster health"
"$DIR/health.sh"
echo
echo "### Recovery state"
"$DIR/recovery.sh"
echo
echo "### Write pressure"
"$DIR/write-pressure.sh"

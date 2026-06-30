#!/bin/bash
# Update NVD database in assets/ using ODC data feed.
# Avoids NVD API 503 errors by fetching from the ODC-maintained cache.
# See: https://github.com/dependency-check/DependencyCheck/discussions/8633

set -eux

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="$SCRIPT_DIR/assets"
IMAGE_TAG="dependency-check-update:local"
ODC_DATAFEED_URL="https://dependency-check.github.io/DependencyCheck_Builder/nvd_cache/nvdcve-{0}.json.gz"

docker build -t "$IMAGE_TAG" "$SCRIPT_DIR"

docker run --rm \
    -v "$DATA_DIR:/opt/dependency-check/data" \
    "$IMAGE_TAG" \
    /opt/dependency-check/bin/dependency-check.sh \
    --updateonly \
    --data /opt/dependency-check/data \
    --nvdDatafeed "$ODC_DATAFEED_URL"

# Remove lock file left by the update process
rm -f "$DATA_DIR/odc.update.lock"

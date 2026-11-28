#!/usr/bin/env bash
set -euo pipefail

NEW_IMAGE="$1"
CONTAINER_NAME="status-api"
PREVIOUS_IMAGE=""

if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    PREVIOUS_IMAGE=$(docker inspect --format='{{.Config.Image}}' "$CONTAINER_NAME")
    echo "Replacing running image: $PREVIOUS_IMAGE"
    docker rm -f "$CONTAINER_NAME"
fi

echo "Starting new image: $NEW_IMAGE"
docker run -d --name "$CONTAINER_NAME" -p 8080:8080 "$NEW_IMAGE"

for i in $(seq 1 10); do
    if curl -fsS http://localhost:8080/health/ready > /dev/null; then
        echo "[SUCCESS] $NEW_IMAGE passed readiness check"
        exit 0
    fi
    echo "Waiting for app to become ready ($i/10)..."
    sleep 2
done

echo "[ERROR] $NEW_IMAGE failed readiness check. Rolling back..."
docker rm -f "$CONTAINER_NAME" || true

if [ -n "$PREVIOUS_IMAGE" ]; then
    docker run -d --name "$CONTAINER_NAME" -p 8080:8080 "$PREVIOUS_IMAGE"
    echo "[ROLLBACK COMPLETE] Restored $PREVIOUS_IMAGE"
fi

exit 1
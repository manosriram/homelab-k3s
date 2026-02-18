#!/bin/bash

source ~/.bashrc;

source /fs/lab/k3s/scripts/envinit.sh;

# Exit if no tag argument is provided
[ -z "$1" ] && { echo "Usage: $0 <tag>"; exit 1; }
TAG="$1" # Assign the provided tag

# Paths to backup
BACKUP_PATHS="/fs/backups /fs/lab/ /fs/k3s/storage/"

restic unlock;

# K8s pvc backup; stored at /fs/k3s/storage
TIMESTAMP=$(date +%d-%m-%Y-%H%M%S)
BACKUP_NAME="backup-${TIMESTAMP}"

if [ "$TAG" == "daily" ]; then
    TTL="720h0m0s"   # 30 Days
elif [ "$TAG" == "monthly" ]; then
    TTL="8760h0m0s"  # 1 Year (365 days)
fi

echo "Starting Velero backup: ${BACKUP_NAME} with TTL ${TTL}"

velero backup create "${BACKUP_NAME}" \
    --default-volumes-to-fs-backup \
    --ttl "$TTL" \
    --labels schedule="$TAG" \
    --wait

echo "Finished Velero backup: ${BACKUP_NAME}"

restic backup --tag "$TAG" $BACKUP_PATHS \
    && echo "Backup with tag '$TAG' completed." \
    || { echo "Backup FAILED!"; exit 1; }

# Conditional curl notification based on tag
if [[ "$TAG" == "daily" ]]; then
	curl -s -X POST -H 'Content-Type: application/json' -d '{"text":"Daily backup completed!"}' $DAILY_HEALTHCHECKS_URL \
		&& echo "Daily curl notification sent."
elif [[ "$TAG" == "monthly" ]]; then
	curl -s -X POST -H 'Content-Type: application/json' -d '{"text":"Monthly backup completed!"}' $MONTHLY_HEALTHCHECKS_URL \
		&& echo "Monthly curl notification sent."
fi

restic forget --tag daily  --prune --keep-last 60  --retry-lock 5m \
    && echo "Daily retention applied."   || echo "Daily retention FAILED!"

restic forget --tag monthly --prune --keep-last 36 --retry-lock 5m \
    && echo "Monthly retention applied." || echo "Monthly retention FAILED!"

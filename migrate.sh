#!/bin/bash

SENSOR_DATA_DB_DIR="/var/lib/sensor-data"
SENSOR_DATA_DB="${SENSOR_DATA_DB_DIR}/sensor-data.db"

ROOT_UID=0
E_NOTROOT=87

# Run as root, of course.
if [ "$UID" -ne "$ROOT_UID" ]; then
  echo "Must be root to run this script."
  exit $E_NOTROOT
fi

echo "Stopping measurement service..."
systemctl stop sensor-data.service

echo "Making backup of database at ${SENSOR_DATA_DB}-bak..."
cp "${SENSOR_DATA_DB}" "${SENSOR_DATA_DB}-bak"
echo "Converting data..."
sqlite3 "${SENSOR_DATA_DB}" < migration.sql

"Installing new version of application..."
./install.sh > /dev/null

echo "Starting measurement service..."
systemctl daemon-reload
systemctl start sensor-data.service

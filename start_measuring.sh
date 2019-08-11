#!/bin/bash

set -e

ROOT_UID=0
E_NOTROOT=87

# Run as root, of course.
if [ "$UID" -ne "$ROOT_UID" ]
then
  echo "Must be root to run this script."
  exit $E_NOTROOT
fi

PROGRAM_DIR="/opt/sensor-data"
VENV_DIR="${PROGRAM_DIR}/venv"
SCRIPT_NAME="bme280_sensor.py"

if modprobe i2c_dev > /dev/null; then
    echo "Loaded the kernel module \"i2c_dev\""
else
    echo "Could not load kernel module \"i2c_dev\"."
    exit 1
fi

cd "${PROGRAM_DIR}"
. "${VENV_DIR}/bin/activate"
python "${SCRIPT_NAME}"

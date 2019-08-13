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
SCRIPT_NAME="lcdscreen.py"

cd "${PROGRAM_DIR}"
. "${VENV_DIR}/bin/activate"
python "${SCRIPT_NAME}"

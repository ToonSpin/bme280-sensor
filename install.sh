#!/bin/bash

PROGRAM_DIR="/opt/sensor-data"
VENV_DIR="${PROGRAM_DIR}/venv"
SCRIPT_NAME="bme280_sensor.py"
ENTRY_POINT="start_measuring.sh"
SENSOR_DATA_DB="/var/lib/sensor-data/sensor-data.db"
SYSTEMD_UNIT_LOCATION="/etc/systemc/system/sensor-data.service"

PACKAGES_NEEDED="python3 python3-venv"
FILES_NEEDED="requirements.txt ${ENTRY_POINT} ${SCRIPT_NAME}"

E_NOTROOT=87

# Run as root, of course.
if [ "$UID" -ne "$ROOT_UID" ]; then
  echo "Must be root to run this script."
  exit $E_NOTROOT
fi

for package in $PACKAGES_NEEDED; do
    if dpkg -l | grep "${package}" > /dev/null; then
        echo "Found package \"${package}\"."
    else
        echo "Could not find required package \"${package}\". You can install it by running:"
        echo
        echo "sudo apt-get install ${package}"
        exit 1
    fi
done

for file in $FILES_NEEDED; do
    if [ -e "$file" ]; then
        echo "Found file \"${file}\"."
    else
        echo "Could not find required file \"${file}\". Please go into the project root and run this command again."
        exit 1
    fi
done

if modprobe i2c_dev > /dev/null; then
    echo "Loaded the kernel module \"i2c_dev\"."
else
    echo "Could not load kernel module \"i2c_dev\". The program will not work without it."
    exit 1
fi

mkdir -p "${PROGRAM_DIR}"
mkdir -p "${VENV_DIR}"

for file in $FILES_NEEDED; do
    cp "${file}" "${PROGRAM_DIR}"
done

echo "Installing the program and its Python dependencies in ${PROGRAM_DIR}."
cd "${PROGRAM_DIR}"
python3 -m venv "${VENV_DIR}"
. "${VENV_DIR}/bin/activate"
pip install -r requirements.txt

echo
echo "Installing systemd unit at ${SYSTEMD_UNIT_LOCATION}."
cat > "${SYSTEMD_UNIT_LOCATION}" << SYSTEMD_UNIT
[Unit]
Description=Sensor data measurement

[Service]
Type=simple
ExecStart=${PROGRAM_DIR}/${ENTRY_POINT}
Environment=SENSOR_DATA_DB=${SENSOR_DATA_DB}

[Install]
WantedBy=multi-user.target
SYSTEMD_UNIT

echo "All done, you can run the following commands to start measuring now and automatically after each reboot. The data will be written to ${SENSOR_DATA_DB}".
echo
echo "sudo systemctl daemon-reload"
echo "sudo systemctl enable $(basename ${SYSTEMD_UNIT_LOCATION})"
echo "sudo systemctl start $(basename ${SYSTEMD_UNIT_LOCATION})"

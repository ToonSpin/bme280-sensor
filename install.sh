#!/bin/bash

set -e

PROGRAM_DIR="/opt/sensor-data"
VENV_DIR="${PROGRAM_DIR}/venv"
SENSOR_DATA_DB_DIR="/var/lib/sensor-data"

SCRIPT_NAME_SENSOR="bme280_sensor.py"
ENTRY_POINT_SENSOR="start_measuring.sh"
SYSTEMD_UNIT_LOCATION_SENSOR="/etc/systemd/system/sensor-data.service"

SCRIPT_NAME_LCDSCREEN="lcdscreen.py"
ENTRY_POINT_LCDSCREEN="start_polling.sh"
SYSTEMD_UNIT_LOCATION_LCDSCREEN="/etc/systemd/system/lcd-screen.service"

SCRIPT_NAME_WEBVIEW="webview.py"
ENTRY_POINT_WEBVIEW="start_webview.sh"
SYSTEMD_UNIT_LOCATION_WEBVIEW="/etc/systemd/system/sensor-data-webview.service"

SENSOR_DATA_DB="${SENSOR_DATA_DB_DIR}/sensor-data.db"

PACKAGES_NEEDED="python3 python3-venv"
FILES_NEEDED="requirements.txt ${ENTRY_POINT_SENSOR} ${SCRIPT_NAME_SENSOR} ${ENTRY_POINT_LCDSCREEN} ${SCRIPT_NAME_LCDSCREEN} ${ENTRY_POINT_WEBVIEW} ${SCRIPT_NAME_WEBVIEW} Adafruit_CharLCD Adafruit_GPIO templates"

ROOT_UID=0
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
    echo "Could not load kernel module \"i2c_dev\". The sensor program will not work without it."
    exit 1
fi

echo "Copying required files to ${PROGRAM_DIR}."
mkdir -p "${PROGRAM_DIR}"
mkdir -p "${VENV_DIR}"
mkdir -p "${SENSOR_DATA_DB_DIR}"

for file in $FILES_NEEDED; do
    cp -r "${file}" "${PROGRAM_DIR}"
done

echo "Installing the program and its Python dependencies in ${PROGRAM_DIR}:"
cd "${PROGRAM_DIR}"
echo "  Creating virtual environment."
python3 -m venv "${VENV_DIR}"
echo "  Activating virtual environment."
. "${VENV_DIR}/bin/activate"
echo "  Installing Python modules into virtual environment."
pip install -r requirements.txt

echo
echo "Installing systemd unit at ${SYSTEMD_UNIT_LOCATION_SENSOR}."
cat > "${SYSTEMD_UNIT_LOCATION_SENSOR}" << SYSTEMD_UNIT
[Unit]
Description=Sensor data measurement

[Service]
Type=simple
ExecStart=${PROGRAM_DIR}/${ENTRY_POINT_SENSOR}
RestartSec=10
Restart=always
Environment=SENSOR_DATA_DB=${SENSOR_DATA_DB}

[Install]
WantedBy=multi-user.target
SYSTEMD_UNIT

echo
echo "Installing systemd unit at ${SYSTEMD_UNIT_LOCATION_LCDSCREEN}."
cat > "${SYSTEMD_UNIT_LOCATION_LCDSCREEN}" << SYSTEMD_UNIT
[Unit]
Description=LCD Screen Updater

[Service]
Type=simple
ExecStart=${PROGRAM_DIR}/${ENTRY_POINT_LCDSCREEN}
RestartSec=10
Restart=always
Environment=SENSOR_DATA_DB=${SENSOR_DATA_DB}

[Install]
WantedBy=multi-user.target
SYSTEMD_UNIT

echo
echo "Installing systemd unit at ${SYSTEMD_UNIT_LOCATION_WEBVIEW}."
cat > "${SYSTEMD_UNIT_LOCATION_WEBVIEW}" << SYSTEMD_UNIT
[Unit]
Description=Web view into temperature data running on port 8000.

[Service]
Type=simple
ExecStart=${PROGRAM_DIR}/${ENTRY_POINT_WEBVIEW}
RestartSec=10
Restart=always
Environment=SENSOR_DATA_DB=${SENSOR_DATA_DB}

[Install]
WantedBy=multi-user.target
SYSTEMD_UNIT

echo
echo "All done."
echo "You can run the following commands to start measuring now and automatically after each reboot. The data will be written to ${SENSOR_DATA_DB}".
echo
echo "sudo systemctl daemon-reload"
echo "sudo systemctl enable $(basename ${SYSTEMD_UNIT_LOCATION_SENSOR})"
echo "sudo systemctl start $(basename ${SYSTEMD_UNIT_LOCATION_SENSOR})"
echo
echo "You can run the following commands to have the LCD screen start reading and displaying data. The data will be read from ${SENSOR_DATA_DB}".
echo
echo "sudo systemctl daemon-reload"
echo "sudo systemctl enable $(basename ${SYSTEMD_UNIT_LOCATION_LCDSCREEN})"
echo "sudo systemctl start $(basename ${SYSTEMD_UNIT_LOCATION_LCDSCREEN})"
echo
echo "You can run the following commands to get the webview up and running on port 8000. The data will be read from ${SENSOR_DATA_DB}".
echo
echo "sudo systemctl daemon-reload"
echo "sudo systemctl enable $(basename ${SYSTEMD_UNIT_LOCATION_WEBVIEW})"
echo "sudo systemctl start $(basename ${SYSTEMD_UNIT_LOCATION_WEBVIEW})"

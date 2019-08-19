# temperature-sensor

This code can read out a BME280 temperature sensor, store the measurements in a
database and display them on an LCD screen. To do this, I had to get my
Raspberry Pi ready, and for the sake of completenesss I'll add all the steps, so
I can easily replicate it on another Raspberry Pi.

## General Raspberry Pi setup stuff:

1. Download Raspbian and create a bootable SD card.
2. In the `/boot` partition, add an empty file called `ssh` to get the Pi to use
   SSH, so you don't have to connect a monitor to it to get into it.
3. In the `/boot` partition, add a file called `wpa_supplicant.conf` with the
   below contents, with the configuration of my WiFi access point. This will
   make the Pi connect to WiFi automatically by placing the configuration file
   at the right path.
4. Create a user called `toon` for myself, and create a `sudoers` file at
   `/etc/sudoers.d/010_toon-nopasswd` with the contents
   `toon ALL=(ALL) NOPASSWD: ALL`. Verify that `sudo` still works after that.
5. Destroy the password for `pi` by editing `/etc/shadow`.

The contents of `/boot/wpa_supplicant.conf`:

    country=NL
    ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
    network={
        ssid="MY_WIFI_SSID"
        psk="MY_WIFI_SSID_PASSPHRASE"
        key_mgmt=WPA-PSK
    }

## Connecting the sensor

The sensor package this script was built for, namely the Velleman VMA335, uses
I2C address 0x76 and port 1. With the systemd unit you should be able to set an
environment variable to modify the script's behavior but I have not tried that
yet.

Find Raspberry Pi pinout diagrams at [pinout.xyz](https://pinout.xyz/). Connect
the pins as follows:

* Connect a 3.3 volt pin (**do not** use a higher voltage!) on the Pi, to the
  `VCC` pin on the sensor.
* Connect a ground pin on the Pi, to the `GND` pin on the sensor.
* Connect the `SDA` pin on the Pi to the `SDA` pin on the sensor.
* Connect the `SDC` pin on the Pi to the `SDC` pin on the sensor.

## Connecting the LCD screen

The LCD screen operates in 4 bit mode, and the one I use is backlit, so it will
need 12 of its pins connected to the Raspberry Pi.

The following pins need to be connected:

|Pin|Connection       |
|---|-----------------|
|1  |Ground           |
|2  |5V               |
|3  |_See below_      |
|4  |Board 22, BCM 25 |
|5  |Ground           |
|6  |Board 18, BCM 24 |
|7  |_do not connect_ |
|8  |_do not connect_ |
|9  |_do not connect_ |
|10 |_do not connect_ |
|11 |Board 16, BCM 23 |
|12 |Board 11, BCM 17 |
|13 |Board 12, BCM 18 |
|14 |Board 15, BCM 22 |
|15 |5V               |
|16 |Ground           |

You need to connect both a 1kOhm resistor and a 2.2kOhm resistor to pin 3. The
1kOhm resistor needs to be connected to 5V and the 2.2kOhm one to ground.

## Python setup:

`install.sh` will do the following:

1. `sudo modprobe i2c_dev`
2. Check for the correct Python packages, and say which `apt-get install`
   commands you need to run if you don't have them
3. Install the necessary scripts and set up a venv at `/opt/sensor-data`
4. Install systemd units and explain how to use them.

Data will end up in the SQLite database `/var/lib/sensor-data/sensor-data.db`.

Enabling and starting the systemd services should take care of everything. There
are three units that are installed by the install script:

* `sensor-data.service` collects the sensor data from the sensor and stores it
  in the database;
* `lcd-screen.service` polls the database and displays the last five seconds'
  worth of data on the LCD screen connected to the Raspberry Pi;
* `sensor-data-webview.service` serves a web site on port 8000 which displays a
  graph of the temperature data.

## Database and sensor data notes

The SQLite backend I've made uses `FLOAT`s as columns for the sensor data. The
reason is pretty unelegant: I wanted to use `DECIMAL`s but it turns out SQLite
would have just made `FLOAT`s out of those.

The sensor returns float data because it can measure fractional quantities.
According to [Bosch's data
sheet](https://ae-bst.resource.bosch.com/media/_tech/media/datasheets/BST-BME280-DS002.pdf)
of the BME280 sensor, the tolerances are:

* Temperature: +/- 1.0 degrees Celcius between 0 and 65 degrees Celcius,
* Humidity: +/- 3% relative humidity,
* Pressure: +/- 1.0 HPa between 0 and 65 degrees Celcius.

Anecdotally, however, the sensor seems to be accurate to well within the
following tolerances:

* Temperature: +/- 0.1 degrees Celcius between 0 and 65 degrees Celcius,
* Humidity: +/- 0.5% relative humidity,
* Pressure: +/- 0.5 HPa between 0 and 65 degrees Celcius.

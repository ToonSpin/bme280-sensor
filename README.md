# temperature-sensor

This code can read out a BME280 temperature sensor. To do this, I had to get my
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

## Python setup:

1. Add the line `i2c-dev` to `/etc/modules` and then `sudo modprobe i2c-dev`
2. `sudo apt-get install python3-venv`
3. Create a venv somewhere: `python3 -m venv $SOME_VENV_DIRECTORY`
4. Activate it: `. $SOME_VENV_DIRECTORY/bin/activate`
5. Install the Python modules in the virtual environment, by going to the
   project root and running `pip install -r requirements.txt`
6. Deactivate while the virtual environment is active by running `deactivate`.

## Running the python script:

1. `. $SOME_VENV_DIRECTORY/bin/activate`
2. `sudo python bme280_sensor.py`. `sudo` is necessary to be able to read from
   `/dev/i2c-1`.

That should be enough to get the script working as I've committed it now.

# temperature-sensor

This code can read out a BME280 temperature sensor. To do this, I had to get my
Raspberry Pi ready, and for completeness's sake I'll add all the steps to it so
I can easily replicate it on another Raspberry Pi.

1. Download Raspbian and create a bootable SD card.
2. In the /boot partition, add an empty file called `ssh` to get the Pi to use
   SSH so you don't have to connect a monitor to it to get into it.
3. In the /boot partition, add a file called `wpa_supplicant.conf` with the
   below contents, with the configuration of my WiFi access point. This will
   make the Pi connect to WiFI automatically by placing the configuration file
   at the right path.
4. Create a user for myself, and create `/etc/sudoers.d/010_toon-nopasswd` with
   the contents `toon ALL=(ALL) NOPASSWD: ALL`. Verify that `sudo` still works
   after this.
5. Destroy the password for `pi` by editing `/etc/shadow`.
6. `sudo apt-get install python-pip`
7. `sudo pip install RPi.bme280` (possibly not needed if I use a venv)
8. Add the line `i2c-dev` to /etc/modules and then `sudo modprobe i2c-dev`

That should be enough to get the script working as I've committed it now.

The contents of `/boot/wpa_supplicant.conf`:

    country=NL
    ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
    network={
        ssid="MY_WIFI_SSID"
        psk="MY_WIFI_SSID_PASSPHRASE"
        key_mgmt=WPA-PSK
    }

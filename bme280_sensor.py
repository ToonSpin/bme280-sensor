import bme280
import smbus2
import sqlite3

from time import sleep
from pathlib import Path
from os import environ
from sys import exit


database_file = "./sensor-data.db"
address = 0x76
port = 1

if 'SENSOR_DATA_DB' in environ:
    database_file = environ['SENSOR_DATA_DB']

if 'SENSOR_DATA_ADDRESS' in environ:
    address = environ['SENSOR_DATA_ADDRESS']

if 'SENSOR_DATA_PORT' in environ:
    port = environ['SENSOR_DATA_PORT']


try:
    bus = smbus2.SMBus(port)
    bme280.load_calibration_params(bus,address)
except OSError:
    print("Error communicating with sensor!")
    exit(1)


db_file = Path(database_file)
if not db_file.is_file():
    try:
        db = sqlite3.connect(database_file)
        cursor = db.cursor()
        cursor.execute('''
            CREATE TABLE sensor_data (
                id INTEGER PRIMARY KEY,
                "timestamp" DATETIME,
                humidity FLOAT(32),
                pressure FLOAT(32),
                temperature FLOAT(32)
            );
        ''')
        cursor.execute('CREATE INDEX timestamp_ind ON sensor_data(timestamp);')
        db.commit()
        db.close()
    except sqlite3.Error:
        print("Error creating database!")
        exit(1)



db = sqlite3.connect(database_file)
cursor = db.cursor()
row_insert_query = 'INSERT INTO sensor_data ("timestamp", humidity, pressure, temperature) VALUES (datetime(\'now\'), ?, ?, ?);'

while True:
    bme280_data = bme280.sample(bus,address)
    try:
        cursor.execute(row_insert_query, (bme280_data.humidity, bme280_data.pressure, bme280_data.temperature))
        db.commit()
    except sqlite3.Error:
        print("Error writing measurement to database!")
    sleep(10)

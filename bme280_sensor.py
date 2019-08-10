import bme280
import smbus2
import sqlite3

from time import sleep
from pathlib import Path

port = 1
address = 0x76
database_file = "./sensor_data.db"

db_file = Path(database_file)
if not db_file.is_file():
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


bus = smbus2.SMBus(port)
bme280.load_calibration_params(bus,address)

db = sqlite3.connect(database_file)
cursor = db.cursor()
row_insert_query = 'INSERT INTO sensor_data ("timestamp", humidity, pressure, temperature) VALUES (datetime(\'now\'), ?, ?, ?);'

while True:
    bme280_data = bme280.sample(bus,address)
    cursor.execute(row_insert_query, (bme280_data.humidity, bme280_data.pressure, bme280_data.temperature))
    db.commit()
    sleep(1)

import Adafruit_CharLCD as LCD
import sqlite3
import signal

from time import sleep
from sys import exit
from os import environ


lcd_rs = 25
lcd_en = 24
lcd_d4 = 23
lcd_d5 = 17
lcd_d6 = 18
lcd_d7 = 22
lcd_backlight = 4
lcd_columns = 16
lcd_rows = 2


# Define LCD column and row size for 16x2 LCD.
lcd_columns = 16
lcd_rows = 2

lcd = LCD.Adafruit_CharLCD(lcd_rs, lcd_en, lcd_d4, lcd_d5, lcd_d6, lcd_d7, lcd_columns, lcd_rows, lcd_backlight)


def signal_handler(sig, frame):
    lcd.clear()
    exit(0)

signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGQUIT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)


database_file = "./sensor-data.db"
if 'SENSOR_DATA_DB' in environ:
    database_file = environ['SENSOR_DATA_DB']


data_select_query = '''
    SELECT
        AVG(temperature) AS temperature,
        AVG(humidity) AS humidity,
        AVG(pressure) AS pressure,
        COUNT(*) AS num_data_points
    FROM sensor_data
    WHERE
        "timestamp" > datetime('now', '-5 seconds')
'''

try:
    conn = sqlite3.connect(database_file)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
except sqlite3.Error:
    print("Error connecting database")
    lcd.clear()
    lcd.message("Database error")
    exit(1)

def get_message(row):
    if row['num_data_points'] == 0:
        return "No recent data,\ncheck status"
    temp = row['temperature']
    hum = int(row['humidity'])
    return "Temp: {:>9.1f}C\nHumidity: {:>5d}%".format(temp, hum)

try:
    while True:
        cursor.execute(data_select_query)
        row = cursor.fetchone()
        lcd.clear()
        lcd.message(get_message(row))
        sleep(2)
except sqlite3.Error:
    print("Error communicating with database")
    lcd.clear()
    lcd.message("Database error")
    exit(1)

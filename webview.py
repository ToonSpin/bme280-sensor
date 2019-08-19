import sqlite3
import json

from os import environ
from sys import exit

from flask import Flask, Response, render_template

database_file = "./sensor-data.db"
if 'SENSOR_DATA_DB' in environ:
    database_file = environ['SENSOR_DATA_DB']


def get_bounds_query(interval):
    data_select_query = '''
        SELECT
            strftime('%s', 'now') AS max_unix_timestamp,
            strftime('%s', 'now', '{interval}') AS min_unix_timestamp
    '''
    return data_select_query.format(interval=interval)


def get_query(interval, resolution):
    data_select_query = '''
        SELECT
            AVG(temperature) AS temperature,
            AVG(humidity) AS humidity,
            AVG(pressure) AS pressure,
            ROUND(AVG(strftime('%s', "timestamp"))) AS "measurement_unixtime",
            COUNT(*) AS num_data_points
        FROM sensor_data
        WHERE "timestamp" <= strftime('%Y-%m-%d %H:%M:%S', 'now')
          AND "timestamp" >= strftime('%Y-%m-%d %H:%M:%S', 'now', '{interval}')
        GROUP BY strftime('%s', "timestamp") / {resolution}
        ORDER BY "measurement_time"
    '''
    return data_select_query.format(interval=interval, resolution=resolution)


def row_to_dict(cursor, row):
    d = {}
    for index, column in enumerate(cursor.description):
        d[column[0]] = row[index]
    if 'temperature' in d:
        d['temperature'] = int(100 * d['temperature']) / 100
        d['humidity'] = int(100 * d['humidity']) / 100
        d['pressure'] = int(d['pressure'])
    return d


def get_cursor():
    conn = sqlite3.connect(database_file)
    conn.row_factory = row_to_dict
    return conn.cursor()

def get_empty_row(row):
    empty_row = row
    empty_row['temperature'] = None
    empty_row['humidity'] = None
    empty_row['pressure'] = None
    return empty_row

def get_data_by_interval(interval, resolution):
    data = get_cursor().execute(get_query(interval, resolution)).fetchall()
    if len(data) == 0:
        return []
    prev_row = data[0]
    response_data = [prev_row]

    for row in data[1:]:
        if int(row['measurement_unixtime']) - int(prev_row['measurement_unixtime']) > 2 * resolution:
            response_data.append(get_empty_row(row))
        response_data.append(row)
        prev_row = row

    return response_data

def get_bounds(interval):
    bounds = get_cursor().execute(get_bounds_query(interval)).fetchone()
    return bounds


app = Flask(__name__)

def get_response_by_interval(interval, resolution):
    data = get_data_by_interval(interval, resolution)
    bounds = get_bounds(interval)
    result = {
        "data": data,
        "bounds": bounds
    }
    return Response(json.dumps(result), mimetype='application/json')

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/onehour')
def onehour():
    return get_response_by_interval('-1 hours', 30)

@app.route('/threehours')
def threehours():
    return get_response_by_interval('-3 hours', 120)

@app.route('/oneday')
def oneday():
    return get_response_by_interval('-1 days', 15 * 60)

@app.route('/oneweek')
def oneweek():
    return get_response_by_interval('-7 days', 60 * 60)

@app.route('/fourweeks')
def fourweeks():
    return get_response_by_interval('-28 days', 120 * 60)

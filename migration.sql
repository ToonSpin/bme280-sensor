ALTER TABLE sensor_data RENAME TO sensor_data_old;
CREATE INDEX timestamp_ind_old ON sensor_data_old(timestamp);
DROP INDEX timestamp_ind;

CREATE TABLE sensor_data (
    id INTEGER PRIMARY KEY,
    "timestamp" DATETIME,
    humidity FLOAT(32),
    pressure FLOAT(32),
    temperature FLOAT(32)
);
CREATE INDEX timestamp_ind ON sensor_data(timestamp);

INSERT INTO sensor_data (temperature, humidity, pressure, "timestamp")
SELECT
    AVG(temperature) AS temperature,
    AVG(humidity) AS humidity,
    AVG(pressure) AS pressure,
    SUBSTR(DATETIME("timestamp"), 1, 18) || "0" AS "timestamp"
FROM sensor_data_old
GROUP BY ROUND(strftime('%s', "timestamp") / 10);

DROP TABLE sensor_data_old;

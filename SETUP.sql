CREATE DATABASE IF NOT EXISTS `weather`;
USE `weather`;

-- Create the Settings table if it doesn't exist
CREATE TABLE IF NOT EXISTS `RPiWx_SETTINGS` (
  `idSETTINGS` int(11) NOT NULL AUTO_INCREMENT,
  `NAME` varchar(45) DEFAULT NULL,
  `VALUE` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`idSETTINGS`),
  UNIQUE KEY `NAME_UNIQUE` (`NAME`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=latin1;

-- Create the WEATHER_MEASUREMENT table if it doesn't exist
CREATE TABLE IF NOT EXISTS `WEATHER_MEASUREMENT` (
  `ID` bigint(20) NOT NULL AUTO_INCREMENT,
  `REMOTE_ID` bigint(20) DEFAULT NULL,
  `AMBIENT_TEMPERATURE` decimal(6,2) NOT NULL,
  `GROUND_TEMPERATURE` decimal(6,2) NOT NULL,
  `AIR_QUALITY` decimal(6,2) NOT NULL,
  `AIR_PRESSURE` decimal(6,2) NOT NULL,
  `HUMIDITY` decimal(6,2) NOT NULL,
  `WIND_DIRECTION` decimal(6,2) DEFAULT NULL,
  `WIND_SPEED` decimal(6,2) NOT NULL,
  `WIND_GUST_SPEED` decimal(6,2) NOT NULL,
  `RAINFALL` decimal(6,4) DEFAULT NULL,
  `CREATED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=4126 DEFAULT CHARSET=latin1;

-- Add the known settings. This won't add them if they are there because of the Unique key constraint on the name column.
INSERT IGNORE INTO RPiWx_SETTINGS (name) VALUE ('WUNDERGROUND_ID');
INSERT IGNORE INTO RPiWx_SETTINGS (name) VALUE ('WUNDERGROUND_PASSWORD');
INSERT IGNORE INTO RPiWx_SETTINGS (`name`, `value`) VALUE ('showMetricAndCelsiusMeasurements', '1');
INSERT IGNORE INTO RPiWx_SETTINGS (`name`, `value`) VALUE ('showPressureInMillibars', '1');
INSERT IGNORE INTO RPiWx_SETTINGS (`name`, `value`) VALUE ('showPressureInMillibars', '0');

-- Create the stored procedures
DROP PROCEDURE IF EXISTS GETRECENTOBS;
DELIMITER $$
CREATE PROCEDURE `GETRECENTOBS`()
BEGIN
	(SELECT 
		*
	FROM
		WEATHER_MEASUREMENT
	ORDER BY created DESC
	LIMIT 1) UNION ALL (SELECT 
		*
	FROM
		WEATHER_MEASUREMENT
	WHERE
		CREATED <= DATE_SUB(NOW(), INTERVAL 1 HOUR)
	ORDER BY created DESC
	LIMIT 1) UNION ALL (SELECT 
		*
	FROM
		WEATHER_MEASUREMENT
	WHERE
		CREATED <= DATE_SUB(NOW(), INTERVAL 6 HOUR)
	ORDER BY created DESC
	LIMIT 1) UNION ALL (SELECT 
		*
	FROM
		WEATHER_MEASUREMENT
	WHERE
		CREATED <= DATE_SUB(NOW(), INTERVAL 12 HOUR)
	ORDER BY created DESC
	LIMIT 1) UNION ALL (SELECT 
		*
	FROM
		WEATHER_MEASUREMENT
	WHERE
		CREATED <= DATE_SUB(NOW(), INTERVAL 24 HOUR)
	ORDER BY created DESC
	LIMIT 1) UNION ALL (SELECT 
		*
	FROM
		WEATHER_MEASUREMENT
	WHERE
		CREATED <= DATE_SUB(NOW(), INTERVAL 48 HOUR)
	ORDER BY created DESC
	LIMIT 1);
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS GETDAILYRECORDS;
DELIMITER $$
CREATE PROCEDURE `GETDAILYRECORDS`()
BEGIN
    SELECT SUM(RAINFALL) FROM WEATHER_MEASUREMENT WHERE created >= DATE(NOW()) INTO @RainfallSinceMidnight;

    SELECT created FROM WEATHER_MEASUREMENT WHERE rainfall > 0 ORDER BY created DESC LIMIT 1 INTO @stormEnd;
    SELECT created FROM WEATHER_MEASUREMENT WHERE rainfall = 0 AND created < @stormEnd ORDER BY created DESC LIMIT 1 INTO @stormStart;
    SELECT SUM(Rainfall) FROM WEATHER_MEASUREMENT WHERE created >= @stormStart AND created <= @stormEnd INTO @stormTotal;

    SELECT AMBIENT_TEMPERATURE FROM WEATHER_MEASUREMENT WHERE created >= DATE(NOW()) ORDER BY AMBIENT_TEMPERATURE ASC LIMIT 1 INTO @LowSinceMidnight;
    SELECT AMBIENT_TEMPERATURE FROM WEATHER_MEASUREMENT WHERE created >= DATE(NOW()) ORDER BY AMBIENT_TEMPERATURE DESC LIMIT 1 INTO @HighSinceMidnight;

    SELECT 
        @RainFallSinceMidnight AS RainFallSinceMidnight,
        @stormStart AS LastStormStart,
        @stormEnd AS LastStormEnd,
        @stormTotal AS LastStormTotal,
        @LowSinceMidnight AS LowSinceMidnight,
        @HighSinceMidnight AS HighSinceMidnight;
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS GETWUNDERGROUNDDATA;
DELIMITER $$
CREATE PROCEDURE `GETWUNDERGROUNDDATA`()
BEGIN
    SELECT SUM(Rainfall) FROM WEATHER_MEASUREMENT WHERE created >= DATE_SUB(NOW(),INTERVAL 1 HOUR) INTO @rainPastHour;
    SELECT SUM(Rainfall) FROM WEATHER_MEASUREMENT WHERE created >= DATE(NOW()) INTO @rainSinceMidnight;
    SELECT VALUE FROM RPiWx_SETTINGS WHERE NAME = 'WUNDERGROUND_ID' LIMIT 1 INTO @WUNDERGROUND_ID;
    SELECT VALUE FROM RPiWx_SETTINGS WHERE NAME = 'WUNDERGROUND_PASSWORD' LIMIT 1 INTO @WUNDERGROUND_PASSWORD;
    SELECT CONVERT_TZ(CREATED, @@session.time_zone, '+00:00') as CREATEDUTC, WIND_DIRECTION, WIND_SPEED, WIND_GUST_SPEED, HUMIDITY, AMBIENT_TEMPERATURE, AIR_PRESSURE, GROUND_TEMPERATURE, @rainPastHour, @rainSinceMidnight, @WUNDERGROUND_ID, @WUNDERGROUND_PASSWORD FROM WEATHER_MEASUREMENT ORDER BY created DESC LIMIT 1;
END$$

DELIMITER ;

DROP procedure IF EXISTS `UPDATEWXSETTING`;
DELIMITER $$
CREATE PROCEDURE `UPDATEWXSETTING` (sName varchar(64), sValue varchar(64))
BEGIN
	UPDATE IGNORE RPiWx_SETTINGS SET `VALUE` = sValue WHERE NAME = sName;
	INSERT IGNORE INTO RPiWx_SETTINGS (`NAME`, `VALUE`) VALUES (sName, sValue);
END$$

DELIMITER ;
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

DELIMITER ##
CREATE PROCEDURE `GETDAILYRECORDS`()
BEGIN
    SELECT @RainfallSinceMidnight:=SUM(RAINFALL) FROM WEATHER_MEASUREMENT WHERE created >= DATE(NOW());

    SELECT @stormEnd:=created FROM WEATHER_MEASUREMENT WHERE rainfall > 0 ORDER BY created DESC LIMIT 1;
    SELECT @stormStart:=created FROM WEATHER_MEASUREMENT WHERE rainfall = 0 AND created < @stormEnd ORDER BY created DESC LIMIT 1;
    SELECT @stormTotal:=SUM(Rainfall) FROM WEATHER_MEASUREMENT WHERE created >= @stormStart AND created <= @stormEnd;

    SELECT @LowSinceMidnight:= AMBIENT_TEMPERATURE FROM WEATHER_MEASUREMENT WHERE created >= DATE(NOW()) ORDER BY AMBIENT_TEMPERATURE ASC LIMIT 1;
    SELECT @HighSinceMidnight:= AMBIENT_TEMPERATURE FROM WEATHER_MEASUREMENT WHERE created >= DATE(NOW()) ORDER BY AMBIENT_TEMPERATURE DESC LIMIT 1;

    SELECT 
        @RainFallSinceMidnight AS RainFallSinceMidnight,
        @stormStart AS LastStormStart,
        @stormEnd AS LastStormEnd,
        @stormTotal AS LastStormTotal,
        @LowSinceMidnight AS LowSinceMidnight,
        @HighSinceMidnight AS HighSinceMidnight;
END##
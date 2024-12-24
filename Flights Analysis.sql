
SELECT *
FROM AllDailyData

--Tempatur
SELECT 
    MONTH_NAME,
    temp_category,
    COUNT(*) AS number_of_flights,
    SUM(COUNT(*)) OVER (PARTITION BY MONTH_NAME) AS total_flights_per_month,
    COUNT(*)  / SUM(COUNT(*)) OVER (PARTITION BY MONTH_NAME) AS percentage_of_delayed_flights
FROM 
    (   SELECT *,
            CASE 
                WHEN temp < 38 THEN 'Very Cold'  
                WHEN temp >= 38 AND temp <= 58 THEN 'Cold'  
                WHEN temp >= 59 AND temp <= 71 THEN 'Pleasant'  
                WHEN temp >= 72 AND temp <= 82 THEN 'Hot'  
                WHEN temp >= 83 AND temp <= 95 THEN 'Very Hot'  
                ELSE 'Extremely Hot'  
            END AS temp_category
        FROM AllDailyData 
    ) AS TBL_CATEGORY
WHERE 
    temp IS NOT NULL AND dep_delay > 0
GROUP BY 
    MONTH_NAME, temp_category
ORDER BY 
    MONTH_NAME, temp_category;



--Visible
SELECT 
    CASE 
        WHEN VISIB >= 10 THEN 'Good Visibility'
        WHEN VISIB >= 5 THEN 'Moderate Visibility'
        WHEN VISIB >= 1 THEN 'Low Visibility'
        ELSE 'Very Low Visibility'
    END AS Visibility_Category,
    COUNT(*) AS Total_Flights,
    SUM(CASE WHEN dep_delay > 0 THEN 1 ELSE 0 END) AS Delayed_Flights,
    ROUND(SUM(CASE WHEN dep_delay > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Delay_Percentage
FROM AllDailyData
WHERE VISIB IS NOT NULL
GROUP BY 
    CASE 
        WHEN VISIB >= 10 THEN 'Good Visibility'
        WHEN VISIB >= 5 THEN 'Moderate Visibility'
        WHEN VISIB >= 1 THEN 'Low Visibility'
        ELSE 'Very Low Visibility'
    END
ORDER BY Delay_Percentage DESC;





--Wind Speed
SELECT  
    CASE
        WHEN wind_speed >= 40 THEN 'Extremely Strong Wind'
        WHEN wind_speed >= 26 AND wind_speed < 40 THEN 'Strong Wind'
        WHEN wind_speed >= 16 AND wind_speed < 26 THEN 'Medium Wind'
        WHEN wind_speed >= 6 AND wind_speed < 15 THEN 'Low Wind'
        ELSE 'Very Low Wind'
    END AS Wind_Category,
    COUNT(*) AS Total_Flights,
    SUM(
        CASE 
            WHEN arr_delay > 0  AND dep_delay > 0 THEN arr_delay - dep_delay 
			WHEN arr_delay > 0 AND  dep_delay < 0 THEN arr_delay - ABS(dep_delay)
            WHEN  arr_delay < 0 AND  dep_delay > 0 THEN arr_delay - dep_delay
			WHEN arr_delay < 0 AND  dep_delay < 0 AND arr_delay > dep_delay THEN arr_delay - ABS(dep_delay)
			WHEN arr_delay < 0 AND  dep_delay < 0 AND arr_delay < dep_delay THEN -1 * (arr_delay - ABS(dep_delay))
        END
    ) AS Total_Air_Delay_In_Minutes,
    AVG(
        CASE 
            WHEN arr_delay > 0  AND dep_delay > 0 THEN arr_delay - dep_delay 
			WHEN arr_delay > 0 AND  dep_delay < 0 THEN arr_delay - ABS(dep_delay)
            WHEN  arr_delay < 0 AND  dep_delay > 0 THEN arr_delay - dep_delay
			WHEN arr_delay < 0 AND  dep_delay < 0 AND arr_delay > dep_delay THEN arr_delay - ABS(dep_delay)
			WHEN arr_delay < 0 AND  dep_delay < 0 AND arr_delay < dep_delay THEN -1 * (arr_delay - ABS(dep_delay))
        END
    ) AS Avg_Air_Delay_In_Minutes
FROM AllDailyData
WHERE wind_speed IS NOT NULL
GROUP BY 
    CASE
        WHEN wind_speed >= 40 THEN 'Extremely Strong Wind'
        WHEN wind_speed >= 26 AND wind_speed < 40 THEN 'Strong Wind'
        WHEN wind_speed >= 16 AND wind_speed < 26 THEN 'Medium Wind'
        WHEN wind_speed >= 6 AND wind_speed < 15 THEN 'Low Wind'
        ELSE 'Very Low Wind'
    END
ORDER BY Wind_Category;



--Precipitation
SELECT MONTH_NAME ,
    CASE
        WHEN precip = 0 THEN 'No Precipitation'
        WHEN precip > 0 AND precip <= 0.2 THEN 'Light Precipitation'
        WHEN precip > 0.2 AND precip <= 0.6 THEN 'Moderate Precipitation'
        WHEN precip > 0.6 AND precip <= 1.0 THEN 'Heavy Precipitation'
        ELSE 'Very Heavy Precipitation'
    END AS Precipitation_Category
, AVG(dep_delay) AS 'Average_Dep_Delayed'
FROM AllDailyData
WHERE MONTH_NAME IN ('November' , 'December' , 'January' , 'March', 'February')
GROUP BY 
    CASE
        WHEN precip = 0 THEN 'No Precipitation'
        WHEN precip > 0 AND precip <= 0.2 THEN 'Light Precipitation'
        WHEN precip > 0.2 AND precip <= 0.6 THEN 'Moderate Precipitation'
        WHEN precip > 0.6 AND precip <= 1.0 THEN 'Heavy Precipitation'
        ELSE 'Very Heavy Precipitation'
    END 
	, MONTH_NAME
ORDER BY Average_Dep_Delayed



--Numer of flight for each airport per month
SELECT 
    origin_airport_name,
    MONTH_NAME,
    COUNT(*) AS 'Count_Flights',
    CASE 
        WHEN origin_airport_name = 'Newark Liberty Intl' THEN 40.6895
        WHEN origin_airport_name = 'John F Kennedy Intl' THEN 40.6413
        WHEN origin_airport_name = 'La Guardia' THEN 40.7769
        ELSE NULL
    END AS Latitude,
    CASE 
        WHEN origin_airport_name = 'Newark Liberty Intl' THEN -74.1745
        WHEN origin_airport_name = 'John F Kennedy Intl' THEN -73.7781
        WHEN origin_airport_name = 'La Guardia' THEN -73.8740
        ELSE NULL
    END AS Longitude
FROM AllDailyData
GROUP BY origin_airport_name, MONTH_NAME
ORDER BY MONTH_NAME;




--Flight Delay Percentage by Airport and Month


WITH CTE_TotalFlighs AS
	(
	SELECT origin_airport_name
	, MONTH_NAME
	, COUNT(*) AS 'Count_Flights'
	FROM AllDailyData
	GROUP BY origin_airport_name , MONTH_NAME
	),
	Cte_FlightsDelay AS
	(
	SELECT origin_airport_name
	, MONTH_NAME
	, COUNT(*) AS 'Count_Flights_Delayed'
	, AVG (Dep_delay) AS 'Average Delay'
	FROM AllDailyData
	WHERE dep_delay > 0
	GROUP BY origin_airport_name , MONTH_NAME
	)
--Query
SELECT CFD.origin_airport_name
, CFD.Count_Flights_Delayed
, CTF.Count_Flights
, CTF.MONTH_NAME
, CFD.[Average Delay]
FROM CTE_TotalFlighs CTF
INNER JOIN Cte_FlightsDelay CFD ON CTF.origin_airport_name = CFD.origin_airport_name AND CFD.MONTH_NAME = CTF.MONTH_NAME


--Total Flights By Airport
SELECT origin_airport_name
, COUNT(*) AS 'Total flights'
FROM AllDailyData
GROUP BY origin_airport_name


--Flight Delay Analysis Based on Aircraft Size

WITH CTE_AirCraft AS
	(
	SELECT 
		TBL.*, 
		CASE
			WHEN TBL.plane_seats >= 50 AND TBL.plane_seats <= 100 THEN 'Small Aircraft'
			WHEN TBL.plane_seats > 100 AND TBL.plane_seats <= 200 THEN 'Medium Aircraft'
			WHEN TBL.plane_seats > 200 AND TBL.plane_seats <= 300 THEN 'Large Aircraft'
			WHEN TBL.plane_seats > 300 AND TBL.plane_seats <= 400 THEN 'Wide-Body Aircraft'
			ELSE 'Very Large Aircraft'
		END AS Aircraft_Category
	FROM 
		(SELECT 
			AllDailyData.*, 
			p.seats AS plane_seats, 
			p.tailnum AS plane_tailnum
		FROM AllDailyData 
		INNER JOIN planes p 
			ON AllDailyData.tailnum = p.tailnum
		WHERE p.seats >= 50) AS TBL
	WHERE dep_delay > 0
	)
--Query
SELECT Aircraft_Category
, COUNT(*) AS 'Count Flights Delay'
, AVG(dep_delay) AS 'Average Delay'
, Sum(dep_delay) AS 'Sum Delay'
FROM CTE_AirCraft
GROUP BY Aircraft_Category


--Flights Delay by Day Part
SELECT Shift_Category
, COUNT(*) AS 'Count Flights Delay'
, AVG(dep_delay) AS 'Average Delay'
, Sum(dep_delay) AS 'Sum Delay'
FROM  (	SELECT *
		,	 CASE 
				WHEN sched_dep_time >= 600 AND sched_dep_time < 1200 THEN 'Morning'
				WHEN sched_dep_time >= 1200 AND sched_dep_time < 1800 THEN 'Noon'
				WHEN sched_dep_time >= 1800 AND sched_dep_time < 2359 THEN 'Evening'
				ELSE 'Night'
				END AS Shift_Category
		FROM AllDailyData ) AS TBL
WHERE dep_delay > 0 AND dep_delay IS NOT NULL
GROUP BY Shift_Category

-- Flights Delay by Day Part with Airport Filter 2
SELECT 
    origin_airport_name AS Airport_Name,
    Shift_Category,
    COUNT(*) AS 'Count Flights Delay',
    AVG(dep_delay) AS 'Average Delay',
    SUM(dep_delay) AS 'Sum Delay'
FROM  
    (SELECT *,
            CASE 
                WHEN sched_dep_time >= 600 AND sched_dep_time < 1200 THEN 'Morning'
                WHEN sched_dep_time >= 1200 AND sched_dep_time < 1800 THEN 'Noon'
                WHEN sched_dep_time >= 1800 AND sched_dep_time < 2359 THEN 'Evening'
                ELSE 'Night'
            END AS Shift_Category
     FROM AllDailyData) AS TBL
WHERE 
    dep_delay > 0 AND dep_delay IS NOT NULL
GROUP BY 
    origin_airport_name, Shift_Category;






--Number of Destinations by airline
SELECT airline_name
,COUNT(DISTINCT dest_airport_name) AS 'Number of Destinations'
FROM AllDailyData
GROUP BY airline_name


--Map Destinations by airline
SELECT DISTINCT airline_name
, dest_airport_name
, dest
, COUNT(dest_airport_name) AS 'Flight Count'
FROM AllDailyData
WHERE dest_airport_name IS NOT NULL
GROUP BY airline_name , dest_airport_name , dest


--Cancelled flights percentage by airline
WITH CTE_CountCancelled_byAirline AS
	(Endeavor Air Inc.
		SELECT airline_name
		, COUNT(*) AS 'Number_Of_Flights_Cancelled'
		FROM AllDailyData
		WHERE Cancelled = 1
		GROUP BY airline_name
	), CTE_TotalFlights_ByAirline AS
	(
		SELECT airline_name
		, COUNT(*) AS 'Total_Flights_by_Airline'
		FROM AllDailyData
		GROUP BY airline_name
	)
--Query
SELECT TFA.airline_name
, CCA.Number_Of_Flights_Cancelled
, TFA.Total_Flights_by_Airline
FROM CTE_CountCancelled_byAirline CCA
RIGHT JOIN CTE_TotalFlights_ByAirline TFA ON CCA.airline_name = TFA.airline_name


--Impact of Aircraft Age on Flight Delays
SELECT Plane_Age_Category
, COUNT(TBL.dep_delay) AS 'Count Flights'
, AVG(TBL.dep_delay) AS 'Average Delay'
FROM  (	SELECT *
		,	CASE 
				WHEN Plane_Age >= 0 AND Plane_Age < 10 THEN 'New'
				WHEN Plane_Age >= 10 AND Plane_Age < 20 THEN 'Relatively New'
				WHEN Plane_Age >= 20 AND Plane_Age < 30 THEN 'Middle-Aged'
				WHEN Plane_Age >= 30 AND Plane_Age < 40 THEN 'Old'
				ELSE 'Very Old'
				END AS Plane_Age_Category
		FROM AllDailyData
		WHERE Plane_Age IS NOT NULL ) AS TBL
WHERE TBL.dep_delay  > 0
GROUP BY Plane_Age_Category
ORDER BY [Average Delay] DESC


--Analysis of Flight Delays by Route and Airline Performance
WITH PopularRoutes AS (
    SELECT 
        origin_airport_name, 
        dest_airport_name
    FROM (
        SELECT 
            origin_airport_name, 
            dest_airport_name, 
            COUNT(*) AS FlightCount,
            ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS RowNum
        FROM AllDailyData
        GROUP BY origin_airport_name, dest_airport_name
    ) AS SubQuery
    WHERE RowNum <= 10
)
SELECT 
    TBL.origin_airport_name, 
    TBL.dest_airport_name, 
    TBL.airline_name, 
    COUNT(*) AS 'Flight Count', 
    AVG(TBL.dep_delay) AS 'Average Departure Delay',
    AVG(TBL.arr_delay) AS 'Average Arrival Delay'
FROM 
    AllDailyData AS TBL
JOIN 
    PopularRoutes AS PR
ON 
    TBL.origin_airport_name = PR.origin_airport_name 
    AND TBL.dest_airport_name = PR.dest_airport_name
GROUP BY 
    TBL.origin_airport_name, 
    TBL.dest_airport_name, 
    TBL.airline_name
ORDER BY 
    TBL.origin_airport_name, 
    TBL.dest_airport_name, 
    [Average Arrival Delay] ASC;



--Analysis by date name
SELECT 
    month_name,        
    DATENAME(WEEKDAY, [Date]) AS DayOfWeek,       
    AVG(dep_delay) AS Avg_Departure_Delay,        
    COUNT(CASE WHEN dep_delay > 0 THEN 1 END) AS Flights_Delayed 
FROM 
    AllDailyData
WHERE 
    dep_delay IS NOT NULL
GROUP BY 
    month_name, 
    DATENAME(WEEKDAY, [Date])
                

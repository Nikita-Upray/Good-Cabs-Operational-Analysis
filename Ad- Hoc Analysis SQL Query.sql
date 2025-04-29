USE trips_db;

/* Business Request - 1: City-Level Fare and Trip Summary Report
Generate a report that displays the total trips, average fare per km, average fare per trip, and the percentage contribution of each city's trips to the overall trips. 
This report will help in assessing trip volume, pricing efficiency, and each city's contribution to the overall trip count.
*/

SELECT 
    dc.city_name AS "City",
    COUNT(ft.trip_id) AS "Total Trips",
    ROUND(SUM(ft.fare_amount) / NULLIF(SUM(ft.distance_travelled_km), 0), 2) AS "Avg Fare Per Km",
    ROUND(AVG(ft.fare_amount), 2) AS "Avg Fare Per Trip",
    CONCAT(ROUND(COUNT(ft.trip_id) * 100.0 / 
                 (SELECT COUNT(*) FROM fact_trips), 2), '%') AS `% Contribution to Total Trips`
FROM 
    fact_trips ft
JOIN 
    dim_city dc ON ft.city_id = dc.city_id
GROUP BY 
    dc.city_name
ORDER BY 
    "Total Trips" DESC;

/*
Business Request - 2: Monthly City-Level Trips Target Performance Report
Generate a report that evaluates the target performance for trips at the monthly and city level. 
For each city and month, compare the actual total trips with the target trips and categorise the performance as follows:
If actual trips are greater than target trips, mark it as "Above Target".
If actual trips are less than or equal to target trips, mark it as "Below Target".
Additionally, calculate the % difference between actual and target trips to quantify the performance gap.
*/

SELECT 
    dc.city_name AS "City",
    dd.month_name AS "Month",
    COUNT(ft.trip_id) AS "Actual Trips",
    mt.total_target_trips AS "Target Trips",                                              
    CASE
        WHEN COUNT(ft.trip_id) > mt.total_target_trips THEN 'Above Target'             
        ELSE 'Below Target'                                                              
    END AS "Performance Status",                                                           
    CONCAT( 																	
        ROUND(
            ((COUNT(ft.trip_id) - mt.total_target_trips) * 100.0 / mt.total_target_trips), 
            2),
        "%"
		) AS `% Difference`                                                               
FROM
    fact_trips ft                                                                        
JOIN
    dim_city dc ON ft.city_id = dc.city_id                                               
JOIN
    dim_date dd ON ft.date = dd.date                                                     
JOIN
    targets_db.monthly_target_trips mt 												
    ON dc.city_id = mt.city_id                                                          
    AND dd.start_of_month = mt.month                                                   
GROUP BY 
    dc.city_name,                                                                       
    dd.month_name,                                                                       
    mt.total_target_trips,                                                             
    dd.start_of_month                                                                    
ORDER BY 
    dc.city_name,                                                                      
    MONTH(dd.start_of_month);
    
    
/*
Business Request - 3: City-Level Repeat Passenger Trip Frequency Report
Generate a report that shows the percentage distribution of repeat passengers by the number of trips they have taken in each city. 
Calculate the percentage of repeat passengers who took 2 trips, 3 trips, and so on, up to 10 trips.
Each column should represent a trip count category, displaying the percentage of repeat passengers who fall into that category 
out of the total repeat passengers for that city.
*/


SELECT 
    dc.city_name AS City,

    CONCAT(ROUND(SUM(CASE WHEN trip_count IN ('2-trips', '2trips') THEN repeat_passenger_count ELSE 0 END)
         / SUM(drtd.repeat_passenger_count) * 100, 2), '%') AS `2-Trips`,

    CONCAT(ROUND(SUM(CASE WHEN trip_count IN ('3-trips', '3trips') THEN drtd.repeat_passenger_count ELSE 0 END)
         / SUM(drtd.repeat_passenger_count) * 100, 2), '%') AS `3-Trips`,

    CONCAT(ROUND(SUM(CASE WHEN trip_count IN ('4-trips', '4trips') THEN repeat_passenger_count ELSE 0 END)
         / SUM(repeat_passenger_count) * 100, 2), '%') AS `4-Trips`,

    CONCAT(ROUND(SUM(CASE WHEN trip_count IN ('5-trips', '5trips') THEN repeat_passenger_count ELSE 0 END)
         / SUM(repeat_passenger_count) * 100, 2), '%') AS `5-Trips`,

    CONCAT(ROUND(SUM(CASE WHEN trip_count IN ('6-trips', '6trips') THEN repeat_passenger_count ELSE 0 END)
         / SUM(repeat_passenger_count) * 100, 2), '%') AS `6-Trips`,

    CONCAT(ROUND(SUM(CASE WHEN drtd.trip_count IN ('7-trips', '7trips') THEN repeat_passenger_count ELSE 0 END)
         / SUM(repeat_passenger_count) * 100, 2), '%') AS `7-Trips`,

    CONCAT(ROUND(SUM(CASE WHEN trip_count IN ('8-trips', '8trips') THEN repeat_passenger_count ELSE 0 END)
         / SUM(repeat_passenger_count) * 100, 2), '%') AS `8-Trips`,

    CONCAT(ROUND(SUM(CASE WHEN trip_count IN ('9-trips', '9trips') THEN repeat_passenger_count ELSE 0 END)
         / SUM(repeat_passenger_count) * 100, 2), '%') AS `9-Trips`,

    CONCAT(ROUND(SUM(CASE WHEN trip_count IN ('10-trips', '10trips') THEN repeat_passenger_count ELSE 0 END)
         / SUM(repeat_passenger_count) * 100, 2), '%') AS `10-Trips`

FROM 
    dim_repeat_trip_distribution drtd
JOIN 
    dim_city dc 
    ON drtd.city_id = dc.city_id
GROUP BY 
    dc.city_name
ORDER BY 
    dc.city_name;


/*
Business Request - 4: Identify Cities with Highest and Lowest Total New Passengers
Generate a report that calculates the total new passengers for each city and ranks them based on this value. 
Identify the top 3 cities with the highest number of new passengers as well as the bottom 3 cities 
with the lowest number of new passengers, categorising them as "Top 3" or "Bottom 3" accordingly.
*/

WITH city_passenger_totals AS 
(                                                        
    SELECT 
        dc.city_name,                                                      
        SUM(fp.new_passengers) AS total_new_passengers                     
    FROM 
        fact_passenger_summary fp                                    
    JOIN 
        dim_city dc ON fp.city_id = dc.city_id             
    GROUP BY 
        dc.city_name                                       
),                                                                         

ranked_cities AS 
(
    SELECT 
        city_name,
        total_new_passengers,
        RANK() OVER (ORDER BY total_new_passengers DESC) AS rank_highest,  
        RANK() OVER (ORDER BY total_new_passengers ASC) AS rank_lowest     
    FROM 
        city_passenger_totals
),                                                                        

categorized_cities AS 
(
    SELECT 
        city_name,
        total_new_passengers,
        CASE 
            WHEN rank_highest <= 3 THEN 'Top 3'                           
            WHEN rank_lowest <= 3 THEN 'Bottom 3'                         
            ELSE NULL                                                    
        END AS city_category                                              
    FROM 
        ranked_cities
)


SELECT 
    city_name AS City,
    total_new_passengers AS "New Passengers",
    city_category AS "City Category"                                        
FROM 
    categorized_cities
WHERE 
    city_category IS NOT NULL                                             
ORDER BY 
	total_new_passengers DESC;       


/*
Business Request - 5: Identify Month with Highest Revenue for Each City
Generate a report that identifies the month with the highest revenue for each city. 
For each city, display the month_name, the revenue amount for that month, 
and the percentage contribution of that month's revenue to the city's total revenue.
*/

WITH revenue_per_city_month AS 
(
    SELECT 
        dc.city_name,
        MONTHNAME(ft.date) AS month_name,
        SUM(ft.fare_amount) AS revenue
    FROM 
        fact_trips ft
    JOIN 
		dim_city dc 
    ON 
		ft.city_id = dc.city_id
    GROUP BY 
        dc.city_name, month_name
),

revenue_with_total AS (
    SELECT 
        city_name,
        month_name,
        revenue,
        SUM(revenue) OVER (PARTITION BY city_name) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY city_name ORDER BY revenue DESC) AS rn
    FROM 
        revenue_per_city_month
)

SELECT 
    city_name AS City,
    month_name AS "Highest Revenue Month",
    Revenue,
    CONCAT(ROUND(revenue / total_revenue * 100, 2), "%") AS "% Contribution"
FROM 
    revenue_with_total
WHERE 
    rn = 1
ORDER BY 
    Revenue DESC;


/* 
Business Request - 6: Repeat Passenger Rate Analysis
Generate a report that calculates two metrics:
1. Monthly Repeat Passenger Rate: Calculate the repeat passenger rate for each city and month by comparing the number of repeat passengers to the total passengers.
 2. City-wide Repeat Passenger Rate: Calculate the overall repeat passenger rate for each city, considering all passengers across months.
These metrics will provide insights into monthly repeat trends as well as the overall repeat behaviour for each city.
Fields:
city_name
month
total_passengers
repeat_passengers
monthly_repeat_passenger_rate (%): Repeat passenger rate at the city and
month level
city_repeat_passenger_rate (%): Overall repeat passenger rate for each city, aggregated across months */


WITH city_monthly_data AS 
(
    SELECT 
        dc.city_name,
        MONTHNAME(fps.month) AS month_name,
        fps.total_passengers,
        fps.repeat_passengers,
        CONCAT(ROUND(fps.repeat_passengers / fps.total_passengers * 100, 2), "%") AS monthly_repeat_passenger_rate
    FROM 
        fact_passenger_summary fps
    JOIN 
        dim_city dc 
	ON 
		fps.city_id = dc.city_id
),

city_overall_rate AS 
(
    SELECT 
        city_name,
        CONCAT(ROUND(SUM(repeat_passengers) / SUM(total_passengers) * 100, 2), "%") AS city_repeat_passenger_rate
    FROM 
        city_monthly_data
    GROUP BY 
        city_name
)

SELECT 
    cmd.city_name AS "City",
    cmd.month_name AS "Month",
    cmd.total_passengers "Total Passengers",
    cmd.repeat_passengers AS "Repeat Passengers",
    cmd.monthly_repeat_passenger_rate AS "Monthly Repeat Passenger Rate %",
    cor.city_repeat_passenger_rate AS "City Repeat Passenger Rate %"
FROM 
    city_monthly_data cmd
JOIN 
    city_overall_rate cor 
ON 
	cmd.city_name = cor.city_name
ORDER BY 
    cmd.city_name, 
    FIELD(month_name, 'January', 'February', 'March', 'April', 'May', 'June');
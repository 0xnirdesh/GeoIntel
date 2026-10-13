-- Q7: Ward ranking by population
SELECT ward_name, population,
       RANK() OVER (ORDER BY population DESC) AS pop_rank
FROM ward_complete_stats
ORDER BY pop_rank
LIMIT 10;

-- Q8: Running total of buildings
SELECT ward_name, buildings,
       SUM(buildings) OVER (ORDER BY ward_id) AS running_total
FROM ward_complete_stats
ORDER BY ward_id
LIMIT 15;

-- Q9: LAG/LEAD — AQI comparison
SELECT ward_name, avg_aqi,
       LAG(avg_aqi) OVER (ORDER BY ward_id) AS prev_aqi,
       LEAD(avg_aqi) OVER (ORDER BY ward_id) AS next_aqi
FROM ward_complete_stats
WHERE avg_aqi IS NOT NULL
LIMIT 10;

-- Q10: Quartile distribution
SELECT ward_name, literacy,
       NTILE(4) OVER (ORDER BY literacy DESC) AS quartile
FROM ward_complete_stats
ORDER BY quartile, literacy DESC
LIMIT 20;

-- Q11: Top 3 wards per district by hospital
SELECT district_id, ward_name, hospitals,
       ROW_NUMBER() OVER (PARTITION BY district_id ORDER BY hospitals DESC) AS rn
FROM ward_complete_stats wcs
JOIN wards w ON wcs.ward_id = w.ward_id
ORDER BY district_id, rn
LIMIT 20;

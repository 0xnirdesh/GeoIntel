-- Q15: GROUPING SETS
SELECT ward_id, crop_name, SUM(area_hectare) AS total_area
FROM crops
GROUP BY GROUPING SETS ((ward_id), (crop_name), ())
ORDER BY ward_id NULLS LAST
LIMIT 20;

-- Q16: ROLLUP
SELECT w.district_id, w.ward_id, SUM(p.total) AS total_pop
FROM wards w
JOIN population p ON w.ward_id = p.ward_id
GROUP BY ROLLUP (w.district_id, w.ward_id)
ORDER BY w.district_id NULLS LAST
LIMIT 20;

-- Q17: CUBE
SELECT p.ward_id, p.poi_type, COUNT(*) AS cnt
FROM pois p
GROUP BY CUBE (p.ward_id, p.poi_type)
ORDER BY p.ward_id NULLS LAST
LIMIT 20;

-- Q18: FILTER clause
SELECT ward_id,
       COUNT(*) FILTER (WHERE aqi < 50) AS good,
       COUNT(*) FILTER (WHERE aqi BETWEEN 50 AND 100) AS moderate,
       COUNT(*) FILTER (WHERE aqi BETWEEN 100 AND 200) AS poor,
       COUNT(*) FILTER (WHERE aqi > 200) AS very_poor
FROM pollution
GROUP BY ward_id
ORDER BY ward_id
LIMIT 15;

-- Q19: DISTINCT ON
SELECT DISTINCT ON (ward_id) ward_id, crop_name, area_hectare
FROM crops
ORDER BY ward_id, area_hectare DESC
LIMIT 10;

-- Q20: Statistical aggregate
SELECT 
    ROUND(AVG(aqi)::numeric, 2) AS avg_aqi,
    MIN(aqi) AS min_aqi,
    MAX(aqi) AS max_aqi,
    ROUND(STDDEV(aqi)::numeric, 2) AS stddev_aqi,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY aqi) AS median_aqi
FROM pollution;

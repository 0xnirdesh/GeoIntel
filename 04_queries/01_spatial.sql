-- Q1: Nearest 5 hospitals from India Gate
SELECT name, 
       ROUND(ST_Distance(geom::geography, 
             ST_MakePoint(77.2295, 28.6129)::geography)::numeric, 2) AS distance_m
FROM hospitals
ORDER BY geom <-> ST_MakePoint(77.2295, 28.6129)
LIMIT 5;

-- Q2: Schools within 2 km of India Gate
SELECT name
FROM schools
WHERE ST_DWithin(
    geom::geography,
    ST_MakePoint(77.2295, 28.6129)::geography,
    2000
);

-- Q3: Buildings inside flood zones
SELECT fz.risk_level, COUNT(b.building_id) AS building_count
FROM flood_zones fz
JOIN buildings b ON ST_Intersects(b.geom, fz.geom)
GROUP BY fz.risk_level;

-- Q4: Wards with NO hospital within 3 km
SELECT w.name
FROM wards w
WHERE NOT EXISTS (
    SELECT 1 FROM hospitals h
    WHERE ST_DWithin(h.geom::geography, w.geom::geography, 3000)
)
LIMIT 10;

-- Q5: Area of each ward in sq km
SELECT name, 
       ROUND((ST_Area(geom::geography)/1000000)::numeric, 2) AS area_sqkm
FROM wards
ORDER BY area_sqkm DESC
LIMIT 10;

-- Q6: Petrol pumps within 500m of a highway
SELECT DISTINCT p.name
FROM pois p
JOIN roads r ON ST_DWithin(p.geom::geography, r.geom::geography, 500)
WHERE p.poi_type = 'fuel' 
AND r.road_type IN ('motorway', 'trunk', 'primary')
LIMIT 10;

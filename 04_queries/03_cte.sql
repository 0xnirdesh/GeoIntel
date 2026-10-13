-- Q12: Recursive hierarchy
WITH RECURSIVE hierarchy AS (
    SELECT state_id AS id, name, NULL::INT AS parent_id, 1 AS level
    FROM states
    UNION ALL
    SELECT d.district_id, d.name, d.state_id, h.level + 1
    FROM districts d
    JOIN hierarchy h ON d.state_id = h.id AND h.level = 1
    UNION ALL
    SELECT w.ward_id, w.name, w.district_id, h.level + 1
    FROM wards w
    JOIN hierarchy h ON w.district_id = h.id AND h.level = 2
)
SELECT * FROM hierarchy ORDER BY level, name LIMIT 20;

-- Q13: Wards with more than average buildings
WITH avg_buildings AS (
    SELECT AVG(buildings) AS avg_b FROM ward_complete_stats
)
SELECT ward_name, buildings
FROM ward_complete_stats, avg_buildings
WHERE buildings > avg_b
ORDER BY buildings DESC
LIMIT 10;

-- Q14: Ward full profile
WITH ward_profile AS (
    SELECT w.ward_id, w.name,
           COUNT(DISTINCT h.hospital_id) AS hospitals,
           COUNT(DISTINCT s.school_id) AS schools,
           COUNT(DISTINCT p.poi_id) AS pois
    FROM wards w
    LEFT JOIN hospitals h ON w.ward_id = h.ward_id
    LEFT JOIN schools s ON w.ward_id = s.ward_id
    LEFT JOIN pois p ON w.ward_id = p.ward_id
    GROUP BY w.ward_id, w.name
)
SELECT * FROM ward_profile
WHERE hospitals > 0 AND schools > 0
ORDER BY hospitals DESC
LIMIT 10;

-- Function 1: Nearest hospital
CREATE OR REPLACE FUNCTION nearest_hospital(lat FLOAT, lon FLOAT)
RETURNS TABLE(hospital_name TEXT, distance_m NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT name::TEXT, 
           ROUND(ST_Distance(geom::geography, ST_MakePoint(lon, lat)::geography)::numeric, 2)
    FROM hospitals
    ORDER BY geom <-> ST_MakePoint(lon, lat)
    LIMIT 5;
END;
$$ LANGUAGE plpgsql;

-- Function 2: Ward risk score
CREATE OR REPLACE FUNCTION ward_risk_score(p_ward_id INT)
RETURNS NUMERIC AS $$
DECLARE
    v_flood_count INT;
    v_avg_aqi NUMERIC;
    v_score NUMERIC;
BEGIN
    SELECT COUNT(*) INTO v_flood_count 
    FROM flood_zones fz 
    WHERE ST_Intersects(fz.geom, (SELECT geom FROM wards WHERE ward_id = p_ward_id));
    
    SELECT COALESCE(AVG(aqi), 100) INTO v_avg_aqi 
    FROM pollution WHERE ward_id = p_ward_id;
    
    v_score := (v_flood_count * 30) + (v_avg_aqi * 0.5);
    RETURN ROUND(v_score, 2);
END;
$$ LANGUAGE plpgsql;

-- Function 3: Coverage gap
CREATE OR REPLACE FUNCTION coverage_gap(radius_m INT)
RETURNS TABLE(ward_name TEXT, nearest_hospital_m NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT w.name::TEXT,
           ROUND(MIN(ST_Distance(w.geom::geography, h.geom::geography))::numeric, 2)
    FROM wards w
    LEFT JOIN hospitals h ON ST_DWithin(h.geom::geography, w.geom::geography, radius_m)
    GROUP BY w.ward_id, w.name
    HAVING COUNT(h.hospital_id) = 0
    ORDER BY 2 DESC NULLS LAST
    LIMIT 10;
END;
$$ LANGUAGE plpgsql;

-- Procedure: Refresh materialized view
CREATE OR REPLACE PROCEDURE refresh_ward_stats()
LANGUAGE plpgsql AS $$
BEGIN
    REFRESH MATERIALIZED VIEW ward_complete_stats;
    RAISE NOTICE 'Ward stats refreshed at %', NOW();
END;
$$;

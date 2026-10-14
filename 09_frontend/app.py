from flask import Flask, render_template, jsonify, request
import psycopg2
from psycopg2.extras import RealDictCursor

app = Flask(__name__)

def get_db():
    return psycopg2.connect(dbname="geointel", user="thakursahab", host="localhost")

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/stats')
def stats():
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("""
        SELECT 
            (SELECT COUNT(*) FROM wards) AS wards,
            (SELECT COUNT(*) FROM hospitals) AS hospitals,
            (SELECT COUNT(*) FROM schools) AS schools,
            (SELECT COUNT(*) FROM buildings) AS buildings,
            (SELECT COUNT(*) FROM roads) AS roads,
            (SELECT COUNT(*) FROM pois) AS pois,
            (SELECT COUNT(*) FROM flood_zones) AS flood_zones,
            (SELECT COUNT(*) FROM pollution) AS pollution_readings
    """)
    result = cur.fetchone()
    conn.close()
    return jsonify(result)

@app.route('/api/hospitals')
def hospitals():
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("""
        SELECT hospital_id, name, ST_X(geom) AS lon, ST_Y(geom) AS lat
        FROM hospitals WHERE geom IS NOT NULL LIMIT 100
    """)
    result = cur.fetchall()
    conn.close()
    return jsonify(result)

@app.route('/api/schools')
def schools():
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("""
        SELECT school_id, name, ST_X(geom) AS lon, ST_Y(geom) AS lat
        FROM schools WHERE geom IS NOT NULL LIMIT 100
    """)
    result = cur.fetchall()
    conn.close()
    return jsonify(result)

@app.route('/api/flood_zones')
def flood_zones():
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("""
        SELECT zone_id, risk_level, ST_AsGeoJSON(geom) AS geometry
        FROM flood_zones
    """)
    result = cur.fetchall()
    conn.close()
    return jsonify(result)

@app.route('/api/ward_stats')
def ward_stats():
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("""
        SELECT ward_name, population, literacy, hospitals, avg_aqi
        FROM ward_complete_stats
        WHERE population IS NOT NULL
        ORDER BY population DESC LIMIT 20
    """)
    result = cur.fetchall()
    conn.close()
    return jsonify(result)

@app.route('/api/location_info')
def location_info():
    lat = request.args.get('lat', type=float)
    lon = request.args.get('lon', type=float)
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)

    # Nearest 5 hospitals
    cur.execute("""
        SELECT name, 
               ROUND(ST_Distance(geom::geography, 
                     ST_SetSRID(ST_MakePoint(%s, %s), 4326)::geography)::numeric, 1) AS distance_m
        FROM hospitals
        ORDER BY geom <-> ST_SetSRID(ST_MakePoint(%s, %s), 4326)
        LIMIT 5
    """, (lon, lat, lon, lat))
    hosp = cur.fetchall()

    # Nearest 5 schools
    cur.execute("""
        SELECT name, 
               ROUND(ST_Distance(geom::geography, 
                     ST_SetSRID(ST_MakePoint(%s, %s), 4326)::geography)::numeric, 1) AS distance_m
        FROM schools
        ORDER BY geom <-> ST_SetSRID(ST_MakePoint(%s, %s), 4326)
        LIMIT 5
    """, (lon, lat, lon, lat))
    sch = cur.fetchall()

    # Ward info
    cur.execute("""
        SELECT w.name AS ward_name, wcs.population, wcs.literacy, wcs.avg_aqi,
               wcs.hospitals AS total_hospitals, wcs.schools AS total_schools,
               wcs.buildings AS total_buildings
        FROM wards w
        LEFT JOIN ward_complete_stats wcs ON w.ward_id = wcs.ward_id
        WHERE ST_Within(ST_SetSRID(ST_MakePoint(%s, %s), 4326), w.geom)
        LIMIT 1
    """, (lon, lat))
    ward = cur.fetchone()

    # Flood zone
    cur.execute("""
        SELECT risk_level
        FROM flood_zones
        WHERE ST_Within(ST_SetSRID(ST_MakePoint(%s, %s), 4326), geom)
        LIMIT 1
    """, (lon, lat))
    flood = cur.fetchone()

    # Counts within 2 km
    cur.execute("""
        SELECT 
            COUNT(DISTINCT h.hospital_id) AS hospitals_2km,
            COUNT(DISTINCT s.school_id) AS schools_2km
        FROM (SELECT 1) x
        LEFT JOIN hospitals h ON ST_DWithin(h.geom::geography, 
            ST_SetSRID(ST_MakePoint(%s, %s), 4326)::geography, 2000)
        LEFT JOIN schools s ON ST_DWithin(s.geom::geography, 
            ST_SetSRID(ST_MakePoint(%s, %s), 4326)::geography, 2000)
    """, (lon, lat, lon, lat))
    counts = cur.fetchone()

    conn.close()
    return jsonify({
        'hospitals': hosp,
        'schools': sch,
        'ward': ward,
        'flood_zone': flood['risk_level'] if flood else None,
        'counts': counts
    })
@app.route('/api/insights')
def insights():
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    # Average AQI
    cur.execute("SELECT ROUND(AVG(aqi)::numeric, 1) AS avg_aqi FROM pollution")
    avg_aqi = cur.fetchone()
    
    # High flood risk wards count
    cur.execute("""
        SELECT COUNT(DISTINCT w.ward_id) AS flood_wards
        FROM wards w
        JOIN flood_zones fz ON ST_Intersects(w.geom, fz.geom)
        WHERE fz.risk_level = 'High'
    """)
    flood_wards = cur.fetchone()
    
    # Highest population ward
    cur.execute("""
        SELECT w.name, p.total 
        FROM wards w JOIN population p ON w.ward_id = p.ward_id
        ORDER BY p.total DESC LIMIT 1
    """)
    top_pop = cur.fetchone()
    
    # Ward with most hospitals
    cur.execute("""
        SELECT w.name, COUNT(h.hospital_id) AS cnt
        FROM wards w JOIN hospitals h ON w.ward_id = h.ward_id
        GROUP BY w.name ORDER BY cnt DESC LIMIT 1
    """)
    top_hosp = cur.fetchone()
    
    # Total area
    cur.execute("SELECT ROUND(SUM(ST_Area(geom::geography)/1000000)::numeric, 1) AS area FROM wards")
    area = cur.fetchone()
    
    # Language distribution
    cur.execute("""
        SELECT language, ROUND(AVG(percentage)::numeric, 1) AS avg_pct
        FROM languages GROUP BY language ORDER BY avg_pct DESC LIMIT 3
    """)
    langs = cur.fetchall()
    
    conn.close()
    return jsonify({
        'avg_aqi': avg_aqi['avg_aqi'],
        'flood_wards': flood_wards['flood_wards'],
        'top_pop': top_pop,
        'top_hosp': top_hosp,
        'area': area['area'],
        'languages': langs
    })
@app.route('/api/pois/<poi_type>')
def get_pois(poi_type):
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("""
        SELECT poi_id, name, ST_X(geom) AS lon, ST_Y(geom) AS lat
        FROM pois 
        WHERE poi_type = %s AND geom IS NOT NULL
        LIMIT 500
    """, (poi_type,))
    result = cur.fetchall()
    conn.close()
    return jsonify(result)

@app.route('/api/poi_types')
def poi_types():
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("""
        SELECT poi_type, COUNT(*) AS count 
        FROM pois 
        GROUP BY poi_type 
        ORDER BY count DESC
    """)
    result = cur.fetchall()
    conn.close()
    return jsonify(result)

if __name__ == '__main__':
    app.run(debug=True, port=5000)
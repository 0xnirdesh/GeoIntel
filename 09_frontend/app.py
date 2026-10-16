from flask import Flask, render_template, jsonify, request
import psycopg2
import os
from psycopg2.extras import RealDictCursor

app = Flask(__name__)



def get_db():
    db_url = os.environ.get('DATABASE_URL')
    if db_url:
        return psycopg2.connect(db_url)
    else:
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
            (SELECT COUNT(*) FROM pois) AS pois
    """)
    result = cur.fetchone()
    conn.close()
    return jsonify(result)

@app.route('/api/hospitals')
def hospitals():
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("SELECT hospital_id, name, ST_X(geom) AS lon, ST_Y(geom) AS lat FROM hospitals WHERE geom IS NOT NULL LIMIT 200")
    result = cur.fetchall()
    conn.close()
    return jsonify(result)

@app.route('/api/schools')
def schools():
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("SELECT school_id, name, ST_X(geom) AS lon, ST_Y(geom) AS lat FROM schools WHERE geom IS NOT NULL LIMIT 200")
    result = cur.fetchall()
    conn.close()
    return jsonify(result)

@app.route('/api/flood_zones')
def flood_zones():
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("SELECT zone_id, risk_level, ST_AsGeoJSON(geom) AS geometry FROM flood_zones")
    result = cur.fetchall()
    conn.close()
    return jsonify(result)

@app.route('/api/poi_types')
def poi_types():
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("SELECT poi_type, COUNT(*) AS count FROM pois GROUP BY poi_type ORDER BY count DESC")
    result = cur.fetchall()
    conn.close()
    return jsonify(result)

@app.route('/api/pois/<poi_type>')
def get_pois(poi_type):
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("""
        SELECT poi_id, name, ST_X(geom) AS lon, ST_Y(geom) AS lat
        FROM pois WHERE poi_type = %s AND geom IS NOT NULL LIMIT 500
    """, (poi_type,))
    result = cur.fetchall()
    conn.close()
    return jsonify(result)

@app.route('/api/location_info')
def location_info():
    lat = request.args.get('lat', type=float)
    lon = request.args.get('lon', type=float)
    active_types = request.args.get('types', '').strip()
    radius = request.args.get('radius', default=2000, type=int)
    
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)

    # Ward info — with ward_no
    cur.execute("""
        SELECT w.name AS ward_name, w.ward_no, wcs.population, wcs.literacy, wcs.avg_aqi
        FROM wards w LEFT JOIN ward_complete_stats wcs ON w.ward_id = wcs.ward_id
        WHERE ST_Within(ST_SetSRID(ST_MakePoint(%s, %s), 4326), w.geom) LIMIT 1
    """, (lon, lat))
    ward = cur.fetchone()

    cur.execute("""
        SELECT risk_level FROM flood_zones
        WHERE ST_Within(ST_SetSRID(ST_MakePoint(%s, %s), 4326), geom) LIMIT 1
    """, (lon, lat))
    flood = cur.fetchone()

    nearest = {}
    type_labels = {
        'hospital': 'Hospitals', 'school': 'Schools', 'pharmacy': 'Pharmacies',
        'bus_stop': 'Bus Stops', 'metro_station': 'Metro Stations',
        'restaurant': 'Restaurants', 'supermarket': 'Supermarkets', 'cinema': 'Cinemas',
        'bank': 'Banks', 'atm': 'ATMs', 'post_office': 'Post Offices', 'library': 'Libraries',
        'police': 'Police Stations', 'fire_station': 'Fire Stations',
        'place_of_worship': 'Places of Worship', 'fuel': 'Fuel Stations', 'hotel': 'Hotels'
    }
    type_emoji = {
        'hospital': '🏥', 'school': '🏫', 'pharmacy': '💊',
        'bus_stop': '🚌', 'metro_station': '🚇', 'restaurant': '🍽️',
        'supermarket': '🛒', 'cinema': '🎬', 'bank': '🏦', 'atm': '💰',
        'post_office': '📮', 'library': '📚', 'police': '🚓',
        'fire_station': '🚒', 'place_of_worship': '🛕', 'fuel': '⛽', 'hotel': '🏨'
    }

    if active_types:
        types_list = [t.strip() for t in active_types.split(',') if t.strip()]
        for ptype in types_list:
            if ptype == 'hospital':
                cur.execute("""
                    SELECT name, ROUND(ST_Distance(geom::geography, ST_SetSRID(ST_MakePoint(%s, %s), 4326)::geography)::numeric, 1) AS distance_m
                    FROM hospitals 
                    WHERE ST_DWithin(geom::geography, ST_SetSRID(ST_MakePoint(%s, %s), 4326)::geography, %s)
                    ORDER BY geom <-> ST_SetSRID(ST_MakePoint(%s, %s), 4326) LIMIT 5
                """, (lon, lat, lon, lat, radius, lon, lat))
            elif ptype == 'school':
                cur.execute("""
                    SELECT name, ROUND(ST_Distance(geom::geography, ST_SetSRID(ST_MakePoint(%s, %s), 4326)::geography)::numeric, 1) AS distance_m
                    FROM schools 
                    WHERE ST_DWithin(geom::geography, ST_SetSRID(ST_MakePoint(%s, %s), 4326)::geography, %s)
                    ORDER BY geom <-> ST_SetSRID(ST_MakePoint(%s, %s), 4326) LIMIT 5
                """, (lon, lat, lon, lat, radius, lon, lat))
            else:
                cur.execute("""
                    SELECT name, ROUND(ST_Distance(geom::geography, ST_SetSRID(ST_MakePoint(%s, %s), 4326)::geography)::numeric, 1) AS distance_m
                    FROM pois WHERE poi_type = %s 
                    AND ST_DWithin(geom::geography, ST_SetSRID(ST_MakePoint(%s, %s), 4326)::geography, %s)
                    ORDER BY geom <-> ST_SetSRID(ST_MakePoint(%s, %s), 4326) LIMIT 5
                """, (lon, lat, ptype, lon, lat, radius, lon, lat))

            rows = cur.fetchall()
            if rows:
                nearest[ptype] = {
                    'label': type_labels.get(ptype, ptype.replace('_', ' ').title()),
                    'emoji': type_emoji.get(ptype, '📍'),
                    'items': rows
                }

    conn.close()
    return jsonify({
        'ward': ward,
        'flood_zone': flood['risk_level'] if flood else None,
        'nearest': nearest,
        'radius': radius
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5001))
    app.run(debug=False, host='0.0.0.0', port=port)
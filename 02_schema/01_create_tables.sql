-- ============================================
-- GEOINTEL — DATABASE SCHEMA
-- Delhi Spatial Intelligence System
-- ============================================

\c geointel
CREATE EXTENSION IF NOT EXISTS postgis;

-- LAYER 1: REFERENCE TABLES
CREATE TABLE states (
    state_id     SERIAL PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    code         VARCHAR(10) UNIQUE NOT NULL,
    area_sqkm   NUMERIC(12,2),
    geom         GEOMETRY(MULTIPOLYGON, 4326),
    created_at   TIMESTAMP DEFAULT NOW()
);

CREATE TABLE districts (
    district_id  SERIAL PRIMARY KEY,
    state_id     INT NOT NULL REFERENCES states(state_id),
    name         VARCHAR(100) NOT NULL,
    code         VARCHAR(10) UNIQUE,
    area_sqkm   NUMERIC(12,2),
    geom         GEOMETRY(MULTIPOLYGON, 4326),
    created_at   TIMESTAMP DEFAULT NOW()
);

CREATE TABLE wards (
    ward_id      SERIAL PRIMARY KEY,
    district_id  INT NOT NULL REFERENCES districts(district_id),
    name         VARCHAR(100) NOT NULL,
    ward_no      INT UNIQUE NOT NULL,
    area_sqkm   NUMERIC(12,2),
    geom         GEOMETRY(MULTIPOLYGON, 4326),
    created_at   TIMESTAMP DEFAULT NOW()
);

CREATE TABLE roads (
    road_id      SERIAL PRIMARY KEY,
    name         VARCHAR(200),
    road_type    VARCHAR(50),
    length_m     NUMERIC(12,2),
    ward_id      INT REFERENCES wards(ward_id),
    geom         GEOMETRY(MULTILINESTRING, 4326),
    created_at   TIMESTAMP DEFAULT NOW()
);

CREATE TABLE buildings (
    building_id  SERIAL PRIMARY KEY,
    building_type VARCHAR(50),
    floors       INT,
    ward_id      INT REFERENCES wards(ward_id),
    attributes   JSONB,
    geom         GEOMETRY(MULTIPOLYGON, 4326),
    created_at   TIMESTAMP DEFAULT NOW()
);

CREATE TABLE hospitals (
    hospital_id  SERIAL PRIMARY KEY,
    name         VARCHAR(200) NOT NULL,
    hospital_type VARCHAR(50),
    beds         INT,
    ward_id      INT REFERENCES wards(ward_id),
    geom         GEOMETRY(POINT, 4326),
    created_at   TIMESTAMP DEFAULT NOW()
);

CREATE TABLE schools (
    school_id    SERIAL PRIMARY KEY,
    name         VARCHAR(200) NOT NULL,
    school_type  VARCHAR(50),
    students     INT,
    ward_id      INT REFERENCES wards(ward_id),
    geom         GEOMETRY(POINT, 4326),
    created_at   TIMESTAMP DEFAULT NOW()
);

CREATE TABLE flood_zones (
    zone_id      SERIAL PRIMARY KEY,
    risk_level   VARCHAR(20),
    year         INT,
    area_sqkm   NUMERIC(12,2),
    geom         GEOMETRY(MULTIPOLYGON, 4326),
    created_at   TIMESTAMP DEFAULT NOW()
);

CREATE TABLE population (
    pop_id       SERIAL PRIMARY KEY,
    ward_id      INT NOT NULL REFERENCES wards(ward_id),
    total        INT,
    male         INT,
    female       INT,
    density      NUMERIC(10,2),
    year         INT,
    created_at   TIMESTAMP DEFAULT NOW()
);

CREATE TABLE literacy (
    lit_id       SERIAL PRIMARY KEY,
    ward_id      INT NOT NULL REFERENCES wards(ward_id),
    male_lit     NUMERIC(5,2),
    female_lit   NUMERIC(5,2),
    total_lit    NUMERIC(5,2),
    year         INT,
    created_at   TIMESTAMP DEFAULT NOW()
);

CREATE TABLE crops (
    crop_id      SERIAL PRIMARY KEY,
    ward_id      INT REFERENCES wards(ward_id),
    crop_name    VARCHAR(100),
    area_hectare NUMERIC(10,2),
    yield_ton    NUMERIC(10,2),
    season       VARCHAR(50),
    year         INT,
    created_at   TIMESTAMP DEFAULT NOW()
);

CREATE TABLE languages (
    lang_id      SERIAL PRIMARY KEY,
    ward_id      INT NOT NULL REFERENCES wards(ward_id),
    language     VARCHAR(50),
    percentage   NUMERIC(5,2),
    created_at   TIMESTAMP DEFAULT NOW()
);

CREATE TABLE pollution (
    poll_id      SERIAL PRIMARY KEY,
    ward_id      INT NOT NULL REFERENCES wards(ward_id),
    aqi          INT,
    pm25         NUMERIC(6,2),
    pm10         NUMERIC(6,2),
    date         DATE NOT NULL,
    created_at   TIMESTAMP DEFAULT NOW()
);

# GeoIntel — Delhi Spatial Intelligence System

> **Developed in the DBMS Lab**  
> **By:** Nirdesh Kumar
> **Under the supervision of Dr. Tanu Shree**

---

A PostgreSQL + PostGIS based spatial database management system for analyzing Delhi's urban infrastructure using OpenStreetMap data.

---

## Project Information

| Field | Details |
|---|---|
| **Project Name** | GeoIntel — Delhi Spatial Intelligence System |
| **Project Type** | DBMS Lab Project |
| **Developed By** | Nirdesh Kumar |
| **Developed In** | DBMS Lab |
| **Under the Supervision of** | Dr. Tanu Shree |
---

## Overview

GeoIntel is a spatial DBMS that stores, queries, and visualizes over **5 lakh spatial features** across **289 municipal wards** of Delhi. It demonstrates advanced database concepts including 3NF normalization, spatial indexing, materialized views, triggers, stored functions, and Row-Level Security.

The system solves real-world urban planning and disaster management problems:
- Find nearest hospitals from any location
- Analyze flood risk zones
- Identify healthcare coverage gaps
- Multi-criteria ward analysis (AQI + literacy + population)

---

## Tech Stack

| Component | Technology |
|---|---|
| Database | PostgreSQL 17.11 |
| Spatial Extension | PostGIS 3.6 |
| OSM Import | osm2pgsql 2.3.1 |
| GIS Tool | GDAL / ogr2ogr 3.13.3 |
| Backend | Flask (Python 3) |
| Frontend | Leaflet.js, Chart.js |
| Version Control | Git + GitHub |

---

## Database Schema

### 16 Tables (3NF Normalized)

**Reference Tables:**
- `states` — State data
- `districts` — 11 districts of Delhi
- `wards` — 289 municipal wards

**Infrastructure Tables:**
- `roads` — Road network (LINESTRING)
- `buildings` — Building footprints (POLYGON)
- `hospitals` — Hospital locations (POINT)
- `schools` — School locations (POINT)
- `flood_zones` — Flood risk areas (POLYGON)

**Knowledge Tables:**
- `population` — Ward-wise population
- `literacy` — Ward-wise literacy
- `crops` — Agriculture data
- `languages` — Language distribution
- `pollution` — AQI data

**Additional:**
- `pois` — Points of interest (petrol pumps, hotels, banks)
- `delhi_boundary` — 289 ward boundaries
- `hospital_audit` — Audit log

---

## Data Sources

| Source | Data | Size |
|---|---|---|
| OpenStreetMap (Geofabrik) | Roads, buildings, POIs | 213 MB PBF |
| DataMeet GitHub | 289 ward boundaries | 718 KB GeoJSON |
| Census of India 2011 | Population, literacy, language | CSV |
| DPCC | Pollution (AQI) data | CSV |
| Generated | Flood zones (Yamuna buffer) | ST_Buffer |

---

## Data Volume

| Table | Rows |
|---|---|
| states | 1 |
| districts | 11 |
| wards | 289 |
| hospitals | 508 |
| schools | 277 |
| roads | 1,65,969 |
| buildings | 2,48,958 |
| pois | 3,098 |
| population | 289 |
| literacy | 289 |
| languages | 1,445 |
| crops | 97 |
| pollution | 1,445 |
| flood_zones | 14 |

**Total: 5+ lakh spatial features**

---

## Advanced DBMS Features

### Spatial Indexing (GiST)
7 spatial indexes for 100x faster queries.

```sql
CREATE INDEX idx_hospitals_geom ON hospitals USING GIST (geom);
CREATE INDEX idx_buildings_geom ON buildings USING GIST (geom);

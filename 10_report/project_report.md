# GeoIntel — Delhi Spatial Intelligence System
## DBMS Project Report

**Submitted By:** Nirdesh Kumar | 2402221530085 | AIML B
**Developed In:** AI Lab
**Supervisor:** Ms. Anjali Srivastava
**Academic Year:** 2025–2026

---

## 1. INTRODUCTION
GeoIntel is a PostgreSQL 17 + PostGIS 3.6 based spatial database system that analyzes Delhi's urban infrastructure using OpenStreetMap and Census data. It supports complex spatial queries, ward-level analytics, and urban planning decisions.

## 2. OBJECTIVES
- Store spatial data for Delhi (289 wards)
- Support complex spatial queries (KNN, buffer, intersection)
- Provide ward-level analytics
- Demonstrate advanced DBMS features

## 3. DATABASE SCHEMA (3NF Normalized)
**13 core tables:**
- Reference: states, districts, wards
- Infrastructure: roads, buildings, hospitals, schools, flood_zones
- Knowledge: population, literacy, crops, languages, pollution
- Additional: pois, delhi_boundary, hospital_audit

## 4. DATA SOURCES
- OpenStreetMap (Delhi PBF extract — 213 MB)
- Census 2011 (population, literacy)
- DataMeet (289 ward boundaries)

## 5. DATA VOLUME
| Table | Rows |
|---|---|
| Wards | 289 |
| Hospitals | 508 |
| Schools | 277 |
| Roads | 1,65,969 |
| Buildings | 2,48,958 |
| POIs | 3,098 |
| Languages | 1,445 |
| Pollution | 1,445 |

## 6. ADVANCED FEATURES
- **GiST Spatial Indexes:** 7 indexes
- **Materialized View:** ward_complete_stats
- **Triggers:** 4 (audit, validation, auto-update)
- **Functions:** 4 (nearest_hospital, ward_risk_score, coverage_gap, refresh_ward_stats)
- **Advanced SQL:** Window functions, CTEs, Recursive queries, ROLLUP, CUBE, FILTER

## 7. PERFORMANCE
- Query execution: 2.3 ms with GiST index
- EXPLAIN ANALYZE: "Index Scan using idx_hospitals_geom"
- Data volume: 5+ lakh spatial features

## 8. SAMPLE QUERIES
1. Nearest 5 hospitals (KNN)
2. Schools within 2 km (ST_DWithin)
3. Buildings in flood zones (ST_Intersects)
4. Coverage gap analysis
5. Ward ranking by population
6. Recursive hierarchy (State → District → Ward)

## 9. CONCLUSION
GeoIntel demonstrates a production-ready spatial DBMS with advanced features applicable to urban planning, disaster management, and smart city projects.

## 10. REFERENCES
[1] PostGIS 3.6 Documentation
[2] PostgreSQL 17 Documentation
[3] OpenStreetMap Contributors
[4] Census of India 2011
[5] DataMeet Municipal Spatial Data

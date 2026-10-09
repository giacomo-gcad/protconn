DROP TABLE IF EXISTS delli.eco_areas_without_antarctica;
CREATE TABLE delli.eco_areas_without_antarctica AS

SELECT DISTINCT
eco_id, SUM(sqkm) area_geo
FROM ind_protconn.ecoregions_2024_terr WHERE eco_id!=19999
GROUP BY eco_id ORDER BY eco_id;
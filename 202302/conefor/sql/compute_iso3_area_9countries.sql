DROP TABLE IF EXISTS delli.iso3_areas_9countries;
CREATE TABLE delli.iso3_areas_9countries AS

SELECT DISTINCT 
iso3,
SUM(sqkm) area_geo
FROM administrative_units.gaul_eez
WHERE source='gaul' and iso3 IN ('DZA','CAN','COL','SWZ','GGY','MAR','PER','PHL','ZAF')
GROUP BY iso3
ORDER BY iso3;

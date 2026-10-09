DROP TABLE IF EXISTS delli.iso3_areas_gisco;
CREATE TABLE delli.iso3_areas_gisco AS

SELECT iso3, SUM(psqkm) area_geo
FROM administrative_units.gisco_admin_2020_single_poly
WHERE source='gisco' AND iso3 NOT LIKE 'X%'
GROUP BY iso3 ORDER BY iso3;

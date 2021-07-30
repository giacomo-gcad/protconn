DROP TABLE IF EXISTS gaul_temp; CREATE TEMPORARY TABLE gaul_temp AS
WITH 
step1 AS (SELECT iso3, geom from :INSCHEMA.:INNAME WHERE source='gaul'),
step2 as (SELECT iso3, (ST_Dump(geom)).geom AS geom FROM step1)
SELECT 
CAST(ROW_NUMBER() OVER () AS integer) AS objectid,
iso3,geom FROM step2;

-- Repair invalid geometries
ALTER TABLE gaul_temp ADD COLUMN geom_was_invalid boolean DEFAULT FALSE;
UPDATE gaul_temp SET geom_was_invalid = TRUE WHERE ST_IsValid(geom) IS FALSE;
UPDATE gaul_temp SET geom = ST_MakeValid(geom) WHERE geom_was_invalid IS TRUE;
ALTER TABLE gaul_temp DROP COLUMN geom_was_invalid;

-- Add area_geo
ALTER TABLE gaul_temp ADD COLUMN "AREA_GEO" double precision;
UPDATE gaul_temp SET "AREA_GEO" = (ST_AREA(geom::geography)/1000000);

-- CREATE GAUL SINGLE PARTED OVER 1km2 WITH NECESSARY FIELDS
DROP TABLE IF EXISTS :OUTSCHEMA.:OUTNAME; CREATE TABLE :OUTSCHEMA.:OUTNAME AS
WITH step1  AS (SELECT *,(objectid + 100000) "nodeID",iso3 "ISO3final" FROM gaul_temp WHERE "AREA_GEO">=1)
SELECT * FROM step1;

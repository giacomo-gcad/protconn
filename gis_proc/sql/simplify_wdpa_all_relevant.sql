-- IMPORT PREPROCESSED WDPA AND  REPAIR GEOMETRIES
DROP TABLE IF EXISTS :OUTSCHEMA.wdpa_temp; CREATE TABLE  :OUTSCHEMA.wdpa_temp AS SELECT wdpaid,iso3,geom FROM :WDPASCHEMA.wdpa_:WDPADATE;
ALTER TABLE :OUTSCHEMA.wdpa_temp ADD COLUMN geom_was_invalid boolean DEFAULT FALSE;
UPDATE :OUTSCHEMA.wdpa_temp SET geom_was_invalid = TRUE WHERE ST_IsValid(geom) IS FALSE;
UPDATE :OUTSCHEMA.wdpa_temp SET geom = ST_MakeValid(geom) WHERE geom_was_invalid IS TRUE;

-- SIMPLIFY GEOMETRIES
DROP TABLE IF EXISTS :OUTSCHEMA.:OUTNAME; CREATE TABLE :OUTSCHEMA.:OUTNAME AS

WITH step1 AS (SELECT CAST(wdpaid AS integer) wdpaid,iso3,ST_SimplifyPreserveTopology(geom,0.001) geom
FROM :OUTSCHEMA.wdpa_temp ORDER BY wdpaid)

SELECT wdpaid,iso3,(ST_Dump(ST_CollectionExtract(geom,3))).geom geom FROM step1;
CREATE INDEX idx_:OUTNAME ON :OUTSCHEMA.:OUTNAME USING gist(geom);

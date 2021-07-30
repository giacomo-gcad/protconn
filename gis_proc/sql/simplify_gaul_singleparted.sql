-- SIMPLIFY GEOMETRIES
DROP TABLE IF EXISTS :OUTSCHEMA.:OUTNAME;
CREATE TABLE :OUTSCHEMA.:OUTNAME AS
WITH step1 AS
(SELECT
objectid,iso3,"nodeID","ISO3final",ST_SimplifyPreserveTopology(geom,0.001) geom
FROM :OUTSCHEMA.:INNAME
ORDER BY iso3)

SELECT objectid,iso3,"nodeID","ISO3final",(ST_Dump(ST_CollectionExtract(geom,3))).geom geom
FROM step1;


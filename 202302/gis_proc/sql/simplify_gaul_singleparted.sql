-- THS PART COULD REPLACE wdpa_country_boundcorr_1.py
-- IT WORKS BUT PRODUCES 1 POLYGON LESS THAN PYTHON SCRIPT.
-- TO BE INVESTIGATED. IF OK, TO BE PARAMETRIZED

/* DROP TABLE IF EXISTS gaul; CREATE TEMPORARY TABLE gaul AS 
(SELECT id_object,id_country,iso3,name_iso31661,geom FROM  administrative_units.gaul_eez WHERE source='gaul');

DROP TABLE IF EXISTS step1; CREATE TEMPORARY TABLE step1 AS
(SELECT id_object,iso3,(ST_Dump(ST_CollectionExtract(geom,3))).geom geom FROM gaul);
ALTER TABLE step1 ADD COLUMN IF NOT EXISTS area_geo double precision;
UPDATE step1 SET area_geo = (ST_AREA(geom::geography)/1000000);

DROP TABLE IF EXISTS ind_protconn.gaul_simpl_to_be_checked; CREATE TABLE ind_protconn.gaul_simpl_to_be_checked AS 
SELECT id_object,iso3,area_geo, ST_SimplifyPreserveTopology(geom,0.001) geom FROM step1 WHERE area_geo>= 1 ORDER BY iso3;
 */

-- SIMPLIFY GEOMETRIES
DROP TABLE IF EXISTS :OUTSCHEMA.:OUTNAME;
CREATE TABLE :OUTSCHEMA.:OUTNAME AS
WITH step1 AS
(SELECT
ogc_fid objectid,iso3,ST_SimplifyPreserveTopology(wkb_geometry,0.001) geom
FROM :OUTSCHEMA.:INNAME
ORDER BY iso3)

SELECT objectid,iso3,(ST_Dump(ST_CollectionExtract(geom,3))).geom geom
FROM step1;


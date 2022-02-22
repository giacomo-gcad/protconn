-- PREPARE SUBSET OF RECORDS TO WORK ON

DROP TABLE IF EXISTS :OUTSCHEMA.:INTILE:CYCLE_N; CREATE TABLE  :OUTSCHEMA.:INTILE:CYCLE_N AS
WITH wdpa_all_:CYCLE_N AS (SELECT * FROM :OUTSCHEMA.:INTABLE ORDER BY objectid)
SELECT * FROM wdpa_all_:CYCLE_N
:RANGE_S1 :RANGE_S2 :RANGE_S3 :RANGE_S4;

-- Generate Near Table for countries (can take several days...)

-- STEP 1 repair geometries
ALTER TABLE :OUTSCHEMA.:INTILE:CYCLE_N
ADD COLUMN geom_was_invalid boolean DEFAULT FALSE;

UPDATE :OUTSCHEMA.:INTILE:CYCLE_N
SET geom_was_invalid = TRUE 
WHERE ST_IsValid(shape) IS FALSE;

UPDATE :OUTSCHEMA.:INTILE:CYCLE_N
SET shape = ST_MakeValid(shape)
WHERE geom_was_invalid IS TRUE;

ALTER TABLE :OUTSCHEMA.:INTILE:CYCLE_N
DROP COLUMN geom_was_invalid;

-- STEP 2 compute near table (may take several days...)
-- create 2 temp tables with spatial index
CREATE TEMPORARY TABLE temp1_:CYCLE_N AS
(SELECT nodeid "IN_FID", shape::geography as gg1 FROM :OUTSCHEMA.:INTILE:CYCLE_N );
CREATE INDEX temp1_idx_:CYCLE_N ON temp1_:CYCLE_N USING GIST (geography(gg1));

CREATE TEMPORARY TABLE temp2_:CYCLE_N AS
(SELECT nodeid "NEAR_FID", shape::geography as gg2 FROM :OUTSCHEMA.:INTABLE);
CREATE INDEX temp2_idx_:CYCLE_N ON temp2_:CYCLE_N USING GIST (geography(gg2));

--create distances table
DROP TABLE IF EXISTS :OUTSCHEMA.:OUTTABLE;
CREATE TABLE :OUTSCHEMA.:OUTTABLE AS

WITH 
finaltable AS (
SELECT DISTINCT
"IN_FID" "OBJECTID",
"IN_FID",
"NEAR_FID",
ST_Distance(gg1, gg2) AS "NEAR_DIST"
FROM temp1_:CYCLE_N,temp2_:CYCLE_N
WHERE ST_DWithin(gg1,gg2,300000, TRUE) --Here we set the maximum distance (300 km) for calculations
)

SELECT 
"OBJECTID",
"IN_FID",
"NEAR_FID",
ROUND("NEAR_DIST"::numeric,1) "NEAR_DIST",
row_number() over (PARTITION BY "IN_FID" ORDER BY "NEAR_DIST") as "NEAR_RANK"
FROM finaltable
WHERE "NEAR_DIST">0
ORDER BY "IN_FID", "NEAR_RANK";

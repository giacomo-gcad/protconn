#!/bin/bash
## PROTCONN: SCRIPT TO Generate Near Table for country in Postgis
## TO BE RUN AFTER RUNNING PROTCONN MODEL (part 2)IN ARCGIS 10.5

echo " "
echo "-------------------------------------------------------------------------------"
echo "- Script $(basename "$0") started at $(date)"
echo " "

date

##READ VARIABLES FROM CONFIGURATION FILE
first_start=`date +%s`
start=${first_start}

# READ VARIABLES FROM CONFIGURATION FILE
SERVICEDIR="/globes/USERS/GIACOMO/protconn/scripts"
source ${SERVICEDIR}/protconn.conf
dbpar="-h ${host} -U ${user} -d ${db}"
dbpar2="-h ${host} -U ${user} -d ${db} -w"

## 1) IMPORT WDPA_FLAT_1KM_FINAL GPKG IN POSTGRES
echo "Now importing GDB layer in PG..."
ogr2ogr \
-progress \
-overwrite \
-skipfailures \
-f "PostgreSQL"  \
PG:"host=${host} user=${user} dbname=${db} active_schema=${protconn_schema} password=${pw}" \
-nln "${protconn_schema}.${wdpa_ecoregions_final}" \
-nlt "MULTIPOLYGON" \
${DATADIR}/${gdb_name} ${wdpa_ecoregions_final}


wait
end=`date +%s`
runtime=$(((end-start) / 60))
echo "Shapefile file imported in PG as table "${protconn_schema}".${wdpa_ecoregions_final} in "${runtime}" minutes"


###########################
## 2) REPAIR GEOMETRIES AND GENERATE NEAR TABLE IN POSTGIS
echo "Now generating Near Table..."

start=`date +%s`
#psql ${dbpar} -t -v OUTSCHEMA=${protconn_schema} -v INTABLE=${wdpa_ecoregions_final} -v OUTTABLE=${raw_distance_eco} -f ${SQLDIR}/generate_near_table_ecoregion.sql
# Run the following line if the geometry column in the imported layer is named "shape" instead of "wkb_geometry"
psql ${dbpar} -t -v OUTSCHEMA=${protconn_schema} -v INTABLE=${wdpa_ecoregions_final} -v OUTTABLE=${raw_distance_eco} -f ${SQLDIR}/generate_near_table_ecoregion_variante_shape.sql

end=`date +%s`
runtime=$(((end-start) / 60))
wait
echo "Near Table for Ecoregion Generated in "${runtime}" minutes"


###########################
## 3) EXPORT NEAR TABLE TO TXT
echo "Now exporting Near Table to txt file"
echo "\copy ${protconn_schema}.${raw_distance_eco} TO ${raw_distance_file_eco} delimiter ',' csv HEADER" > ${SQLDIR}/export_near_table_to_txt.sql
psql ${dbpar} -t -f ${SQLDIR}/export_near_table_to_txt.sql
wait

end=`date +%s`
runtime=$(((end-start) / 60))
wait
echo "Table for ecoregions exported to txt file in "${runtime}" minutes"
runtime_tot=$(((end-first_start) / 60))
echo "Computation of Near Table foe ecoregions performed in "${runtime_tot}" minutes"
exit

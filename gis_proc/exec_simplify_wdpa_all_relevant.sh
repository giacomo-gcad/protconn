#!/bin/bash
## PROTCONN: SCRIPT TO SIMPLIFY wdpa_all_relevant in PG
## TO BE RUN AFTER RUNNING ARCPY SCRIPT a1country.py

date
start1=`date +%s`

##READ VARIABLES FROM CONFIGURATION FILE
SERVICEDIR="/globes/USERS/GIACOMO/protconn/scripts"
source ${SERVICEDIR}/protconn.conf
dbpar="-h ${host} -U ${user} -d ${db}"

## CREATE LOG FOLDER
mkdir -p ${LOGPATH}

###########################
## 1) IMPORT PREPROCESSED WDPA AND SIMPLIFY FEATURES
echo "Now importing and simplifying features..."

psql ${dbpar} -t -v OUTSCHEMA=${protconn_schema} -v WDPADATE=${wdpadate} -v WDPASCHEMA=${wdpa_schema} -v INNAME=${wdpa_all_relevant} -v OUTNAME=${wdpa_all_relevant_simpl} -f ./sql/simplify_wdpa_all_relevant.sql 

wait
echo "Features simplified."

###########################
## 3) EXPORT WDPA FROM POSTGRES TO SHAPEFILE (GPKG DOES NOT WORK DURING SUCCESSIVE IMPORT IN GDB)
echo "Now exporting simplified features in shapefile..."

ogr2ogr  \
-progress \
-f "ESRI Shapefile" \
${DATADIR}/${wdpa_all_relevant_simpl}.shp  \
PG:"host=${host} user=${user} dbname=${db} active_schema=${protconn_schema} password=${pw}"  \
"${protconn_schema}.${wdpa_all_relevant_simpl}"  \
-t_srs EPSG:4326 \
-overwrite \
-skipfailures

wait
date
end1=`date +%s`
runtime=$(((end1-start1) / 60))
echo "Simplified features exported in Shapefile."
echo "Script $(basename "$0") executed in ${runtime} minutes"
echo "-----------------------------------------------------"
echo "Now proceed with the arcpy script wdpa_country.py"

exit


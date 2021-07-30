#!/bin/bash
## PROTCONN: SCRIPT TO SIMPLIFY gaul_singleparted in PG

date
start1=`date +%s`

##READ VARIABLES FROM CONFIGURATION FILE
SERVICEDIR="/globes/USERS/GIACOMO/protconn/scripts"
source ${SERVICEDIR}/protconn.conf
dbpar="-h ${host} -U ${user} -d ${db}"

## 1) PREPARE GAUL SINGLE PARTED IN POSTGRES
echo "Now preparing gaul single part in PG..."

psql ${dbpar} -t -v INSCHEMA=${administrative_schema} -v INNAME=${gaul_table} -v OUTSCHEMA=${protconn_schema} -v OUTNAME=${gaul_for_bound_corr} -f ./sql/prepare_gaul_singleparted.sql 

wait
echo "GAUL singole part created in PG as table ${protconn_schema}.${gaul_for_bound_corr}"


###########################
## 2) SIMPLIFY FEATURES
echo "Now simplifying features..."	

psql ${dbpar} -t -v OUTSCHEMA=${protconn_schema} -v INNAME=${gaul_for_bound_corr} -v OUTNAME=${gaul_for_bound_corr_simpl} -f ./sql/simplify_gaul_singleparted.sql 

wait
echo "Features simplified."


###########################
## 3) EXPORT GAUL SINGLE PARTED FROM POSTGRES TO SHAPEFILE
echo "Now exporting simplified features in shapefile..."

ogr2ogr  \
-progress \
-f "ESRI Shapefile" \
${DATADIR}/${gaul_for_bound_corr_simpl}.shp  \
PG:"host=${host} user=${user} dbname=${db} active_schema=${protconn_schema} password=${pw}"  \
"${protconn_schema}.${gaul_for_bound_corr_simpl}"  \
-t_srs EPSG:4326 \
-overwrite \
-skipfailures

wait
date
end1=`date +%s`
runtime=$(((end1-start1) / 60))

echo " "
echo "----------------------------------------------------------------"
echo "Gaul features simplified."
echo "Script $(basename "$0") executed in ${runtime} minutes"
echo "Now proceed with the arcpy script b2country_boundcorr.py "
echo " "

exit

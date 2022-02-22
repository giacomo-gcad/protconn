#!/bin/bash
## PROTCONN: SCRIPT TO Generate Near Table for country in Postgis
## TO BE RUN AFTER RUNNING PROTCONN MODEL (part 2)IN ARCGIS 10.5

echo " "
echo "-------------------------------------------------------------------------------"
echo "- Script $(basename "$0") started at $(date)"
echo " "

date
first_start=`date +%s`

# READ VARIABLES FROM CONFIGURATION FILE
SERVICEDIR="/globes/USERS/GIACOMO/protconn/scripts"
source ${SERVICEDIR}/protconn.conf
dbpar="-h ${host} -U ${user} -d ${db}"
dbpar2="-h ${host} -U ${user} -d ${db} -w"

###########################################################################################################
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
end1=`date +%s`
runtime=$(((end1-first_start) / 60))
echo "Shapefile file imported in PG as table "${protconn_schema}".${wdpa_ecoregions_final} in "${runtime}" minutes"

############################################
## 2) PREPARE AND EXPORT ATTRIBUTES TABLE
psql ${dbpar} -t -v OUTSCHEMA=${protconn_schema} -v INTABLE=${wdpa_ecoregions_final} -v ATTRIBS=${raw_nodes_eco} -f ${SQLDIR}/prepare_atts_eco.sql
echo "\copy ${protconn_schema}.${raw_nodes_eco} TO ${raw_nodes_file_eco} delimiter ',' csv HEADER" > ${SQLDIR}/export_atts_table_to_txt.sql
	

end2=`date +%s`
runtime=$(((end2-end1) / 60))
wait
echo "Attributs Table for Ecoregions generated in "${runtime}" minutes"


###########################################################################################################
## 3) REPAIR GEOMETRIES AND GENERATE NEAR TABLE IN POSTGIS
echo "Now generating Near Table..."

string_n_obj=`psql ${dbpar} -c 'SELECT COUNT(objectid) FROM '${protconn_schema}'.'${wdpa_ecoregions_final}''`
n_obj=`echo ${string_n_obj}| awk '{print $3}'`
blocksize=$((${n_obj} / 256 ))
echo "-----------------------------------"
echo "Total n. of objects is: "${n_obj}
echo "Block size is: "${blocksize}
echo "-----------------------------------"

start_n=0
cycle_n=1
for TIL in $(for i in $(eval echo {0..256}); do ((start=${blocksize}*$i)); echo -n $start_n" "; done)
do
	end=$(( ${start_n} + ${blocksize} ))
	str1="OFFSET"
	str2=${start_n}
	str3="LIMIT"
	str4=${blocksize}
	echo " psql ${dbpar} -t -v CYCLE_N=${cycle_n} -v RANGE_S1=${str1}  -v RANGE_S2=${str2}  -v RANGE_S3=${str3}  -v RANGE_S4=${str4}  -v OUTSCHEMA=${protconn_schema} -v INTABLE=${wdpa_ecoregions_final} -v INPUT_TILE=${wdpa_final_tile}${cycle_n} -v OUTTABLE=${raw_distance_eco_block}${cycle_n} -f ${SQLDIR}/near_table_ecoregion.sql"
	start_n=$(( ${end} ))
	cycle_n=$(( ${cycle_n} + 1 )) 
done | parallel -j 70

end3=`date +%s`
runtime=$(((end3-end2) / 60))
wait
echo "Near Table for Ecoregion Generated in "${runtime}" minutes"

############################################################################################################
## 4) MERGE ALL BLOCK TABLES, EXPORT TO txt AND REMOVE INTERMEDIATE TABLES
echo "Now merging all block tables into only one and exporting to txt file"

sql_merge="DROP TABLE IF EXISTS ${protconn_schema}.${raw_distance_eco};CREATE TABLE ${protconn_schema}.${raw_distance_eco}
(\"OBJECTID\" integer,\"IN_FID\" integer,\"NEAR_FID\" integer,\"NEAR_DIST\" numeric,\"NEAR_RANK\" bigint);"

psql ${dbpar} -t -c "${sql_merge}"

start_n=0
cycle_n=1
for TIL in $(for i in $(eval echo {0..256}); do ((start=${blocksize}*$i)); echo -n $start_n" "; done)
do
	merge_tab="INSERT INTO ${protconn_schema}.${raw_distance_eco} (\"OBJECTID\",\"IN_FID\",\"NEAR_FID\",\"NEAR_DIST\",\"NEAR_RANK\")
		SELECT \"OBJECTID\",\"IN_FID\",\"NEAR_FID\",\"NEAR_DIST\",\"NEAR_RANK\" FROM ${protconn_schema}.${raw_distance_eco_block}${cycle_n}"
	end=$(( ${start_n} + ${blocksize} ))
	delete_tabs="DROP TABLE IF EXISTS ${protconn_schema}.${raw_distance_eco_block}${cycle_n};DROP TABLE IF EXISTS ${protconn_schema}.${wdpa_final_tile}${cycle_n};"
	psql ${dbpar} -t  -c "${merge_tab}"
	psql ${dbpar} -t  -c "${delete_tabs}"
	start_n=$(( ${end} ))
	cycle_n=$(( ${cycle_n} + 1 )) 
done

#EXPORT TO txt
psql ${dbpar} -t -c  "\copy ${protconn_schema}.${raw_distance_eco} TO '${raw_distance_file_eco}' delimiter ',' csv HEADER"

wait
end4=`date +%s`
runtime=$(((end4-end3) / 60))

echo "Near Table exported to txt file in "${runtime}" minutes"
echo " "
echo "------------------------------------------------------------------------------"
runtime_tot=$(((end3-first_start) / 60))

echo "Computation of Near Table foe ecoregions performed in "${runtime_tot}" minutes"
exit

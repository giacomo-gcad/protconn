#!/bin/bash
## PROTCONN: SCRIPT TO Generate Near Table for country with Bound Correction in Postgis
## TO BE RUN AFTER RUNNING PROTCONN MODEL (part 2)IN ARCGIS 10.5

echo " "
echo "-------------------------------------------------------------------------------"
echo "- Script $(basename "$0") started at $(date)"
echo " "

date

##READ VARIABLES FROM CONFIGURATION FILE
first_start=`date +%s`

# READ VARIABLES FROM CONFIGURATION FILE
SERVICEDIR="/globes/USERS/GIACOMO/protconn/scripts"
source ${SERVICEDIR}/protconn.conf
dbpar="-h ${host} -U ${user} -d ${db}"
dbpar2="-h ${host} -U ${user} -d ${db} -w"

## 1) IMPORT WDPA_FLAT_1KM_FINAL GPKG IN POSTGRES
echo "Now importing GDB layer in Postgis..."
ogr2ogr \
-progress \
-overwrite \
-skipfailures \
-f "PostgreSQL"  \
PG:"host=${host} user=${user} dbname=${db} active_schema=${protconn_schema} password=${pw}" \
-nln "${protconn_schema}.${wdpa_plus_land_flat_1km_final}" \
-nlt "MULTIPOLYGON" \
${DATADIR}/${gdb_name} ${wdpa_plus_land_flat_1km_final}

wait
end0=`date +%s`
runtime=$(((end0-first_start) / 60))
echo "GDB layer imported in PG as table ${protconn_schema}.${wdpa_plus_land_flat_1km_final} in ${runtime} minutes"

############################################
## 2) PREPARE AND EXPORT ATTRIBUTES TABLE
psql ${dbpar} -t -v OUTSCHEMA=${protconn_schema} -v INTABLE=${wdpa_plus_land_flat_1km_final} -v ATTRIBS=${raw_nodes_bound} -f ${SQLDIR}/prepare_atts_country.sql
echo "\copy ${protconn_schema}.${raw_nodes_bound} TO ${raw_nodes_file_bound} delimiter ',' csv HEADER" > ${SQLDIR}/export_atts_table_to_txt.sql
psql ${dbpar} -t -f ${SQLDIR}/export_atts_table_to_txt.sql

end1=`date +%s`
runtime=$(((end1-end0) / 60))
wait
echo "Attributs Table for Country with Bound Correction generated in "${runtime}" minutes"

##############################
## 3) REPAIR GEOMETRIES AND GENERATE NEAR TABLE IN POSTGIS
echo "Now generating Near Table..."

string_n_obj=`psql ${dbpar} -c 'SELECT COUNT(objectid) FROM '${protconn_schema}'.'${wdpa_plus_land_flat_1km_final}''`
n_obj=`echo ${string_n_obj}| awk '{print $3}'`
blocksize=$((${n_obj} / 256 ))
echo "-----------------------------------"
echo "Total n. of objects is: "${n_obj}
echo "Block size is: "${blocksize}
echo "-----------------------------------"

start_n=0
cycle_n=1
dist_tile="wdpa_bcorr_"

for TIL in $(for i in $(eval echo {0..256}); do ((start=${blocksize}*$i)); echo -n $start_n" "; done)
do
	end=$(( ${start_n} + ${blocksize} ))
	str1="OFFSET"
	str2=${start_n}
	str3="LIMIT"
	str4=${blocksize}
	echo " psql ${dbpar} -t -v CYCLE_N=${cycle_n} -v RANGE_S1=${str1}  -v RANGE_S2=${str2}  -v RANGE_S3=${str3}  -v RANGE_S4=${str4}  -v OUTSCHEMA=${protconn_schema} -v INTABLE=${wdpa_plus_land_flat_1km_final} -v INPUT_FULL=${protconn_schema}.${dist_tile}${cycle_n} -v OUTTABLE=${raw_distance_bound_block}${cycle_n} -f ${SQLDIR}/near_table_country_boundcorr.sql"
	echo 
	start_n=$(( ${end} ))
	cycle_n=$(( ${cycle_n} + 1 )) 
done | parallel -j 72

 end2=`date +%s`
runtime=$(((end2-end1) / 60))
wait
echo "Near Table for Country with Bound Correction generated in "${runtime}" minutes"

#####################################################################################
## 4) MERGE ALL BLOCK TABLES, EXPORT TO txt AND REMOVE INTERMEDIATE TABLES
echo "Now merging all block tables into only one and exporting to txt file"

sql_mergedtable="DROP TABLE IF EXISTS ${protconn_schema}.${raw_distance_bound};CREATE TABLE ${protconn_schema}.${raw_distance_bound}
(\"OBJECTID\" integer,\"IN_FID\" integer,\"NEAR_FID\" integer,\"NEAR_DIST\" numeric,\"NEAR_RANK\" bigint);"

psql ${dbpar} -t -c "${sql_mergedtable}"

start_n=0
cycle_n=1
for TIL in $(for i in $(eval echo {0..256}); do ((start=${blocksize}*$i)); echo -n $start_n" "; done)
do
	merge_tab="INSERT INTO ${protconn_schema}.${raw_distance_bound} (\"OBJECTID\",\"IN_FID\",\"NEAR_FID\",\"NEAR_DIST\",\"NEAR_RANK\")
		SELECT \"OBJECTID\",\"IN_FID\",\"NEAR_FID\",\"NEAR_DIST\",\"NEAR_RANK\" FROM ${protconn_schema}.${raw_distance_bound_block}${cycle_n}"
	end=$(( ${start_n} + ${blocksize} ))
	delete_tabs="DROP TABLE IF EXISTS ${protconn_schema}.${raw_distance_bound_block}${cycle_n};DROP TABLE IF EXISTS ${protconn_schema}.${dist_tile}${cycle_n};"
	psql ${dbpar} -t  -c "${merge_tab}"
	psql ${dbpar} -t  -c "${delete_tabs}"
	start_n=$(( ${end} ))
	cycle_n=$(( ${cycle_n} + 1 )) 
done

#EXPORT TO txt
psql ${dbpar} -t -c  "\copy ${protconn_schema}.${raw_distance_bound} TO '${raw_distance_file_bound}' delimiter ',' csv HEADER"

wait
end3=`date +%s`
runtime=$(((end3-end2) / 60))
echo "Near Table for countries with bound correction exported to txt file in "${runtime}" minutes"

runtime_tot=$(((end3-first_start) / 60))
echo "Computation of Near Table for countries with bound correction performed in "${runtime_tot}" minutes"
exit


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
end=`date +%s`
runtime=$(((end-first_start) / 60))
echo "GDB layer imported in PG as table ${protconn_schema}.${wdpa_plus_land_flat_1km_final} in ${runtime} minutes"

############################################
## 2) PREPARE AND EXPORT ATTRIBUTES TABLE
psql ${dbpar} -t -v OUTSCHEMA=${protconn_schema} -v INTABLE=${wdpa_plus_land_flat_1km_final} -v ATTRIBS=${raw_nodes_bound} -f ${SQLDIR}/prepare_atts_country.sql
echo "\copy ${protconn_schema}.${raw_nodes_bound} TO ${raw_nodes_file_bound} delimiter ',' csv HEADER" > ${SQLDIR}/export_atts_table_to_txt.sql
psql ${dbpar} -t -f ${SQLDIR}/export_atts_table_to_txt.sql

end1=`date +%s`
runtime=$(((end1-end) / 60))
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
for TIL in $(for i in $(eval echo {0..256}); do ((start=${blocksize}*$i)); echo -n $start_n" "; done)
do
	end=$(( ${start_n} + ${blocksize} ))
	str1="OFFSET"
	str2=${start_n}
	str3="LIMIT"
	str4=${blocksize}
	echo " psql ${dbpar} -t -v CYCLE_N=${cycle_n} -v RANGE_S1=${str1}  -v RANGE_S2=${str2}  -v RANGE_S3=${str3}  -v RANGE_S4=${str4}  -v OUTSCHEMA=${protconn_schema} -v INTABLE=${wdpa_plus_land_flat_1km_final} -v INPUT_TILE=${wdpa_final_tile}${cycle_n} -v OUTTABLE=${raw_distance_bound_block}${cycle_n} -f ${SQLDIR}/near_table_country_boundcorr.sql"
	start_n=$(( ${end} ))
	cycle_n=$(( ${cycle_n} + 1 )) 
done | parallel -j 70

 end2=`date +%s`
runtime=$(((end2-end1) / 60))
wait
echo "Near Table for Country with Bound Correction generated in "${runtime}" minutes"

##############################
## 4) EXPORT NEAR TABLE TO TXT
start=`date +%s`
echo "Now exporting Near Table to txt file"
echo "\copy ${protconn_schema}.${raw_distance_bound} TO ${raw_distance_file_bound} delimiter ',' csv HEADER" > ${SQLDIR}/export_near_table_to_txt.sql
psql ${dbpar} -t -f ${SQLDIR}/export_near_table_to_txt.sql
wait

end3=`date +%s`
runtime=$(((end3-end2) / 60))
wait
echo "Near Table for countries with bound correction exported to txt file in "${runtime}" minutes"

runtime_tot=$(((end3-first_start) / 60))
echo "Computation of Near Table for countries with bound correction performed in "${runtime_tot}" minutes"
exit


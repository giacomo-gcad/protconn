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

# READ VARIABLES FROM CONFIGURATION FILE
SERVICEDIR="/globes/USERS/GIACOMO/protconn/scripts"
source ${SERVICEDIR}/protconn.conf
dbpar="-h ${host} -U ${user} -d ${db}"
dbpar2="-h ${host} -U ${user} -d ${db} -w"

wdpadate="202301"
yearsuffix=${wdpadate:0:4}				# YEAR SUFFIX TO BE USED IN NAMING NODES AND DISTANCE FILES OF EACH COUNTRY (SCRIPTS IN R)

## PATHS TO FOLDERS FOR GIS PROCESSING AND CONEFOR
BASEDIR="/globes/USERS/GIACOMO/protconn/scripts"
DATADIR="/globes/USERS/GIACOMO/protconn/data/"${wdpadate}	
results_folder="/globes/USERS/GIACOMO/protconn/results/"${wdpadate}			# CREATED BY THE MASTER SCRIPT
LOGPATH="/globes/USERS/GIACOMO/protconn/logs/"${wdpadate}
SQLDIR="/globes/USERS/GIACOMO/protconn/scripts/gis_proc/sql"
RSCRIPTS_FOLDER="/globes/USERS/GIACOMO/protconn/scripts/conefor/R_scripts"
temp_folder="/globes/USERS/GIACOMO/protconn/temp_"${wdpadate}
pa_input_no_oecm="wdpa_"${wdpadate}
pa_input_with_oecm="wdpa_wdoecm_"${wdpadate}
#INPUT AND OUTPUT FILES
gdb_name="ProtConn_"${wdpadate}".gdb"
pa_input_no_oecm="wdpa_"${wdpadate}
pa_input_with_oecm="wdpa_wdoecm_"${wdpadate}
wdpa_all_relevant="wdpa_all_relevant"
wdpa_all_relevant_simpl="wdpa_all_relevant_simpl"
gaul_for_bound_corr="gaul_singleparted"
gaul_for_bound_corr_simpl="gaul_singleparted_shape_simpl"
wdpa_flat_1km_final="wdpa_flat_1km_final_"${wdpadate}
wdpa_plus_land_flat_1km_final="wdpa_plus_land_flat_1km_final_"${wdpadate}
wdpa_ecoregions_final="wdpa_ecoregions_final_"${wdpadate}
# NODES AND DISTANCE FILES FROM GIS PROCESSING
raw_distance_cnt="all_distances_300km_"${wdpadate}								# DISTANCE TABLE FOR  PROTCONN COUNTRY
raw_distance_cnt_block="cnt_block_"
cnt_dist_tile="cnt_tile_" 
raw_distance_file_cnt=${DATADIR}"/"${raw_distance_cnt}".txt"					# DISTANCE FILE FOR PROTCONN COUNTRY
raw_nodes_cnt="attrib_table_wdpa_flat_"${wdpadate}								# ATTRIBUTES TABLE FOR PROTCONN COUNTRY		
raw_nodes_file_cnt=${DATADIR}"/"${raw_nodes_cnt}".txt"							# ATTRIBUTES FILE FOR PROTCONN COUNTRY		

raw_distance_bound="all_distances_wdpa_plus_land100km_"${wdpadate}				# DISTANCE TABLE FOR PROTCONN COUNTRY WITH BOUND CORRECTION
raw_distance_bound_block="cnt_bcorr_block_"
bcorr_dist_tile="bcorr_tile_"
raw_distance_file_bound=${DATADIR}"/"${raw_distance_bound}".txt"				# DISTANCE FILE FOR PROTCONN COUNTRY WITH BOUND CORRECTION
raw_nodes_bound="attrib_table_wdpa_plus_land_"${wdpadate}						# ATTRIBUTES TABLE FOR PROTCONN COUNTRY WITH BOUND CORRECTION
raw_nodes_file_bound=${DATADIR}"/"${raw_nodes_bound}".txt"						# ATTRIBUTES FILE FOR PROTCONN COUNTRY WITH BOUND CORRECTION

raw_distance_eco="all_distances_ecoregions_200km_"${wdpadate}					# DISTANCE TABLE FOR PROTCONN ECOREGIONS
raw_distance_eco_block="eco_block_"
eco_dist_tile="eco_tile_" 
raw_distance_file_eco=${DATADIR}"/"${raw_distance_eco}".txt"					# DISTANCE FILE FOR PROTCONN ECOREGIONS
raw_nodes_eco="attrib_table_ecoregions_"${wdpadate}								# ATTRIBUTES TABLE FOR PROTCONN ECOREGIONS
raw_nodes_file_eco=${DATADIR}"/"${raw_nodes_eco}".txt"							# ATTRIBUTES FILE FOR PROTCONN ECOREGIONS

# ###########################################################################################################
# ## 1) IMPORT WDPA_FLAT_1KM_FINAL GDB IN POSTGRES
# echo "Now importing wdpa final in PG..."
# ogr2ogr \
# -progress \
# -overwrite \
# -skipfailures \
# -f "PostgreSQL"  \
# PG:"host=${host} user=${user} dbname=${db} active_schema=${protconn_schema} password=${pw}" \
# -nln "${protconn_schema}.${wdpa_flat_1km_final}" \
# -nlt "MULTIPOLYGON" \
# ${DATADIR}/${gdb_name} ${wdpa_flat_1km_final}

# wait
# end0=`date +%s`
# runtime=$(((end0-first_start) / 60))
# echo "wdpa final imported in PG as table "${protconn_schema}".${wdpa_flat_1km_final} in "${runtime}" minutes"

##################################################################
## 2) PREPARE AND EXPORT ATTRIBUTES TABLE
psql ${dbpar} -t -v OUTSCHEMA=${protconn_schema} -v INTABLE=${wdpa_flat_1km_final} -v ATTRIBS=${raw_nodes_cnt} -f ${SQLDIR}/prepare_atts_country.sql
echo "\copy ${protconn_schema}.${raw_nodes_cnt} TO ${raw_nodes_file_cnt} delimiter ',' csv HEADER" > ${SQLDIR}/export_atts_table_to_txt.sql
psql ${dbpar} -t -f ${SQLDIR}/export_atts_table_to_txt.sql

end1=`date +%s`
runtime=$(((end1-end0) / 60))
wait
echo "Attributs Table for Country generated in "${runtime}" minutes"

exit

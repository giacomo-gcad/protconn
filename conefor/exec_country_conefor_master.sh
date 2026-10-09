#!/bin/bash
## PROTCONN: SCRIPT TO PERFORM FULL CONNECTIVITY ANALYSIS AT COUNTRY, BOUND CORRECTION 
## AND ECOREGION LEVEL ON SERVER WITH PARALLELIZATION

echo " "
echo "----------------------------------------------------------------------------------"
echo "This script executes in parallel the connectivity analysis for countries (with and"
echo "without transboundary), for countries with bound correction and for ecoregions    "
echo "Script $(basename "$0") started at $(date)                                        "
echo "----------------------------------------------------------------------------------"
echo " "

startdate_master=`date +%s`

# READ VARIABLES FROM CONFIGURATION FILE
SERVICEDIR="/globes/USERS/GIACOMO/protconn/scripts"
source ${SERVICEDIR}/protconn.conf

dbpar="-h ${host} -U ${user} -d ${db} -p ${port}"

## PREPARE FOLDERS AND COPY REQUIRED FILES
mkdir -p ${temp_folder}
mkdir -p ${LOGPATH}
mkdir -p ${results_folder}

mkdir -p ${cnt_with_trans}
mkdir -p ${cnt_without_trans}
mkdir -p ${bound_corr}
cp conefor2.7.3Linux ${cnt_with_trans}/.
cp conefor2.7.3Linux ${cnt_without_trans}/.
cp conefor2.7.3Linux ${bound_corr}/.

#######################################################################################
## FIRST PART: CONNECTIVITY ANALISYS FOR COUNTRIES (WITH AND WITHOUT TRANSBOUNDARY) ###
#######################################################################################

echo "FIRST PART: CONNECTIVITY ANALISYS FOR COUNTRIES (WITH AND WITHOUT TRANSBOUNDARY) started at $(date) "

# MODIFY COLUMN NAME IN ATTRIBUTE FILE
sed -i.bak 's/OID,ISO3final,AREA_GEO,ORIG_FID,nodeID,Shape_Length,Shape_Area/OBJECTID,ISO3final,AREA_GEO,ORIG_FID,nodeID,Shape_Length,Shape_Area/g' ${raw_nodes_file_cnt}

# # RUN THE R SCRIPT TO PREPARE THE nodes_ AND distances_FILES NEEDED BY CONEFOR
echo "Now running the R script that prepares the nodes_ and distances_ files needed by Conefor..."
Rscript ${RSCRIPTS_FOLDER}/prepare_conefor_files_country.R \
		${cnt_with_trans} \
		${cnt_without_trans} \
		${raw_distance_file_cnt} \
		${raw_nodes_file_cnt} \
		${yearsuffix} \
		${RSCRIPTS_FOLDER}
date
echo "Files for protconn (countries with and without transboundary) prepared"

## PARALLEL CONEFOR CYCLE: RUN CONEFOR FOR COUNTRIES WITH TRANS
echo "Now running Conefor at country level in parallel..."
echo "Script exec_conefor_country_part1.sh started at $(date)"
./exec_conefor_country_part1.sh >${LOGPATH}/conefor_country_part1.log 2>&1 &

# now waiting for the completion of most part of the cores
sleep 9000

## PARALLEL CONEFOR CYCLE: RUN CONEFOR FOR COUNTRIES WITHOUT TRANS
echo "Now running Conefor at country level without transboundary in parallel..."
echo "Script exec_conefor_country_part2.sh started at $(date)"
./exec_conefor_country_part2.sh >${LOGPATH}/conefor_country_part2.log 2>&1 &


############################################################################
### SECOND PART : CONNECTIVITY ANALISYS FOR COUNTRIES (BOUND CORRECTION) ###
############################################################################

echo "SECOND PART: CONNECTIVITY ANALISYS FOR COUNTRIES (BOUND CORRECTION) started at $(date) "

sleep 60

# # RUN THE R SCRIPT TO PREPARE THE nodes_ AND distances_FILES NEEDED BY CONEFOR
echo "Now running the R script that prepares the nodes_ and distances_ files needed by Conefor..."
Rscript ${RSCRIPTS_FOLDER}/prepare_conefor_files_bound_correction.R \
		${bound_corr} \
		${raw_distance_file_bound} \
		${raw_nodes_file_bound} \
		${yearsuffix} \
		${RSCRIPTS_FOLDER}

date
echo "Files for protconn (bound correction) prepared"

# now waiting for the completion of most part of the cores used by previous conefor cycles
sleep 5400

## PARALLEL CONEFOR CYCLE: RUN CONEFOR FOR BOUND CORRECTION
echo "Now running Conefor for Bound Correction in parallel..."
echo "Script exec_conefor_bound_correction.sh started at $(date)"
./exec_conefor_bound_correction.sh >${LOGPATH}/conefor_bound_corr.log 2>&1

wait


###########################################################
### FOURTH PART: POSTPROCESSING OF CONNECTIVITY RESULTS ###
###########################################################

echo "Post-processing of connectivity data  started at $(date) "

# # POSTPROCESS RESULTS FROM CONEFOR FOR COUNTRY:
# RUN SQL TO CREATE TABLE WITH AREAS FOR COUNTRIES
psql ${dbpar} -t -f ./sql/compute_iso3_area.sql
psql ${dbpar} -c '\copy (SELECT * FROM delli.iso3_areas) to '${iso3_area_geo}.csv' with csv HEADER'

# RUN SCRIPT TO POSTPROCESS RESULTS FOR COUNTRIES
Rscript ${RSCRIPTS_FOLDER}/postproc_protconn_country.R ${results_folder} ${wdpadate} ${iso3_area_geo}.csv ${RSCRIPTS_FOLDER} >${LOGPATH}/postproc_conefor_country.log 2>&1
wait


##########################################################################################

enddate_master=`date +%s`
runtime_master=$(((enddate_master-startdate_master) / 60))

echo " "
echo "-----------------------------------------------------------------------------------"
echo "Full Connectivity analysis performed in "${runtime_master}" minutes"
echo "END OF PROCEDURE                                                                ---"
echo "-----------------------------------------------------------------------------------"

exit

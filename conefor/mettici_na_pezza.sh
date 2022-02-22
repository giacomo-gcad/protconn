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

BASEDIR="/globes/USERS/GIACOMO/protconn/scripts"
source ${BASEDIR}/protconn.conf

NCORES=64

dbpar="-h ${host} -U ${user} -d ${db} -p ${port}"

############################################################################
### SECOND PART : CONNECTIVITY ANALISYS FOR COUNTRIES (BOUND CORRECTION) ###
############################################################################

echo "SECOND PART: CONNECTIVITY ANALISYS FOR COUNTRIES (BOUND CORRECTION) started at $(date) "


# # RUN THE R SCRIPT TO PREPARE THE nodes_ AND distances_FILES NEEDED BY CONEFOR
echo "Now running the R script that prepares the nodes_ and distances_ files needed by Conefor..."
# Rscript ${RSCRIPTS_FOLDER}/prepare_conefor_files_bound_correction.R \
		# ${bound_corr} \
		# ${raw_distance_file_bound} \
		# ${raw_nodes_file_bound} \
		# ${yearsuffix} \
		# ${RSCRIPTS_FOLDER}

# date
# echo "Files for protconn (bound correction) prepared"

# now waiting for the completion of most part of the cores used by previous conefor cycles


## PARALLEL CONEFOR CYCLE: RUN CONEFOR FOR BOUND CORRECTION
echo "Now running Conefor for Bound Correction in parallel..."
echo "Script exec_conefor_bound_correction.sh started at $(date)"
./exec_conefor_bound_correction.sh >${LOGPATH}/conefor_bound_corr.log 2>&1 &



echo " "
echo "-----------------------------------------------------------------------------------"
echo "Full Connectivity analysis performed in "${runtime_master}" minutes"
echo "END OF PROCEDURE                                                                ---"
echo "-----------------------------------------------------------------------------------"

exit

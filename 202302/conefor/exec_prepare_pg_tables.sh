#!/bin/bash
## PROTCONN: IMPORT FINAL RESULTS IN PG AS FINAL TABLES READY FOR DOPA

echo " "
echo "----------------------------------------------------------------------------------"
echo "Script $(basename "$0") started at $(date)                                        "
echo "----------------------------------------------------------------------------------"
echo " "

startdate_master=`date +%s`

# READ VARIABLES FROM CONFIGURATION FILE

BASEDIR="/globes/USERS/GIACOMO/protconn/scripts"
source ${BASEDIR}/protconn.conf

dbpar="-h ${host} -U ${user} -d ${db} -p ${port}"

## Hardcoded globals (OVERRIDE protconn.conf VARIABLES)
schema_results="results_"${wdpadate}"_non_cep_oecm" ## EDIT THIS LINE TO WORK WITH NON OECM RESULTS


# REPLACE PIPE WITH COMMA IN COUNTRY CSV
sed -i.bak 's/|/,/g' ${results_folder}/with_oecm/protconn_results_countries_${wdpadate}.csv
# REPLACE PIPE WITH COMMA IN ECOREGIONS CSV GENERATED IN EXCEL (!!! TO BE FIXED THE OUTPUT FOR 9999_ !!!)
sed -i.bak 's/|/,/g' ${results_folder}/with_oecm/protconn_results_eco_${wdpadate}.csv

wait

# # IMPORT IN PG FINAL RESULTS FOR COUNTRIES
psql ${dbpar} -c 'DROP TABLE IF EXISTS ind_protconn.protconn_countries_with_oecm_'${wdpadate}';
CREATE TABLE ind_protconn.protconn_countries_with_oecm_'${wdpadate}' (iso3 text,protconn double precision);'
psql ${dbpar} -c '\copy ind_protconn.protconn_countries_with_oecm_'${wdpadate}' FROM '${results_folder}/with_oecm/protconn_results_countries_${wdpadate}.csv' with csv HEADER'
psql ${dbpar} -c 'DROP TABLE IF EXISTS ${schema_results}.country_conservation_connectivity;
CREATE TABLE ${schema_results}.country_conservation_connectivity AS
SELECT country country_id,protconn FROM results_'${wdpadate}'_cep_in.atts_country_last 
JOIN ind_protconn.protconn_countries_'${wdpadate}' USING(iso3);'

# # IMPORT IN PG FINAL RESULTS FOR ECOREGIONS
psql ${dbpar} -c 'DROP TABLE IF EXISTS ind_protconn.protconn_eco_with_oecm_'${wdpadate}';
CREATE TABLE ind_protconn.protconn_eco_with_oecm_'${wdpadate}' (eco_id integer,protconn double precision);'
# COY DATA FROM TABLE GENERATED IN EXCEL (!!! TO BE FIXED THE OUTPUT FOR 9999_ !!!)
psql ${dbpar} -c '\copy ind_protconn.protconn_eco_with_oecm_'${wdpadate}' FROM '${results_folder}/with_oecm/protconn_results_eco_${wdpadate}.csv' with csv HEADER'
psql ${dbpar} -c 'DROP TABLE IF EXISTS ${schema_results}.ecoregion_conservation_connectivity;
CREATE TABLE ${schema_results}.ecoregion_conservation_connectivity AS
SELECT eco_id,protconn FROM ind_protconn.protconn_eco_'${wdpadate}';'

wait

##########################################################################################

enddate_master=`date +%s`
runtime_master=$((enddate_master-startdate_master))

echo " "
echo "-----------------------------------------------------------------------------------"
echo "Import performed in "${runtime_master}" seconds"
echo "END OF PROCEDURE                                                                ---"
echo "-----------------------------------------------------------------------------------"

exit

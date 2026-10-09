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
schema_results="results_"${wdpadate}"_non_cep" ## EDIT THIS LINE TO WORK WITH NON OECM RESULTS


# # REPLACE PIPE WITH COMMA IN COUNTRY CSV
# sed -i.bak 's/|/,/g' ${results_folder}/protconn_results_countries_${wdpadate}.csv
# # REPLACE PIPE WITH COMMA IN ECOREGIONS CSV GENERATED IN EXCEL (!!! TO BE FIXED THE OUTPUT FOR 9999_ !!!)
# sed -i.bak 's/|/,/g' ${results_folder}/protconn_results_eco_${wdpadate}.csv

# wait

# # # IMPORT IN PG FINAL RESULTS FOR COUNTRIES
echo "DROP TABLE IF EXISTS ${protconn_schema}.protconn_countries_${wdpadate}_with_oecm;
CREATE TABLE ${protconn_schema}.protconn_countries_${wdpadate}_with_oecm (iso3 text,protconn double precision);" | psql ${dbpar}
echo "\copy ${protconn_schema}.protconn_countries_${wdpadate}_with_oecm FROM ${results_folder}/protconn_results_countries_${wdpadate}.csv with csv HEADER" | psql ${dbpar}
echo "DROP TABLE IF EXISTS ${schema_results}.country_conservation_connectivity;
CREATE TABLE ${schema_results}.country_conservation_connectivity AS
SELECT country country_id,protconn FROM results_${wdpadate}_cep_in.atts_country_last 
JOIN ${protconn_schema}.protconn_countries_${wdpadate}_with_oecm USING(iso3);" | psql ${dbpar}

# # IMPORT IN PG FINAL RESULTS FOR ECOREGIONS
echo "DROP TABLE IF EXISTS ${protconn_schema}.protconn_eco_${wdpadate}_with_oecm;
CREATE TABLE ${protconn_schema}.protconn_eco_${wdpadate}_with_oecm (eco_id integer,protconn double precision);" | psql ${dbpar}
# COPY DATA FROM TABLE GENERATED IN EXCEL (!!! TO BE FIXED THE OUTPUT FOR 9999_ !!!)
echo "\copy ${protconn_schema}.protconn_eco_${wdpadate}_with_oecm FROM ${results_folder}/protconn_results_eco_${wdpadate}.csv with csv HEADER" | psql ${dbpar}
echo "DROP TABLE IF EXISTS ${schema_results}.ecoregion_conservation_connectivity;
CREATE TABLE ${schema_results}.ecoregion_conservation_connectivity AS SELECT eco_id,protconn FROM ${protconn_schema}.protconn_eco_${wdpadate}_with_oecm;" | psql ${dbpar}

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

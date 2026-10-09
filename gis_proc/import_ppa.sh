#!/bin/bash
## PROTCONN: SCRIPT TO SIMPLIFY wdpa_all_relevant in PG

date
start1=`date +%s`

SERVICEDIR="/globes/USERS/GIACOMO/protconn/scripts"

################################################
## EDITED ON 20230502 (PPA ANALYSIS)
source ${SERVICEDIR}/protconn_ppa.conf
################################################

dbpar="-h ${host} -U ${user} -d ${db}"

poly="Protected_areas_excl_PPAs"


ogr2ogr \
-overwrite \
-skipfailures \
-dialect sqlite \
-sql "
SELECT * FROM "${poly}" 
" \
-f "PostgreSQL" PG:"host=${host} user=${user} dbname=${db} active_schema=${wdpa_schema}" \
-nln ${wdpa_schema}".wdpa_40coun_no_ppa" \
-nlt "MULTIPOLYGON" \
${DATADIR}"/WDPA_excl_PPAs.gdb"
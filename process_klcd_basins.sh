#!/bin/bash
# Process klcd_basin union

host="dopaprc"
user="h05ibex"
db="wolfe"
port=5432
pw=`cat ~/.pgpass|grep s-jrciprap| awk '{print $5}' FS=":"`
dbpar="-h ${host} -U ${user} -d ${db}"

DATADIR="/globes/USERS/GIACOMO/kcbd/klcd_intpa/data"
gdb_name="klcd"
lyr_name="klcd_basin_lev7"
# IMPORT UNION OF KLCD AND BASINS PERFORMED IN ARCMAP
ogr2ogr -progress -overwrite -skipfailures -f "PostgreSQL"  \ 
PG:"host=${host} user=${user} dbname=${db} active_schema=klcd password=${pw}" \ 
-nln "klcd.${lyr_name}" -nlt "MULTIPOLYGON" \ 
${DATADIR}/${gdb_name} ${lyr_name}

# COMPUTE AVERAGE DISCHARGE (WEIGHTED BY AREA) FOR EACH KCD
psql ${dbpar} -t -v LYR=${lyr_name} sql/process_basinatlas.sql




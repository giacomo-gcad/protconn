# Workflow for computation of Protection Connectivity

## Introduction

The whole workflow for the computation of Protection Connectivity (hereinafter referred to as ProtConn) has been developed reproducing step by step the procedure described by Santiago Saura as per his handover of June 2019. It consists of 2 steps:

1. GIS processing: 
  - spatial data processing and 
  - computation of distances tables

Presently the GIS processing step uses a mix of arcypython (ESRI Arcgis license required) and bash/psql tools.

2. ProtConn analysis in Conefor: 
  - processing of distances tables and computation of ProtConn
  - post-processing of outputs from Conefor.

The ProtConn analysis step is based on bash, R and psql scripts. **Conefor with command line interface** is required. Here, [version 2.7.3](http://www.conefor.org/files/usuarios/Conefor_command_line.zip) is used. 

**TBD**: removing the the arcpython component from step 1. The main constraint in removing this component is the 'dissolve' features step, not successfully implementable (until now) in Postgis.


Input data used are for computation of ProtConn are:

  - WDPA (latest gdb file downloaded from [protectedplanet.net](https://www.protectedplanet.net))
  - Global Administrative Unit Layers (GAUL), revision 2015 (2017-02-02). 
  - Terrestrial Ecoregions of the World (Olson et al., 2001).   

Presently both GAUL and Ecoregions layers are stored as feature classes in the gdb ../data/BaseLayers.gdb and are copied in the working gdb by the relevant script.

### 1. GIS processing

Scripts have been developed and extensively tested for each of the three aggregation levels of ProtConn, i.e. country, country with bound correction and ecoregion.
For each level, the scripts described below need to be executed sequentially.  

All variables of bash scripts are controlled by the configuration file [protconn.conf](protconn.conf).  

The variables for arcpython scripts are declared at the beginning of each script.  

**TBD**: prepare an external file with variables and import in python at start.  

A full run of all the GIS processing scripts described below takes approximately 3 days in total.  


**a) Country level**  

 
a.1. [exec_simplify_wdpa_all_relevant.sh](gis_proc/exec_simplify_wdpa_all_relevant.sh)  
   - Copy in a new table relevant wdpa and required attributes, simplify polygons, export to shp.  
  
a.2. [wdpa_country.py](gis_proc/arcpy/wdpa_country.py)  
   - Copy GAUL layer from existing BaseLayers.gdb.  
   - Import shapefile with simplified wdpa, process multi iso3 polygons, prepare wdpa flat final, ready for calculation of distances in PostGis (ST_distance).  
   - Generate near table (much slower than the same operation in postgis, described below. Presently it's commented and not executed).  
  
a.3. [exec_near_table_country_parallel.sh](gis_proc/exec_near_table_country_parallel.sh)  
   - Import wdpa from gdb, export attribute table as .txt file, repair geometries and compute Near Table in Postgis for countries. It runs in parallel on 64 cores.    

Overall processing time is approximately 400 minutes (120 minutes for steps a.1-a.2, 280 minutes for step a.3).  


**b) Country level with bound correction**  

b.1. [wdpa_country_boundcorr_1.py](gis_proc/arcpy/wdpa_country_boundcorr_1.py)  
   - Convert GAUL to single part, repair geometries, compute area_geo  

b.2. [exec_simplify_gaul_bound_correction.sh](gis_proc/exec_simplify_gaul_bound_correction.sh)  
   - Select polygons with area_geo>=1km2  
   - Simplify polygons.  

b.3. [wdpa_country_boundcorr_2.py](gis_proc/arcpy/wdpa_country_boundcorr_2.py)  
   - Import simplified polygons, merge gaul and wdpa, repair geometries.  
   - Generate near table (much slower than the same operation in postgis, described below. Presently it's commented and not executed).  

b.4. [exec_near_table_country_bcorr_parallel.sh](gis_proc/exec_near_table_country_bcorr_parallel.sh)  
   - Import relevant layer from gdb, export attribute table as .txt file, repair geometries and compute Near Table in Postgis for countries with bound correction. It runs in parallel on 72 cores.  

Overall processing time is approximately 280 minutes (30 minutes for steps b.1-b.3, 250 minutes for step b.4).  


**c) Ecoregion level**  

c.1. [wdpa_ecoregion.py](gis_proc/arcpy/wdpa_ecoregion.py)  
   - Select terrestrial ecoregions, dissolve WDPA, intersect it with ecoregions, select polygons over 1km2, add and compute required fields, export attributes  
   - Generate near table (much slower than the same operation in postgis, presently is commented and not executed).  
   
c.2. [exec_near_table_ecoregion_parallel.sh](gis_proc/exec_near_table_ecoregion_parallel.sh)  
   - Import relevant layer from gdb, export attribute table as .txt file, repair geometries and compute Near Table in Postgis for ecoregions.  It runs in parallel on 70 cores.  
   
Overall processing time is approximately 110 minutes (45 minutes for step c.1, 65 minutes for step c.2).  

  
**Recommendations and tips**  
   - when moving a layer from/to the FIle GDB to/from Postgis it's always worth **to check the number of objects** in input and output.  
 

### 2. ProtConn Analysis in Conefor  

Scripts for conefor analysis are devoped in bash, psql and R.  
Conefor analysis is executed five times:  

1) for countries, including transboundary PAs;  

2) for countries, excluding transboundary PAs;  

3) for countries with bound correction (i.e. considering also PAs that are up to a given maximum distance - 300 km);  

4) for ecoregions, including transboundary PAs;  

5) for ecoregions, excluding transboundary PAs;  

For each of the above runs, input data used (all produced with GIS processing step) are:  

   - attributes table file. It **must** include a unique identifier (iso3 as text for countries, eco_id as integer for ecoregions) and area in km2 for each object.  
   - distances file, generated either in postgis or arcpy.  

Each run generates a pair of text files (nodes file and distances file) for each object (country or ecoregion), stored in a temporary folder:  

For each run, first a R script is executed to prepare a pair of text files (nodes file and distances file) for each object (country or ecoregion), then the executable conefor is run  for each object (country or ecoregion) in parallel, using 48 threads.
Once completed all the confefor cycles, two R scripts are run to postprocess/aggregate the outputs from analysis and write final ProtConn results.  

A [master script](conefor/exec_full_conefor_master.sh) calls in sequence all the subscripts required to perform the whole ProtConn analysis and postprocessing. Also, it performs some string operations (using bash conmands) required to format the intermediate text files generated.  

Here below the list of subscripts called by master script.  

**1) Countries**  

   - [prepare_conefor_files_country.R](conefor/R_scripts/prepare_conefor_files_country.R)  
   - [exec_conefor_country_part1.sh](conefor/exec_conefor_country_part1.sh)  
   - [exec_conefor_country_part2.sh](conefor/exec_conefor_country_part2.sh)  

**2) Countries with bound correction**  

   - [prepare_conefor_files_bound_correction.R](conefor/R_scripts/prepare_conefor_files_bound_correction.R)  
   - [exec_conefor_bound_correction.sh](conefor/exec_conefor_bound_correction.sh)  

**3) Ecoregions**  

   - [prepare_conefor_files_ecoregions.R](conefor/R_scripts/prepare_conefor_files_ecoregions.R)  
   - [exec_conefor_eco_part1.sh](conefor/exec_conefor_eco_part1.sh)  
   - [exec_conefor_eco_part2.sh](conefor/exec_conefor_eco_part2.sh)  


In postprocessing/aggregation phase, the two R scripts involved are:  

   - [postproc_protconn_country.R](conefor/R_scripts/postproc_protconn_country.R)  
   - [postproc_protconn_eco.R](conefor/R_scripts/postproc_protconn_eco.R)  


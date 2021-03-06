# -*- coding: utf-8 -*-
# --------------------------------------------------------------------------------
# b1country_boudcorr_draft.py
# Created on: 2019-11-15 14:01:37.00000
#   (generated by ArcGIS/ModelBuilder)
# Description: GIS processing for Country-ProtCoon with bound correction (part 1#2)
# --------------------------------------------------------------------------------

# Import modules
import sys
import arcpy
from arcpy import env
import os
import os.path

from datetime import datetime
firststarttime=datetime.now()

print(" ")
print("PROCEDURE STARTED at ", datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
print('-------------------------------------------------------')

# Set environment variables
arcpy.env.overwriteOutput = True

# Output Geodatabase
outgdb = "Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/"

# Local variables:
gaul = outgdb+"gaul"
gaul_singleparted = outgdb+"gaul_singleparted"
gaul_for_bound_corr_gpkg = "Z:/globes/USERS/GIACOMO/protconn/data/gaul_for_bound_corr.gpkg"

# Process: Multipart To Singlepart
arcpy.MultipartToSinglepart_management(gaul, gaul_singleparted)
print("Gaul converted to single part")

# Process: Repair Geometry
arcpy.RepairGeometry_management(gaul_singleparted, "DELETE_NULL")
print("Geometries repaired")

# Process: Add Geometry Attributes
arcpy.AddGeometryAttributes_management(gaul_singleparted, "AREA_GEODESIC", "", "SQUARE_KILOMETERS", "GEOGCS['GCS_WGS_1984',DATUM['D_WGS_1984',SPHEROID['WGS_1984',6378137.0,298.257223563]],PRIMEM['Greenwich',0.0],UNIT['Degree',0.0174532925199433]]")
print("Geodetic area computed")

# Process: Create SQLite Database
if arcpy.Exists(gaul_for_bound_corr_gpkg):
	print(gaul_for_bound_corr_gpkg, " already exists.")
else:
	arcpy.CreateSQLiteDatabase_management(gaul_for_bound_corr_gpkg, "GEOPACKAGE")

# Process: Feature Class to Feature Class with threshold >1km2
arcpy.FeatureClassToFeatureClass_conversion(gaul_singleparted, gaul_for_bound_corr_gpkg, "gaul_singleparted", "\"AREA_GEO\" >=1", "id_object \"id_object\" true true false 4 Long 0 0 ,First,#,Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/gaul_singleparted,id_object,-1,-1;id_country \"id_country\" true true false 4 Long 0 0 ,First,#,Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/gaul_singleparted,id_country,-1,-1;name_iso31 \"name_iso31\" true true false 254 Text 0 0 ,First,#,Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/gaul_singleparted,name_iso31,-1,-1;sovereign_ \"sovereign_\" true true false 254 Text 0 0 ,First,#,Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/gaul_singleparted,sovereign_,-1,-1;sovereig_1 \"sovereig_1\" true true false 254 Text 0 0 ,First,#,Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/gaul_singleparted,sovereig_1,-1,-1;sovereig_2 \"sovereig_2\" true true false 254 Text 0 0 ,First,#,Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/gaul_singleparted,sovereig_2,-1,-1;iso3 \"iso3\" true true false 254 Text 0 0 ,First,#,Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/gaul_singleparted,iso3,-1,-1;iso2 \"iso2\" true true false 254 Text 0 0 ,First,#,Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/gaul_singleparted,iso2,-1,-1;un_m49 \"un_m49\" true true false 254 Text 0 0 ,First,#,Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/gaul_singleparted,un_m49,-1,-1;source \"source\" true true false 254 Text 0 0 ,First,#,Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/gaul_singleparted,source,-1,-1;status \"status\" true true false 254 Text 0 0 ,First,#,Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/gaul_singleparted,status,-1,-1;original_d \"original_d\" true true false 254 Text 0 0 ,First,#,Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/gaul_singleparted,original_d,-1,-1;original_n \"original_n\" true true false 254 Text 0 0 ,First,#,Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/gaul_singleparted,original_n,-1,-1;source_cod \"source_cod\" true true false 254 Text 0 0 ,First,#,Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/gaul_singleparted,source_cod,-1,-1;sqkm \"sqkm\" true true false 8 Double 0 0 ,First,#,Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/gaul_singleparted,sqkm,-1,-1;Shape_Length \"Shape_Length\" true true true 8 Double 0 0 ,First,#,Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/gaul_singleparted,Shape_Length,-1,-1,Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/gaul_singleparted,Shape_length,-1,-1;Shape_Area \"Shape_Area\" true true true 8 Double 0 0 ,First,#,Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/gaul_singleparted,Shape_Area,-1,-1,Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/gaul_singleparted,Shape_area,-1,-1;ORIG_FID \"ORIG_FID\" true true false 0 Long 0 0 ,First,#,Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/gaul_singleparted,ORIG_FID,-1,-1;AREA_GEO \"AREA_GEO\" true true false 4 Double 0 0 ,First,#,Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/gaul_singleparted,AREA_GEO,-1,-1", "")
print("Features exported in Geopackage")

print('-------------------------------------------------------')
endtime=datetime.now()
totaltime= endtime-firststarttime
print(' ')
print('PROCEDURE COMPLETED. Elapsed time: ', totaltime)
print('Now execute in docker the script "/globes/USERS/GIACOMO/protconn/scripts/gis_proc/exec_simplify_gaul_bound_correction.sh" ')
print(' ')

sys.exit()

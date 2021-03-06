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

log = open("Z:/globes/USERS/GIACOMO/protconn/logs/b1_country_boundcorr.log", "a")
sys.stdout = log

from datetime import datetime
firststarttime=datetime.now()

print(" ")
print("PROCEDURE STARTED at ", datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
print('-------------------------------------------------------')

# Set environment variables
arcpy.env.overwriteOutput = True

# Output Geodatabase
outgdb_name="ProtConn_Jun2020.gdb"
outgdb_fullpath = "Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Jun2020.gdb"
#Out_path
outpath="Z:/globes/USERS/GIACOMO/protconn/data"

# Local variables:
gaul = outgdb_fullpath+"/gaul"
gaul_singleparted = outgdb_fullpath+"/gaul_singleparted"

# Process: Multipart To Singlepart
arcpy.MultipartToSinglepart_management(gaul, gaul_singleparted)
print("Gaul converted to single part")

# Process: Repair Geometry
arcpy.RepairGeometry_management(gaul_singleparted, "DELETE_NULL")
print("Geometries repaired")

# Process: Add Geometry Attributes
arcpy.AddGeometryAttributes_management(gaul_singleparted, "AREA_GEODESIC", "", "SQUARE_KILOMETERS", "GEOGCS['GCS_WGS_1984',DATUM['D_WGS_1984',SPHEROID['WGS_1984',6378137.0,298.257223563]],PRIMEM['Greenwich',0.0],UNIT['Degree',0.0174532925199433]]")
print("Geodetic area computed")

print('-------------------------------------------------------')
endtime=datetime.now()
totaltime= endtime-firststarttime
print(' ')
print('PROCEDURE COMPLETED. Elapsed time: ', totaltime)
print('Now execute in docker the script "/globes/USERS/GIACOMO/protconn/scripts/gis_proc/exec_simplify_gaul_bound_correction.sh" ')
print(' ')

log.close()
sys.exit()

# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# c1ecoregion.py
# Created on: 2019-11-18 11:11:22.00000
#   (generated by ArcGIS/ModelBuilder)
# Description: GIS processing for Ecoregion-ProtCoon (part 1#1)
# ---------------------------------------------------------------------------

# Import arcpy module
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
arcpy.env.workspace = "Z:/globes/USERS/GIACOMO/protconn/data/"

# Output Geodatabase
outgdb = "Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/"
outpath = "Z:/globes/USERS/GIACOMO/protconn/data"
outshape="wdpa_ecoregions_final.shp"

# Output layers
ecoregions = outgdb+"ecoregions_2019"
terrestrial_ecoregions = outgdb+"terrestrial_ecoregions"
terrestrial_ecoregions_lyr = "terrestrial_ecoregions"
wdpa_all_relevant_shape_simpl = outgdb+"wdpa_all_relevant_shape_simpl"
wdpa_dissolved_for_ecoregions = outgdb+"wdpa_dissolved_for_ecoregions"
wdpa_dissolved_for_ecoregions_1km_lyr = "wdpa_dissolved_for_ecoregions_1km_lyr"
wdpa_dissolved_for_ecoregions_1km = outgdb+"wdpa_dissolved_for_ecoregions_1km"
wdpa_simpl_dissolved_1km_intersect_ecoreg = outgdb+"wdpa_simpl_dissolved_1km_intersect_ecoreg"
wdpa_simpl_dissolved_1km_intersect_ecoreg_1km = "wdpa_simpl_dissolved_1km_intersect_ecoreg_1km"
wdpa_simpl_dissolved_1km_intersect_ecoreg_1km_singlepart = outgdb+"wdpa_simpl_dissolved_1km_intersect_ecoreg_1km_singlepart"
wdpa_ecoregions_final = outgdb+"wdpa_ecoregions_final"
wdpa_for_protconn_gpkg = "Z:\\globes\\USERS\\GIACOMO\\protconn\\wdpa_for_protconn.gpkg"
all_distances_ecoregions_200km = outgdb+"all_distances_ecoregions_200km"
outfile_attr="Attrib_table_ecoregions_200km.txt"
outfile_dist="all_distances_ecoregions_200km.txt"

# Process: Make Feature Layer terrestrial ecoreg
arcpy.MakeFeatureLayer_management(ecoregions, terrestrial_ecoregions_lyr, "source = 'teow'", "", "OBJECTID OBJECTID VISIBLE NONE;Shape Shape VISIBLE NONE;first_level first_level VISIBLE NONE;second_level_code second_level_code HIDDEN NONE;second_level second_level HIDDEN NONE;third_level_code third_level_code HIDDEN NONE;third_level third_level HIDDEN NONE;source source HIDDEN NONE;sqkm sqkm HIDDEN NONE;Shape_Length Shape_Length HIDDEN NONE;Shape_Area Shape_Area HIDDEN NONE")

# Process: Copy Features
arcpy.CopyFeatures_management(terrestrial_ecoregions_lyr, terrestrial_ecoregions, "", "0", "0", "0")

# Process: Add Field
arcpy.AddField_management(terrestrial_ecoregions, "ECO_Id_int", "LONG", "", "", "", "", "NULLABLE", "NON_REQUIRED", "")

# Process: Calculate Field
arcpy.CalculateField_management(terrestrial_ecoregions, "ECO_Id_int", "float(!first_leve!)", "PYTHON_9.3", "")
print("Terrestrial ecoregions selected")

# Process: Dissolve wdpa
arcpy.Dissolve_management(wdpa_all_relevant_shape_simpl, wdpa_dissolved_for_ecoregions, "", "", "SINGLE_PART", "DISSOLVE_LINES")
print("Simplified wdpa dissolved")

# Process: Repair Geometry
arcpy.RepairGeometry_management(wdpa_dissolved_for_ecoregions, "DELETE_NULL")
print("Geometries of simplified wdpa repaired")

# Process: Add Geometry Attributes
arcpy.AddGeometryAttributes_management(wdpa_dissolved_for_ecoregions, "AREA_GEODESIC", "", "SQUARE_KILOMETERS", "GEOGCS['GCS_WGS_1984',DATUM['D_WGS_1984',SPHEROID['WGS_1984',6378137.0,298.257223563]],PRIMEM['Greenwich',0.0],UNIT['Degree',0.0174532925199433]]")

# Process: Make Feature Layer over 1 km2
arcpy.MakeFeatureLayer_management(wdpa_dissolved_for_ecoregions, wdpa_dissolved_for_ecoregions_1km_lyr, "\"AREA_GEO\" >=1", "", "OBJECTID OBJECTID VISIBLE NONE;Shape Shape VISIBLE NONE;AREA_GEO AREA_GEO VISIBLE NONE")

# Process: Copy Features
arcpy.CopyFeatures_management(wdpa_dissolved_for_ecoregions_1km_lyr, wdpa_dissolved_for_ecoregions_1km, "", "0", "0", "0")
print("Simplified wdpa over 1 km2 selected")

# Process: Pairwise Intersect (ArcGis PRO)
arcpy.analysis.PairwiseIntersect(r"Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/terrestrial_ecoregions;Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/wdpa_dissolved_for_ecoregions_1km",r"Z:/globes/USERS/GIACOMO/protconn/data/ProtConn_Mar2020.gdb/wdpa_simpl_dissolved_1km_intersect_ecoreg", "ALL", None, "INPUT")
print("Terrestrial ecoregions intersected with Simplified wdpa over 1 km")

# Process: Add Geometry Attributes (2)
arcpy.AddGeometryAttributes_management(wdpa_simpl_dissolved_1km_intersect_ecoreg, "AREA_GEODESIC", "", "SQUARE_KILOMETERS", "GEOGCS['GCS_WGS_1984',DATUM['D_WGS_1984',SPHEROID['WGS_1984',6378137.0,298.257223563]],PRIMEM['Greenwich',0.0],UNIT['Degree',0.0174532925199433]]")

# Process: Make Feature Layer over 1 km
arcpy.MakeFeatureLayer_management(wdpa_simpl_dissolved_1km_intersect_ecoreg, wdpa_simpl_dissolved_1km_intersect_ecoreg_1km, "\"AREA_GEO\" >1", "", "OBJECTID OBJECTID VISIBLE NONE;FID_ecoregions FID_ecoregions VISIBLE NONE;Shape Shape VISIBLE NONE;first_leve first_leve VISIBLE NONE;first_le_1 first_le_1 VISIBLE NONE;second_lev second_lev VISIBLE NONE;second_l_1 second_l_1 VISIBLE NONE;third_leve third_leve VISIBLE NONE;third_le_1 third_le_1 VISIBLE NONE;source source VISIBLE NONE;teow_eco_n teow_eco_n VISIBLE NONE;teow_eco_c teow_eco_c VISIBLE NONE;teow_gbl_s teow_gbl_s VISIBLE NONE;teow_gbl_1 teow_gbl_1 VISIBLE NONE;teow_area_ teow_area_ VISIBLE NONE;teow_g200_ teow_g200_ VISIBLE NONE;teow_g20_1 teow_g20_1 VISIBLE NONE;teow_g20_2 teow_g20_2 VISIBLE NONE;teow_g20_3 teow_g20_3 VISIBLE NONE;teow_g20_4 teow_g20_4 VISIBLE NONE;teow_g20_5 teow_g20_5 VISIBLE NONE;sqkm sqkm VISIBLE NONE;Shape_Length Shape_Length VISIBLE NONE;Shape_Area Shape_Area VISIBLE NONE;ECO_Id_int ECO_Id_int VISIBLE NONE;FID_wdpa_all_relevant_shape_simpl_dissolved_all_for_ecoregions FID_wdpa_all_relevant_shape_simpl_dissolved_all_for_ecoregions VISIBLE NONE;Shape_Length_1 Shape_Length_1 VISIBLE NONE;Shape_Area_1 Shape_Area_1 VISIBLE NONE;AREA_GEO AREA_GEO VISIBLE NONE;Shape_length Shape_length VISIBLE NONE;Shape_area Shape_area VISIBLE NONE;AREA_GEO AREA_GEO VISIBLE NONE")
print("Intersected features over 1 km selected")

# Process: Repair Geometry (2)
arcpy.RepairGeometry_management(wdpa_simpl_dissolved_1km_intersect_ecoreg_1km, "DELETE_NULL")
print("Geometries re-repaired...")

# Process: Multipart To Singlepart
arcpy.MultipartToSinglepart_management(wdpa_simpl_dissolved_1km_intersect_ecoreg_1km, wdpa_simpl_dissolved_1km_intersect_ecoreg_1km_singlepart)
print("Intersected features converted to singlepart")

# Process: Repair Geometry (3)
arcpy.RepairGeometry_management(wdpa_simpl_dissolved_1km_intersect_ecoreg_1km_singlepart, "DELETE_NULL")
print("Geometries re-re-repaired...")

# Process: Add Geometry Attributes (3)
arcpy.AddGeometryAttributes_management(wdpa_simpl_dissolved_1km_intersect_ecoreg_1km_singlepart, "AREA_GEODESIC", "", "SQUARE_KILOMETERS", "GEOGCS['GCS_WGS_1984',DATUM['D_WGS_1984',SPHEROID['WGS_1984',6378137.0,298.257223563]],PRIMEM['Greenwich',0.0],UNIT['Degree',0.0174532925199433]]")
print("Geodesic area re-computed")

# Process: Add Field (2)
arcpy.AddField_management(wdpa_simpl_dissolved_1km_intersect_ecoreg_1km_singlepart, "nodeid", "LONG", "", "", "", "", "NULLABLE", "NON_REQUIRED", "")

# Process: Calculate Field
arcpy.CalculateField_management(wdpa_simpl_dissolved_1km_intersect_ecoreg_1km_singlepart, "nodeid", "!OBJECTID!", "PYTHON_9.3", "")
print("Field nodeid added and calculated")

# Process: Delete Field
arcpy.DeleteField_management(wdpa_simpl_dissolved_1km_intersect_ecoreg_1km_singlepart, "FID_terrestrial_ecoregions;first_leve;first_le_1;second_lev;second_l_1;third_leve;third_le_1;source;teow_eco_n;teow_eco_c;teow_gbl_s;teow_gbl_1;teow_area_;teow_g200_;teow_g20_1;teow_g20_2;teow_g20_3;teow_g20_4;teow_g20_5;sqkm;FID_wdpa_dissolved_for_ecoregions_1km;ORIG_FID")
print("Useless fields deleted")

# Process: Copy Features
arcpy.CopyFeatures_management(wdpa_simpl_dissolved_1km_intersect_ecoreg_1km_singlepart, wdpa_ecoregions_final, "", "0", "0", "0")
print("Final feature class ready for ST_Distance created")

# Export attributes tables of final wdpa to txt file
arcpy.CopyRows_management(in_rows=wdpa_ecoregions_final, out_table=outfile_attr, config_keyword="")
print("Attribute Table exported in .txt")

# Process: Copy Features to shp (export to gpkg does not work, 2 features are lost in the process)
arcpy.FeatureClassToFeatureClass_conversion(wdpa_ecoregions_final, out_path=outpath, out_name=outshape, field_mapping='ECO_Id_int "ECO_Id_int" true true false 4 Long 0 0 ,First,#,wdpa_ecoregions_final,ECO_Id_int,-1,-1;AREA_GEO "AREA_GEO" true true false 8 Double 0 0 ,First,#,wdpa_ecoregions_final,AREA_GEO,-1,-1;nodeid "nodeid" true true false 4 Long 0 0 ,First,#,wdpa_ecoregions_final,nodeid,-1,-1;Shape_Leng "Shape_Leng" false true true 8 Double 0 0 ,First,#,wdpa_ecoregions_final,Shape_Length,-1,-1;Shape_Area "Shape_Area" false true true 8 Double 0 0 ,First,#,wdpa_ecoregions_final,Shape_Area,-1,-1')
partialtime=datetime.now()
laptime= partialtime-firststarttime
print('wdpa_ecoregions_final processed and exported in shapefile in ', laptime)

# Process: Generate Near Table 
print("Generating Near Table, please wait... about 3.5 days")
print("Meanwhile, you could execute in docker the script /globes/USERS/GIACOMO/protconn/scripts/gis_proc/exec_generate_near_table_ecoregion.sh")
arcpy.GenerateNearTable_analysis(wdpa_ecoregions_final, wdpa_ecoregions_final, all_distances_ecoregions_200km, "200 Kilometers", "NO_LOCATION", "NO_ANGLE", "ALL", "0", "GEODESIC")
print("Near Table generated")

# Process: Copy Rows
arcpy.CopyRows_management(all_distances_ecoregions_200km, outfile_dist, "")
print("Distance table exported in .txt")

print('-------------------------------------------------------')
endtime=datetime.now()
totaltime= endtime-firststarttime
print(' ')
print('PROCEDURE COMPLETED. Elapsed time: ', totaltime)
print(' ')

sys.exit()

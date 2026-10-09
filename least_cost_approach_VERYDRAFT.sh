##!/bin/bash
##COMPUTE NEAR TABLE USING A LEAST COST SURFACE RASTER
## GENERAL SKETCH AI-GENERATED USING GENESIS

# Set the computational region to the extent of the cost surface
## TO BE MODIFIED, the region can't be the whole cost surface, we need to consider the 300km buffer around the PA
g.region raster=cost_surface 

# Rasterise the source polygon (A) – cells with value 1, background = null
v.to.rast input=polygon_A output=src_raster use=cat value=1

# Rasterise the target polygons – each polygon receives its own category (cat)
v.to.rast input=target_polygons output=target_raster use=cat

# Compute the cumulative cost from the source
r.cost input=cost_surface output=cost_cumulative start_raster=src_raster distance=TRUE

# Derive the least-cost distance for each target polygon
## NON MI CONVINCE
r.stats.zonal input=cost_cumulative zones=target_raster method=minimum separator=pipe output=least_cost_per_polygon.txt

# OUTPUT : 
# zone|minimum
# 1|23.5
# 2|41.2
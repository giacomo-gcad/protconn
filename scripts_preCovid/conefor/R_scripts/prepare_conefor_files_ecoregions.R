## This script performs the connectivity analyses required to obtain the ecoregion-level ProtConn.
## It takes as an input the files obtained in the GIS processing (described in a different document), manipulates and prepares the files as needed for Conefor, 
## and calls the executable file of the Conefor command line.
## There is a different R script for the post-processing of the Conefor results to obtain the values of ProtConn for each ecoregion.
print("Script prepare_conefor_files_ecoregions.R started at:")
print(Sys.time())

args <- commandArgs()

root_folder <- "/globes/USERS/GIACOMO/protconn/scripts/conefor/R_scripts"
node_dist_files_ecoreg_folder <- args[6]
node_dist_files_ecoreg_without_trans_folder <- args[7]

## This is the distance file calculated from the protected area (PA) for the ecoregions
Raw_distance_file  <- args[8]
## Now we need the information on the area and ECO_Id_int of each PA, which is in another file (the attribute table of the PA layer)
raw_nodes_file  <- args[9]

prefix_nodes_files <- "nodes_"
prefix_distances_files <- "distances_"

out_ec <- paste(args[6],"/ECAminmax_ecoregions_with_trans.txt", sep = "")
out_ec_wt <- paste(args[7],"/ECAminmax_ecoregions_without_trans.txt", sep = "")

## The following are the nameS of the folders and some specifications of the file names where the node and distance files for Conefor (graph-based connectivity analysis) will be written
## These two folders have to be created "manually" in the location of "inputfolder" above (they are not created automatically by the script) and should contain the executable file of the Conefor commnad line within them
## The files (not the folders) are created automatically by the script
directory_name <- paste(args[6],"/",sep="")
directory_name_WITHOUT_TRANS <- paste(args[7],"/",sep="")

end_file_name <- "_2019"
end_file_name_WITHOUT_TRANS <- "_2019_WITHOUT_TRANS"
## The folder and file names "WITHOUT_TRANS" refer to the files that do not account for the transboundary connections (and hence do not account for the Trans component of ProtConn)
## The folder and file names without that addition consider the transboundary connections (the comparison of the results from one and the other set of files allows to obtain the Trans component of ProtConn)
###### ALL LOCAL VARIABLES ARE SET

setwd(root_folder) 

Raw_Distances <- read.csv(Raw_distance_file) 
Distances <- Raw_Distances 
Raw_Nodes <- read.csv(raw_nodes_file)


## Remove two columns that are not needed from distance file
Distances$OBJECTID <- NULL
Distances$NEAR_RANK <- NULL

## Now we identify the duplicates (i.e. both directions; the distance from X to Y is (should be) the same than from Y to X). 
## We check that this is the case (that the distance from X to Y is the same than from Y to X) and then we remove one of the two duplicated cases (e.g. we keep the distance from X to Y and remove the distance from Y to X; any of the two can be kept)
## Procedure taken from one of the responses (not the first one) here: https://stackoverflow.com/questions/29170099/remove-duplicate-column-pairs-sort-rows-based-on-2-columns?rq=1
uid = unique(unlist(Distances[c("IN_FID", "NEAR_FID")], use.names=FALSE))

swap = match(Distances[["IN_FID"]], uid) > match(Distances[["NEAR_FID"]], uid)

tmp = Distances[swap, "IN_FID"]
Distances[swap, "IN_FID"] = Distances[swap, "NEAR_FID"]
Distances[swap, "NEAR_FID"] = tmp
Distances <- Distances[!duplicated(Distances[1:2]),]

## Remove columns that are not needed, by selecting/retaining only the columns of interest from Raw_Nodes
Nodes <- data.frame(Raw_Nodes$nodeid) ## Modified by GD on 20191126: all 'OBJECTID' replaced bi 'nodeid'
Nodes$ECO_Id_int <- Raw_Nodes$ECO_Id_int
Nodes$AREA_GEO <- Raw_Nodes$AREA_GEO
colnames(Nodes) <- c("nodeid","ECO_Id_int","AREA_GEO")

list_ECO_ID <- unique(Nodes$ECO_Id_int)

## Now we select, for each ecoregion (ECO_Id_int code), the rows in the distance file that have that ECO_Id_int in any of the two ID columns
## We do so because we want to include the PAS that are within a given ecoregion (ECO_Id_int code) but also those that are up to a given maximum distance (300 km) around the PAs of that ecoregion (ECO_Id_int)

for (i in list_ECO_ID) 
{
  ## First we select from the node file the rows that correspond to a given ecoregion
  Nodes_current_ecoregion <- Nodes[Nodes$ECO_Id_int %in% i,]
  
  ## Now we find in the distance file the rows that have, in any of the ID fields (In or Near), the objectID of the list of IDs for a given ecoregion (Nodes_current_ecoregion)
  temp_Distances_current_ecoregion <- Distances[Distances$IN_FID %in% Nodes_current_ecoregion$nodeid | Distances$NEAR_FID %in% Nodes_current_ecoregion$nodeid,]
  temp_Nodes_FINAL_current_ecoregion <- Nodes[Nodes$nodeid %in% temp_Distances_current_ecoregion$IN_FID  | Nodes$nodeid %in% temp_Distances_current_ecoregion$NEAR_FID | Nodes$nodeid %in% Nodes_current_ecoregion$nodeid,]
  ## Now we add those that have distances calculated from/to any of the previous rows
  Distances_current_ecoregion <- Distances[Distances$IN_FID %in% temp_Nodes_FINAL_current_ecoregion$nodeid | Distances$NEAR_FID %in% temp_Nodes_FINAL_current_ecoregion$nodeid,]
  ## And here only those cases in which both PAs in the distance pair are within the ecoregion (we here exclude transboundary connectivity)
  Distances_current_ecoregion_WITHOUT_TRANS <- Distances[Distances$IN_FID %in% Nodes_current_ecoregion$nodeid & Distances$NEAR_FID %in% Nodes_current_ecoregion$nodeid,]
  
  ## Now I select the cases for the node file of a given country (ISO3 code). The last condition is to include the cases "intra" (intra-patch / intra-PA connectivity) from all the PAs within a given country
  Nodes_FINAL_current_ecoregion <- Nodes[Nodes$nodeid %in% Distances_current_ecoregion$IN_FID  | Nodes$nodeid %in% Distances_current_ecoregion$NEAR_FID | Nodes$nodeid %in% Nodes_current_ecoregion$nodeid,]
  ## The node file for a given ecoregion but without the transboundary connectivity component is directly the one we had from before
  Nodes_FINAL_current_ecoregion_WITHOUT_TRANS <-Nodes_current_ecoregion
  
  ## Now we need to set the attribute (area) equal to zero for those PAs that are not found within the ecoregion (these PAs are only potential stepping stones, not sources or destinations). This obviously only applies to the case in which the transboundary connectivity is considered
  Nodes_FINAL_current_ecoregion$AREA_GEO [Nodes_FINAL_current_ecoregion$ECO_Id_int != i] <- 0
  
  ## Now we remove the second column with the ECO_Id_int, wihch is no longer needed within the file
  Nodes_FINAL_current_ecoregion$ECO_Id_int <- NULL
  Nodes_FINAL_current_ecoregion_WITHOUT_TRANS$ECO_Id_int <- NULL
  
  ## This will be the node file for the ecoregion (ECO_Id_int), saved without column headers and without row names (this is the right format for Conefor)
  node_file_name <- paste(directory_name,prefix_nodes_files,i,end_file_name,sep="")
  write.table(Nodes_FINAL_current_ecoregion, file=node_file_name, row.names = FALSE, col.names = FALSE,  sep="\t")
  
  node_file_name_WITHOUT_TRANS <- paste(directory_name_WITHOUT_TRANS,prefix_nodes_files,i,end_file_name_WITHOUT_TRANS,sep="")
  write.table(Nodes_FINAL_current_ecoregion_WITHOUT_TRANS, file=node_file_name_WITHOUT_TRANS, row.names = FALSE, col.names = FALSE,  sep="\t")
  
  ## And now we similarly produce the distance file for COnefor for the country (ISO3 code)
  distance_file_name <- paste(directory_name,prefix_distances_files,i,end_file_name,sep="")
  write.table(Distances_current_ecoregion, file=distance_file_name, row.names = FALSE, col.names = FALSE,  sep="\t")
  
  distance_file_name_WITHOUT_TRANS <- paste(directory_name_WITHOUT_TRANS,prefix_distances_files,i,end_file_name_WITHOUT_TRANS,sep="")
  write.table(Distances_current_ecoregion_WITHOUT_TRANS, file=distance_file_name_WITHOUT_TRANS, row.names = FALSE, col.names = FALSE,  sep="\t")
  
  ## this is just to see the progress of the loop
  print(i)
 
}

## First we make the runs considering the transboundary connectivity
setwd(node_dist_files_ecoreg_folder) 

## The following lines ("for" loop) will account and correct for the cases (ecoregions) that have nothing written in the distance file, which can be because of two reasons:
## 1) There is only one node (one PA) and hence do not have any distance calculated between any pair of PAs
## 2) There are several PAs but they are separated by a distance larger than the maximum dispersal distance considered (300 km) and hence there are no distance values in the distance file
## Both cases are solved in the same way: we add a "imaginary" or "fake" node in the node file, and we create a distance file with a distance that is almost infinite between this "imaginary" node and the first node that appears listed in the node file of the ecoregion
## This does not cause any change in the resultant connectivity values for the ecoregion, but allows to have the results of Conefor calculated systematically and in the same format and table for all ecoregions (including the ecoregions in this case that is here "corrected" or treated separately)

## In the following lines ("for" loop) we also calculate the minimum and maximum possible value of ECA (Equivalent Connected Area) in each ecoregion

file_names_nodes <- dir(node_dist_files_ecoreg_folder, pattern = prefix_nodes_files)
file_names_distances <- dir(node_dist_files_ecoreg_folder, pattern = prefix_distances_files)
ECAminmax<-as.table(matrix(nrow=length(file_names_nodes),ncol=3,byrow=TRUE))
for(i in 1:length(file_names_nodes))
{
  nodefile <- read.table(file_names_nodes[i],header=FALSE, sep="\t", stringsAsFactors=FALSE)
  ## Using "tryCatch" here allows to detect the cases with an empty distance file and avoid an error when dealing with these cases
  distfile <- tryCatch(read.table(file_names_distances[i],header=FALSE, sep="\t", stringsAsFactors=FALSE), error=function(e) NULL)
  # ECAminmax[i,1]=substr(file_names_nodes[i],nchar(file_names_nodes[i])-num_char_id_unit+1,nchar(file_names_nodes[i]))
  ECAminmax[i,1]=substr(file_names_nodes[i],nchar(prefix_nodes_files)+1,nchar(prefix_nodes_files)+5+nchar(end_file_name))
  ECAminmax[i,2]=sqrt(sum(nodefile[,2]*nodefile[,2]))
  ECAminmax[i,3]=sum(nodefile[,2])
  if (is.null(nrow(distfile)))
  {
    nodefile[nrow(nodefile)+1,] =c(-1,0)
    distfile <-as.table(matrix(c(nodefile[1,1],nodefile[nrow(nodefile),1],99999999999999999999),ncol=3,byrow=TRUE))
    write.table(nodefile,file = file_names_nodes[i],row.names=FALSE,col.names=FALSE,sep="\t")
    write.table(distfile,file=paste(prefix_distances_files,substr(file_names_nodes[i],nchar(prefix_nodes_files)+1,nchar(file_names_nodes[i])),sep=""),row.names=FALSE,col.names = FALSE,sep="\t")
  }
}

## Now we write the minimum and maximum values that are possible for ECA in each country
write.table(ECAminmax,file = out_ec,row.names=FALSE,col.names=FALSE,sep="\t")


## And now we do the same as above but without considering the transboundary connectivity component (without trans)
setwd(node_dist_files_ecoreg_without_trans_folder) 

file_names_nodes <- dir(node_dist_files_ecoreg_without_trans_folder, pattern = prefix_nodes_files)
file_names_distances <- dir(node_dist_files_ecoreg_without_trans_folder, pattern = prefix_distances_files)
ECAminmax<-as.table(matrix(nrow=length(file_names_nodes),ncol=3,byrow=TRUE))
for(i in 1:length(file_names_nodes))
{
  nodefile <- read.table(file_names_nodes[i],header=FALSE, sep="\t", stringsAsFactors=FALSE)
  distfile <- tryCatch(read.table(file_names_distances[i],header=FALSE, sep="\t", stringsAsFactors=FALSE), error=function(e) NULL)
  # ECAminmax[i,1]=substr(file_names_nodes[i],nchar(file_names_nodes[i])-num_char_id_unit-9,nchar(file_names_nodes[i])-10)
  ECAminmax[i,1]=substr(file_names_nodes[i],nchar(prefix_nodes_files)+1,nchar(prefix_nodes_files)+5+nchar(end_file_name))
  ECAminmax[i,2]=sqrt(sum(nodefile[,2]*nodefile[,2]))
  ECAminmax[i,3]=sum(nodefile[,2])
  if (is.null(nrow(distfile)))
  {
    nodefile[nrow(nodefile)+1,] =c(-1,0)
    distfile <-as.table(matrix(c(nodefile[1,1],nodefile[nrow(nodefile),1],99999999999999999999),ncol=3,byrow=TRUE))
    write.table(nodefile,file = file_names_nodes[i],row.names=FALSE,col.names=FALSE,sep="\t")
    write.table(distfile,file=paste(prefix_distances_files,substr(file_names_nodes[i],nchar(prefix_nodes_files)+1,nchar(file_names_nodes[i])),sep=""),row.names=FALSE,col.names = FALSE,sep="\t")
  }
}

write.table(ECAminmax,file = out_ec_wt,row.names=FALSE,col.names=FALSE,sep="\t")

print("Script prepare_conefor_files_ecoregions.R ended at:")
print(Sys.time())

## END



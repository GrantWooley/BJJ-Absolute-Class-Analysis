#Contains common Vars across R scripts.


library(here)
#forcats needs to be inlcuded in setup file. During Quarto file render, one of the plot objects that are
#loaded has a forcats function that is called in the plot object.
library(forcats)

Path_Main <- file.path(here())
Path_Data <- file.path(Path_Main,"data")
Path_Data_Raw <- file.path(Path_Main,"data","raw_data")
Path_Plots <- file.path(Path_Data,"plots")

File_Results <- "IBJJF_Results_Weight_Class.rds"
File_Absolute_Results <- "IBJJF_Results_Absolute.rds"

read_Plot <- function(plotFile){
  readRDS(file.path(Path_Plots,plotFile))
}
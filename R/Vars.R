#Contains common Vars across R scripts.

library(here)

Path_Main <- file.path(here())
Path_Data <- file.path(Path_Main,"data")
Path_Data_Raw <- file.path(Path_Main,"data","raw_data")

File_Results <- "IBJJF_Results_Weight_Class.rds"
File_Absolute_Results <- "IBJJF_Results_Absolute.rds"
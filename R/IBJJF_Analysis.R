#Script to do analys after inital data cleansing.

rm(list = ls())

source("C:/Users/grant/OneDrive/Road To DE/Data Projects/BJJ Absolute Class Analysis/R/Vars.R")
dt_Results <- readRDS(file.path(Path_Data,File_Results))
dt_Absolute_Results <- readRDS(file.path(Path_Data,File_Absolute_Results))

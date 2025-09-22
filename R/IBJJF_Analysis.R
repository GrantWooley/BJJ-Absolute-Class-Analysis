#Script to do analys after inital data cleansing.

rm(list = ls())

library(here)

source(here("R","Vars.R"))

dt_Results <- readRDS(file.path(Path_Data,File_Results))
dt_Absolute_Results <- readRDS(file.path(Path_Data,File_Absolute_Results))

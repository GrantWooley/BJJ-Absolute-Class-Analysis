rm(list = ls())

library(data.table)
library(dplyr)
library(tidyr)
library(ggplot2)
library(stringr)
library(scales)
library(forcats)
library(purrr)
library(here)


print("Set up environment.")
source(here("R", "0.1_Setup.R"))

print("Clean Raw Data")
source(here("R", "1.0_Data_Cleansing.R"))

print("Run Analysis and Produce Plots")
source(here("R", "2.0_IBJJF_Analysis.R"))

print("Run Data Quality Checks")
source(here("R", "3.0_DQC.R"))

print("Analysis finsihed, ready for Quarto site to be rendered.")
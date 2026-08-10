#Script to do analysis after initial data cleansing.
rm(list = ls())

library(here)
library(data.table)
library(dplyr)
library(ggplot2)
library(scales)
library(forcats)
library(purrr)

source(here("R", "0.1_Setup.R"))

dt_Results <- readRDS(file.path(Path_Data,File_Results))
dt_Absolute_Results <- readRDS(file.path(Path_Data,File_Absolute_Results))

dt_Absolute_Results %>% sample_n(10)

dt_Results %>% sample_n(10)

summary(dt_Absolute_Results)
glimpse(dt_Absolute_Results)


sum_stats <- function(df) {
      df %>% group_by(Tournament) %>%
        summarize(
          n = n(),
          n_age = n_distinct(Age),
          n_gender = n_distinct(Gender),
          n_weight_class = n_distinct(Weight_Class),
          # min_weight_class = min(Weight_Class),
          # max_weight_class = max(Weight_Class),
          n_weight = n_distinct(Weight),
          min_weight = min(Weight),
          avg_weight = mean(Weight),
          max_weight = max(Weight),
          n_year = n_distinct(Year),
          min_year = min(Year),
          # median_year = median(Year),
          max_year = max(Year),

          n_belt = n_distinct(Belt),
          n_distinct_placing = n_distinct(Placing),
          min_placing = min(Placing),
          median_placing = median(Placing),
          max_placing = max(Placing),
          n_name = n_distinct(Competitor_Name),
          n_academy = n_distinct(Academy_Name)


        )
}

sum_stats(dt_Results)

# Count NAs for all columns in the dataset
dt_Results %>%
  summarise(across(everything(), ~ sum(is.na(.))))

dt_Results %>%
  group_by(Tournament) %>%
  summarise(
           na_Type = sum(is.na(Type)),
           na_Age = sum(is.na(Age)),
           na_Gender = sum(is.na(Gender)),
           na_Weight_Class = sum(is.na(Weight_Class)),
           na_Weight = sum(is.na(Weight)),
           na_UOM= sum(is.na(UOM)),
           na_Year = sum(is.na(Year)),
           na_Belt = sum(is.na(Belt)),
           na_Placing = sum(is.na(Placing)),
           na_Competitor_Name = sum(is.na(Competitor_Name)),
  )

# Count NAs in the 'column_name' variable
dt_Results %>%
  summarise(na_count = sum(is.na(Weight)))

dt_Check <- dt_Results %>% filter(Tournament == "BRAZILIAN NATIONAL IBJJF JIU JITSU CHAMPIONSHIP")


#Need to code up a check that looks at distinct value per group. I'm seeing some columns like Belt where I've missed some translation.

# Data Quality Checks
rm(list = ls())

library(here)
library(data.table)
library(dplyr)
library(ggplot2)
library(scales)
library(forcats)
library(purrr)

source(here("R", "0.1_Setup.R"))

dt_Results <- readRDS(file.path(Path_Data_Processed,File_Results))
dt_Absolute_Results <- readRDS(file.path(Path_Data_Processed,File_Absolute_Results))


# Expected Values ####
# Validate all values in cleaned data.tables are expected.

Valid_Types <- c('GI','NO-GI')
Valid_Age <- 'Adult'
Valid_Genders <- c('Male','Female')
# NAs acceptable for these two categoires. For some competitiors there is no way to determine their weight class. I.e. They only ever have records competing in the Open class.
Valid_Weight_Classes <- c('LIGHT FEATHER','FEATHER','LIGHT','MIDDLE','MEDIUM HEAVY','HEAVY','SUPER HEAVY','ULTRA HEAVY','ROOSTER', NA)
Valid_UOM  <- c('lbs', NA)
Valid_Tournaments <- c(
  'WORLD IBJJF JIU JITSU CHAMPIONSHIP',
  'WORLD IBJJF JIU JITSU NO GI CHAMPIONSHIP',
  'PAN IBJJF JIU JITSU CHAMPIONSHIP',
  'PAN IBJJF JIU JITSU NO GI CHAMPIONSHIP',
  'EUROPEAN IBJJF JIU JITSU CHAMPIONSHIP',
  'EUROPEAN IBJJF JIU JITSU NO GI CHAMPIONSHIP',
  'BRAZILIAN NATIONAL IBJJF JIU JITSU CHAMPIONSHIP',
  'BRAZILIAN NATIONAL JIU JITSU NO GI CHAMPIONSHIP'
)
# Purple Brown Black and Brown Black categoires are from earlier tournament years where Female divisions were often merged across belt levels.
Valid_Belts <- c('Black','Purple Brown Black', 'Brown Black')
Valid_Placings <- c(1,2,3)

# Validate all values in a column are pre-defined expected values.
Validate_Column <- function (dataTable, columnName, expectedValues){
  dataTable %>%
    summarise(all_valid = all({{columnName}} %in% expectedValues)) %>%
    pull() %>%
    return()

}

dt_data_quality_checks <- data.table(
  Data_Table = c('dt_Results', 'dt_Absolute_Results'),
  Type_Valid = c(),
  Age_Valid = c(),
  Gender_Valid = c(),
  Weight_Class_Valid = c(),
  UOM_Valid = c(),
  Tournament_Valid = c(),
  Belt_Valid = c(),
  Placing_Valid = c()

)


dt_data_quality_checks[Data_Table == 'dt_Results', Type_Valid := Validate_Column(dt_Results,Type,Valid_Types)]
dt_data_quality_checks[Data_Table == 'dt_Results', Age_Valid := Validate_Column(dt_Results,Age,Valid_Age)]
dt_data_quality_checks[Data_Table == 'dt_Results', Gender_Valid := Validate_Column(dt_Results,Gender,Valid_Genders)]
dt_data_quality_checks[Data_Table == 'dt_Results', Weight_Class_Valid := Validate_Column(dt_Results,Weight_Class,Valid_Weight_Classes)]
dt_data_quality_checks[Data_Table == 'dt_Results', UOM_Valid := Validate_Column(dt_Results,UOM,Valid_UOM)]
dt_data_quality_checks[Data_Table == 'dt_Results', Tournament_Valid := Validate_Column(dt_Results,Tournament,Valid_Tournaments)]
dt_data_quality_checks[Data_Table == 'dt_Results', Belt_Valid := Validate_Column(dt_Results,Belt,Valid_Belts)]
dt_data_quality_checks[Data_Table == 'dt_Results', Placing_Valid := Validate_Column(dt_Results,Placing,Valid_Placings)]

dt_data_quality_checks[Data_Table == 'dt_Absolute_Results', Type_Valid := Validate_Column(dt_Absolute_Results,Type,Valid_Types)]
dt_data_quality_checks[Data_Table == 'dt_Absolute_Results', Age_Valid := Validate_Column(dt_Absolute_Results,Age,Valid_Age)]
dt_data_quality_checks[Data_Table == 'dt_Absolute_Results', Gender_Valid := Validate_Column(dt_Absolute_Results,Gender,Valid_Genders)]
dt_data_quality_checks[Data_Table == 'dt_Absolute_Results', Weight_Class_Valid := Validate_Column(dt_Absolute_Results,Weight_Class,Valid_Weight_Classes)]
dt_data_quality_checks[Data_Table == 'dt_Absolute_Results', UOM_Valid := Validate_Column(dt_Absolute_Results,UOM,Valid_UOM)]
dt_data_quality_checks[Data_Table == 'dt_Absolute_Results', Tournament_Valid := Validate_Column(dt_Absolute_Results,Tournament,Valid_Tournaments)]
dt_data_quality_checks[Data_Table == 'dt_Absolute_Results', Belt_Valid := Validate_Column(dt_Absolute_Results,Belt,Valid_Belts)]
dt_data_quality_checks[Data_Table == 'dt_Absolute_Results', Placing_Valid := Validate_Column(dt_Absolute_Results,Placing_Absolute,Valid_Placings)]



if (any(dt_data_quality_checks == FALSE)) {
  print(dt_data_quality_checks)
  stop("Validation failed, unexpected values. Investigate.")
}


# Row Count Checks ####

# Regular Results dt Check #

# 9 possible weight classes * 4 placings max per weight class = 36 placings/rows per gender category.
max_row_count_tournamnet_year_gender <- 36
# Some early tournamnet years have a pretty low row count but with tournamnets now being large we should never see a super low row count for future tournaments.
min_tournament_row_count <- 10

dt_Gender_Row_Count <- dt_Results %>%
  group_by(Tournament,Year, Gender) %>%
  summarize(Row_Count = n(), .groups = "drop") %>%
  arrange(Tournament, Year, Gender)

dt_Year_Row_Count<- dt_Results %>%
  group_by(Tournament,Year) %>%
  summarize(Row_Count = n(), .groups = "drop") %>%
  arrange(Tournament, Year)


if (any(dt_Gender_Row_Count$Row_Count > max_row_count_tournamnet_year_gender)) {
  print(dt_Gender_Row_Count)
  stop("Validation failed, greater than max number of expected rows in dt_Results.")
}


if (any(dt_Year_Row_Count$Row_Count < min_tournament_row_count)){
  print(dt_Year_Row_Count)
  stop("Validation failed, low record count for tournament year in dt_Results.")
}


# Aboslute Results dt Check #

# For the aboslute there should never be more than 4 placings.
max_row_count_tournamnet_year_gender <- 4

dt_Gender_Row_Count <- dt_Absolute_Results %>%
  group_by(Tournament,Year, Gender) %>%
  summarize(Row_Count = n(), .groups = "drop") %>%
  arrange(Tournament, Year, Gender)

if (any(dt_Gender_Row_Count$Row_Count > max_row_count_tournamnet_year_gender)) {
  print(dt_Gender_Row_Count)
  stop("Validation failed, greater than max number of expected rows in dt_Absolute_Results.")
}

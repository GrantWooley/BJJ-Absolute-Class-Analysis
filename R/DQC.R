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

dt_Results <- readRDS(file.path(Path_Data_Processed,File_Results))
dt_Absolute_Results <- readRDS(file.path(Path_Data_Processed,File_Absolute_Results))

# NAs to figure out if thats aboslute or what that is.

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



# Preta value in belt need to fix this.
# NA values Wieght_Class, UOM_Valid
dt_Results %>% distinct(Placing)

dt_Results %>% filter(Belt == 'Preta') %>%


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
dt_Results %>% colnames()



dt_Results %>% distinct(Belt)






#Some type of NA check maybe.

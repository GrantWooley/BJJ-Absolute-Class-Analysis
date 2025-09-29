#Script used to clean the scraped data.
rm(list = ls())

library(data.table)
library(dplyr)
library(tidyr)
library(stringr)
library(purrr)
library(here)

source(here("R","Vars.R"))

dt_IBJFF_Weight_Classes <- data.table(
  Type = c("GI","GI","GI","GI","GI","GI","GI","GI","GI","GI","GI","GI","GI","GI","GI","GI","GI",
           "NO-GI","NO-GI","NO-GI","NO-GI","NO-GI","NO-GI","NO-GI","NO-GI","NO-GI","NO-GI","NO-GI","NO-GI","NO-GI","NO-GI","NO-GI","NO-GI","NO-GI"),
  Age = c("Adult","Adult","Adult","Adult","Adult","Adult","Adult","Adult","Adult", "Adult","Adult","Adult","Adult","Adult","Adult","Adult","Adult",
          "Adult","Adult","Adult","Adult","Adult","Adult","Adult","Adult","Adult", "Adult","Adult","Adult","Adult","Adult","Adult","Adult","Adult"),
  Gender = c("Male","Male","Male","Male","Male","Male","Male","Male","Male",
             "Female","Female","Female","Female","Female","Female","Female","Female",
             "Male","Male","Male","Male","Male","Male","Male","Male","Male",
             "Female","Female","Female","Female","Female","Female","Female","Female"),
  Weight_Class = c("ROOSTER","LIGHT FEATHER", "FEATHER", "LIGHT","MIDDLE","MEDIUM HEAVY","HEAVY", "SUPER HEAVY", "ULTRA HEAVY",
                   "ROOSTER","LIGHT FEATHER", "FEATHER", "LIGHT","MIDDLE","MEDIUM HEAVY","HEAVY", "SUPER HEAVY",
                   "ROOSTER","LIGHT FEATHER", "FEATHER", "LIGHT","MIDDLE","MEDIUM HEAVY","HEAVY", "SUPER HEAVY", "ULTRA HEAVY",
                   "ROOSTER","LIGHT FEATHER", "FEATHER", "LIGHT","MIDDLE","MEDIUM HEAVY","HEAVY", "SUPER HEAVY"),
  #For Super Heavy Female, and Ultra Heavy Male there is no actual weight defined by IBJJF. It is uncapped, but to make time series
  #plots work correctly we need to declare an actual weight. I took the average weight diference between each Type/Gender category
  #combination to set the weight for Super Heavy and Ultra Heavy. This biases some of the anlysis in favor of lighter competitors/weights.
  #I think this bias is acceptable to produce good time series plots.
  Weight = c(127.0,141.6,154.6,168.0,181.6,195.0,208.0,222.0, 236.0,
             107.0,118.0,129.0,141.6,152.6,163.6,175.0, 186.4,
             122.6,136.0,149.0,162.6,175.6,188.6,202,215,228.0,
             103.0,114.0,125.0,136.0,147.0,158.0,169.0,180.0)
)
dt_IBJFF_Weight_Classes <- dt_IBJFF_Weight_Classes[, UOM := "lbs"]


Files_Raw_Data <- list.files(Path_Data_Raw)
#Funciton read raw data files.
File_Read_Results <- function (fileName,filePath){
  File <- file.path(filePath,fileName)
  #Enforcing character as datatype, to handle NAs in some columns causing fread to get confused. Convert to numeric later.
  df <- fread(File, colClasses = c(
    Age = "character",
    Gender = "character",
    Belt = "character",
    `Weight Class` = "character",
    Placing = "character",
    `Competitor Name` = "character",
    `Academy Name` = "character",
    Year = "character",
    Tournament = "character"
  ))
}
dt_Results <- map(Files_Raw_Data,File_Read_Results,Path_Data_Raw)
dt_Results <- bind_rows(dt_Results) %>% setDT()

dt_Results <- dt_Results %>%
  rename_with( ~ gsub(" ","_", .x))

dt_Results <- dt_Results[, `:=`(
  Placing = as.numeric(Placing),
  Weight_Class = case_when(
      Weight_Class == "Galo" ~ "Rooster",
      Weight_Class == "Pluma" ~ "Light Feather",
      Weight_Class == "Pena" ~ "Feather",
      Weight_Class == "Leve" ~ "Light",
      Weight_Class == "Medio" ~ "Middle",
      Weight_Class == "Meio Pesado" ~ "Medium Heavy",
      Weight_Class == "Pesado" ~ "Heavy",
      Weight_Class == "Super Pesado" ~ "Super-Heavy",
      Weight_Class == "Pesadissimo" ~ "Ultra Heavy",
      Weight_Class == "Absoluto" ~ "Absolute",
      Weight_Class == "Enum_WeightDivision_Absoluto_Label" ~ "Absolute",
      Weight_Class == "Open Class" ~ "Absolute",
      .default = Weight_Class
  ),
  Gender = case_when(
    Gender == "Masculino" ~ "Male",
    Gender == "Feminino" ~ "Female",
    .default = Gender
  ),
  Age = ifelse(Age == "Adulto","Adult",Age)
)
]

dt_Results <- dt_Results[ ,`:=`(
  Weight_Class = toupper(str_replace_all(Weight_Class, "-"," ")),
  Tournament = toupper(str_replace_all(Tournament, "-"," "))
)
]
#In 2009 for the CAMPEONATO BRASILEIRO DE JIU JITSU tournament. Several Female divisions only had one entrance. They were not given a placing. However by default they would have placed 1st.
#Correcting these NAs.
dt_Results <- dt_Results[is.na(Placing) & Tournament == "CAMPEONATO BRASILEIRO DE JIU JITSU" & Year == "2009", Placing := 1]

dt_Results <- dt_Results[, Type := case_when(
  Tournament %like% "NO GI" ~ "NO-GI",
  Tournament %like% "SEM KIMONO" ~ "NO-GI",
  .default = "GI"
)]

#Tournament names are not consistent, need to account for this. I.e. Worlds has 3 different names. Correcting this issue.
dt_Results <- dt_Results[Type == "GI", Tournament := case_when(
           Tournament %like% "WORLD" ~ "WORLD IBJJF JIU JITSU CHAMPIONSHIP",
           Tournament %like% "EUROPEAN" ~ "EUROPEAN IBJJF JIU JITSU CHAMPIONSHIP",
           Tournament %like% "PAN" ~ "PAN IBJJF JIU JITSU CHAMPIONSHIP",
           Tournament %like% "BRASILEIRO" ~ "BRAZILIAN NATIONAL IBJJF JIU JITSU CHAMPIONSHIP",
           .default = Tournament
)
]
dt_Results <- dt_Results[Type == "NO-GI", Tournament := case_when(
  Tournament %like% "WORLD" ~ "WORLD IBJJF JIU JITSU NO GI CHAMPIONSHIP",
  Tournament %like% "EUROPEAN" ~ "EUROPEAN IBJJF JIU JITSU NO GI CHAMPIONSHIP",
  Tournament %like% "PAN" ~ "PAN IBJJF JIU JITSU NO GI CHAMPIONSHIP",
  Tournament %like% "BRASILEIRO" ~ "BRAZILIAN NATIONAL JIU JITSU NO GI CHAMPIONSHIP",
  .default = Tournament
)
]


dt_Results <- dt_IBJFF_Weight_Classes[dt_Results, on = c("Weight_Class","Gender", "Type","Age")]

#Join together our data to get the weight of each Absolute compteitor.
dt_Absolute_Results <- dt_Results[Weight_Class == "ABSOLUTE"]
dt_helper <- dt_Results[Weight_Class != "ABSOLUTE",.(Type,Gender,Weight_Class,Belt,Competitor_Name,Year,Tournament, Weight,UOM,Placing)]


#Absolute table is the i table, helper is x table
dt_Absolute_Results <- dt_helper[dt_Absolute_Results,
                                  on = c("Type","Gender","Belt","Competitor_Name","Year","Tournament"),
                     j =.(Year,Tournament,Type,Belt,Gender,Age,Competitor_Name,Academy_Name,Weight_Class,Weight,UOM,
                          Placing_Absolute = i.Placing, Placing_Weight_Class = x.Placing)
]
rm(dt_helper)

#After doing our inital join to get the Weight of our Absolute compteitors, we sitll have a couple hundred records where we do not know the wieght
#of the absolute competitor. After data exploration I'm seeing two primary reasons. 1. I see some records where a competitor only entered the absolute, and they have no
#record for a regular weight divison. Possilby an IBJJF ruling or exception i'm unfamiliar with. Dealing with these missing weights in a multitude of ways.
#2. Sometimes the competitors name was not spelled the same between their weight class entrance and their absolute class entrance.

#For the cases where a competitor does not show up in a regular weight division for the tournament, they often show up in a different tournament under a
#weight class. Find their most common weight across all records.
dt_Common_Weight <- dt_Results[Weight_Class != "ABSOLUTE", .(N = .N), by = c("Type","Gender","Weight_Class","Weight","UOM", "Belt", "Competitor_Name")]
dt_Common_Weight <- dt_Common_Weight %>% group_by(Type,Gender, Belt, Competitor_Name) %>% filter(N == max(N)) %>% ungroup()
#Sometimes we have a tie for the most common weight class. I.e. A competitor will have competed an equal number of times across different weight classes.
#My hypothesis is that being heavier increases your odds of oding well in the Absolute, I want to bias the analysis against my hypothesis. So for these instacnes,
#I will keep the record with the lower weight.
dt_Common_Weight <- dt_Common_Weight %>% group_by(Type,Gender, Belt, Competitor_Name) %>% filter(Weight == min(Weight)) %>% ungroup() %>% setDT()
#Join on our common weight to our NA records.
dt_Absolute_Results <- dt_Common_Weight[dt_Absolute_Results, on = c("Type","Gender","Belt","Competitor_Name"),
                                        j = .(Year,Tournament,Type,Belt,Gender,Age,Competitor_Name,Academy_Name,Weight_Class = i.Weight_Class,Weight = i.Weight,
                                              UOM = i.UOM,  Placing_Absolute, Placing_Weight_Class, CW_Weight_Class = x.Weight_Class, CW_Weight = x.Weight, CW_UOM = x.UOM)
                                        ]
dt_Absolute_Results <- dt_Absolute_Results[is.na(Weight_Class), `:=`(
  Weight_Class =  CW_Weight_Class,
  Weight = CW_Weight,
  UOM = CW_UOM
)]
dt_Absolute_Results <- dt_Absolute_Results[, `:=` (  CW_Weight_Class = NULL, CW_Weight = NULL, CW_UOM = NULL)]
rm(dt_Common_Weight)

#For the cases where a competitors name is spelled differently between their weight class entrance and their absolue entrance, I will split our competitior name into a First Name,
#Last Name, and remaining Name columns (some competitors have many names). Then join in our results using Name, Year, Academy, etc... for each of the 3 naming categories. This should catch a large number
#of these spelling errors. Note: I explored using a fuzzy match solution, but this did not work well.
#dt_Results %>% mutate(
#  Fname = str_split(Competitor_Name, " ")
#)
Split_Names <- function (dt,colName){
  dt <- dt %>% mutate(Name_Split = str_split({{colName}}," "))
  dt <- dt %>% unnest_wider(Name_Split, names_sep = "_",transform = str_to_lower)
  dt <- dt %>% rename_with(~gsub("Name_Split","Name",.x))
}

dt_Results_Names <- dt_Results[Weight_Class != "ABSOLUTE"]
dt_Results_Names <- dt_Results_Names %>% rename(RN_Weight_Class = Weight_Class, RN_Weight = Weight, RN_UOM = UOM)
dt_Results_Names <- dt_Results_Names %>% Split_Names(Competitor_Name) %>% mutate(Competitor_Name = NULL) %>%  setDT()
dt_Absolute_Results <- dt_Absolute_Results %>% Split_Names(Competitor_Name) %>% setDT()

Join_Results_Name_Table <- function (dtAbsoluteTable,dtResultsNameTable,nameColumn){
  dt_helper <- dtResultsNameTable[, c("Year", "Tournament", "Type", "Belt", "Gender", "Age", "Academy_Name",
                                      "RN_Weight_Class", "RN_Weight", "RN_UOM", "Placing", nameColumn), with = FALSE]
  #Filter out records that are NA, to prevent incorrect joins as we get to nameColumns that are largely empty.
  dt_helper <-  dt_helper[!is.na(get(nameColumn))]
  dtAbsoluteTable <- dt_helper[dtAbsoluteTable, on = c("Year","Tournament","Type","Belt","Gender","Age","Academy_Name",nameColumn)
  ]
  dtAbsoluteTable[is.na(Weight_Class), `:=`(
    Placing_Weight_Class = Placing,
    Weight_Class =RN_Weight_Class,
    Weight = RN_Weight,
    UOM = RN_UOM
  )]
  dtAbsoluteTable[, `:=`(
    Placing = NULL,
    RN_Weight_Class = NULL,
    RN_Weight = NULL,
    RN_UOM = NULL
  )]
}
#Joining on more than the first 3 names is no longer significantly reducing the amount of null records we have for our weight class
#and is causing duplication. Not worth doing more than 3 columns.
dt_Absolute_Results <- dt_Absolute_Results %>% Join_Results_Name_Table(dt_Results_Names, "Name_1")
dt_Absolute_Results <- dt_Absolute_Results %>% Join_Results_Name_Table(dt_Results_Names, "Name_2")
dt_Absolute_Results <- dt_Absolute_Results %>% Join_Results_Name_Table(dt_Results_Names, "Name_3")

dt_Absolute_Results <- dt_Absolute_Results[,.(Year,Tournament,Type,Belt,Gender,Age,Competitor_Name,Academy_Name,Weight_Class,
                                              Weight,UOM, Placing_Absolute,Placing_Weight_Class
)]

#Drop out the duplicates that was caused by joining on Names.
dt_Absolute_Results <- distinct(dt_Absolute_Results)

#Final Clean Up before saving data.
dt_Results <- dt_Results[Weight_Class != "ABOSLUTE"]
Factor_Order <- c(NA,"ROOSTER","LIGHT FEATHER","FEATHER", "LIGHT","MIDDLE","MEDIUM HEAVY","HEAVY","SUPER HEAVY","ULTRA HEAVY")
dt_Results <- dt_Results[, Weight_Class := factor(Weight_Class, levels = Factor_Order)]
dt_Absolute_Results <- dt_Absolute_Results[, Weight_Class := factor(Weight_Class, levels = Factor_Order)]

setorder(dt_Results,Type,Tournament,Year, Placing)
setorder(dt_Absolute_Results,Type,Tournament,Year, Placing_Absolute)

saveRDS(dt_Results,file.path(Path_Data,File_Results))
saveRDS(dt_Absolute_Results,file.path(Path_Data,File_Absolute_Results))
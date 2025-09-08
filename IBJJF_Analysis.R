rm(list = ls())

#FIXME Dont use all of tidyverse only the packages I need.
library(tidyverse)
library(data.table)
library(readxl)

Path_Main <- file.path(getwd())
Path_Data <- file.path(Path_Main,"IBJJF Result Files")

dt_IBJFF_Weight_Classes <- data.table(
  Type = c("GI","GI","GI","GI","GI","GI","GI","GI","GI","GI","GI","GI","GI","GI","GI","GI","GI",
           "NO-GI","NO-GI","NO-GI","NO-GI","NO-GI","NO-GI","NO-GI","NO-GI","NO-GI","NO-GI","NO-GI","NO-GI","NO-GI","NO-GI","NO-GI","NO-GI","NO-GI"),
  Age = c("Adult","Adult","Adult","Adult","Adult","Adult","Adult","Adult","Adult", "Adult","Adult","Adult","Adult","Adult","Adult","Adult","Adult",
          "Adult","Adult","Adult","Adult","Adult","Adult","Adult","Adult","Adult", "Adult","Adult","Adult","Adult","Adult","Adult","Adult","Adult"),
  Gender = c("Male","Male","Male","Male","Male","Male","Male","Male","Male", "Female","Female","Female","Female","Female","Female","Female","Female",
             "Male","Male","Male","Male","Male","Male","Male","Male","Male", "Female","Female","Female","Female","Female","Female","Female","Female"),
  Weight_Class = c("ROOSTER","LIGHT FEATHER", "FEATHER", "LIGHT","MIDDLE","MEDIUM HEAVY","HEAVY", "SUPER HEAVY", "ULTRA HEAVY", "ROOSTER","LIGHT FEATHER", "FEATHER", "LIGHT","MIDDLE","MEDIUM HEAVY","HEAVY", "SUPER HEAVY",
                   "ROOSTER","LIGHT FEATHER", "FEATHER", "LIGHT","MIDDLE","MEDIUM HEAVY","HEAVY", "SUPER HEAVY", "ULTRA HEAVY", "ROOSTER","LIGHT FEATHER", "FEATHER", "LIGHT","MIDDLE","MEDIUM HEAVY","HEAVY", "SUPER HEAVY"),
  Weight = c(127.0,141.6,154.6,168.0,181.6,195.0,208.0,222.0, NA, 107.0,118.0,129.0,141.6,152.6,163.6,175.0, NA,
             122.6,136.0,149.0,162.6,175.6,188.6,202,215,NA,103.0,114.0,125.0,136.0,147.0,158.0,169.0,NA)
)
dt_IBJFF_Weight_Classes <- dt_IBJFF_Weight_Classes[, UOM := "lbs"]


List_Df <- list()

for( File  in list.files(Path_Data)){
  File <- file.path(Path_Data,File)
  #FIXME Update Python scrapers to produce .csv files, then use fread for faster I/O
  df <- read_excel(File,sheet = 1)
  List_Df[[length(List_Df) + 1]] <- df
}

dt_Results <- bind_rows(List_Df)
setDT(dt_Results)

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
#In 2009 for the CAMPEONATO BRASILEIRO DE JIU JITSU tournament. Several Female divisions only had on entrance. They were not giving a placing. However by default they would have placed 1st.
#Correcting these NAs.
dt_Results <- dt_Results[is.na(Placing), Placing := 1]

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

dt_Absolute_Results <- dt_Results[Weight_Class == "ABSOLUTE"]
dt_helper <- dt_Results[Weight_Class != "ABSOLUTE",.(Type,Gender,Weight_Class,Belt,Competitor_Name,Year,Tournament, Weight,UOM,Placing)]
dt_Absolute_Results <- dt_helper[dt_Absolute_Results,
                                  on = c("Type","Gender","Weight_Class","Belt","Competitor_Name","Year","Tournament"),
                                 #FIXME I really don't know how to use the data.table j argument. Lets learn this next time.
                                 j = .(Year, Tournament, Type, Weight_Class, Age, Belt,Gender, Competitor_Name, Weight , UOM ,
                                       Placing_Weight_Division = Placing, Placing_Absolute = i.Placing, Academy_Name)
]
rm(dt_helper)

dt_Absolute_Results %>% head(10)

colnames(dt_Absolute_Results)


dt_Absolute_Results %>% head(10)


colnames(dt_Results)









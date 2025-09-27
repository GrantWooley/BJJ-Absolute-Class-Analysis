#Script to do analys after inital data cleansing.

rm(list = ls())

library(here)
library(data.table)
library(dplyr)
library(ggplot2)

source(here("R","Vars.R"))

dt_Results <- readRDS(file.path(Path_Data,File_Results))
dt_Absolute_Results <- readRDS(file.path(Path_Data,File_Absolute_Results))

#Before starting my actual analysis my hypothesis is the following:
#It is not realistic for a competitor to win the Absolute regardless of their weight and size. I believe that there is a natural cut off
#point, where you simply become to small. I also generally believe that being larger and heavier increases you chances of winning or placing in the absolute.

#High Level Analysis
#First look at what does the data say in general?
dt_Absolute_High_Level <- dt_Absolute_Results[!is.na(Weight_Class),.(Type,Gender,Placing_Absolute,Weight_Class,Placing_Weight_Class)]
#Do we see a general trend across the whole dataset? What weight class places in the absolute on average?
dt_Absolute_Overview <- dt_Absolute_High_Level[,.N, by = c("Weight_Class")]
dt_Absolute_Overview <- dt_Absolute_Overview[, Total := sum(N)]
dt_Absolute_Overview <- dt_Absolute_Overview[, Proportion := round(N/Total,3)]

dt_Absolute_Overview %>%
  ggplot(aes(x =Weight_Class, y = N))+
  geom_col( fill = "darkorange1", color = "black") +
  geom_text(aes(label = N), vjust = -0.5) +
  labs(
    title = "Absolute Placings by Weight Class",
    subtitle = paste0("# of Observations: ",sum(dt_Absolute_Overview$N)),
    caption = "Placings include taking 2nd or 3rd in the absolute.",
    x = "Weight Class",
    y = "Count"
  )+
    theme_minimal() +
  theme(
    plot.title = element_text(size = 30, face = "bold"),
    axis.title.x = element_text(size = 15,face = "bold"),
    axis.title.y = element_text(size = 15,face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
  )

#Do we see a difference between Gi and No-GI perhaps we see more of a skew in one category or the other.
dt_Absolute_Type <- dt_Absolute_High_Level[,.N, by = c("Type","Weight_Class")]
dt_Absolute_Type <- dt_Absolute_Type[, Total := sum(N), by = c("Type")]
dt_Absolute_Type <- dt_Absolute_Type[, Proportion := round(N/Total,3)]

Observations_GI <- dt_Absolute_Type %>% filter(Type == "GI") %>% summarize(N = sum(N)) %>% pull()
Observations_NO_GI <- dt_Absolute_Type %>% filter(Type == "NO-GI") %>% summarize(N = sum(N)) %>% pull()

dt_Absolute_Type %>%
  ggplot(aes(x =Weight_Class, y = Proportion))+
  geom_col(fill = "darkorange1", color = "black")+
  facet_wrap(vars(Type))+
  geom_text(aes(label = scales::percent(Proportion)), vjust = -0.5) +
  labs(
    title = "GI vs NO-GI Proportion",
    subtitle = paste0("Observations  GI: ",Observations_GI, "  NO-GI: ",Observations_NO_GI),
    caption = "Placings include taking 2nd or 3rd in the absolute.",
    x = "Weight Class",
    y = "Proportion"
  )+
  theme_minimal() +
  theme(
    plot.title = element_text(size = 30, face = "bold",hjust = 0.5),
    plot.subtitle = element_text(size = 12),
    axis.title.x = element_text(size = 15,face = "bold"),
    axis.title.y = element_text(size = 15,face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
    strip.text = element_text(size = 16, face = "bold")
  )



#Do we see a difference between Male and Female perhaps we see more skew in one category or the other.
dt_Absolute_Gender <- dt_Absolute_High_Level[,.N, by = c("Gender","Weight_Class")]
dt_Absolute_Gender <- dt_Absolute_Gender[, Total := sum(N), by = c("Gender")]
dt_Absolute_Gender <- dt_Absolute_Gender[, Proportion := round(N/Total,3)]

Observations_Male <- dt_Absolute_Gender %>% filter(Gender == "Male") %>% summarize(N = sum(N)) %>% pull()
Observations_Female <- dt_Absolute_Gender %>% filter(Gender == "Female") %>% summarize(N = sum(N)) %>% pull()

dt_Absolute_Gender %>%
  ggplot(aes(x =Weight_Class, y = Proportion))+
  geom_col(fill = "darkorange1", color = "black")+
  facet_wrap(vars(Gender))+
  geom_text(aes(label = scales::percent(Proportion)), vjust = -0.5) +
  labs(
    title = "GI vs NO-GI Proportion",
    subtitle = paste0("Observations  Female: ",Observations_Female, "  Male: ",Observations_Male),
    caption = "Placings include taking 2nd or 3rd in the absolute.",
    x = "Weight Class",
    y = "Proportion"
  )+
  theme_minimal() +
  theme(
    plot.title = element_text(size = 25, face = "bold",hjust = 0.5),
    plot.subtitle = element_text(size = 12),
    axis.title.x = element_text(size = 15,face = "bold"),
    axis.title.y = element_text(size = 15,face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
    strip.text = element_text(size = 16, face = "bold")
  )




#Time to start brainstorming what questions do I really want to ask?
#Potential Questions and Analysis
#Levels Male vs Female Gi vs No-GI

#Tournaments Analysis
#Does the tournament play a role at all in who can place in the absolute, perhaps in Brazil where teh sport is very mature its mostly heavier competitors.
#Maybe in Europe where people tend be skinnier we see less heavy weights dominating the aboslute.


#Placings Analysis
#Do people who place high in their weight class place high in the absolute or does it not matter?

#Perhaps the lower weight classes often place in the absolute, but only the heavy weight classes take first. Break down of what percent of each absoute placing
#is made up of different weight classes.




#Trends over time Analysis
#As the sport has matured have we seen the average weight of competitors that place or win the absolute change over time?
#Plot at a macro level.
#Plot at Placing Level.
#Plot at a Malve Vs Female level
#Plot at a tournament level.
#Plot at GI vs No-GI level.
#Remember in early years, women had mixed belts.


#Optional Analysis, what competitor won the absolute the most.
#What academy won the absolute the most.

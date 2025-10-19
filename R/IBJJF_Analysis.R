#Script to do analysis after inital data cleansing.
rm(list = ls())

library(here)
library(data.table)
library(dplyr)
library(ggplot2)
library(scales)
library(forcats)
library(purrr)

source(here("R","Vars.R"))

List_Plots <- list()

dt_Results <- readRDS(file.path(Path_Data,File_Results))
dt_Absolute_Results <- readRDS(file.path(Path_Data,File_Absolute_Results))

#Before starting my actual analysis my hypothesis is the following:
#It is not realistic for a competitor to win the Absolute regardless of their weight and size. I believe that there is a natural cut off
#point, where you simply become to small. I also generally believe that being larger and heavier increases you chances of winning or placing in the absolute.

#High Level Analysis ####
#First look at what does the data say in general?
dt_Absolute_High_Level <- dt_Absolute_Results[!is.na(Weight_Class),.(Type,Gender,Placing_Absolute,Weight_Class,Placing_Weight_Class)]
#Do we see a general trend across the whole dataset? What weight class places in the absolute on average?
dt_Absolute_Overview <- dt_Absolute_High_Level[,.N, by = c("Weight_Class")]
dt_Absolute_Overview <- dt_Absolute_Overview[, Total := sum(N)]
dt_Absolute_Overview <- dt_Absolute_Overview[, Proportion := round(N/Total,3)]

Plot_Overview <- dt_Absolute_Overview %>%
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

List_Plots <- append(List_Plots,list("Overview" = Plot_Overview))


#Do we see a difference between Gi and No-GI perhaps we see more of a skew in one category or the other.
dt_Absolute_Type <- dt_Absolute_High_Level[,.N, by = c("Type","Weight_Class")]
dt_Absolute_Type <- dt_Absolute_Type[, Total := sum(N), by = c("Type")]
dt_Absolute_Type <- dt_Absolute_Type[, Proportion := round(N/Total,3)]

Observations_GI <- dt_Absolute_Type %>% filter(Type == "GI") %>% summarize(N = sum(N)) %>% pull()
Observations_NO_GI <- dt_Absolute_Type %>% filter(Type == "NO-GI") %>% summarize(N = sum(N)) %>% pull()

Plot_Type <- dt_Absolute_Type %>%
  ggplot(aes(x =Weight_Class, y = Proportion))+
  geom_col(fill = "darkorange1", color = "black")+
  facet_wrap(vars(Type))+
  geom_text(aes(label = scales::percent(Proportion, accuracy = Percent_Accuracy)), vjust = -0.5, size = Percent_Size) +
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

List_Plots <- append(List_Plots,list("Type" = Plot_Type))


#Do we see a difference between Male and Female perhaps we see more skew in one category or the other.
dt_Absolute_Gender <- dt_Absolute_High_Level[,.N, by = c("Gender","Weight_Class")]
dt_Absolute_Gender <- dt_Absolute_Gender[, Total := sum(N), by = c("Gender")]
dt_Absolute_Gender <- dt_Absolute_Gender[, Proportion := round(N/Total,3)]

Observations_Male <- dt_Absolute_Gender %>% filter(Gender == "Male") %>% summarize(N = sum(N)) %>% pull()
Observations_Female <- dt_Absolute_Gender %>% filter(Gender == "Female") %>% summarize(N = sum(N)) %>% pull()

Plot_Gender <- dt_Absolute_Gender %>%
  ggplot(aes(x =Weight_Class, y = Proportion))+
  geom_col(fill = "darkorange1", color = "black")+
  facet_wrap(vars(Gender))+
  geom_text(aes(label = scales::percent(Proportion, accuracy = Percent_Accuracy)), vjust = -0.5, size = Percent_Size) +
  labs(
    title = "Female vs Male Proportion",
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

List_Plots <- append(List_Plots,list("Gender" = Plot_Gender))


#Tournaments Analysis
#Does the tournament play a role at all in who can place in the absolute, perhaps in Brazil where the sport is very mature its mostly heavier competitors.
#Maybe in Europe where people tend be skinnier we see less heavy weights dominating the aboslute.
dt_Tournaments <- dt_Absolute_Results[!is.na(Weight_Class), .(Year,Type,Tournament, Weight_Class, Placing_Absolute,Placing_Weight_Class)]
dt_Tournaments <- dt_Tournaments[, Tournament := case_when(
  Tournament == "WORLD IBJJF JIU JITSU CHAMPIONSHIP" ~ "Worlds",
  Tournament == "WORLD IBJJF JIU JITSU NO GI CHAMPIONSHIP" ~ "Worlds",
  Tournament == "PAN IBJJF JIU JITSU CHAMPIONSHIP" ~ "Pans",
  Tournament == "PAN IBJJF JIU JITSU NO GI CHAMPIONSHIP" ~ "Pans",
  Tournament == "BRAZILIAN NATIONAL IBJJF JIU JITSU CHAMPIONSHIP" ~ "Brazilian Nationals",
  Tournament == "BRAZILIAN NATIONAL JIU JITSU NO GI CHAMPIONSHIP" ~ "Brazilian Nationals",
  Tournament == "EUROPEAN IBJJF JIU JITSU CHAMPIONSHIP" ~ "Europeans",
  Tournament == "EUROPEAN IBJJF JIU JITSU NO GI CHAMPIONSHIP" ~ "Europeans",
  .default = Tournament
)]
dt_Tournaments <- dt_Tournaments[,.N, , by = c("Type","Tournament","Weight_Class")]
dt_Tournaments <- dt_Tournaments[, Total := sum(N), by = c("Tournament","Type")]
dt_Tournaments <- dt_Tournaments[, Proportion := round(N/Total,3)]

#GI Tournaments plotting.
dt_Tournaments_GI <- dt_Tournaments[Type == "GI"]
Plot_Tournaments_GI <- dt_Tournaments_GI %>%
  ggplot(aes(x = Weight_Class, y = Proportion)) +
  geom_col(fill = "darkorange1", color = "black")+
  facet_wrap(vars(Tournament), ncol = 2, nrow = 2) +
  geom_text(aes(label = scales::percent(Proportion,accuracy = Percent_Accuracy)), vjust = -0.5, size = Percent_Size) +
  labs(
    title = "Absolute Placings by Tournament : GI",
    subtitle = "Percentage of medals won by weight class.",
    caption = "Placings include taking 2nd or 3rd in the absolute.",
    x = "Weight Class",
    y = "Proportion"
  )+
  theme_minimal() +
  theme(
    plot.title = element_text(size = 30, face = "bold"),
    plot.subtitle = element_text(size = 12),
    axis.title.x = element_text(size = 15,face = "bold"),
    axis.title.y = element_text(size = 15,face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
    strip.text = element_text(size = 16, face = "bold")
  )

List_Plots <- append(List_Plots,list("Tournaments_GI" = Plot_Tournaments_GI))


#NO-GI Tournaments plotting.
dt_Tournaments_NO_GI <- dt_Tournaments[Type == "NO-GI"]
Plot_Tournaments_NO_GI <- dt_Tournaments_NO_GI %>%
  ggplot(aes(x = Weight_Class, y = Proportion)) +
  geom_col(fill = "darkorange1", color = "black")+
  facet_wrap(vars(Tournament), ncol = 2, nrow = 2) +
  geom_text(aes(label = scales::percent(Proportion, accuracy = Percent_Accuracy)), vjust = -0.5, size = Percent_Size) +
  labs(
    title = "Absolute Placings by Tournament : NO-GI",
    subtitle = "Percentage of medals won by weight class.",
    caption = "Placings include taking 2nd or 3rd in the absolute.",
    x = "Weight Class",
    y = "Proportion"
  )+
  theme_minimal() +
  theme(
    plot.title = element_text(size = 30, face = "bold"),
    plot.subtitle = element_text(size = 12),
    axis.title.x = element_text(size = 15,face = "bold"),
    axis.title.y = element_text(size = 15,face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
    strip.text = element_text(size = 16, face = "bold")
  )

List_Plots <- append(List_Plots,list("Tournaments_NO_GI" = Plot_Tournaments_NO_GI))


#Placings Analysis ####
#Do we see certain weight classes taking absolute placing 1, 2, or 3?
dt_Placings <- dt_Absolute_Results[!is.na(Weight_Class), .(Weight_Class,Placing_Absolute,Placing_Weight_Class)]
dt_Placings_Absolute <- dt_Placings
dt_Placings_Absolute <- dt_Placings_Absolute[, .N, by = c("Weight_Class", "Placing_Absolute")]
dt_Placings_Absolute <- dt_Placings_Absolute[, Total := sum(N), by = c("Placing_Absolute")]
dt_Placiings_Absolute <- dt_Placings_Absolute[, Proportion := round(N/Total,3) ]
setorder(dt_Placings_Absolute, Placing_Absolute,Weight_Class)

Plot_Placings_Absolute <- dt_Placings_Absolute %>%
  ggplot(aes(x = Placing_Absolute, y = Proportion, fill = fct_rev(Weight_Class)))+
  geom_bar(stat = "identity") +
  geom_text(
    data =  subset(dt_Placings_Absolute, Proportion >= 0.05),
    aes(label = paste0((Proportion * 100),"%")),
            position = position_stack(vjust = 0.9),
            color = "white", size = 3.5) +
  scale_y_continuous(labels = label_percent())+
labs(
    title = "Proportion of Placings",
    subtitle = "by Weight Class",
    fill = "Weight Class",
    x = "Absolute Placing",
    y = "Proportion"
  )+
  theme_minimal() +
  theme(
    plot.title = element_text(size = 20, face = "bold"),
    plot.subtitle = element_text(size = 12),
    axis.title.x = element_text(size = 15,face = "bold"),
    axis.title.y = element_text(size = 15,face = "bold"),
    axis.text.x = element_text( size = 10,face = "bold")
  )

List_Plots <- append(List_Plots,list("Placings_Absolute" = Plot_Placings_Absolute))

#Do people who place high in their weight class place high in the absolute or does it not matter?
dt_Placings_Weight_Class <- dt_Placings
#Because the IBJJF source data is not super clean. Have to filter out records where I was able to get a Weight class for a competitor based on another years results
#but they did not actually have a wieght class record/placing for the specific tournament/observation.
dt_Placings_Weight_Class <- dt_Placings_Weight_Class[!is.na(Placing_Weight_Class)]
dt_Placings_Weight_Class <- dt_Placings_Weight_Class[, .N, by = c("Placing_Weight_Class", "Placing_Absolute")]
dt_Placings_Weight_Class <- dt_Placings_Weight_Class[, Total := sum(N), by = c("Placing_Absolute")]
dt_Placings_Weight_Class <- dt_Placings_Weight_Class[, Proportion := round(N/Total,3) ]
setorder(dt_Placings_Weight_Class,Placing_Absolute,Placing_Weight_Class)
dt_Placings_Weight_Class <- dt_Placings_Weight_Class[, Placing_Weight_Class := factor(Placing_Weight_Class, levels = c(3,2,1))]

Plot_Placings_Weight_Class <- dt_Placings_Weight_Class %>%
  ggplot(aes(x = Placing_Absolute, y = Proportion, fill = Placing_Weight_Class))+
   geom_bar(stat = "identity") +
   geom_text(
    aes(label = paste0((Proportion * 100),"%")),
    position = position_stack(vjust = 0.5),
    color = "white", size = 3.5) +
   scale_y_continuous(labels = label_percent())+
  labs(
    title = "Proportion of Placings",
    subtitle = "by Weight Class Placing",
    fill = "Weight Class Placing",
    x = "Absolute Placing",
    y = "Proportion"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 20, face = "bold"),
    plot.subtitle = element_text(size = 12),
    axis.title.x = element_text(size = 15,face = "bold"),
    axis.title.y = element_text(size = 15,face = "bold"),
    axis.text.x = element_text( size = 10,face = "bold")
  )

List_Plots <- append(List_Plots,list("Placings_Weight_Class" = Plot_Placings_Weight_Class))



#Note: Graph How many Competitors placed in the absolute per weight class placing.
# I.e. 100 competitors who took 1st in their weight class made the absolute podium.
# 200 competitors who took 2nd in their weight class made the absolute podium. etc… Will do soon.
dt_Placings_Distribution <- dt_Placings
dt_Placings_Distribution <- dt_Placings_Distribution[!is.na(Placing_Weight_Class)]
dt_Placings_Distribution <- dt_Placings_Distribution[, .N, by = c("Placing_Weight_Class")]

Plot_Placings_Distribution <- dt_Placings_Distribution %>%
  ggplot(aes(x =Placing_Weight_Class, y = N))+
  geom_col( fill = "darkorange1", color = "black") +
  geom_text(aes(label = N), vjust = -0.5) +
  labs(
    title = "Absolute Placings by Weight Class Placing",
    subtitle = paste0("# of Observations: ",sum(dt_Placings_Distribution$N)),
    x = "Weight Class Placing",
    y = "Count"
  )+
  theme_minimal() +
  theme(
    plot.title = element_text(size = 30, face = "bold"),
    axis.title.x = element_text(size = 15,face = "bold"),
    axis.title.y = element_text(size = 15,face = "bold"),
    axis.text.x = element_text(angle = 45,hjust = 1, face = "bold"),
    strip.text = element_text(size = 16, face = "bold")
  )

List_Plots <- append(List_Plots,list("Placings_Distribution" = Plot_Placings_Distribution))

#Trends over time Analysis ####
#As the sport has matured have we seen the average weight of competitors that place or win the absolute change over time?
dt_Time_Series <- dt_Absolute_Results[!is.na(Weight_Class), .(Year,Tournament,Type,Belt,Gender,Weight_Class,Weight,UOM, Placing_Absolute,Placing_Weight_Class)]
dt_Time_Series <- dt_Time_Series[, Year := as.Date(paste0(Year,"0101"), format = "%Y%m%d")]

#In the following plots I use geom_smooth with LOESS (LOcal regrESSion). The data is realtively nosiy,
#and the goal with this section of the analysis is to spot a trend, not strictly show results with something
#like geom_line.

#Analyzing 1st place winnders.
dt_TS_First_Place <- dt_Time_Series[Placing_Absolute == 1]
dt_TS_First_Place <- dt_TS_First_Place[, .(Avg_Weight = round(mean(Weight,na.rm = TRUE),2)), by = c("Type","Gender", "Year")]

Plot_TS_First_Place_Male <- dt_TS_First_Place[Gender == "Male"] %>%
  ggplot(aes(x = Year,y = Avg_Weight)) +
  geom_smooth(method = "loess") +
  facet_wrap(vars(Type)) +
  scale_x_date(
    date_breaks = "2 year",
    date_labels = "%Y"
  )+
  labs(
    title = "Avg Weight 1st Place Medalists : Male",
    subtitle = "Trend over time, LOESS method.",
    x = "Average Weight",
    y = "Year"
    ) +
  theme(
    plot.title = element_text(size = 30, face = "bold"),
    axis.title.x = element_text(size = 15,face = "bold"),
    axis.title.y = element_text(size = 15,face = "bold"),
    axis.text.x = element_text(angle = 45,  hjust = 1, face = "bold"),
    strip.text = element_text(size = 16, face = "bold")
  )

List_Plots <- append(List_Plots,list("TS_First_Place_M" = Plot_TS_First_Place_Male))

Plot_TS_First_Place_Female <- dt_TS_First_Place[Gender == "Female"] %>%
  ggplot(aes(x = Year,y = Avg_Weight)) +
  geom_smooth(method = "loess") +
  facet_wrap(vars(Type)) +
  scale_x_date(
    date_breaks = "2 year",
    date_labels = "%Y"
  )+
  labs(
    title = "Avg Weight 1st Place Medalists : Female",
    subtitle = "Trend over time, LOESS method.",
    x = "Average Weight",
    y = "Year"
  ) +
  theme(
    plot.title = element_text(size = 30, face = "bold"),
    axis.title.x = element_text(size = 15,face = "bold"),
    axis.title.y = element_text(size = 15,face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
    strip.text = element_text(size = 16, face = "bold")
  )

List_Plots <- append(List_Plots,list("TS_First_Place_F" = Plot_TS_First_Place_Female))


dt_TS_Two_Three_Place <- dt_Time_Series[Placing_Absolute != 1]
dt_TS_Two_Three_Place <- dt_TS_Two_Three_Place[, .(Avg_Weight = round(mean(Weight,na.rm = TRUE),2)), by = c("Type","Gender", "Year")]

Plot_TS_Two_Three_Place_Male <- dt_TS_Two_Three_Place[Gender == "Male"] %>%
  ggplot(aes(x = Year,y = Avg_Weight)) +
  geom_smooth(method = "loess") +
  facet_wrap(vars(Type)) +
  scale_x_date(
    date_breaks = "2 year",
    date_labels = "%Y"
  )+
  labs(
    title = "Avg Weight 2nd & 3rd Place Medalists : Male",
    subtitle = "Trend over time, LOESS method.",
    x = "Average Weight",
    y = "Year"
  ) +
  theme(
    plot.title = element_text(size = 30, face = "bold"),
    axis.title.x = element_text(size = 15,face = "bold"),
    axis.title.y = element_text(size = 15,face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
    strip.text = element_text(size = 16, face = "bold")
  )

List_Plots <- append(List_Plots,list("TS_Two_Three_Place_M" = Plot_TS_Two_Three_Place_Male))

Plot_TS_Two_Three_Place_Female <- dt_TS_Two_Three_Place[Gender == "Female"] %>%
  ggplot(aes(x = Year,y = Avg_Weight)) +
  geom_smooth(method = "loess") +
  facet_wrap(vars(Type)) +
  scale_x_date(
    date_breaks = "2 year",
    date_labels = "%Y"
  )+
  labs(
    title = "Avg Weight 2nd & 3rd Place Medalists : Female",
    subtitle = "Trend over time, LOESS method.",
    x = "Average Weight",
    y = "Year"
  ) +
  theme(
    plot.title = element_text(size = 30, face = "bold"),
    axis.title.x = element_text(size = 15,face = "bold"),
    axis.title.y = element_text(size = 15,face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
    strip.text = element_text(size = 16, face = "bold")
  )


List_Plots <- append(List_Plots,list("TS_Two_Three_Place_F" = Plot_TS_Two_Three_Place_Female))

#Save Plots
List_Plot_Names <- paste0(Path_Plots,"/",names(List_Plots), ".rds")
map2(List_Plots, List_Plot_Names,~saveRDS(object = .x, file = .y))
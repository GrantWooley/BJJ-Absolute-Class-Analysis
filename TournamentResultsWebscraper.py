#Webscraper Used for Scraping IBJJF Tournament Reulsts
#For Worlds, Pans, Europeans, Brazilian Nationals, No-Gi Worlds, No-Gi Pans, No-Gi Europeans, & No-Gi Brazilian Nationals
#Male Black Belt Divisions

#Import libraries and Webscraper functions
from urllib.request import urlopen
from bs4 import BeautifulSoup
import Scraper_Functions as sc


#Open Connection to the primary IBJJF Event Results Webpage
DirectoryURL = "https://ibjjf.com/events/results"

#Get the Soup
Soup = sc.GetSoup(DirectoryURL)

#Getting all tags that have an asscocitaed results URLs
tags = Soup.find_all('a',class_ = 'event-year-result')


# List of Major Tournament names
Tournaments =["World Jiu-Jitsu IBJJF Championship",
    "World Jiu-Jitsu No-Gi IBJJF Championship",
     "Pan Jiu-Jitsu IBJJF Championship",
     "Pan Jiu-Jitsu No-Gi IBJJF Championship",
     "European Jiu-Jitsu IBJJF Championship",
     "European Jiu-Jitsu No-Gi IBJJF Championship",
     "Campeonato Brasileiro de Jiu-Jitsu",
     "Brazilian National Jiu-Jitsu No-Gi Championship"]


#Storing links to results pages from any tag that has a data-n elemnet matching a major tournament.
#ResultsURLs = [tag['href'] for tag in tags  if any(Tournament in tag['data-n'] for Tournament in Tournaments)]
ResultsURLs = [tag['href'] for tag in tags  if any(Tournament == tag['data-n'] for Tournament in Tournaments)]

#IBJJF has two web page layouts. Around the year 2012 the HTML format/layout changed.
#In the URLs for the results pages this is reflected. The older format web pages' URLs always end 
#in the following format /year-tournammentname-ibjjf-championship. The newer web pages' URLs always
#end wiht /PublicResults

#Loop through URL in ResultsURL list. 
#If the URL ends with PublicResults use the web scraping file set up for the new HTML format/layout
#Else use the web scraping file set up for the old HTML format/layout

#Loop opening connections to every IBJJF Results Page for major tournaments, scraping the webpage, returning a dataframe, and saving as CSV.
i = 0
for URL in ResultsURLs:
    CheckURL = URL.rsplit("/",1)
    if CheckURL[1] == 'PublicResults':
        #Run Webscraper set up for new format.
        print("Scraping: " + URL)
        #Try to connect to the URL, if you can't then continue to next iteration of the loop. 
        try:
            Soup = sc.GetSoup(URL)
        except:
            print("Unable to connect to webpage, continuing to next URL.") 
            continue   
        df = sc.ModernScrape(Soup)
        #Access first row, and columns Tournament, Year of df to set the file name. 
        File = df.loc[0,"Tournament"] +" " + df.loc[0,"Year"]
        df.to_excel(fr"C:\Users\grant\OneDrive\Road To DE\Data Projects\IBJJF Result Files\{File}.xlsx", sheet_name= "Results", index= False)
        print(File + " saved.")    
    else:
        #Run webscraper set up for old format.
        print("Scraping: " + URL)
        #Try to connect to the URL, if you can't then continue to next iteration of the loop. 
        try:
            Soup = sc.GetSoup(URL)
        except:
            print("Unable to connect to webpage,continuing to next URL.")
            continue
        df = sc.LegacyScrape(Soup)
        #Access first row, and columns Tournament, Year of df to set the file name. 
        File = df.loc[0,"Tournament"] +" " + df.loc[0,"Year"]
        df.to_excel(fr"C:\Users\grant\OneDrive\Road To DE\Data Projects\IBJJF Result Files\{File}.xlsx", sheet_name= "Results", index= False)
        print(File + " saved.")
        
print("All Web Pages Successfully Scraped!")

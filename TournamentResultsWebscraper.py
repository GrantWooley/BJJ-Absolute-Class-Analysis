#Webscraper Used for Scraping IBJJF Tournament Reulsts
#For Worlds, Pans, Europeans, Brazilian Nationals, No-Gi Worlds, No-Gi Pans, No-Gi Europeans, & No-Gi Brazilian Nationals
#Madle Black Belt Divisions

#Import libraries beautiful soup urllib
from urllib.request import urlopen
from bs4 import BeautifulSoup

#Open Connection to the primary IBJJF Event Results Webpage
DirectoryURL = "https://ibjjf.com/events/results"
Page = urlopen (DirectoryURL)

#Get HTML
Soup = BeautifulSoup(Page, "html.parser")
#Getting all tags that have an asscocitaed results URL
tags = Soup.find_all('a',class_ = 'event-year-result')

# List ofTournament names
Tournaments =["World Jiu-Jitsu IBJJF Championship",
    "World Jiu-Jitsu No-Gi IBJJF Championship",
     "Pan Jiu-Jitsu IBJJF Championship",
     "Pan Jiu-Jitsu No-Gi IBJJF Championship",
     "European Jiu-Jitsu IBJJF Championship",
     "European Jiu-Jitsu No-Gi IBJJF Championship",
     "European Jiu-Jitsu No-Gi IBJJF Championship"
     "Campeonato Brasileiro de Jiu-Jitsu",
     "Brazilian National Jiu-Jitsu No-Gi Championship"]


ResultsURLs = [tag['href'] for tag in tags  if any(Tournament in tag['data-n'] for Tournament in Tournaments)]
for x in ResultsURLs:
    print(x)
    


#It looks like IBJJF has two web page layouts. Around the year 2012 the HTML changes. 
#Need to figure out how to scrape both the old and the new web page formats for results data.
#If URL ends in Public Results, use new scraping method, else use table scraping method.

#Loop to begin opening connections to every IBJJF Results Page for major tournaments and fetching tournament results data.
#for URL in ResultsURLs:
#    ResultURL = URL
#    ResultPage = urlopen (ResultURL)
    #Get HTML
#    ResultSoup = BeautifulSoup(ResultPage, "html.parser")
    #print(ResultSoup.title)


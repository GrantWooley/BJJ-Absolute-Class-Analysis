#Webscraper Used for Scraping IBJJF tournament results for all major tournaments.
#Worlds, Pans, Europeans, Brazilian Nationals, No-Gi Worlds, No-Gi Pans, No-Gi Europeans, & No-Gi Brazilian Nationals
#Male Black Belt Divisions


from urllib.request import urlopen

from bs4 import BeautifulSoup
from pyhere import here

#Import custom Webscraper functions
import tournament_scrapers as sc

#Major IBJJF Tournament names
TOURNAMENTS =[
    "World Jiu-Jitsu IBJJF Championship",
    "World Jiu-Jitsu No-Gi IBJJF Championship",
    "Pan Jiu-Jitsu IBJJF Championship",
    "Pan Jiu-Jitsu No-Gi IBJJF Championship",
    "European Jiu-Jitsu IBJJF Championship",
    "European Jiu-Jitsu No-Gi IBJJF Championship",
    "Campeonato Brasileiro de Jiu-Jitsu",
    "Brazilian National Jiu-Jitsu No-Gi Championship"
]

#Primary IBJJF Event Results Webpage
URL_RESULTS = "https://ibjjf.com/events/results"

#pyhere used so project can run easily on any machine.
# PATH_DATA = here('data','raw_data')
PATH_DATA = here('data','test')

#Open URL and get beautiful soup object. Defining this function separately to allow
#error handling of the URLs on the IBJFF Results page that are dead links.
def get_main_results_page(URL):
    Soup = urlopen(URL)
    Soup = BeautifulSoup(Soup,"html.parser")
    return Soup

def get_individual_results_urls(soup):
    #Getting all tags that have an associated results URLs
    tags = soup.find_all('a',class_ = 'event-year-result')
    #Storing links to results pages from any tag that has a data-n element matching a major tournament.
    results_urls = [tag['href'] for tag in tags  if any(Tournament == tag['data-n'] for Tournament in TOURNAMENTS)]
    return results_urls

def scrape_webpage(tournament_url):
    #IBJJF has two web page layouts. Around the year 2012 the HTML format/layout changed.
    #In the URLs for the results pages this is reflected. The older format web pages' URLs always end
    #in the following format /year-tournammentname-ibjjf-championship. The newer web pages' URLs always
    #end with /PublicResults
    check_url = current_url.rsplit("/",1)

    #Select appropriate webscraping method based on url.
    if check_url[1] == 'PublicResults':

        df = sc.ModernScrape(Soup)
        return df

    else:

        df = sc.LegacyScrape(Soup)
        return df



if __name__ == "__main__":

    #Get main results page
    Soup = get_main_results_page(URL_RESULTS)
    #Get individual tournament results webpage urls.
    results_urls = get_individual_results_urls(Soup)

    #Scrape each webpage and save results as CSV file.
    for current_url in results_urls:

        #Somre urls provided by results page are broken. Skip if unable to connect.
        try:
            Soup = get_main_results_page(current_url)
        except:
            print("Unable to connect to webpage, continuing to next URL.")
            continue

        print("Scraping: " + current_url)
        df = scrape_webpage(current_url)

        #Access first row of Tournament and Year columns to set the file name.
        file_name = df.loc[0,"Tournament"] +" " + df.loc[0,"Year"]
        df.to_csv(fr"{PATH_DATA}\{file_name}.csv", index= False)

        print(file_name + " saved.")

    print("All Web Pages Successfully Scraped!")
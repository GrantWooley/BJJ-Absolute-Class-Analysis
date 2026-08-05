# Webscraper used for Scraping IBJJF Male Black Belt division tournament results for all major tournaments.
# Worlds, Pans, Europeans, Brazilian Nationals, No-Gi Worlds, No-Gi Pans, No-Gi Europeans, & No-Gi Brazilian Nationals

import re
from urllib.request import urlopen

import pandas as pd
from bs4 import BeautifulSoup
from pyhere import here

# Import custom Webscraper functions
from tournament_scrapers import scrape_legacy_web_page, scrape_modern_web_page

# Major IBJJF Tournament names
TOURNAMENTS = [
    "World Jiu-Jitsu IBJJF Championship",
    "World Jiu-Jitsu No-Gi IBJJF Championship",
    "Pan Jiu-Jitsu IBJJF Championship",
    "Pan Jiu-Jitsu No-Gi IBJJF Championship",
    "European Jiu-Jitsu IBJJF Championship",
    "European Jiu-Jitsu No-Gi IBJJF Championship",
    "Campeonato Brasileiro de Jiu-Jitsu",
    "Brazilian National Jiu-Jitsu No-Gi Championship",
]

# Primary IBJJF Event Results Webpage
URL_RESULTS = "https://ibjjf.com/events/results"

# pyhere used so project can run easily on any machine.
PATH_DATA = here('data','raw_data')

def _get_beautiful_soup(url):
    Soup = urlopen(url)
    Soup = BeautifulSoup(Soup, "html.parser")
    return Soup

def _get_results_urls(Soup, tournaments):
    # Collect all urls to for result webpages for designated major tournaments.
    tournament_result_urls = {}

    for tournament in tournaments:
        results_urls = _get_individual_tournament_urls(Soup, tournament)
        tournament_result_urls[tournament] = results_urls
    
    return tournament_result_urls

def _get_individual_tournament_urls(Soup, tournament):
    # Get results urls for a specific tournament.

    # Find the specific tournament's tags and grab the urls from the tags.
    tags = Soup.find_all("a",
        attrs={
        "data-n": re.compile(fr"^{tournament}"),
        "class": "event-year-result"
        }
    )

    # href element = url
    results_urls = [tag["href"] for tag in tags]

    return results_urls

def _scrape_tournaments_webpages(individual_tournament_urls):
    # Scrape all the results webpages associated with a specific tournament.
    # Returning a list of dataframes. Each df containing the results of the tournament year combination.

    list_dfs = []

    for current_url in individual_tournament_urls:
        # Some urls provided by results page are have been broken in the past. Skip if unable to connect.
        try:
            print("Scraping: " + current_url)
            df = _scrape_individual_webpage(current_url)
            list_dfs.append(df)

        except Exception:
            print("Unable to connect to webpage, continuing to next URL.\n{e}")
            continue

    return list_dfs

def _scrape_individual_webpage(tournament_url):
    # IBJJF has two web page layouts. Around the year 2012 the HTML format/layout changed.
    # The older format web pages' URLs always end in the following format /year-tournammentname-ibjjf-championship.
    # The newer web pages' URLs always end with /PublicResults
    check_url = tournament_url.rsplit("/", 1)

    # Select appropriate webscraping method based on url.
    if check_url[1] == "PublicResults":
        df = scrape_modern_web_page(tournament_url)
        return df

    else:
        df = scrape_legacy_web_page(tournament_url)
        return df

def _format_tournament_df(list_dfs):
    # Combines all individual DataFrames for a tournament into a singular df and formats df in preparation for file save.

    df = pd.concat(list_dfs, ignore_index=True)
    df = df[['Tournament','Year','Age','Belt','Gender','Weight Class','Placing','Competitor Name','Academy Name']]
    df = df.sort_values(['Year','Gender','Placing'], ascending=[True, False, True])

    return df

def _save_tournament_results_file(df):
    # Access first row of Tournament and Year columns to set the file name.
    file_name = df.loc[0, "Tournament"] + " Results.csv"
    df.to_csv(rf"{PATH_DATA}\{file_name}", index=False)

    print(file_name + " saved.")


def main():
    # Get Main result sweb page.
    Soup = _get_beautiful_soup(URL_RESULTS)

    tournament_result_urls = _get_results_urls(Soup, TOURNAMENTS)

    for tournament in tournament_result_urls:

        print("Start Scraping for: " + tournament)

        individual_tournament_urls = tournament_result_urls[tournament]

        list_dfs = _scrape_tournaments_webpages(individual_tournament_urls)

        df = _format_tournament_df(list_dfs)

        _save_tournament_results_file(df)

        print("Finished Scraping for: " + tournament + "\n")

    print("All Web Pages Successfully Scraped!")



if __name__ == "__main__":
    main()

# Webscraper used for Scraping IBJJF Male Black Belt division tournament results for all major tournaments.
# Worlds, Pans, Europeans, Brazilian Nationals, No-Gi Worlds, No-Gi Pans, No-Gi Europeans, & No-Gi Brazilian Nationals

from urllib.request import urlopen

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
# PATH_DATA = here('data','raw_data')
# FIXME
PATH_DATA = here("data", "test")


def _get_individual_results_urls(url):
    # Get individual urls for all results web pages.

    Soup = urlopen(url)
    Soup = BeautifulSoup(Soup, "html.parser")

    # Get tags that have an associated results URL.
    tags = Soup.find_all("a", class_="event-year-result")
    # Storing links to results pages from any tag that has a data-n element matching a major tournament.
    results_urls = [
        tag["href"]
        for tag in tags
        if any(Tournament == tag["data-n"] for Tournament in TOURNAMENTS)
    ]

    return results_urls


def _scrape_webpage(tournament_url):
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


def _save_tournament_results_file(df):
    # Access first row of Tournament and Year columns to set the file name.
    file_name = df.loc[0, "Tournament"] + " " + df.loc[0, "Year"]
    df.to_csv(rf"{PATH_DATA}\{file_name}.csv", index=False)

    print(file_name + " saved.")


def main():
    # Get individual tournament results webpage urls.
    results_urls = _get_individual_results_urls(URL_RESULTS)

    # Scrape each webpage and save results as CSV file.
    for current_url in results_urls:
        # Some urls provided by results page are broken. Skip if unable to connect.
        try:
            print("Scraping: " + current_url)
            df = _scrape_webpage(current_url)

        except Exception:
            print("Unable to connect to webpage, continuing to next URL.\n{e}")
            continue

        _save_tournament_results_file(df)

    print("All Web Pages Successfully Scraped!")


if __name__ == "__main__":
    main()

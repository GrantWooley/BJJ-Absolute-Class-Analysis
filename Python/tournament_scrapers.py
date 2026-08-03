# tournament_scrapers file contains helper function two separate web scraping functions for scraping both the old and new HTML format of the IBJJF results web pages.

from urllib.request import urlopen

import numpy as np
import pandas as pd
from bs4 import BeautifulSoup


def scrape_legacy_web_page(url):
    # Function for Scraping older HTML format of IBJFF pages. From roughly the year 2012 and before.

    Soup = _get_webpage_beautiful_soup(url)

    # Pull out  HTML that includes all athlete result data, excludes Academy Results data.
    athlete_results = Soup.find("div", class_="col-sm-12 athletes")

    # Get Division Information. I.e. adult, blue, male, middle
    division_categories = _collect_legacy_division_categories(athlete_results)
    # Get Placing information. I.e. Placing, Athlete Name, and Academy Name.
    results = _collect_legacy_page_results(athlete_results)

    full_rows = _build_rows_of_data(division_categories, results)
    df = _create_standard_tournament_df(full_rows)

    df = _filter_to_blackbelt_adult(df)
    df["Tournament"] = _get_legacy_tournament_name(Soup)
    df["Year"] = _get_legacy_tournament_year(Soup)
    df = df.reset_index(drop=True)

    return df


def scrape_modern_web_page(url):
    # Function for scraping newer HTML format of IBJJF results pages. Roughly 2012 onward.

    Soup = _get_webpage_beautiful_soup(url)

    # Pull out  HTML that includes all athlete result data, excludes Academy Results data.
    athlete_results = Soup.find("div", class_="col-xs-12 col-md-6 col-athlete")

    # Get Division Information. I.e. adult, blue, male, middle
    division_categories = _collect_modern_division_categories(athlete_results)
    # Get Placing information. I.e. Placing, Athlete Name, and Academy Name.
    results = _collect_modern_page_results(athlete_results)

    full_rows = _build_rows_of_data(division_categories, results)
    df = _create_standard_tournament_df(full_rows)

    df = _filter_to_blackbelt_adult(df)

    # Set year and tournament name using title.
    page_title = _get_modern_page_title(Soup)
    df["Year"] = page_title[-4:]
    df["Tournament"] = page_title[:-4]

    df = df.reset_index(drop=True)

    return df


def _get_webpage_beautiful_soup(url):
    Soup = urlopen(url)
    Soup = BeautifulSoup(Soup, "html.parser")

    return Soup


def _collect_legacy_division_categories(athlete_results):
    # Parse through legacy webpage athlete results data.
    # Pulling out division header info: age, belt, gender, weight.
    # Returning all division headers.
    # I.e. adult, blue, male, middle
    #      adult, blue, male, heavy

    # Grab category tags that contain division info.
    category_tags = athlete_results.find_all("div", class_="category mt-4 mb-3")

    divisions = []
    for category in category_tags:
        # One web page was missing a string attribute for a div tag.
        # If this happens insert a dummy header, as to not negatively affect ordering of finals dataframe results.
        # Should not affect final df. If it does this is handled in data cleaning.
        if category.string is None:
            dummycategory = ["dummy1", "dummy2", "dummy3", "dummy4"]
            divisions.append(dummycategory)
            continue

        # Split the category tag into Age, Belt, Gender, Weight
        category = category.string.split(" / ")
        divisions.append(category)

    return divisions


def _collect_modern_division_categories(athlete_results):
    # Parse through legacy webpage athlete results data.
    # Pulling out division header info: age, belt, gender, weight.
    # Returning all division headers.
    # I.e. adult, blue, male, middle
    #      adult, blue, male, heavy

    # Grab tags that contain division info.
    category_tags = athlete_results.find_all("h4", class_="subtitle")

    divisions = []

    for category in category_tags:
        # Category contents contain age, belt, gender, weight.
        # Contents contain category info in multiple formats. Pull the best format.
        category_contents = category.contents
        category_contents = category_contents[1]

        # Strings need to be split, reordered, and then stripped of line returns to get a clean division list.
        category_contents = category_contents.split("/")
        category_contents = _reorder_modern_division_category(category_contents)
        category_contents = [content.strip() for content in category_contents]

        divisions.append(category_contents)

    return divisions


def _reorder_modern_division_category(category_contents):
    # Reorder contents of the category so it matches the order used in the legacy web pages.
    # I.e. Change order of Age, Gender, Belt, Weight Class to Age, Belt, Gender, Weight Class
    # Allows for reuse of more functions across both web page formats.

    gender = category_contents[1]
    belt = category_contents[2]
    category_contents[1] = belt
    category_contents[2] = gender

    return category_contents


def _collect_legacy_page_results(athlete_results):
    # Pull out table objects from web page, and parse through them collecting results information.

    # Grab Tags that contain Tbodies aka tables.
    result_tables = athlete_results.find_all("tbody")

    # List to Store Placing information. Placing, Athlete Name, and Academy Name.
    results = []

    for table in result_tables:
        # Pull Out td children tags containing Placing, Athlete Name, and Academy Name.
        td_tags = table.find_all("td")
        individual_table_results = _collect_individual_legacy_table_results(td_tags)

        results.append(individual_table_results)

    return results


def _collect_individual_legacy_table_results(td_tags):
    # Collect all rows of an individual tournament results table object.

    individual_table = []

    # Go through tags collecting each row of Placing, Athlete Name, and Academy Name in table object.
    for tag in td_tags:
        # Access td tags class.
        td_tag_class = tag["class"][0]

        # Store Placing information.
        if td_tag_class == "place":
            # Some web pages have errors where no placing was recorded.
            # Returns none. Convert to string to prevent errors in later code.
            individual_table.append(str(tag.string))

        # If the tag is an athlete academy tag, parse the html tree further to get athlete name and academy.
        elif td_tag_class == "athlete-academy":
            div_tags = tag.find_all("div")

            # Collect and Store Athlete Name and Academy Name information.
            for div in div_tags:
                # Some Athletes do not have an affiliated academy, in those instances you get a return of none,
                # converting to string data type to prevent error.
                individual_table.append(str(div.string))

    return individual_table


def _collect_modern_page_results(athlete_results):
    # Pull out table objects from web page, and parse through them collecting results information.

    # Stores Placing information. I.e. Placings, Athlete Names, and Academy Names.
    results = []

    # List tags are table like objects.
    result_tables = athlete_results.find_all("div", class_="list")

    for current_table in result_tables:
        individual_table_results = _collect_individual_modern_table_results(
            current_table
        )
        results.append(individual_table_results)

    return results


def _collect_individual_modern_table_results(table):
    # Collect all rows of a modern webpage individual tournament results table object.

    individual_table = []

    # Pull Out Athlete Item tags. I.e. Rows of the table.
    athlete_items = table.find_all("div", class_="athlete-item")

    for item in athlete_items:
        # Get tag that contains Placing
        placing = item.find("div", class_="position-athlete")
        placing = placing.contents[0]
        individual_table.append(placing.strip())

        # p tags contains both athlete and school name
        p_tag = item.find("p")

        athlete_name = p_tag.contents[0]
        individual_table.append(athlete_name.strip())

        academy_name = p_tag.find("span")
        individual_table.append(academy_name.string.strip())

    return individual_table


def _build_rows_of_data(division_categories, results):
    # Go through both our division categories and results.
    # Combining them into full rows of data for final dataframe creation.

    full_rows = []

    x = 0
    while x < len(division_categories):
        # Access results list at the same position we are accessing division_categories list and store.
        results_split = results[x]

        # A list object im getting from the results array can be anywhere from 2 competitors to 4, but will always include 3 elements: Placing, Name, Academy Name.

        # Access the first 3 elements of the results split list and add them to the new row.
        # Remove the elements out of the results split list until the results split list has nothing left in it.
        while len(results_split) != 0:
            new_row = []

            current_category = division_categories[x]
            for category in current_category:
                # Clean Strings before storing, some had whitespaces.
                new_row.append(category.strip())

            individual_result = results_split[0:3]
            for result in individual_result:
                new_row.append(result.strip())

            full_rows.append(new_row)

            del results_split[0:3]

        x += 1

    return full_rows


def _create_standard_tournament_df(rows_of_data):
    df = pd.DataFrame(
        rows_of_data,
        columns=[
            "Age",
            "Belt",
            "Gender",
            "Weight Class",
            "Placing",
            "Competitor Name",
            "Academy Name",
        ],
    )
    return df


def _filter_to_blackbelt_adult(df):

    # Analysis is for top level competition. Black Belt, Adult

    # Use contains instead of exact match as Female Divisions in early tournament years were combined belts.
    # I.E. Brown Black, Purple Brown Black categories.
    # Some tournament results are stored in Portuguese. Filter for both English & Portuguese.
    df = df[
        (df["Belt"].str.contains("Black", na=False))
        | (df["Belt"].str.contains("Preta", na=False))
    ]

    # On one web page, Adult is misspelled as Asult. Filtering for this page and correcting these records.
    df = df[(df["Age"] == "Adult") | (df["Age"] == "Adulto") | (df["Age"] == "Asult")]
    df["Age"] = np.where(df["Age"] == "Asult", "Adult", df["Age"])

    return df


def _get_legacy_tournament_name(Soup):
    # Using the title element of the Soup to get the tournament name.
    tournament_name = Soup.title.string

    # Tournament name is always the title string until the 13th to last character.
    tournament_name = tournament_name[:-13]
    return tournament_name


def _get_legacy_tournament_year(Soup):
    # Using title element of the Soup to get year of the tournament.

    # Title element contains both year of tournament and tournament name.
    # Year is always the 3rd to last String in the title.
    tournament_year = Soup.title.string.split()
    tournament_year = tournament_year[-3]
    return tournament_year


def _get_modern_page_title(Soup):
    # Getting the title that contains both tournament name and year.
    title = Soup.find_all("h2", class_="title")
    title = title[1]
    title = title.string.strip()

    return title

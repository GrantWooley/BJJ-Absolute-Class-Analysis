#Functions file contains helper function to Open web pages,
#and two separate web scraping functions for scraping both the old and new HTML
#format of the IBJJF results web pages.


import pandas as pd
import numpy as np


#Function for Scraping older HTML format of IBJFF pages. From roughly the year 2012 and before.
#Accepts Beautiful Soup object as Argument.
def LegacyScrape(Soup):
    #Pull out  HTML that includes all athlete result data, excludes Academy Results data.
    athlete_results = Soup.find("div", class_ = "col-sm-12 athletes")

    #Get Division Information. I.e. adult, blue, male, middle
    division_categories = parse_division_categories(athlete_results)
    #Get Placing information. I.e. Placing, Athlete Name, and Academy Name.
    results = collect_page_results(athlete_results)

    #FIXME Shared across both functions Will need to implement this same approach in second scraper.
    full_rows = build_rows_of_data(division_categories, results)
    df = create_standard_tournament_df(full_rows)

    df = filter_to_blackbelt_adult(df)
    df['Tournament'] = get_tournament_name(Soup)
    df['Year'] = get_tournament_year(Soup)
    df = df.reset_index(drop = True)

    return df

#FIXME Time to start refactor of second scraping function.
#Function for scraping newer HTML format of IBJJF results pages. Roughly 2012 onward.
#Accepts Beautiful Soup object as Argument.
def ModernScrape(Soup):

    #Pull out  HTML that includes all athlete result data, excludes Academy Results data.
    athlete_results = Soup.find("div", class_ = "col-xs-12 col-md-6 col-athlete")

    #Splitting Out Tags that contain categories.
    division_categories =  athlete_results.find_all("h4", class_ = "subtitle")

    #Scrape through Categories tags. Pulling out Division string and splitting the strings properly
    #into age, belt, gender, weight
    #Declare a list to store Categories into. I.E. One instance of Age, Belt, Gender, Weight
    # Is one category.
    Headers = []

    #Loop through each category
    for category in division_categories:
        #Pull the categories Contents, which contains Age, Gender, Belt, and Weights
        Contents = category.contents
        #Contents contain category info in multiple formats. Pulling the best format.
        Contents = Contents[1]
        #Strings need to be split, and then stripped of line returns one at a time before being placed
        #into the headers list.
        Contents = Contents.split("/")
        #Declaring Sublist
        Sublist =[]
        #Stripping each string of whitespace and adding to sublist.
        for x in Contents:
            Sublist.append(x.strip())
        #Appending cleaned category to Headers list
        Headers.append(Sublist)



    #Splitting Out div Tags that contain lists. These list tags contain the table like objects that include Placing, Athlete Name, Athlete Academy.
    #They have children div tags with class athlete-item. One for each competitor result.
    #Athelte item div tags contain two children div tags:
    #1.Class = position-athlete contains placing.
    #2.Class = name contains two elements: Athlete Name, Academy name. Which are stored under P and Span children tags.

    #Declare List to Store Placing information. Placings, Athlete Names, and Academy Names.
    Results = []
    #Declaring List that is used, to store one set of Placings, Athlete Names, and Academy Names before being placed in the Results list.
    Sublist = []


    #Getting All List tags
    ListTags = athlete_results.find_all("div", class_ = "list")
    #Loop through each list tag
    for ListT in ListTags:
        #Pull Out Athlete Item tags
        AthleteItems = ListT.find_all("div", class_ = "athlete-item")
        #Loop through each Athlete Item tag Picking out my individual Results elements from the Tag.
        for Item in AthleteItems:
                #Get tag that contains Placing
                Placing = Item.find("div",class_ = "position-athlete")
                #Access the contenets where the placing number is held.
                Placing = Placing.contents[0]
                #Strip whitespace and add to sublist
                Sublist.append(Placing.strip())
                #Get p tag that contains both athlete and school name
                Ptag = Item.find("p")
                #Acess Athlete name from P tag
                AthName = Ptag.contents[0]
                #Strip white space and add to sublist.
                Sublist.append(AthName.strip())
                #Out of the p tag get the span tag containing Academy name
                AcademyName = Ptag.find("span")
                #Get AcademyName string, strip whitespace, and add to sublist.
                Sublist.append(AcademyName.string.strip())
        #Append Sublist Variable to Results list and then clear the sublist.
        Results.append(Sublist)
        Sublist = []



    #Empty df to be filled with scraped data.
    # df = create_standard_tournament_df()
    df = pd.DataFrame( columns=['Age','Belt','Gender','Weight Class','Placing','Competitor Name','Academy Name'])

    #FIXME Shared across both functions
    # will use build rows functions but need to refactor earlier sections of code first.
    # full_rows = build_rows_of_data(division_categories, results)
    #Looping through the two lists that contain data. Accessing them to build one row of data at a time and
    #adding it to the data frame.
    x = 0
    while x < len(Headers):
        #Access results list at the same position we are accessing headers list and store in a variable.
        ResultsSplit = Results[x]
        #A list object im getting from the Results array can be anywhere from 2 competitors to 4, but a result will always include 3 elements: Placing, Name, Academy Name.
        #So I am accessing the first 3 elements of the Results Split list. Adding them to my new row, 
        #and then taking them out of the ResultsSplit list until the results split list has nothing left in it.
        while len(ResultsSplit) != 0:
            NewRow = []
            NewHeader = Headers[x]
            for Header in NewHeader:
                #Some strings have white spaces. Stripping strings before storing.
                NewRow.append(Header.strip()) 
            IndiviualResult = ResultsSplit[0:3]    
            for Result in IndiviualResult:
                NewRow.append(Result.strip())
            df.loc[len(df)] = NewRow
            del ResultsSplit[0:3]
            
        x += 1



    df = filter_to_blackbelt_adult(df)

    #Getting the title that contains both tournament name and year.
    Title = Soup.find_all("h2",class_ = "title")
    Title = Title[1]
    Title = Title.string.strip()

    #Using title element of the Soup to get year of tournament and adding to the data frame.
    #Year is always the last 4 characters of the title string.
    Year = Title[-4:]
    df['Year'] = Year

    #Using the title element of the Soup to get the tournament name and adding to the data frame.
    #Tournament name is always the title string until the 4th to last character.
    Tournament = Title[:-4]
    df['Tournament'] = Tournament


    df = df.reset_index(drop = True)
    return df

def parse_division_categories(athlete_results):
    # Parse through athlete results data. Pulling out division header info: age, belt, gender, weight.
    # Returning all division headers.
    # I.e. adult, blue, male, middle
    #      adult, blue, male, heavy

    #Grab category tags that contain division info.
    category_tags = athlete_results.find_all("div", class_ ="category mt-4 mb-3")

    divisions = []
    for category in category_tags:
        #One web page was missing a string attribute for a div tag.
        #If this happens insert a dummy header, as to not negatively affect ordering of finals dataframe results.
        #Should not affect final df. If it does this is handled in data cleaning.
        if category.string is None:
            dummycategory = ['dummy1','dummy2','dummy3','dummy4']
            divisions.append(dummycategory)
            continue

        #Split the category tag into Age, Belt, Gender, Weight
        category = category.string.split(" / ")
        divisions.append(category)

    return divisions

def collect_page_results(athlete_results):
    # Pull out table objects from web page, and parse through them collecting resutls information.

    # Grab Tags that contain Tbodies aka tables.
    result_tables = athlete_results.find_all("tbody")

    #List to Store Placing information. Placing, Athlete Name, and Academy Name.
    results = []

    for tag in result_tables:
        #Pull Out td children tags containing Placing, Athlete Name, and Academy Name.
        td_tags = tag.find_all("td")
        individual_table_results = collect_individual_table_results(td_tags)

        results.append(individual_table_results)

    return results

def collect_individual_table_results(td_tags):
    #Colles all rows of an individual tournament results table object.

    individual_table = []

    #Go through tags collecting each row of Placing, Athlete Name, and Academy Name in table object.
    for tag in td_tags:

        #Access td tags class.
        td_tag_class = tag['class'][0]

        #Store Placing information.
        if td_tag_class == 'place':
            # Some web pages have errors where no placing was recorded.
            # Returns none. Convert to string to prevent errors in later code.
            individual_table.append(str(tag.string))

        #If the tag is an athlete academy tag, parse the html tree further to get athlete name and academy.
        elif td_tag_class == 'athlete-academy':

            div_tags = tag.find_all("div")

            #Collect and Store Athlete Name and Academy Name information.
            for div in div_tags:
                #Some Athletes do not have an affiliated academy, in those instances you get a return of none,
                #converting to string data type to prevent error.
                individual_table.append(str(div.string))

    return individual_table

def build_rows_of_data(division_categories, results):
    #Go through both our division categories and results.
    #Combining them into full rows of data for final dataframe creation.

    full_rows = []

    x = 0
    while x < len(division_categories):

        #Access results list at the same position we are accessing division_categories list and store.
        results_split = results[x]

        #A list object im getting from the results array can be anywhere from 2 competitors to 4, but will always include 3 elements: Placing, Name, Academy Name.

        #Access the first 3 elements of the results split list and add them to the new row.
        #Remove the elements out of the results split list until the results split list has nothing left in it.
        while len(results_split) != 0:

            new_row = []

            current_category = division_categories[x]
            for category in current_category:
                #Clean Strings before storing, some had whitespaces.
                new_row.append(category.strip())

            individual_result = results_split[0:3]
            for result in individual_result:
                new_row.append(result.strip())


            full_rows.append(new_row)

            del results_split[0:3]

        x += 1

    return full_rows

def create_standard_tournament_df(rows_of_data):
    df = pd.DataFrame(rows_of_data,
                      columns=['Age','Belt','Gender','Weight Class','Placing','Competitor Name','Academy Name']
                      )
    return df

def filter_to_blackbelt_adult(df):
    # Analysis is for top level competition. Black Belt, Adult
    
    # Use contains instead of exact match as Female Divisions in early tournament years were combined belts.
    # I.E. Brown Black, Purple Brown Black categories.
    # Some tournament results are stored in Portuguese. Filter for both English & Portuguese.
    df = df[(df['Belt'].str.contains('Black', na = False)) | (df['Belt'].str.contains('Preta', na = False))]
    
    #On one web page, Adult is misspelled as Asult. Filtering for this page and correcting these records.
    df = df[(df['Age'] == 'Adult') | (df['Age'] == 'Adulto') | (df['Age'] == 'Asult')]
    df['Age'] = np.where(df['Age'] == 'Asult', 'Adult', df['Age'])
    
    return df

def get_tournament_name(Soup):
    #Using the title element of the Soup to get the tournament name.
    tournament_name = Soup.title.string

    #Tournament name is always the title string until the 13th to last character.
    tournament_name = tournament_name[:-13]
    return tournament_name

def get_tournament_year(Soup):
    #Using title element of the Soup to get year of the tournament.

    #Title element contains both year of tournament and tournament name.
    #Year is always the 3rd to last String in the title.
    tournament_year = Soup.title.string.split()
    tournament_year = tournament_year[-3]
    return tournament_year


#File for scraping newer HTML format of IBJJF results pages. Roughly 2012 onward.

#import packes
from urllib.request import urlopen
from bs4 import BeautifulSoup 
import pandas as pd
import numpy as np

#Defining file as function to call in Main TournamentResultsWebscraper file.

def ModernScrape(URL):

    #Open the WebPage connecton
    Page = urlopen(URL)

    #Get the Soup
    Soup = BeautifulSoup(Page,"html.parser")

    #Splitout Athelete Results
    AthleteResults = Soup.find("div", class_ = "col-xs-12 col-md-6 col-athlete")

    #Splitting Out Tags that contain categories.
    Categories =  AthleteResults.find_all("h4", class_ = "subtitle")

    #Scrape through Categories tags. Pulling out Divsion string and splitting the strings properly
    #into age, belt, gender, weight
    #Declare a list to store Categories into. I.E. One instance of Age, Belt, Gender, Weight 
    # Is one cateogry.
    Headers = []

    #Loop through each category
    for Cateogry in Categories:
        #Pull the caegories Contents, which contains Age, Gender, Belt, and Weights
        Contents = Cateogry.contents
        #Contents contain cateogry info in multiple formats. Pulling the best format.
        Contents = Contents[1]
        #Strings need to be split, and then stripped of line returns one at a time before being placed
        #into the headers list.
        Contents = Contents.split("/")
        #Declaring Sublist
        Sublist =[]
        #Stripping each string of whitespace and adding to sublist.
        for x in Contents:
            Sublist.append(x.strip())
        #Appending cleaned Cateogry to Headers list
        Headers.append(Sublist)
        


    #Splitting Out div Tags that contain lists. These list tags contain the table like objects that include Placing, Athlete Name, Athlete Academy. 
    #They have children div tags with class athlete-item. One for each competitor result.
    #Athelte item div tags contian two children div tags:
    #1.Class = position-athlete contains placing. 
    #2.Class = name contains two elements: Athlete Name, Academy name. Which are stored under P and Span children tags.

    #Declare List to Store Placing information. Placings, Athlete Names, and Academy Names.
    Results = []
    #Declaring List that is used, to store one set of Placings, Athlete Names, and Academy Names before being placed in the Results list.
    Sublist = []


    #Getting All List tags
    ListTags = AthleteResults.find_all("div", class_ = "list")
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
        


    #Declaring empty dataframe to be filled with scraped data.
    df = pd.DataFrame( columns=['Age','Gender','Belt','Weight Class','Placing','Competitor Name','Academy Name'])

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



    #Filtering df to only Adult divisions that contain Black Belt, 
    #as analys will only be for top level competition.
    #Female Divsions in early tournmaent years were combined belts. I.E. Brown Black, Purple Brown Black categories.
    #Brazilian Nationals Results are stored in Portugese so, need to filter for bothn English and Portugese words.
    df = df[(df['Belt'].str.contains('Black', na = False)) | (df['Belt'].str.contains('Preta', na = False))]
    #On one web page, Adult is misspelled as Asult. Filtering for this page and doing data cleansing to correct these records.
    df = df[(df['Age'] == 'Adult') | (df['Age'] == 'Adulto') | (df['Age'] == 'Asult')]
    df['Age'] = np.where(df['Age']== 'Asult', 'Adult', df['Age'])


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

    #Reseting df index and returning df.
    df = df.reset_index(drop = True)
    return df



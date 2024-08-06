#File for Scraping older HTML format of IBJFF pages. From rouglhy the year 2012 and before.
from urllib.request import urlopen
from bs4 import BeautifulSoup
import pandas as pd
import numpy as np

#Defining file as function to call in Main TournamentResultsWebscraper file.

def LegacyScrape(URL):

    #Open the connection and Get the HTML
    Page = urlopen(URL)
    Soup = BeautifulSoup(Page,"html.parser")

    #Pull out  HTML that includes all athlete result data, excludes Academy Results data.
    AthleteResults = Soup.find("div", class_ = "col-sm-12 athletes")

    #Splitting Out Tags that contain categories.
    Categories = AthleteResults.find_all("div", class_ ="category mt-4 mb-3")

    #Scrape through Categories tags. Pulling out Divsion string and splitting the strings properly
    #into age, belt, gender, weight.
    #Declare a list to store Categories into. I.E. One instance of Age, Belt, Gender, Weight 
    #is one cateogry.
    Headers = []
    for x in Categories:
        #One web page was missing a string attribute for a div tag. 
        #If this happens insert a dummy header, as to not negatively affect ordering of finals dataframe results.
        #Will likely not ever affect black belts results, if it does I will clean the final dataframe.
        if x.string == None:
            dummycategory = ['dummy1','dummy2','dummy3','dummy4']
            Headers.append(dummycategory)
            continue
        #Split the category tag's .string into Age, Belt, Gender, Weight
        NewCategory = x.string.split(" / ")
        Headers.append(NewCategory)


    #Split out Tags that contain Tbodies aka tables. These have two td children tags. Td tag one contains Athlete placing.
    #Td tag two contains two cildren elements. 
    # Child1: Athelete Name, Child2: Academy Name
    ResultTables = AthleteResults.find_all("tbody")

    #Declare List to Store Placing information. Placing, Athlete Name, and Academy Name.
    Results = []
    #Declaring List that is used, to store one set of Placing Athlete Name, and Academy Name before being placed in the Results list.
    Sublist = []

    #Loop through each tbody.
    for tag in ResultTables:
        #Pull Out td children tags containing Placing, Athlete Name, and Academy Name.
        TDtags = tag.find_all("td")
        #Loop through TD tags and add elements to Sublist.
        for tag in TDtags:
            #Access td tags class and store in list variable.
            x = tag['class']
            x = x[0]
            #If the td tag is a placing tag, add its text to sublist.
            if x == 'place':
                #Some web pages have errors where no placing was recorded. This returns none. Converting to string
                #to prevent errors in later code.
                Sublist.append(str(tag.string))
            #Else if it is an athlete academy tag, go deeper into the html tree to get athlete name and academy.  
            elif x == 'athlete-academy':
                #Search the tag for all div tags. 
                DivTags = tag.find_all("div")
                #Loop through each div tag and and add tag.string to results lists.
                for div in DivTags:
                    #Some Atheletes do not have an affiliated academy, in those instances you get a return of none,
                    #converting to string data type to prevent error.
                    Sublist.append(str(div.string))
        #Append Sublist Variable to Results list and then clear the sublist.
        Results.append(Sublist)
        Sublist = []

    #Declaring empty dataframe to be filled with scraped data.
    df = pd.DataFrame( columns=['Age','Belt','Gender','Weight Class','Placing','Competitor Name','Academy Name'])

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



    #Using title element of the Soup to get year of tournament and adding to the data frame.
    Title = Soup.title.string.split()
    #Year is always the 3rd to last String in the title.
    Year = Title[-3]
    df['Year'] = Year

    #Using the title element of the Soup to get the tournament name and adding to the data frame.
    Tournament = Soup.title.string
    #Tournament name is always the title string until the 13th to last character.
    #Accessing title string from the 0th position to the 13th to last position.
    Tournament = Tournament[:-13]
    df['Tournament'] = Tournament

    #Reseting df index and returning df.
    df = df.reset_index(drop = True)
    return df





#Functions file contains helper function to Open web pages,
#and two separate web scraping functions for scraping both the old and new HTML
#format of the IBJJF results web pages.

from urllib.request import urlopen
from bs4 import BeautifulSoup
import pandas as pd
import numpy as np

#Function to open URL and get beautiful soup object. Defining this function separately to allow
#error handling of the URLs on the IBJFF Results page that are dead links.
def GetSoup(URL):
    Soup = urlopen(URL)
    Soup = BeautifulSoup(Soup,"html.parser")
    return Soup



#Function for Scraping older HTML format of IBJFF pages. From roughly the year 2012 and before.
#Accepts Beautiful Soup object as Argument.
def LegacyScrape(Soup):

    #Pull out  HTML that includes all athlete result data, excludes Academy Results data.
    AthleteResults = Soup.find("div", class_ = "col-sm-12 athletes")

    #Splitting Out Tags that contain categories.
    Categories = AthleteResults.find_all("div", class_ ="category mt-4 mb-3")

    #Scrape through Categories tags. Pulling out Division string and splitting the strings properly
    #into age, belt, gender, weight.
    #Declare a list to store Categories into. I.E. One instance of Age, Belt, Gender, Weight 
    #is one category.
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
    #Td tag two contains two children elements.
    # Child1: Athlete Name, Child2: Academy Name
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
                    #Some Athletes do not have an affiliated academy, in those instances you get a return of none,
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
    #Female Divisions in early tournament years were combined belts. I.E. Brown Black, Purple Brown Black categories.
    #Brazilian Nationals Results are stored in Portuguese so, need to filter for both English and Portuguese words.
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


#Function for scraping newer HTML format of IBJJF results pages. Roughly 2012 onward.
#Accepts Beautiful Soup object as Argument.
def ModernScrape(Soup):

    #Splitout Athlete Results
    AthleteResults = Soup.find("div", class_ = "col-xs-12 col-md-6 col-athlete")

    #Splitting Out Tags that contain categories.
    Categories =  AthleteResults.find_all("h4", class_ = "subtitle")

    #Scrape through Categories tags. Pulling out Division string and splitting the strings properly
    #into age, belt, gender, weight
    #Declare a list to store Categories into. I.E. One instance of Age, Belt, Gender, Weight 
    # Is one category.
    Headers = []

    #Loop through each category
    for Category in Categories:
        #Pull the categories Contents, which contains Age, Gender, Belt, and Weights
        Contents = Category.contents
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
    #Female Divisions in early tournament years were combined belts. I.E. Brown Black, Purple Brown Black categories.
    #Brazilian Nationals Results are stored in Portuguese so, need to filter for both English and Portuguese words.
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



#File for Scraping older HTML format of IBJFF pages. From rouglhy the year 2012 and before.
from urllib.request import urlopen
from bs4 import BeautifulSoup
import pandas as pd

#Example URL, will later turn .py file into function that accepts URL from TournamentResultsWebscraper.py
URL = "https://ibjjf.com/events/results/2011-world-jiu-jitsu-ibjjf-championship"
Page = urlopen(URL)

Soup = BeautifulSoup(Page,"html.parser")

AthleteResults = Soup.find("div", class_ = "col-sm-12 athletes")

#Splitting Out Tags that contain categories.
Categories = AthleteResults.find_all("div", class_ ="category mt-4 mb-3")

#Scrape through Categories tags. Pulling out Divsion string and splitting the strings properly
#into age, belt, gender, weight
#Declare a list to store Categories into. I.E. One instance of Age, Belt, Gender, Weight 
# Is one cateogry.
Headers = []
for x in Categories:
    #Split the category tag's .string into Age, Belt, Gender, Weight
    NewCategory = x.string.split(" / ")
    Headers.append(NewCategory)


#Split out Tags that contain Tables, that have two td elements. Td element one containing Athlete placing.
#Td element two containing two cildren elements. 
# Child1: Athelete Name, Child2: Academy Name
ResultTables = AthleteResults.find_all("td")

#Declare List to Store Placing information. Placing, Athlete Name, and Academy Name.
Results = []
#Declaring List that is used, to store one set of Placing Athlete Name, and Academy Name before being placed in the Results list.
Sublist = []

i = 0
#Loop for seperating out Placing, Athlete Name, and Academy name.
for tag in ResultTables:
#    access tags attributes using tag['class'] and store in list
    Checklist = tag['class']
# access first element of list if the string is 'place'
    if Checklist[0] == 'place':
#Sometimes a division has 4 placing competitiors, sometimes it has 3. So, I need to check the placing. Everytime the placing = 1. wipe the sublist. and start over.
#if the record is placing = 1 append the sublist to results, then wipe it, and add in the new record. This way each group of placings per division is stored in its own list, within the reuslts list.
#checking for len of sublist so the first time through the loop we do not add an empty list to Results.
        if tag.string == '1' and len(Sublist) != 0:
            Results.append(Sublist)
            Sublist = []
#access Tag.str and add to results lists
        Sublist.append(tag.string)        
#else if it is the string 'athelete-academy'
    elif Checklist[0] == 'athlete-academy':
#search the tag for all div tags. 
        DivTags = tag.find_all("div")
#loop through each div tag and and add tag.string to results lists
        for div in DivTags:
            Sublist.append(div.string)
#Appending Sublist to main results list on time outside of loop, because the way the loop works, the last group competitor results will be in the sublist but not appended to the results in the loop itself.
Results.append(Sublist)



#Declaring my dataframe that I will now fill in with all of the scraped data.
df = pd.DataFrame( columns=['Age','Belt','Gender','Weight Class','Placing','Competitor Name','Academy Name'])

#I want to get one row of data. From my two lists. but my Results array has up to 4 rows worth of data in a single list.
x = 0
while x < len(Headers):
    #access results list at the same position we are accessing headers list and store in a variable.
    ResultsSplit = Results[x]
    #A list object im getting from the Results array can be anywhere from 2 competitors to 4. But a result will always include 3 elements: Placing, Name, Academy Name.
    #So I want to access the first 3 elements of the Results Split list. Add them to my new row, and then take them out of the ResultsSplit list until the results split list has nothing left in it.
    while len(ResultsSplit) != 0:
        NewRow = []
        NewHeader = Headers[x]
        for Header in NewHeader:
            #Noticed some strings have white spaces. Stripping strings before storing.
            NewRow.append(Header.strip()) 
        IndiviualResult = ResultsSplit[0:3]    
        for Result in IndiviualResult:
            NewRow.append(Result.strip())
        df.loc[len(df)] = NewRow
        del ResultsSplit[0:3]
        
    x += 1


#Filtering df to only Black Belt, and Brown Black results (Female Divsions). As I only want to do analysis on the top level of competition.
df = df[(df['Belt'] == 'Black') | (df['Belt'] == 'Brown Black')]

df = df['Age']
df = df.drop_duplicates()

print(df.head)
print(df.tail)



  



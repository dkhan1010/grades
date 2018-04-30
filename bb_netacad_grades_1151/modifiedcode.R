install.packages('dplyr')
install.packages('tidyr')
install.packages('readr')
install.packages('xlsx')
install.packages('readxl')
install.packages("rJava",type="source")
#use the following line in the command prompt to setup path for rJava
#sudo ln -f -s $(/usr/libexec/java_home)/jre/lib/server/libjvm.dylib /usr/local/lib
library(dplyr)
library(tidyr)
library(readr)
library(xlsx)
library(readxl)

# load netacad grade with default column type of double except Student and SIS Login ID which are character
netacad = read_csv('netacad_grades.csv',col_types = cols(.default = 'd', Student = 'c','SIS Login ID' = 'c'))
# remove the first row where ID = NA
netacad = netacad %>% filter(!is.na(ID))
# Replace all NAs with 0
netacad[is.na(netacad)] = 0
# Rename column name SIS Login ID to Email
netacad = netacad %>% rename(Email = `SIS Login ID`)
# Change email column to lowercase
netacad$Email = tolower(netacad$Email)


####################################
# Read student list with predefined column names and separate columns
slist = read_csv('slist.csv',col_names = c('Student ID','FN','LN','Email','Role','temp1','temp2','CRN'))
slist = separate(slist,'Student ID',into=c('Student ID'),sep='\\ ',extra='drop')
# Select all rows where role is student
slist = slist %>% filter(Role=='Student',!is.na(CRN)) %>% select(`Student ID`,FN,LN,Email,Role,CRN)
# Change Email column to lower case 
slist$Email = tolower(slist$Email)

########################################
# Join slist and netacad grades
grades = slist %>% left_join(netacad)
# Replace NAs to 0
grades[is.na(grades)] = 0
# Remove Student column which is an extra column due to join coming from netacad
grades = grades %>% select(-Student)
# Write grades.csv file
write_csv(grades,'grades.csv')

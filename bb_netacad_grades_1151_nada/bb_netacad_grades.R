install.packages('readr')
install.packages('dplyr')
install.packages('tidyr')
library(readr)
library(dplyr)
library(tidyr)
# read configuration file
# read slist filename from the configuration file and remove NAs
#temp_slist = config$slist_filename %>% na.omit()
# Load student list downloaded in the .csv format from the Blackboard
slist = read_csv(file = 'slist.csv',col_names=c('Student ID','FN','LN','SIS Login ID','Role','temp1','temp2','CRN'))
slist = separate(slist,'Student ID',into=c('Student ID'),sep='\\ ',extra='drop')
# Select all rows where role is student
slist = slist %>% filter(Role=='Student',!is.na(CRN)) %>% select(`Student ID`,FN,LN,`SIS Login ID`)
# Change Email column to lower case 
slist$`SIS Login ID` = tolower(slist$`SIS Login ID`)
# Find preview user from the slist if present and remove it
if (length(grep(pattern = 'previewuser',slist$`Student ID`))>0) {
  slist = slist[-grep(pattern = 'previewuser',slist$`Student ID`),]
}

###############################
bb_grades = read_csv('bb_grades.csv')
bb_grades = bb_grades %>% select(Username,`Lab 1 [Total Pts: 7.5 Score] |913474`,`Lab 2 [Total Pts: 7.5 Score] |913475`,`Lab 3 [Total Pts: 7.5 Score] |913476`,`Lab 4 [Total Pts: 7.5 Score] |913477`,`Lab 5 [Total Pts: 7.5 Score] |913478`) %>% rename('Student ID' = Username)
bb_grades$`Student ID` = as.character(bb_grades$`Student ID`)
bb_grades= slist %>% left_join(bb_grades)
bb_grades$`Lab 1 [Total Pts: 7.5 Score] |913474` = as.double(bb_grades$`Lab 1 [Total Pts: 7.5 Score] |913474`)
bb_grades$`Lab 2 [Total Pts: 7.5 Score] |913475` = as.double(bb_grades$`Lab 2 [Total Pts: 7.5 Score] |913475`)
bb_grades$`Lab 3 [Total Pts: 7.5 Score] |913476` = as.double(bb_grades$`Lab 3 [Total Pts: 7.5 Score] |913476`)
bb_grades$`Lab 4 [Total Pts: 7.5 Score] |913477` = as.double(bb_grades$`Lab 4 [Total Pts: 7.5 Score] |913477`)
bb_grades$`Lab 5 [Total Pts: 7.5 Score] |913478` = as.double(bb_grades$`Lab 5 [Total Pts: 7.5 Score] |913478`)

bb_grades[is.na(bb_grades)]=0
bb_grades$`Lab 1 [Total Pts: 7.5 Score] |913474`=(bb_grades$`Lab 1 [Total Pts: 7.5 Score] |913474`/100)*7.5
bb_grades$`Lab 2 [Total Pts: 7.5 Score] |913475`=(bb_grades$`Lab 2 [Total Pts: 7.5 Score] |913475`/100)*7.5
bb_grades$`Lab 3 [Total Pts: 7.5 Score] |913476`=(bb_grades$`Lab 3 [Total Pts: 7.5 Score] |913476`/100)*7.5
bb_grades$`Lab 4 [Total Pts: 7.5 Score] |913477`=(bb_grades$`Lab 4 [Total Pts: 7.5 Score] |913477`/100)*7.5
bb_grades$`Lab 5 [Total Pts: 7.5 Score] |913478`=(bb_grades$`Lab 5 [Total Pts: 7.5 Score] |913478`/100)*7.5


###########################
netacad_grades = read_csv('netacad_grades.csv',col_types = cols(.default = 'd', Student = 'c','SIS Login ID' = 'c'))
netacad_grades$`SIS Login ID` = tolower(netacad_grades$`SIS Login ID`)
netacad_grades = netacad_grades %>% filter(!is.na(ID))
if (length(grep(pattern = 'Test Student',netacad_grades$Student))>0) {
  netacad_grades = netacad_grades[-grep(pattern = 'Test Student',netacad_grades$Student),]
}

##########################
temp = netacad_grades %>% left_join(bb_grades)
write_csv(temp,'temp.csv')


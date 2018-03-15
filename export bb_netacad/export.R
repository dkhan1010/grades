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
slist = read_csv(file = 'slist.csv',col_names=c('Student ID','FN','LN','Email','Role','temp1','temp2','CRN'))
slist = separate(slist,'Student ID',into=c('Student ID'),sep='\\ ',extra='drop')
# Select all rows where role is student
slist = slist %>% filter(Role=='Student',!is.na(CRN)) %>% select(`Student ID`,FN,LN,Email)
# Change Email column to lower case 
slist$Email = tolower(slist$Email)
# Find preview user from the slist if present and remove it
if (length(grep(pattern = 'previewuser',slist$`Student ID`))>0) {
  slist = slist[-grep(pattern = 'previewuser',slist$`Student ID`),]
}


###################
# Load BB grades
bb_grades = read_csv('gc_XLIST_Khan_COMP1151_201702_fullgc_2018-03-14-13-02-53.csv')
bb_grades = bb_grades %>% select(-c(`Student ID`,`Last Access`,Availability,`Child Course ID`))
bb_grades = bb_grades %>% rename('Student ID' = Username)
bb_grades$`Student ID` = as.character(bb_grades$`Student ID`)
bb_grades= slist %>% left_join(bb_grades)
#bb_grades$`Mid-Term [Total Pts: 50 Score] |926205` = as.double(bb_grades$`Mid-Term [Total Pts: 50 Score] |926205`)
bb_grades[is.na(bb_grades)]=0
#bb_grades = bb_grades %>% mutate(midterm = (`Mid-Term [Total Pts: 50 Score] |926205`/50)*30)
#bb_grades$midterm = round(bb_grades$midterm,2)
#bb_grades = bb_grades %>% select(Email,midterm)
bb_grades = bb_grades %>% rename('SIS Login ID' = Email)

######################
# Load netacad grades
netacad_grades = read_csv('netacad.csv',col_types = cols(.default = 'd', Student = 'c','SIS Login ID' = 'c'))
netacad_grades$`SIS Login ID` = tolower(netacad_grades$`SIS Login ID`)
netacad_grades = netacad_grades %>% filter(!is.na(ID))
if (length(grep(pattern = 'Test Student',netacad_grades$Student))>0) {
  netacad_grades = netacad_grades[-grep(pattern = 'Test Student',netacad_grades$Student),]
}
netacad_grades = netacad_grades %>% left_join(bb_grades)

######################
# t1 variable takes netacad grades into vector and t2 variables takes BB grades into vector
t1 = netacad_grades$`Lab 1 (1151) (12503434)`
t1[is.na(t1)]=0
t1 = as.double(t1)
t2 = netacad_grades$`Lab 1 [Total Pts: 7.5 Score] |913474`
t2[is.na(t2)]=0
t2 = as.double(t2)
# apply weights to the score
t2 = (t2/100)*7.5
i = which(t2>t1)
t1[i] = t2[i]

write_csv(netacad_grades,'netacad_grades_merge.csv')

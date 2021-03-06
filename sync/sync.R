install.packages('readr')
install.packages('dplyr')
install.packages('tidyr')
library(readr)
library(dplyr)
library(tidyr)

# read configuration file
config = read_csv('config.csv')
# read slist filename from the configuration file and remove NAs
temp_slist = config$slist_filename %>% na.omit()
# Load student list downloaded in the .csv format from the Blackboard
slist = read_csv(temp_slist,col_names = c('Student ID','FN','LN','Email','Role','temp1','temp2','CRN'))
slist = separate(slist,'Student ID',into=c('Student ID'),sep='\\ ',extra='drop')
# Select all rows where role is student
slist = slist %>% filter(Role=='Student',!is.na(CRN)) %>% select(`Student ID`,FN,LN,Email)
# Change Email column to lower case 
slist$Email = tolower(slist$Email)
# Find preview user from the slist and remove if present
if (grep(pattern = 'previewuser',slist$`Student ID`)>0) {
  slist = slist[-grep(pattern = 'previewuser',slist$`Student ID`),]
}

# Load grades from the netacad
# read netacad filename from the configuration file and remove NAs
temp_netacad = config$netacad_filename %>% na.omit()
netacad = read_csv(temp_netacad)
netacad = netacad %>% filter(!is.na(ID)) %>% select(Student,`SIS Login ID`) %>% rename('Email' = `SIS Login ID`)
netacad$Email = tolower(netacad$Email)

# Find 'Test Student' pattern and remove if present
if (grep(pattern = 'Test Student',netacad$Student)>0) {
netacad = netacad[-grep(pattern = 'Test Student',netacad$Student),]
}

# Students in the slist which are not in the netacad
missing = which(!(slist$Email %in% netacad$Email))
write_csv(slist[missing,],'to_be_added_in_netacad.csv')

# Students in the netacad which are not in the slist
extra = which(!(netacad$Email %in% slist$Email))
write_csv(netacad[extra,],'to_be_removed_from_netacad.csv')
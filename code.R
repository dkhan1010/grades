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

# read configuration file
config = read_csv('config.csv')
# read netacad filename from the configuration file and remove NAs
temp_netacad = config$Netacad %>% na.omit()
# load netacad grade with default column type of double except Student and SIS Login ID which are character
netacad = read_csv(temp_netacad,col_types = cols(.default = 'd', Student = 'c','SIS Login ID' = 'c'))
# remove the first row where ID = NA
netacad = netacad %>% filter(!is.na(ID))
# Replace all NAs with 0
netacad[is.na(netacad)] = 0
# Rename column name SIS Login ID to Email
netacad = netacad %>% rename(Email = `SIS Login ID`)
# Change email column to lowercase
netacad$Email = tolower(netacad$Email)
# Change 'current/final' selection in config.csv to lowercase
netacad.score = tolower(config$`Score to include (current/final)`[1])
# Replaces NAs to 0 in the weight column read from the config.csv
config$`Netacad column name weights (0-100)`[is.na(config$`Netacad column name weights (0-100)`)]=0

# The below statement works when score type 'current' is selected
if (netacad.score == 'current') {
  # select relevant columns from the netacad
  netacad.grades = netacad %>% 
    select(Student,
           Email,
           `Assignments Current Score`,
           `Pretest Exam Current Score`,
           `Chapter Exams Current Score`,
           `Skills Exams Current Score`,
           `Practice Final Exam Current Score`,
           `Final Exam Current Score`)
  
  # Change the column name to add 'out of'. The 'out of' value is selected from the config.csv
  wt = c('Student',
         'Email',
         paste('Assignments','out of',config$`Netacad column name weights (0-100)`[1]),
         paste('Pretest','out of',config$`Netacad column name weights (0-100)`[3]),
         paste('Chapter exam','out of',config$`Netacad column name weights (0-100)`[5]),
         paste('Skills exam','out of',config$`Netacad column name weights (0-100)`[7]),
         paste('Practice exam','out of',config$`Netacad column name weights (0-100)`[9]),
         paste('Final exam','out of',config$`Netacad column name weights (0-100)`[11]),
         'Total out of 100')
  
  # The following is used to calculate score based on the weights and then round off
  # The formula is: (Current score/100) * weights
  # The column name is also changed to remove Current Score from the column headings
  netacad.grades = netacad.grades %>%
    mutate('Assignments' = round((`Assignments Current Score`/100)*config$`Netacad column name weights (0-100)`[1],2),
           'Pretest' = round((`Pretest Exam Current Score`/100)*config$`Netacad column name weights (0-100)`[3],2),
           'Chapter exam' = round((`Chapter Exams Current Score`/100)*config$`Netacad column name weights (0-100)`[5],2),
           'Skills exam' = round((`Skills Exams Current Score`/100)* config$`Netacad column name weights (0-100)`[7],2),
           'Practice exam' = round((`Practice Final Exam Current Score`/100)*config$`Netacad column name weights (0-100)`[9],2),
           'Final exam' = round((`Final Exam Current Score`/100)*config$`Netacad column name weights (0-100)`[11],2))
  
  # Calculate total
  netacad.grades = netacad.grades %>% 
    mutate('Total' = (`Assignments Current Score`/100)   *  config$`Netacad column name weights (0-100)`[1]+
             (`Pretest Exam Current Score`/100)  *  config$`Netacad column name weights (0-100)`[3]+
             (`Chapter Exams Current Score`/100) *  config$`Netacad column name weights (0-100)`[5]+
             (`Skills Exams Current Score`/100) *  config$`Netacad column name weights (0-100)`[7]+
             (`Practice Final Exam Current Score`/100) * config$`Netacad column name weights (0-100)`[9]+
             (`Final Exam Current Score`/100) * config$`Netacad column name weights (0-100)`[11])
  
  # Round off total column
  netacad.grades$Total = round(netacad.grades$Total,0)
  # Remove columns which ends with Score
  netacad.grades = netacad.grades %>% select(-ends_with('Score'))
  # Change column names as defined in variable wt
  colnames(netacad.grades) = wt
  # Remove columns which are all zeros
  netacad.grades = netacad.grades[, colSums(netacad.grades != 0) > 0]
  
  # Following if stmt only applies when CCNA1 is selected in the config.csv
  # When a student gets less than 50% in practice exam then total becomes 0
  if (config$`Course to include (Type 1 for Yes)`[1] == 1 ) {
    netacad.grades$`Total out of 100` = 
      netacad.grades$`Total out of 100` * (netacad.grades$`Practice exam out of 35`> (config$`Netacad column name weights (0-100)`[9])/2)
  }
  
} #end of if statement

# The below statement works when score type 'final' is selected
if (netacad.score == 'final') {
  # select relevant columns from the netacad
  netacad.grades = netacad %>% 
    select(Student,
           Email,
           `Assignments Final Score`,
           `Pretest Exam Final Score`,
           `Chapter Exams Final Score`,
           `Skills Exams Final Score`,
           `Practice Final Exam Final Score`,
           `Final Exam Final Score`)
  
  # Change the column name to add 'out of'. The 'out of' value is selected from the config.csv
  wt = c('Student',
         'Email',
         paste('Assignments','out of',config$`Netacad column name weights (0-100)`[2]),
         paste('Pretest','out of',config$`Netacad column name weights (0-100)`[4]),
         paste('Chapter exam','out of',config$`Netacad column name weights (0-100)`[6]),
         paste('Skills exam','out of',config$`Netacad column name weights (0-100)`[8]),
         paste('Practice exam','out of',config$`Netacad column name weights (0-100)`[10]),
         paste('Final exam','out of',config$`Netacad column name weights (0-100)`[12]),
         'Total out of 100')
  
  # The following is used to calculate score based on the weights and then round off
  # The formula is: (Final score/100) * weights
  # The column name is also changed to remove Final Score from the column headings
  netacad.grades = netacad.grades %>%
    mutate('Assignments' = round((`Assignments Final Score`/100)*config$`Netacad column name weights (0-100)`[2],2),
           'Pretest' = round((`Pretest Exam Final Score`/100)*config$`Netacad column name weights (0-100)`[4],2),
           'Chapter exam' = round((`Chapter Exams Final Score`/100)*config$`Netacad column name weights (0-100)`[6],2),
           'Skills exam' = round((`Skills Exams Final Score`/100)* config$`Netacad column name weights (0-100)`[8],2),
           'Practice exam' = round((`Practice Final Exam Final Score`/100)*config$`Netacad column name weights (0-100)`[10],2),
           'Final exam' = round((`Final Exam Final Score`/100)*config$`Netacad column name weights (0-100)`[12],2))
  
  # Calculate total
  netacad.grades = netacad.grades %>% 
    mutate('Total' = (`Assignments Final Score`/100)   *  config$`Netacad column name weights (0-100)`[2]+
             (`Pretest Exam Final Score`/100)  *  config$`Netacad column name weights (0-100)`[4]+
             (`Chapter Exams Final Score`/100) *  config$`Netacad column name weights (0-100)`[6]+
             (`Skills Exams Final Score`/100) *  config$`Netacad column name weights (0-100)`[8]+
             (`Practice Final Exam Final Score`/100) * config$`Netacad column name weights (0-100)`[10]+
             (`Final Exam Final Score`/100) * config$`Netacad column name weights (0-100)`[12])
  
  # Round off total column
  netacad.grades$Total = round(netacad.grades$Total,0) 
  # Remove columns which ends with Score
  netacad.grades = netacad.grades %>% select(-ends_with('Score'))
  # Change column names as defined in variable wt
  colnames(netacad.grades) = wt
  # Remove columns which are all zeros
  netacad.grades = netacad.grades[, colSums(netacad.grades != 0) > 0]
  
  # Following if stmt only applies when CCNA1 is selected in the config.csv
  # When a student gets less than 50% in practice exam then total becomes 0
  if (config$`Course to include (Type 1 for Yes)`[1] == 1 ) {
    netacad.grades$`Total out of 100` = 
      netacad.grades$`Total out of 100` * (netacad.grades$`Practice exam out of 35`> (config$`Netacad column name weights (0-100)`[10])/2)
  }
  
} #end of if statement


####################################
# Get student list filename from the config.csv and remove all NAs
temp_slist = config$Student_list %>% na.omit()
# Read student list with predefined column names and separate columns
slist = read_csv(temp_slist,col_names = c('Student ID','FN','LN','Email','Role','temp1','temp2','CRN'))
slist = separate(slist,'Student ID',into=c('Student ID'),sep='\\ ',extra='drop')
# Select all rows where role is student
slist = slist %>% filter(Role=='Student',!is.na(CRN)) %>% select(`Student ID`,FN,LN,Email,Role,CRN)
# Change Email column to lower case 
slist$Email = tolower(slist$Email)

########################################
# Join slist and netacad grades
grades = slist %>% left_join(netacad.grades)
# Replace NAs to 0
grades[is.na(grades)] = 0
# Remove Student column which is an extra column due to join coming from netacad
grades = grades %>% select(-Student)
# Write grades_breakdown.csv
write_csv(grades,'grades_breakdown.csv')
# Select columns to upload in a template for the Millennium
# Millennium template only requires two columns 
# The column name should be title as 'Student ID' and 'Percent'
final = grades %>% select(`Student ID`,`Total out of 100`) %>% rename(Percent = 'Total out of 100')

#########################################
#add for loop to read files w.r.t CRN and export files

# Read filenames from the config.csv and remove all NAs
crn.list = crn.list = config$Template %>% na.omit()
# Read each file in the list
df.list <- lapply(crn.list, read_excel)
# for loop runs equal to the number of files in the config.csv
for (i in 1:length(df.list)){
  # Get only Student ID
  temp = as.data.frame(df.list[[i]]$`Student ID`)
  # Rename column name
  colnames(temp) = 'Student ID'
  # Change column type
  temp$`Student ID` = as.character(temp$`Student ID`)
  # Join temp and final. The join will done at the 'Student ID' and the corresponding Percent column is added
  temp = temp %>% left_join(final)
  # Write in .xls format
  write.xlsx(temp,paste('upload_',crn.list[i],sep=""),row.names = FALSE)
  # Remove temp variable for the next for loop
  rm(temp)  
}
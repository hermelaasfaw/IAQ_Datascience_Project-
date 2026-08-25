# ################################################################
# DATA EXPLORATION
# Initial investigating of the raw IAQ sensor dataset
# 1. DATASET STRUCTURE AND INITIAL EXPLORATION
# ################################################################

library(dplyr)
library(tidyverse)

list.files()

# Create folders if it doesn't already exist
dir.create("results", showWarnings = FALSE)
dir.create("results/figures", showWarnings = FALSE)

# ################################################################
# 1. Inspect the dataset structure, sensor files and variables 
# using room00 as initial example
# ################################################################

getwd()
list.files("raw_data/room00")
room00_files <- list.files("raw_data/room00", full.names = TRUE)

room00_files[1]

one_sensor <-  read.csv(room00_files[1])
head(one_sensor)
str(one_sensor)
length(room00_files)
basename(room00_files)

room00_Co2 <-  read.csv(room00_files[2])
head(room00_Co2)

str(room00_Co2)
names(room00_Co2)

# inspecting each csv in room00
for(file in room00_files) {
  data <- read.csv(file, nrows = 5)
  
  cat("\n---", basename(file), "\n---")
  #print(names(data))
  print(data)
}

# inspecting the co2 file specifically from room00
summary(room00_Co2)
colSums(is.na(room00_Co2))
range(room00_Co2$co2)


# inspecting the timestamp
head(room00_Co2$devicetimestamp)
tail(room00_Co2$devicetimestamp)

# ################################################################
# 2. CO2 EXPLORATION ACROSS ALL ROOMS
# Examine CO2 file structure, descriptive statistics and 
# suspicious extreme readings across the 13 rooms 
# ################################################################

room_folders <-  list.dirs(path = "raw_data", recursive = FALSE, full.names = TRUE)
room_folders

# what files contain co2 inside
co2_files <-  list.files(
  path = room_folders,
  pattern = "CO2",
  full.names = TRUE,
  ignore.case = TRUE
)
length(co2_files)
basename(co2_files) # so each room has 1 co2 file 

# build summary table for all the co2 files 
co2_summary <-  data.frame()

for (file in co2_files) {
  data <- read.csv(file)
  room_name <-  substr(basename(file), 1,6)
  
  one_row <-  data.frame(
    room = room_name,
    observations = nrow(data),
    min_co2 = min(data$co2, na.rm = TRUE),
    mean_co2 = mean(data$co2, na.rm= TRUE),
    max_co2 = max(data$co2, na.rm = TRUE),
    missing_co2 = sum(is.na(data$co2))
  )
  
  co2_summary <-  rbind(co2_summary, one_row)
}

co2_summary # having 3 rooms suspicious 

# after noticing some extreme values 
room02_data <- read.csv(co2_files[3])

sum(room02_data$co2 == 43690) # how many obs 

which(room02_data$co2 == 43690) # row position 
# check the values in bln 
room02_data[18339:18349, ]
# now for the rest for the row position which got this extrme value
extreme_vale <-  which(room02_data$co2 == 43690)
extreme_vale

room02_data$co2[extreme_vale - 1] # give co2 measurment immediately before each reading 
room02_data$co2[extreme_vale]
room02_data$co2[extreme_vale + 1] # after 

# checking for room03 and room12 for the same extreme values
#read the files
room03_data <-  read.csv(co2_files[4])
room12_data <-  read.csv(co2_files[13])

extreme03 <-  which(room03_data$co2 == 43690)
extreme12 <-  which(room12_data$co2 == 43690)

cbind(
  before = room03_data$co2[extreme03 -1],
  extreme = room03_data$co2[extreme03],
  after = room03_data$co2[extreme03 +1]
)
cbind(
  before = room12_data$co2[extreme12 -1],
  extreme = room12_data$co2[extreme12],
  after = room12_data$co2[extreme12 +1]
)
unique(room03_data$nodeid)
unique(room12_data$nodeid)

# ################################################################
# 3. TEMPERATURE AND HUMIDITY SENSOR EXPLORATION
# Compare environmental measurements across sensor files and
# investigate sensor/node structure 
# ################################################################

all_sensor_files <-  list.files(
  path = room_folders,
  pattern = "\\.csv$",
  full.names = TRUE
)
length(all_sensor_files)
basename(all_sensor_files)

# first how many sensor files dooes each room contain?
sapply(room_folders, function(folder) {
  length(list.files(folder, pattern = "\\.csv$"))
})

# check the env't of each room 
# first for room00 to check
room00_env_summary <-  data.frame()

for(file in room00_files) {
  data <-  read.csv(file)
  
  one_sensor <-  data.frame(
    sensor_file = basename(file),
    nodeid = unique(data$nodeid),
    mean_temp = mean(data$temperature, na.rm = TRUE),
    mean_humidity = mean(data$humidity, na.rm = TRUE)
  )
   
  room00_env_summary <-  rbind(room00_env_summary, one_sensor)
  
}
room00_env_summary

# for other rooms 
# env_summary <- data.frame()
# 
# for (file in all_sensor_files) {
#   data <- read.csv(file)
#   room_name <- substr(basename(file),1, 6)
#   
#   one_sensor <- data.frame(
#     room = room_name,
#     nodeid = unique(data$nodeid),
#     mean_temp = mean(data$temperature, na.rm = TRUE),
#     mean_humidity = mean(data$humidity, na.rm = TRUE)
#   )
#   env_summary <-  rbind(env_summary, one_sensor)
# }
# env_summary
#
# length(all_sensor_files)
# nrow(env_summary)
# # Initial attempt:
# # Assumed each CSV contained one nodeid.
# # This assumption was checked and found not to hold for all files.
# # room04_THP-PIR_908 contains nodeids 908 and 909.

# how many nodeid values are inside each file
node_counts <- sapply(all_sensor_files, function(file) {
  data <- read.csv(file)
  length(unique(data$nodeid))
})

node_counts

which(node_counts > 1)
basename(all_sensor_files[node_counts > 1]) # so room04_908 contains more that 1 nodeid

#understanding this sensor more
room04_908 <- read.csv(all_sensor_files[22])

unique(room04_908$nodeid)
table(room04_908$nodeid) # count how many obs to each node

# load room04
room04_files <- list.files(
  "raw_data/room04",
  full.names = TRUE
)

basename(room04_files)

# File-level temperature and humidity comparison
# Use one row per CSV rather than assuming one nodeid per csv
env_summary <- data.frame()

for (file in all_sensor_files) {
  
  data <- read.csv(file)
  
  one_sensor <- data.frame(
    room = substr(basename(file), 1, 6),
    sensor_file = basename(file),
    mean_temp = mean(data$temperature, na.rm = TRUE),
    mean_humidity = mean(data$humidity, na.rm = TRUE)
  )
  
  env_summary <- rbind(env_summary, one_sensor)
}
nrow(env_summary)

# now comparing that how far apart are the ave temps in that room 
room_sensor_comparison <- env_summary %>%
  group_by(room) %>% # grp all sensor file belonging to same room
  summarise(
    temp_min = min(mean_temp, na.rm = TRUE),
    temp_max = max(mean_temp, na.rm = TRUE),
    temp_difference = temp_max - temp_min,
    
    humidity_min = min(mean_humidity, na.rm = TRUE),
    humidity_max = max(mean_humidity, na.rm = TRUE),
    humidity_difference = humidity_max - humidity_min
  )

room_sensor_comparison

# ################################################################
# 4. TIME-SERIES STRUCTURE AND GAP ANALYSIS
# Examine timestamp frquency, temporal coverage and
# measurement gaps across the THP-CO2 files
# ################################################################

#converting the timestap to more readable
#first as a sample take room00
room00_Co2$datetime <- as.POSIXct(
  room00_Co2$devicetimestamp,
  origin = "1970-01-01",
  tz = "UTC"
)

names(room00_Co2)

head(room00_Co2[, c("devicetimestamp", "datetime")])
tail(room00_Co2[, c("devicetimestamp", "datetime")])

time_gaps <- diff(room00_Co2$devicetimestamp)
summary(time_gaps)
table(time_gaps)[1:10]

# count and 10 most common 
sort(table(time_gaps), decreasing = TRUE)[1:10]
sum(time_gaps >= 59 & time_gaps <= 62)
mean(time_gaps >= 59 & time_gaps <= 62) * 100
sum(time_gaps > 300)

# now to the other rooms, inspecting time-series 
time_summary <-  data.frame()

for (file in co2_files) {
  data <- read.csv(file)
  
  # convert timestamp to datetime
  data$datetime <-  as.POSIXct(
    data$devicetimestamp, 
    origin = "1970-01-01",
    tz = "UTC"
  )
  
  # calculate gaps bln consecutive obs 
  gaps <-  diff(data$devicetimestamp)
  
  one_room <- data.frame(
    room = substr(basename(file), 1, 6),
    observations = nrow(data),
    start_time = min(data$datetime),
    end_time = max(data$datetime),
    median_gap_sec = median(gaps),
    max_gap_sec = max(gaps),
    gaps_over_5min = sum(gaps >300)
  )
  
  time_summary <- rbind(time_summary, one_room)
}

time_summary

# for more readability lets change the sec
time_summary$max_gap_hours <- time_summary$max_gap_sec / 3600
time_summary$max_gap_days <- time_summary$max_gap_sec / 86400
time_summary[, c(
  "room",
  "start_time",
  "median_gap_sec",
  "gaps_over_5min",
  "max_gap_hours",
  "max_gap_days"
)]

write.csv(
  time_summary,
  "results/time_summary.csv",
  row.names = FALSE
)
file.exists("results/time_summary.csv")


# categorize the gap
gap_summary <- data.frame()

for (file in co2_files) {
  data <- read.csv(file)
  gaps <- diff(data$devicetimestamp)
  
  one_room <- data.frame(
    room = substr(basename(file), 1, 6),
    
    gaps_5min_1hour =
      sum(gaps > 300 & gaps <= 3600),
    gaps_1hour_1day =
      sum(gaps > 3600 & gaps <= 86400),
    gaps_over_1day =
      sum(gaps > 86400)
  )
  gap_summary <- rbind(gap_summary, one_room)
}
gap_summary

# ################################################################
# 5. CO2 DISTRIBUTION AND FINAL RAW-DATA QUALITY CHECK 
# Summarise the CO2 distribution across rooms and confirm
# where the identified invalid value occurs 
# ################################################################

co2_value_summary <- data.frame()

for (file in co2_files) {
  data <- read.csv(file)
  
  one_room <- data.frame(
    room = substr(basename(file), 1, 6),
    min_co2 = min(data$co2, na.rm = TRUE),
    q1_co2 = quantile(data$co2, 0.25, na.rm = TRUE),
    median_co2 = median(data$co2, na.rm = TRUE),
    q3_co2 = quantile(data$co2, 0.75, na.rm = TRUE),
    max_co2 = max(data$co2, na.rm = TRUE),
    values_43690 = sum(data$co2 == 43690, na.rm = TRUE)
  )
  co2_value_summary <- rbind(co2_value_summary, one_room)
}

co2_value_summary


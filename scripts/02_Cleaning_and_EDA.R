# ################################################################
# 1. SETUP 
# Identify the THP-CO2 files used for cleaning and EDA
# ################################################################
room_folders <-  list.dirs(
  path = "raw_data", 
  recursive = FALSE, 
  full.names = TRUE
)

co2_files <-  list.files(
  path = room_folders,
  pattern = "CO2",
  full.names = TRUE,
  ignore.case = TRUE
)

# ################################################################
# 2. DATA CLEANING
# clean the selected THP-CO2 stream and validate the result  
# ################################################################
# create an empty list to store cleanesd THP_CO2 datasets 
clean_co2_data <-  list()

for (file in co2_files) {
  data <-  read.csv(file)
  room_name <-  substr(basename(file), 1, 6)
  
  data$datetime <-  as.POSIXct(
    data$devicetimestamp, 
    origin = "1970-01-01",
    tz = "UTC"
  )
  # replace the identified invalid co2 into NA, preserving the rest rows
  data$co2[data$co2 == 43690] <- NA
  
  #store the cleaned dataset
  clean_co2_data[[room_name]] <-  data
}

# Check the dataset after cleaning
sapply(clean_co2_data, function(data) {
  sum(data$co2 == 43690, na.rm = TRUE)
})
# Count missing CO2 values after replacing the invalid readings
sapply(clean_co2_data, function(data) {
  sum(is.na(data$co2))
})

# ################################################################
# 3. INITIAL TIME-SERIES EDA - ROOM00
# Examine full-year and short-term temporal behaviour 
# ################################################################

room00_clean <-  clean_co2_data[["room00"]]
head(room00_clean)
str(room00_clean)

# plot CO2 measurments over time for room00
plot(
  room00_clean$datetime,
  room00_clean$co2,
  type = "l",
  xlab = "Date",
  ylab = "CO2 (ppm)",
  main = "Room00 CO2 over time"
)

# before moving to all the other rooms, zooming in to room00 first to understand dailt behaviour 

# so selecting 1 week data since shorter period, the easier to observe patterns 
room00_week <- room00_clean[
  room00_clean$datetime >= as.POSIXct("2019-03-01", tz = "UTC") &
    room00_clean$datetime < as.POSIXct("2019-03-08", tz = "UTC"),
]
# plot on the selected week: so now we are zooming in on the plot we did before
plot(
  room00_week$datetime,
  room00_week$co2,
  type = "l",
  xlab = "Date",
  ylab = "CO2 (ppm)",
  main = "Room00 CO2- One Week"
)

#plot temp over the same 1-week period, allows to compare with temporal behavior observed for CO2
plot(
  room00_week$datetime,
  room00_week$temperature,
  type = "l",
  xlab = "Date",
  ylab = "Temperature (°C)",
  main = "Room00 Temperature- One Week"
)

# same for the humidity 
plot(
  room00_week$datetime,
  room00_week$humidity,
  type = "l",
  xlab = "Date",
  ylab = "Humidity (%)",
  main = "Room00 Humidity- One Week"
)

# Now examine the relationship between variables 
# first using the cleaned room00 THP-Co2 measurments 
cor(
  room00_clean[, c("co2", "temperature", "humidity")],
  use = "complete.obs"
)

# ################################################################
# 4.CROSS-ROOM EDA
# Compare cleaned CO2, temperature and humidity across all the romms
# ################################################################

# cross_room_co2 <- data.frame()
# 
# for (room_name in names(clean_co2_data)) {
#   data <- clean_co2_data[[room_name]]
#   
#   one_room <- data.frame(
#     room = room_name,
#     observations = nrow(data),
#     missing_co2 = sum(is.na(data$co2)),
#     mean_co2 = mean(data$co2, na.rm = TRUE),
#     median_co2 = median(data$co2, na.rm = TRUE),
#     sd_co2 = sd(data$co2, na.rm = TRUE),
#     min_co2 = min(data$co2, na.rm = TRUE),
#     max_co2 = max(data$co2, na.rm = TRUE)
#   )
#   cross_room_co2 <- rbind(cross_room_co2, one_room)
# }
# cross_room_co2

# extend the EDA also including temperature and humidity across the rooms 
cross_room_summary <-  data.frame()

for (room_name in names(clean_co2_data)) {
  data <- clean_co2_data[[room_name]]
  
  one_room <-  data.frame(
    room = room_name,
    observations = nrow(data),
    
    # co2 summary 
    missing_co2 = sum(is.na(data$co2)),
    mean_co2 = mean(data$co2, na.rm = TRUE),
    median_co2 = median(data$co2, na.rm = TRUE),
    sd_co2 = sd(data$co2, na.rm = TRUE),
    min_co2 = min(data$co2, na.rm = TRUE),
    max_co2 = max(data$co2, na.rm = TRUE),
    
    # temperature summary
    missing_temp = sum(is.na(data$temperature)),
    mean_temp = mean(data$temperature, na.rm = TRUE),
    median_temp = median(data$temperature, na.rm = TRUE),
    sd_temp = sd(data$temperature, na.rm = TRUE),
    min_temp = min(data$temperature, na.rm = TRUE),
    max_temp = max(data$temperature, na.rm = TRUE),
    
    # humidity summary
    missing_hum = sum(is.na(data$humidity)),
    mean_hum = mean(data$humidity, na.rm = TRUE),
    median_hum = median(data$humidity, na.rm = TRUE),
    sd_hum = sd(data$humidity, na.rm = TRUE),
    min_hum = min(data$humidity, na.rm = TRUE),
    max_hum = max(data$humidity, na.rm = TRUE)
  )
  cross_room_summary <-  rbind(cross_room_summary, one_room)
}

cross_room_summary

write.csv(
  cross_room_summary,
  "results/cross_room_summary.csv",
  row.names = FALSE
)

# plot the mean and meadian of cross-room summary
plot(
  1:nrow(cross_room_summary), # x: 1:13 the 13 rooms
  cross_room_summary$mean_co2, # y: the calculated mean for co2 across the rooms
  type = "b",
  xaxt = "n", # prevent from automatically drawing the label of x-axis
  xlab = "Room",
  ylab = "CO2 (ppm)",
  main = "Mean and Median CO2 Across Rooms"
)
# now add room names to the x-axis
axis(
  1,
  at = 1:nrow(cross_room_summary),
  labels = cross_room_summary$room
)
# adding median in the same plot 
lines(
  1:nrow(cross_room_summary),
  cross_room_summary$median_co2,
  type = "b",
  lty = 2
)
legend(
  "topright",
  legend = c("Mean CO2", "Median CO2"),
  lty = c(1,2)
)

#for temp and humidity 
# compare ave temp across the romms 
plot(
  1:nrow(cross_room_summary), 
  cross_room_summary$mean_temp, 
  type = "b",
  xaxt = "n", 
  xlab = "Room",
  ylab = "Temprature (°C)",
  main = "Mean Temprature Across Rooms"
)
axis(
  1,
  at = 1:nrow(cross_room_summary),
  labels = cross_room_summary$room
)
# compare ave humidity across the romms
plot(
  1:nrow(cross_room_summary), 
  cross_room_summary$mean_hum, 
  type = "b",
  xaxt = "n", 
  xlab = "Room",
  ylab = "Humidity (%)",
  main = "Mean Humidity Across Rooms"
)
axis(
  1,
  at = 1:nrow(cross_room_summary),
  labels = cross_room_summary$room
)
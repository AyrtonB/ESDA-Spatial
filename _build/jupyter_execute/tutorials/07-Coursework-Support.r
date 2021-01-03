library(RNetCDF)
library(tidync)
library(ncmeta)
library(tidyverse)
library(lubridate)
library(ggplot2)

nc_filepath = '../data/Coursework-Support/era5.nc'

nc_file = tidync(nc_filepath)

nc_file

hyper_dims(nc_file)

hyper_vars(nc_file)

ncmeta::nc_atts(nc_filepath, 'NC_GLOBAL')

ncmeta::nc_atts(nc_filepath, 'u10')

times <- (nc_file %>% activate(time) %>% hyper_tibble)$time

times

ncmeta::nc_atts(nc_filepath, 'time')

hours_to_datetime <- function(hour) {
    start_date <- ymd('1900-01-01')
    datetime <- start_date + dhours(hour)
    return(datetime)
}

datetime <- hours_to_datetime(times)

datetime

radiation_slice <- nc_file %>% 
                    activate(ssrd) %>% 
                    hyper_filter(time=time<1043145) %>% 
                    hyper_array

radiation_slice

image(radiation_slice[[1]], useRaster=TRUE)

longitudes = (nc_file %>% activate(longitude) %>% hyper_tibble)$longitude
latitudes = (nc_file %>% activate(latitude) %>% hyper_tibble)$latitude

latitudes[1:5]

# We'll reverse the matrix
radiation_matrix <- radiation_slice[[1]]
radiation_matrix <- radiation_matrix[,length(latitudes):1]

# And also the latitudes values
latitudes = (nc_file %>% activate(latitude) %>% hyper_tibble)$latitude
latitudes <- latitudes[length(latitudes):1]

# Calculate the lat/lon ratio
lat_lon_ratio = length(latitudes)/length(longitudes)

# And visualise them
image(radiation_matrix, asp=lat_lon_ratio)

max_rad <- max(radiation_matrix, na.rm=TRUE)
max_rad_idx <- which(radiation_matrix == max_rad, arr.ind=TRUE)

max_rad_idx

max_lon <- longitudes[max_rad_idx[1]]
max_lat <- latitudes[max_rad_idx[2]]

print(c(max_lon, max_lat))

# 

ncmeta::nc_atts(nc_filepath, 'ssrd')

radiation_to_power <- function(radiation, area=10, yield=0.175, pr=0.6, hours=1){
    kWh <- radiation * area * yield * pr * (hours/3600) / 1000
    return(kWh)
}

max_kWh <- radiation_to_power(max_rad)

max_kWh

# 

u_slice <- nc_file %>% 
            activate(u10) %>% 
            hyper_filter(time=time<1043145) %>% 
            hyper_array

v_slice <- nc_file %>% 
            activate(v10) %>% 
            hyper_filter(time=time<1043145) %>% 
            hyper_array

u_matrix <- u_slice[[1]]
v_matrix <- v_slice[[1]]

speed_matrix <- sqrt(u_matrix**2 + v_matrix**2)
speed_matrix <- speed_matrix[,length(latitudes):1]

image(speed_matrix, asp=lat_lon_ratio)

max_speed <- max(speed_matrix, na.rm=TRUE)

max_speed

calc_turbine_speed <- function(speed, turbine_height=70, data_height=10, hellman_exponent=1/7){
    turbine_speed <-  speed*(turbine_height/data_height)^hellman_exponent
    return(turbine_speed)
}

turbine_speed <- calc_turbine_speed(max_speed)

turbine_speed

speed_to_power <- function(speed){
    pc <- c(0, 0, 0, 0, 0, 40, 102, 160, 257, 355, 471, 605, 750, 972, 1194, 1455, 1713, 1970, 2227, 2380, 2465, 2495, 2500, 2500, 2500, 2500, 2500, 2500, 2500, 2500, 2500, 2500, 2500, 2500, 2500, 2500, 2500, 2500, 2500, 2500, 2500, 2500, 2500, 2500, 2500, 2460, 2400, 2335, 2250)
    names(pc) <- seq(from=0, to=24, by=0.5)
    power <- pc[toString(round(speed, 0))]
    return(power)
}

power <- speed_to_power(turbine_speed)

power

# 

turbine_capacity <- 2.5
num_turbines <- 30
capacity_factor <- 0.3
dollars_per_kWh <- 0.07
lifetime_yrs <- 25

kWh <- turbine_capacity * num_turbines * capacity_factor * 1000 * 24 * 365
annual_revenue <-dollars_per_kWh  * kWh

annual_revenue

calc_NPV <- function(annual_revenue, i=0.05, lifetime_yrs=25, CAPEX=150000000, OPEX=0){
    costs <- rep(OPEX, lifetime_yrs)
    costs[1] <- costs[1]  + CAPEX
    revenue <- rep(annual_revenue, lifetime_yrs)

    t <- seq(1, lifetime_yrs, 1)
    NPV <- sum((revenue - costs)/(1 + i)**t)

    return(round(NPV, 0))
}

calc_NPV(annual_revenue)

# 

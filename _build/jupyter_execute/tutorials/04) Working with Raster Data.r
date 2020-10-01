library(sf) # for handling spatial features
library(stars) # for converting between raster and vector data
library(dplyr) # used for data manipulation
library(raster) # useful in some spatial operations
library(ggplot2) # for plotting
library(zeallot) # used for unpacking variables

source('../scripts/helpers.R') # helper script, note that '../' is used to change into the directory above the directory this notebook is in

download_data()

df_zambia <- read_sf('../data/zambia/zambia.shp')

df_zambia

solar <- raster('../data/africa/solar.tif')
land_cover <- raster('../data/africa/land_cover.tif')
elevation <- raster('../data/africa/elevation.tif')

plot(solar)

df_zambia_4326 <- st_transform(df_zambia, crs=st_crs(solar))
solar_zambia <- crop(solar, df_zambia_4326)

plot(solar_zambia)
plot(df_zambia_4326['geometry'], add=TRUE)



mask(solar, df_zambia_4326)

rstr_zambia_4326 <- st_rasterize(df_zambia_4326)

plot(rstr_zambia_4326)



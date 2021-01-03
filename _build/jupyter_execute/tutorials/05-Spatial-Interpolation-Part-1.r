library(raster) # rasters
library(rgdal)  # spatial data
library(sf)     # for handling spatial features
library(ape)    # clustering (Morans I)
library(scales) # transparencies
library(deldir) # triangulation
library(gstat)  # geostatistics

source('../scripts/helpers.R') # helper script, note that '../' is used to change into the directory above the directory this notebook is in

download_data()

df_zambia <- read_sf('../data/zambia/zambia.shp')
df_africa_cities <- read_sf('../data/africa/cities.shp')
solar <- raster('../data/zambia/solar.tif')
altitude <- raster('../data/zambia/altitude.tif')

df_zambian_cities <- df_africa_cities[which(df_africa_cities$COUNTRY=='Zambia'), ]
df_zambian_cities_UTM35S <- st_transform(df_zambian_cities, crs=st_crs(20935))

head(df_zambian_cities_UTM35S, 3)

plot(altitude)
plot(df_zambia['geometry'], add=TRUE)
plot(df_zambian_cities_UTM35S['geometry'], add=TRUE)

cities_deldir <- deldir(df_zambian_cities_UTM35S$LONGITUDE, df_zambian_cities_UTM35S$LATITUDE)

cities_deldir

cities_polygons <- tile.list(cities_deldir) # Produces Thiessen polygons

plot(cities_polygons)

cities_polygons[[1]]

city_coords = st_coordinates(df_zambian_cities_UTM35S)

df_zambian_cities_UTM35S$solar <- extract(solar, city_coords)
df_zambian_cities_UTM35S$altitude <- extract(altitude, city_coords)

df_zambian_cities_UTM35S$x <- city_coords[, 1]
df_zambian_cities_UTM35S$y <- city_coords[, 2]

plot(df_zambian_cities_UTM35S$x, df_zambian_cities_UTM35S$solar, pch=19)
abline(lm(df_zambian_cities_UTM35S$solar ~ df_zambian_cities_UTM35S$x))

plot(df_zambian_cities_UTM35S$y, df_zambian_cities_UTM35S$solar, pch=19)
abline(lm(df_zambian_cities_UTM35S$solar ~ df_zambian_cities_UTM35S$y))

trend_1st <- lm(solar~x+y, data=df_zambian_cities_UTM35S)
summary(trend_1st)

grid <- st_as_sf(rasterToPoints(solar, spatial=TRUE)) # uses existing raster cell centres as point locations
grid$solar <- NULL # clear existing data

plot(grid, pch=".")

grid_coords <- as.data.frame(st_coordinates(grid))

grid$x <- grid_coords[, 1]
grid$y <- grid_coords[, 2]

grid$solar <- extract(solar, grid_coords[, 1:2])
grid$altitude <- extract(altitude, grid_coords[, 1:2])

plot(grid)

grid_pred <- predict(trend_1st, newdata=grid, se.fit=TRUE)
grid$prediction <- grid_pred$fit

plot(grid[c('solar', 'prediction')])

plot(df_zambian_cities_UTM35S$altitude, df_zambian_cities_UTM35S$solar, pch=19)
abline(lm(df_zambian_cities_UTM35S$solar ~ df_zambian_cities_UTM35S$altitude))

trend_1st <- lm(solar~altitude, data=df_zambian_cities_UTM35S)

grid_pred <- predict(trend_1st, newdata=grid, se.fit=TRUE)
grid$prediction <- grid_pred$fit

plot(grid[c('solar', 'prediction')])

# 

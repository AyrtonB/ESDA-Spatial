library(sf) # for handling spatial features
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

masked_solar_zambia <- mask(solar_zambia, df_zambia_4326)

plot(masked_solar_zambia)

plot(mask(solar, df_zambia_4326))

zambia_raster_mask <- rasterize(df_zambia_4326, solar_zambia, getCover=TRUE)
zambia_raster_mask[zambia_raster_mask==0] <- NA

plot(zambia_raster_mask) 

tb_zambia_raster_mask <- gplot_data(zambia_raster_mask)
tb_zambia_raster_mask <- subset(tb_zambia_raster_mask, !is.na(tb_zambia_raster_mask$value))

head(tb_zambia_raster_mask)

ggplot() +
    geom_tile(data=tb_zambia_raster_mask, aes(x=x, y=y, fill=value)) + 
    geom_sf(data=df_zambia_4326, fill='orange') +
    coord_sf(xlim=c(28, 30), 
             ylim=c(-13.5, -11.75))

masked_solar_zambia <- mask(solar_zambia, zambia_raster_mask)

plot(masked_solar_zambia)

quick_mask_raster <- function(raster_data, masking_vector){
    masking_vector <- st_transform(masking_vector, st_crs(raster_data))
    cropped_raster_data <- crop(raster_data, masking_vector)
    masked_raster_data <- mask(cropped_raster_data, masking_vector)
    
    return(masked_raster_data)
}

mask_raster <- function(raster_data, masking_vector, min_mask_cover=1){
    # Ensuring masking_vector is in the same proj
    masking_vector <- st_transform(masking_vector, st_crs(raster_data))
    
    # Cropping raster to masking_vector extents
    cropped_raster <- crop(raster_data, masking_vector)
    
    # Creating raster mask according to specified cover percentage
    raster_mask <- rasterize(masking_vector, cropped_raster, getCover=TRUE)
    raster_mask[raster_mask<min_mask_cover] <- NA

    # Masking the raster
    masked_raster <- mask(cropped_raster, raster_mask)
    
    return(masked_raster)
}

masked_elevation <- quick_mask_raster(elevation, df_zambia)
masked_land_cover <- quick_mask_raster(land_cover, df_zambia)

plot(masked_land_cover)

rm(solar, land_cover, elevation)

# 

crs = '+proj=utm +zone=35 +south +a=6378249.145 +b=6356514.966398753 +towgs84=-143,-90,-294,0,0,0,0 +units=m +no_defs '
zambia_solar_reproj = projectRaster(masked_solar_zambia, crs=crs)

plot(zambia_solar_reproj)

plot(masked_solar_zambia) 

zambia_elevation_reproj = projectRaster(masked_elevation, crs=crs, method='bilinear')
zambia_land_use_reproj = projectRaster(masked_land_cover, crs=crs, method='ngb')

df_land_cover_classes <- read.csv('../data/africa/land_cover_classes.csv', header=TRUE)

head(df_land_cover_classes)

zambia_land_use_reclass <- subs(zambia_land_use_reproj, df_land_cover_classes, by='ID', which='reclass')

zambia_land_use_reclass

plot(ratify(zambia_land_use_reclass))

zambia_land_use_suitability <- subs(zambia_land_use_reproj, df_land_cover_classes, by='ID', which='suitability')

zambia_land_use_suitability

plot(ratify(zambia_land_use_suitability))

# 

zambia_land_use_suitability_regrid <- resample(zambia_land_use_suitability, zambia_elevation_reproj, method='ngb')
zambia_solar_reproj_regrid <- resample(zambia_solar_reproj, zambia_elevation_reproj, method='bilinear')

zambia_land_use_suitability_regrid

dim(zambia_elevation_reproj) == dim(zambia_land_use_suitability_regrid)

zambia_solar_monthly <- zambia_solar_reproj_regrid/12

zambia_suitable_solar <- zambia_solar_reproj_regrid * zambia_land_use_suitability_regrid
zambia_suitable_solar[zambia_suitable_solar==0] <- NA

plot(zambia_suitable_solar)

# 

df_countrys <- read_sf('../data/africa/countries.shp')
df_countrys <- st_transform(df_countrys, st_crs(zambia_solar_reproj_regrid))

df_countrys$area <- st_area(df_countrys)

plot(df_countrys)

rasterized_country_areas <- rasterize(df_countrys, zambia_solar_reproj_regrid, 'area')

plot(rasterized_country_areas)

polygonized_country_areas <- rasterToPolygons(rasterized_country_areas, dissolve=TRUE)

head(polygonized_country_areas)

plot(polygonized_country_areas)

df_zambia_solar_mean <- extract(solar_zambia, df_zambia, fun=mean, df=TRUE)

df_zambia_solar_mean

df_cities <- read_sf('../data/africa/cities.shp')
df_zambia_cities <- df_cities[which(st_intersects(st_transform(df_cities, st_crs(df_zambia)), df_zambia, sparse=FALSE)), ]

df_zambia_cities_solar <- extract(solar_zambia, df_zambia_cities, df=TRUE)

head(df_zambia_cities_solar)

head(extract(masked_land_cover, df_zambia_cities, df=TRUE))

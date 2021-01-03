library(sf) # for handling spatial features
library(dplyr) # used for data manipulation
library(raster) # useful in some spatial operations
library(ggplot2) # for plotting
library(zeallot) # used for unpacking variables

source('../scripts/helpers.R') # helper script, note that '../' is used to change into the directory above the directory this notebook is in

download_data()

df_country <- read_sf('../data/zambia/zambia.shp')

df_country

plot(df_country['geometry'], col='orange')

st_crs(df_country)

df_africa_countries <- read_sf('../data/africa/countries.shp')
df_africa_cities <- read_sf('../data/africa/cities.shp')
df_africa_roads <- read_sf('../data/africa/roads.shp')
df_africa_grid <- read_sf('../data/africa/grid.shp')

transparent_theme <- theme(
    panel.grid.major = element_blank(), 
    panel.grid.minor = element_blank(),
    panel.background = element_rect(fill='transparent', colour=NA),
    plot.background = element_rect(fill='transparent', colour=NA)
)

ggplot() +
    geom_sf(data=df_country, fill='antiquewhite') +
    geom_sf(data=df_africa_cities, shape=21, 
            color='black', fill='orange', size=3, stroke=1) + 
    coord_sf(xlim=c(0, 1220000), 
             ylim=c(8000000, 9100000)) +
    transparent_theme

coord_lims <- get_geo_df_plot_lims(df_country)

ggplot() +
    geom_sf(data=df_country, fill='antiquewhite') +
    geom_sf(data=df_africa_cities, shape=21, 
            color='black', fill='orange', size=3, stroke=1) + 
    coord_lims + 
    transparent_theme

epsg <- extract_epsg_from_df(df_africa_cities)

epsg

extract_epsg_from_dfs <- function(dfs) {
    epsgs <- list() # We'll create an empty list which 
                    # the epsg codes will be put into
    
    for (df in dfs) # We'll then loop over all of the 
                    # dataframes we've just loaded
    {
        epsg <- extract_epsg_from_df(df) # Extract each epsg code
        epsgs <- append(epsgs, c(epsg))  # and append it to the epsgs list
    }
    
    return(epsgs)
}

dfs <- list(df_africa_cities, df_africa_roads, df_africa_grid)
epsgs <- extract_epsg_from_dfs(dfs)

epsgs

df_africa_cities_UTM35S <- st_transform(df_africa_cities, crs=st_crs(20935))
df_africa_roads_UTM35S <- st_transform(df_africa_roads, crs=st_crs(20935))
df_africa_grid_UTM35S <- st_transform(df_africa_grid, crs=st_crs(20935))

dfs <- list(df_africa_cities_UTM35S, df_africa_roads_UTM35S, df_africa_grid_UTM35S)
epsgs <- extract_epsg_from_dfs(dfs)

epsgs

non_matching_countries <- setdiff(df_africa_countries$NAME, df_africa_cities$COUNTRY)
pct_countries_unmatched <- round(100*length(non_matching_countries)/nrow(df_africa_countries), 2)

pct_countries_unmatched

intersected_cities_bool <- st_intersects(df_africa_cities_UTM35S, df_country, sparse=FALSE)

head(intersected_cities_bool)

intersected_cities_idxs <- which(intersected_cities_bool)

head(intersected_cities_idxs)

idx <- intersected_cities_idxs[1]

df_africa_cities_UTM35S[idx, 'COUNTRY']

df_zambia_cities_UTM35S <- df_africa_cities_UTM35S[intersected_cities_idxs, ]

ggplot() +
    geom_sf(data=df_country, fill='antiquewhite') +
    geom_sf(data=df_zambia_cities_UTM35S, shape=21, 
            color='black', fill='orange', size=3, stroke=1) + 
    transparent_theme

filter_geo_predicate <- function(binary_pred_func, x, y){
    binary_predicate <- binary_pred_func(x, y, sparse=FALSE)
    x_filtered <- x[which(binary_predicate), ]
    
    return(x_filtered)
}

df_intersected_cities <- filter_geo_predicate(st_intersects, df_africa_cities_UTM35S, df_country)

identical(df_intersected_cities, df_zambia_cities_UTM35S)

df_within_cities <- filter_geo_predicate(st_within, df_africa_cities_UTM35S, df_country)

identical(df_intersected_cities, df_within_cities)

df_intersects_grid <- filter_geo_predicate(st_intersects, df_africa_grid_UTM35S, df_country)
df_within_grid <- filter_geo_predicate(st_within, df_africa_grid_UTM35S, df_country)

identical(df_intersects_grid, df_within_grid)

nrow(df_within_grid)

nrow(df_intersects_grid)

within_idxs <- which(st_within(df_africa_grid_UTM35S, df_country, sparse=FALSE))
intersects_idxs <- which(st_intersects(df_africa_grid_UTM35S, df_country, sparse=FALSE))

extra_idxs <- setdiff(intersects_idxs, within_idxs)

extra_idxs

df_grid_intersects_extra <- df_africa_grid_UTM35S[extra_idxs, ]

ggplot() +
    geom_sf(data=df_country, fill='antiquewhite') +
    geom_sf(data=df_grid_intersects_extra, color='blue', size=2) + 
    transparent_theme

# 

# 

df_country_cities <- st_intersection(df_country, df_africa_cities_UTM35S)
df_country_grid <- st_intersection(df_country, df_africa_grid_UTM35S)
df_country_roads <- st_intersection(df_country, df_africa_roads_UTM35S)

ggplot() +
    geom_sf(data=df_country, fill='antiquewhite') +
    geom_sf(data=df_country_roads, color='black') + 
    geom_sf(data=df_country_grid, color='blue') + 
    geom_sf(data=df_country_cities, shape=21, 
            color='black', fill='orange', size=3, stroke=1) + 
    transparent_theme

alt_intersection <- function(x, y){
    y_filtered <- filter_geo_predicate(st_intersects, y, x)
    
    return(y_filtered)
}

df_country_cities_alt <- alt_intersection(df_country, df_africa_cities_UTM35S)
df_country_grid_alt <- alt_intersection(df_country, df_africa_grid_UTM35S)
df_country_roads_alt <- alt_intersection(df_country, df_africa_roads_UTM35S)

ggplot() +
    geom_sf(data=df_country, fill='antiquewhite') +
    geom_sf(data=df_country_roads_alt, color='black') + 
    geom_sf(data=df_country_grid_alt, color='blue') + 
    geom_sf(data=df_country_cities_alt, shape=21, 
            color='black', fill='orange', size=3, stroke=1) + 
    transparent_theme

grid_multilinestring <- st_union(df_country_grid)

grid_multilinestring

df_country_grid <- transform(df_country_grid, length_km=as.numeric(length_km))

df_grid_groups <- df_country_grid %>%
                    group_by(voltage_kV) %>%
                    summarize(length_km=sum(length_km, na.rm=TRUE))

df_grid_groups

grid_geom_set <- st_cast(grid_multilinestring, 'LINESTRING')

grid_geom_set

st_length(grid_multilinestring)

# 

# 

df_road_UTM35S <- df_africa_roads_UTM35S[1, ]
df_buffered_road_UTM35S <- st_buffer(df_road_UTM35S, dist=5000)

ggplot() +
    geom_sf(data=df_buffered_road_UTM35S, color='yellow') + 
    geom_sf(data=df_road_UTM35S, color='blue') + 
    transparent_theme

df_road <- df_africa_roads[1, ]
df_buffered_road <- st_buffer(df_road, dist=5000)

ggplot() +
    geom_sf(data=df_buffered_road, color='yellow') + 
    geom_sf(data=df_road, color='blue') + 
    transparent_theme

df_road <- df_africa_roads[1, ]
df_buffered_road <- st_buffer(df_road, dist=0.05)

ggplot() +
    geom_sf(data=df_buffered_road, color='yellow') + 
    geom_sf(data=df_road, color='blue') + 
    transparent_theme

df_buffered_roads <- st_buffer(df_country_roads, dist=5000)

ggplot() +
    geom_sf(data=df_country, fill='antiquewhite') +
    geom_sf(data=df_buffered_roads, fill='orange') + 
    geom_sf(data=df_country_roads, color='blue') + 
    transparent_theme

df_buffered_cities <- st_buffer(df_country_cities, dist=50000)

ggplot() +
    geom_sf(data=df_country, fill='antiquewhite') +
    geom_sf(data=df_buffered_cities, fill='orange') + 
    geom_sf(data=df_country_cities, color='blue') + 
    transparent_theme

df_country_big_cities <- df_country_cities[df_country_cities$ES00POP>10000, ]
df_buffered_cities <- st_buffer(df_country_big_cities, dist=50000)
df_buffered_cities_comb <- st_union(df_buffered_cities)

ggplot() +
    geom_sf(data=df_country, fill='antiquewhite') +
    geom_sf(data=df_buffered_cities_comb, fill='orange') + 
    geom_sf(data=df_country_cities, color='blue') + 
    transparent_theme

dist <- df_country_grid$voltage_kV * 10
df_buffered_grid <- st_buffer(df_country_grid, dist=dist)
df_buffered_grid_comb <- st_union(df_buffered_grid)

ggplot() +
    geom_sf(data=df_country, fill='antiquewhite') +
    geom_sf(data=df_buffered_grid_comb, fill='orange') + 
    geom_sf(data=df_country_grid, color='blue') + 
    transparent_theme

df_grid_cities_intersection <- st_intersection(df_buffered_grid_comb, df_buffered_cities_comb)

ggplot() +
    geom_sf(data=df_country, fill='antiquewhite') +
    geom_sf(data=df_grid_cities_intersection, fill='orange') + 
    transparent_theme

df_grid_cities_union <- st_union(df_buffered_grid_comb, df_buffered_cities_comb)

ggplot() +
    geom_sf(data=df_country, fill='antiquewhite') +
    geom_sf(data=df_grid_cities_union, fill='orange') + 
    transparent_theme

df_country_cities_diff<- st_difference(df_country, df_buffered_cities_comb)

ggplot() +
    geom_sf(data=df_country, fill='antiquewhite') +
    geom_sf(data=df_country_cities_diff, fill='orange') + 
    transparent_theme

df_country_cities_sym_diff <- st_sym_difference(df_country, df_buffered_cities_comb)

ggplot() +
    geom_sf(data=df_country, fill='antiquewhite') +
    geom_sf(data=df_country_cities_sym_diff, fill='orange') + 
    transparent_theme

df_biggest_city <- df_country_cities[which.max(df_country_cities$ES00POP), ]

df_biggest_city

dist_matrix <- st_distance(df_country_cities, df_biggest_city)

dist_matrix

near_capital_dist <- sort(dist_matrix)[2]

near_capital_dist

s_nearest_to_capital <- as.data.frame(dist_matrix==near_capital_dist)[, 1]

df_country_cities[s_nearest_to_capital, 'NAME1']

# 

# 

# 

get_geo_df_limits <- function(df){
    ## Identifies the min/max of the x and y coordinates 
    ## for features in a spatial dataframe
    
    # Extracting x/y coordinates
    df_coords <- st_coordinates(df)
    
    # Separating x/y coordinates
    x_vals <- df_coords[, 1]
    y_vals <- df_coords[, 2]

    # Identifying the limits of x/y
    min_x <- min(x_vals)
    max_x <- max(x_vals)
    min_y <- min(y_vals)
    max_y <- max(y_vals)
    
    return(c(min_x, max_x, min_y, max_y))
}

extract_epsg_from_df <- function(df) {
    ## Extracts the epsg code from a spatial dataframe
    epsg <- st_crs(df)$epsg
    
    return(epsg)
}

transform_bbox_corner_crs <- function(min_x_in, max_x_in, 
                                      min_y_in, max_y_in, 
                                      crs_in, crs_out) {
    
    bottom_left <- st_point(c(min_x_in, min_y_in))
    top_right <- st_point(c(max_x_in, max_y_in))

    bbox_corners_in <- st_sfc(bottom_left, top_right, crs=crs_in)
    bbox_corners_out <- st_transform(bbox_corners_in, crs=crs_out)
    
    df_bbox_out <- st_coordinates(bbox_corners_out)

    min_x_out <- df_bbox_out[1, 1]
    max_x_out <- df_bbox_out[2, 1]
    min_y_out <- df_bbox_out[1, 2]
    max_y_out <- df_bbox_out[2, 2]
    
    return(c(min_x_out, max_x_out, min_y_out, max_y_out))
}

get_geo_df_plot_lims <- function(df, crs_out=NA){
    # Identify limits
    geo_df_limits <- get_geo_df_limits(df)
    c(min_x_out, max_x_out, min_y_out, max_y_out) %<-% geo_df_limits

    # Optionally convert to new crs
    if (!is.na(crs_out)) {
        crs_in <- extract_epsg_from_df(df) %>%
                    strtoi() %>%
                    st_crs

        out_coords <- transform_bbox_corner_crs(min_x_in, max_x_in, 
                                                min_y_in, max_y_in, 
                                                crs_in, crs_out)

        c(min_x_out, max_x_out, min_y_out, max_y_out) %<-% out_coords
    }

    # Convert to ggplot2 coordinate limits
    coord_lims <- coord_sf(xlim=c(min_x_out, max_x_out), 
                           ylim=c(min_y_out, max_y_out))
    
    return(coord_lims)
}

get_data_dir <- function(){
    cwd <- getwd()
    repo_root_dir <- gsub('(ESDA-Spatial).*', '\\1', cwd)
    data_dir <- paste(repo_root_dir, 'data', sep='/')
    
    using_binder <- grepl('/home/jovyan', data_dir, fixed=TRUE)
    
    if (using_binder) {
        data_dir <- '/home/jovyan/data'
    }

    return(data_dir)    
}

retrieve_zip <- function(url, dir){
    temp_shapefile <- tempfile()
    download.file(url, temp_shapefile)
    unzip(temp_shapefile, exdir=dir)
}

get_path_to_obj <- function(data_dir){
    # make it so auto gen from passed list, keep to zipped folders in s3
    path_to_obj <- vector(mode='list', length=2)
    
    names(path_to_obj) <- c(
        paste(data_dir, 'zambia', sep='/'),
        paste(data_dir, 'africa', sep='/')
    )

    path_to_obj[[1]] <- 'https://esda-spatial.s3.eu-west-2.amazonaws.com/zambia.zip'
    path_to_obj[[2]] <- 'https://esda-spatial.s3.eu-west-2.amazonaws.com/africa.zip'
    
    return(path_to_obj)
}

download_data <- function(data_dir){
    data_dir <- get_data_dir()
    path_to_obj <- get_path_to_obj(data_dir)
    filepaths <- names(path_to_obj)

    for(i in seq_along(path_to_obj)) {
        dir <- filepaths[i]
        obj <- toString(path_to_obj[i])

        if (!dir.exists(dir)) {
            retrieve_zip(obj, dir)
        }
    }
}

gplot_data <- function(x, maxpixels = 50000)  {
    # taken from -> https://github.com/statnmap/cartomisc/blob/master/R/gplot_data.R
    
    # extract coords
    x <- raster::sampleRegular(x, maxpixels, asRaster = TRUE)
    coords <- raster::xyFromCell(x, seq_len(raster::ncell(x)))
    
    # Extract values
    dat <- utils::stack(as.data.frame(raster::getValues(x)))
    names(dat) <- c('value', 'variable')
    
    # If only one variable
    if (dat$variable[1] == "raster::getValues(x)") {
        dat$variable <- names(x)
    }

    dat <- dplyr::as_tibble(data.frame(coords, dat))

    if (!is.null(levels(x))) {
        dat <- dplyr::left_join(dat, levels(x)[[1]],
                                by = c("value" = "ID"))
    }
    
    return(dat)
}

hours_to_datetime <- function(hour) {
    start_date <- ymd('1900-01-01')
    datetime <- start_date + dhours(hour)
    return(datetime)
}

radiation_to_power <- function(radiation, area=10, yield=0.175, pr=0.6, hours=1){
    kWh <- radiation * area * yield * pr * (hours/3600) / 1000
    return(kWh)
}

calc_turbine_speed <- function(speed, turbine_height=70, data_height=10, hellman_exponent=1/7){
    turbine_speed <-  speed*(turbine_height/data_height)^hellman_exponent
    return(turbine_speed)
}

calc_NPV <- function(annual_revenue, i=0.05, lifetime_yrs=25, CAPEX=150000000, OPEX=0){
    costs <- rep(OPEX, lifetime_yrs)
    costs[1] <- costs[1]  + CAPEX
    revenue <- rep(annual_revenue, lifetime_yrs)

    t <- seq(1, lifetime_yrs, 1)
    NPV <- sum((revenue - costs)/(1 + i)**t)

    return(round(NPV, 0))
}
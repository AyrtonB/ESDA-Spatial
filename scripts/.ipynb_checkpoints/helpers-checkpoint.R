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
    
    wkt <- st_crs(df)['wkt']
    
    epsg <- wkt %>%
        as.character() %>%
        strsplit('\\n') %>%
        unlist() %>%
        tail(1) %>%
        strsplit(',') %>%
        unlist() %>%
        tail(1) %>% 
        strsplit(']') %>%
        unlist() %>%
        head(1) %>%
        strtoi()
    
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
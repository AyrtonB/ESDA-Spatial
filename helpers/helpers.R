get_geo_df_limits <- function(df){
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
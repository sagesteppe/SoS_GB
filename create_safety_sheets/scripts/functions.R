#' recover the coordinates of a place from a tigris places dataframe
coord_grab <- function(places_data, search_cities){
  
  place <- places_data[grep(search_cities, places_data$NAME), ]
  place <- sf::st_point_on_surface(place) |>
    sf::st_coordinates(place)
  
  return(place)
}


#' @param x search result from google
#' @param y query string
#' 
true_types <- function(x, y){
  
  true_types <- lapply( # many attributes are in this column, test each one for a logical match
    x[["results"]][["types"]], grep, y)
  
  w_tt <- which(sapply(true_types, any)) # identify rows with matches in the column
  right_type <- x[["results"]][w_tt,] # subset the appropriate rows
  
  rt_df <- right_type[right_type$business_status == 'OPERATIONAL',
                            c('name', 'formatted_address', 'user_ratings_total', 
                              'rating', 'types')]
  rt_geo <- cbind(rt_df, data.frame(
      lat = right_type[,'geometry'][[1]]$lat,
      long = right_type[,'geometry'][[1]]$lng
      )
    ) %>% 
    st_as_sf(., coords = c(x = 'long', y = 'lat'), remove = F, crs = 4326)
  
  return(rt_geo)
}


services_fn <- function(location_type, search_cities, places_sf){
  
  resin <- vector(mode = "list", length = length(search_cities))
  for (i in 1:length(search_cities)){
  
    s_city <- coord_grab(places_sf, search_cities = search_cities[i])
  
    searches <- lapply(location_type, FUN = google_places, 
                     location=c(s_city[1,2], s_city[1,1]), rankby = 'distance', 
                keyword = 'name', key = SoS_gkey)
    names(searches) <- location_type

    true_search <- mapply(FUN = true_types, x = searches, y = l_type, SIMPLIFY = FALSE)
    resin[[i]] <- dplyr::bind_rows(true_search, .id = "Service")
  }
  
  results <- dplyr::bind_rows(resin) |>
    dplyr::distinct(name, lat, long, .keep_all = T)
  
  return(results)

}


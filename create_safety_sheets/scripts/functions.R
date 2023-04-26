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
  right_type <- x[["results"]]
  
  rt_geo <- cbind(right_type, data.frame(
      lat = right_type[,'geometry'][[1]]$lat,
      long = right_type[,'geometry'][[1]]$lng
      )
    ) %>% 
    st_as_sf(., coords = c(x = 'long', y = 'lat'), remove = F, crs = 4326)
  
  rt_geo <- rt_geo[w_tt,] # subset the appropriate rows
  rt_geo <- rt_geo[rt_geo$business_status == 'OPERATIONAL',
                      c('name', 'formatted_address', 'user_ratings_total', 
                        'rating', 'types', 'lat', 'long')]
  
  return(rt_geo)
}


services_fn <- function(location_type, search_cities, places_sf, dist){
  
  resin <- vector(mode = "list", length = length(search_cities))
  for (i in 1:length(search_cities)){
  
    s_city <- coord_grab(places_sf, search_cities = search_cities[i])
  
    searches <- lapply(location_type, FUN = google_places, 
                     location=c(s_city[1,2], s_city[1,1]), rankby = 'distance', key = SoS_gkey)
    names(searches) <- location_type

    true_search <- mapply(FUN = true_types, x = searches, y = location_type, SIMPLIFY = FALSE)
    resin[[i]] <- dplyr::bind_rows(true_search, .id = "Service")
  }
  
  cands <- dplyr::bind_rows(resin) |>
    dplyr::distinct(name, lat, long, .keep_all = T)
  
  results <- within(cands, dist, search_cities, places_sf)
  results <- dplyr::arrange(results, Service)
  return(results)

}

#' select locations only X within distance from places

within <- function(x, dist, search_cities, places_data){
  
  cities <- places_data[grep(search_cities, places_data$NAME), ]
  
  focal <- sf::st_union(cities) %>% 
    sf::st_transform(5070) %>% 
    sf::st_buffer(dist)
  x_5070 <- st_transform(x, 5070)
  
  x_sub <- x[sf::st_intersects(x_5070, focal) %>% lengths > 0,]
  
  return(x_sub)
  
}

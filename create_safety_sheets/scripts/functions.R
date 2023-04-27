#' recover the coordinates of a place from a tigris places dataframe
coord_grab <- function(places_data, search_cities){
  
  place <- places_data[grep(search_cities, places_data$NAME), ]
  st_agr(place) = "constant"
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
  rt_geo <- rt_geo[rt_geo$business_status == 'OPERATIONAL',]
  
  vars <- c('name',  'user_ratings_total', 'rating', 'types', 'lat', 'long')
  rt_geo <- dplyr::select(rt_geo, any_of(vars))
  
  return(rt_geo)
}


services_fn <- function(location_type, search_cities, places_sf, dist){
  
  resin <- vector(mode = "list", length = length(search_cities))
  names(resin) <- search_cities
  for (i in 1:length(search_cities)){
  
    s_city <- coord_grab(places_sf, search_cities = search_cities[i])
  
    searches <- vector(mode = "list", length = length(location_type))
    for (z in 1:length(location_type)){
      
      searches[[z]] <- google_places(
        place_type = location_type[z], location = c(s_city[1,2], s_city[1,1]),
                                 rankby = 'distance', key = SoS_gkey)
    }
    
    names(searches) <- location_type
    searches <- searches[ sapply(lapply(searches, "[", 1:2), lengths) [2,] > 0 ]

    true_search <- mapply(FUN = true_types, x = searches, y = names(searches), SIMPLIFY = FALSE)
    true_search <- true_search[sapply(true_search, function(x) dim(x)[1]) > 0]
    true_search <- dplyr::bind_rows(true_search, .id = 'Service')
    resin[[i]] <- true_search
  
  }

   cands <- dplyr::bind_rows(resin, .id = 'Locality') |>
    dplyr::distinct(name, lat, long, .keep_all = T)
  
  results <- within(cands, dist, search_cities, places_sf)
  results <- dplyr::arrange(results, Service)

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


#' gather distance and azimuth from shop to center of town
#'
#' Help provide some simple context between the building and the 
#' @param x an sf/tibble/dataframe of locations with associated nearest locality data
#' @param places_data an sf/dataframe/dataframe which contains coordinates for the locations in the data
distAZE <- function(x, places_data){
  
  locality <- sf::st_drop_geometry(x)
  locality <- locality[1, 'Locality']
  
  focal <- places_data[grep(locality, places_data$NAME), ]
  if(nrow(focal) > 1){
    union_loc <- sf::st_union(x) |> sf::st_point_on_surface()
    focal <- focal[sf::st_nearest_feature(union_loc, focal),]
  }
  
  location_from <- sf::st_centroid(focal)
  
  location_from <- sf::st_transform(location_from, 5070)
  x_planar <- sf::st_transform(x, 5070)
  distances <- sf::st_distance(location_from, x_planar, which = 'Euclidean')
  
  azy <- nngeo::st_azimuth(
    location_from, 
    x_planar
  )
  
  distances <- data.frame(
    st_drop_geometry(x),
    Distance = round(as.numeric(distances / 1609.34), 1),
    Azimuth = round(as.numeric(azy), 0),
    geometry = x[,'geometry']
  )
  
}

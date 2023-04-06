#' remove duplicate population records from natural history databases
#' 
#' Use this tool to remove records of the same species if they are within a 
#' distance threshold of each other
#' @param x the first data set, this should be (generally) smaller of the two
#' @param y the second data set
#' @param dist_thresh the minimum distance to keep records of

dupe_dropper <- function(x, y, dist_thresh){
  
     # Identify the closet record between each data sets
  all_distances <- st_distance(x, y)
  min_dist_partner <- apply(all_distances, 1, which.min)

  # now calculate the exact distance between the records
  min_dist <- as.numeric(
    st_distance(
      x, y[min_dist_partner,], by_element = T)
    )

  # drop records  from the GBIF data set which are less than 500m from BIEN records
  x_out <- x[min_dist > dist_thresh,]
  return(x_out)
  
}


#' generate and ensemble species distribution models here
#' 
#' Use this function to generate weighted Random Forest, Boosted Regression Trees, 
#' and weighted Support Vector Machine models of probability of suitable habitat.

Machine_SDM <- function(x){
  
  binomial <-  x$binomial[1]
  taxon <- x %>% 
    mutate(occurrence = case_when(occurrence == 2 | occurrence == 1 ~ 1,
                                  occurrence == 0 ~ 0)) %>% 
    dplyr::select(occurrence) %>% 
    as(., "Spatial")
  taxon = spTransform(taxon,geo_proj)
  
  sdm_data_obj <- sdmData(formula = occurrence~., 
                          train = taxon, 
                          predictors = WPDPV2)
  sdm_model <- sdm(
    formula = occurrence ~ .,  data = sdm_data_obj, 
    methods = c('rf', 'brt', 'svm'), replication = 'sub', 
    test.percent = 30, n = 5)
  
  fname <- paste0('../results/maps/', binomial, Sys.time(),'.tif')
  fname <- gsub(' ', '_', fname)
  
  sdm_ensemble_prediction <- sdm::ensemble(
    sdm_model, WPDPV2, 
    setting = list(method = "weighted", stat = 'tss', opt = 2), 
    filename = fname)
  
  fname <- paste0('../results/stats/', binomial, Sys.time(),'.csv')
  fname <- gsub(' ', '_', fname)
  evaluation <- getEvaluation(
    sdm_model, stat=c('TSS','Kappa','AUC'), wtest=c('training','test'), opt = 1)
  write.csv(evaluation, file = fname)
  
}

#' erase one geometry from another
st_erase = function(x, y) st_difference(x, st_union(y))

#' draw an equal number of absences to presences to SDMs
#' 
#' use this function to draw an equal number of absences as presences for 
#' species distribution modelling. Submit a polygon in planar coordinates which
#' specifies the extent of the area, and an offset distance from each presence
#' record which the closest absence can be located in
#' @param polyg spatial extent to perform sampling in
#' @param occurrences occurrence records to be used for modelling
#' @param dist minimum distance an absence records can be relative to an occurrence, 
#' @param species the name of the column holding species data
#' if missing defaults to 100 meters

random_draw <- function(occurrences, polyg, dist, species){
  
  if(missing(dist)){dist = 100}
  if(st_crs(polyg) != st_crs(occurrences)){polyg <- st_transform(polyg, st_crs(occurrences))}
  species <- enquo(species)
  
  taxon <- pull(occurrences, !!species)[1]
  
  
  occ_buff <- sf::st_buffer(occurrences, dist) 
  polyg <- st_erase(polyg, occ_buff)
  
  absences <- sf::st_sample(polyg, occ_buff, size = nrow(occurrences)) %>% 
    sf::st_as_sf() |>
    dplyr::rename(geometry = x) |>
    dplyr::mutate(Occurrence = 0, !!species := taxon,
                  .before = geometry)
  
  results <- dplyr::bind_rows(absences, occurrences |>
                                dplyr::mutate(Occurrence = 1, .before = geometry) )
  
  return(results)
  
}

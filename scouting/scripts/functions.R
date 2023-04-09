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
  
  presences <- nrow(occurrences[occurrences$Occurrence == 1,])
  abs_need <- nrow(occurrences) - presences
  taxon <- pull(occurrences, !!species)[1]
  
  absences <- sf::st_sample(polyg, size = round(nrow(occurrences) * 1.5), 0) |>
    sf::st_as_sf() |>
    dplyr::rename(geometry = x) 
  absences <- absences[st_is_within_distance(absences, occurrences, dist = 10000) %>% lengths == 0,]
  absences <- absences[sample(nrow(absences), size = abs_need, replace = F),]
  
  absences <- absences |>
    dplyr::mutate(Occurrence = 0, !!species := taxon,
                  .before = geometry)
  
  results <- dplyr::bind_rows(occurrences, absences)
  return(results)
  
}


###################
# TRUE ABSENCE ML #
###################

true_absence_ML <- function(x){ # for collecting true absence records from BLM land. 
  
  taxon <- x$species[1]
  no_record <- nrow(x)
  
  TA_req <- round((no_record * prop_blm)*1.2, 0) # how many true absences needed? # buffered for NA cells
  presence_PK <- x %>% pull(PrimaryKey) # which plots can absences not occur in because a presence is there?
  
  AIM_absence <- AIM_points %>% # remove plots with an occurrence of the taxon. 
    filter(!PrimaryKey %in% presence_PK)  %>% # make sure the plot does not have a presence record
    mutate(species = taxon,
           Occurrence = 0, .before = geometry)
  
  AIM_absence <- AIM_absence[sample(1:nrow(AIM_absence), size = TA_req, replace = F),]
  
  out <- bind_rows(x %>% 
                     mutate(Occurrence = 1, .before = geometry), AIM_absence) %>% 
    st_as_sf()
  return(out)
}


#' crop and aggregate rasters for projects
#' 
import_crop <- function(x, y, ppred){
  
  intermed <- file.path(ppred, "GreatBasin", 
                        paste0("GreatBasin", x$QUADRAT[1], ".tif"))
  collection <- sprc(lapply(x$location, rast))
  mo <- mosaic(collection, filename = intermed)
  
  mo <- mo[[c(1:10, 13:14, 16:20, 22:26, 28, 31:32)]]
  
  mo <- terra::crop(mo, outer_bounds, mask = T)
  in_bounds <- y[y$QUADRAT == x$QUADRAT[1],]
  mo <- terra::crop(mo, gr, mask = T)
  
  mo_agg <- aggregate(
    mo, fact=9, cores = parallel::detectCores(), filename =
      file.path(ppred, "GreatBasin",
                paste0("GreatBasin", x$QUADRAT[1], "-agg.tif")))
  
  
  if (file.exists(intermed)) {
    file.remove(intermed)
    message(paste0("Intermediate mosaic deleted and replaced by final aggregated dataset, Quadrat:",  x$QUADRAT[1]))
  }
  
  gc()
  
}

rast_project <- function(x, proj, ppred){
  
  rasty <- rast(x)
  
  terra::project(rasty, proj, filename = 
                   file.path(ppred, "GreatBasin",
                             gsub( 'agg', "5070", basename(x))))
  
  if (file.exists(x)) {
    file.remove(x)
    message(paste0("Aggregate mosaic deleted and replaced by final aggregated dataset, Quadrat:",  x))
  }
  
  gc()
  
}



#' generate and ensemble species distribution models here
#' 
#' Use this function to generate weighted Random Forest, Boosted Regression Trees, 
#' and weighted Support Vector Machine models of probability of suitable habitat.

Machine_SDM <- function(x){
  
  binomial <-  gsub(" ", "_", x$species)[1]
  occ <-  x[x$Occurrence == 1, ]
  absence <- x[x$Occurrence == 0, ]
  
  sdm_data_obj <- sdmData(formula = Occurrence ~ ., 
                          bg = absence, 
                          train = occ)

  sdm_model <- sdm(
    data = sdm_data_obj, 
    methods = 'rf', replication = 'cv', cv.folds = 5, n = 3, 
    parallelSettings = list(ncore = detectCores(), method = 'parallel'))
  
  fname <- paste0('../results/stats/', binomial, '_', Sys.Date(),'.csv')
  evaluation <- getEvaluation(
    sdm_model, stat=c('TSS','Kappa','AUC'), wtest=c('training','test'), opt = 1)
  
  write.csv(evaluation, file = fname, row.names = F)
  

  fname <- paste0('../results/maps/', binomial, '_', Sys.Date(),'.tif')
  sdm_ensemble_prediction <- sdm::ensemble(
    sdm_model, WPDPV, 
    setting = list(method = "weighted", stat = 'tss', opt = 2), 
    filename = fname)
  
  gc()
}


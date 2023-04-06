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


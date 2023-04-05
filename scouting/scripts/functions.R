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

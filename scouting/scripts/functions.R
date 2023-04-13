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


############################################################################
# write out portions of 

#' Write out all spatial data for crews to a directory
#'
#' @param project_areas split sf data set, with each crews field office(s), and name
#' @param target_species a dataframe containing possible target species
#' @param crew_id column in project_areas holding the crews identifier info 'e.g. UFO'
#' @param _blm_surf sf data set of surface management as multipolygon at most
#' @param fs_surf sf data set of surface USFS land management as multipolygon at most
#' @param fire sf data set of historic fires as multipopylgon at most
#' @param invasive sf dataset of invasive species relative cover estimates
#' @param historic_SOS sf dataset with historic SoS endeavors and relevant info
#' @param roads sf dataset of roads with relevant attritbutes
#' @param seed_transfer sf dataset of seed transfer zones 
#' @param drought6 netcdf of drought dataset from SPEI website, we recommend using 6 and 12 month
#' @param drought12 12 netcdf of drought dataset from SPEI website, we recommend using 6 and 12 month

project_maker <- function(x, target_species,
                          blm_surf, fs_surf, # ownership stuff
                          fire,  invasive,
                          sdm_stack,  occurrences, historic_SOS, 
                          roads, seed_transfer, 
                          drought6, drought12){
  
  defaultW <- getOption("warn")
  options(warn = -1)
  
  #### Initiate Project Directories ####
  
  # create directory to hold all contents
  x_df <- st_drop_geometry(x)
  crew_dir <- paste0('../Crews/', x_df['Crew'][[1]][1])
  
  ifelse(!dir.exists(file.path('../Crews/')), dir.create(file.path('../Crews/')), FALSE)
  ifelse(!dir.exists(file.path(crew_dir)), dir.create(file.path(crew_dir)), FALSE)
  ifelse(!dir.exists(file.path(crew_dir, 'Geodata')), 
         dir.create(file.path(crew_dir, 'Geodata')), FALSE)
  ifelse(!dir.exists(file.path(crew_dir, 'Data')), 
         dir.create(file.path(crew_dir, 'Data')), FALSE)
  
  # write out BLM and Forest Service
  dir.create( file.path(crew_dir, 'Geodata/Admin') ) 
  dir.create( file.path(crew_dir, 'Geodata/Admin/Boundaries') ) 
  dir.create( file.path(crew_dir, 'Geodata/Admin/Surface') ) # both BLM and Forest Service go in here
  
  # fire and invasive species data
  dir.create( file.path(crew_dir, 'Geodata/Disturb') ) 
  dir.create( file.path(crew_dir, 'Geodata/Disturb/Fire') ) 
  dir.create( file.path(crew_dir, 'Geodata/Disturb/Invasive') ) 
  
  # target species information
  dir.create( file.path(crew_dir, 'Geodata/Species') ) 
  dir.create( file.path(crew_dir, 'Geodata/Species/SDM') ) 
  dir.create( file.path(crew_dir, 'Geodata/Species/Occurrences') ) 
  dir.create( file.path(crew_dir, 'Geodata/Species/Historic_SoS'))
  
  # Roads
  dir.create( file.path(crew_dir, 'Geodata/Roads')) 
  # Seed transfer zones
  dir.create( file.path(crew_dir, 'Geodata/STZ')) 
  # drought 
  dir.create( file.path(crew_dir, 'Geodata/Drought'))
  
  
  #### Process geographic data to a mask of the field office ####
  
  focal_bbox <- x %>%  # create this to clip all data to.
    st_union() %>% 
    st_transform(5070) %>% 
    st_buffer(dist = 10000) 
  
  focal_vect  <- focal_bbox %>%  
    vect()
  focal_bbox <- focal_bbox 
  
  ### identify target species and pull out of the SDM stack
  
  t_spp <- target_species %>% 
    filter(Crew %in% c('Universal', x_df['Crew'][[1]][1])) 
  t <- t_spp %>% 
    mutate(Species = str_replace(Species, " ", "_")) %>% 
    pull(Species)
  
  write.csv(t_spp, file = file.path(crew_dir, 'Data', 'Target-species.csv'), row.names = F)
  sub <- sdms[[str_remove(names(sdms), '_[0-9].*$') %in% t]]

  # write out ownership details
  st_write(x, dsn = file.path(crew_dir, 'Geodata/Admin/Boundaries', 'Field_Office_Boundaries.shp' ), quiet = T)
  st_intersection(blm_surf, focal_bbox) %>%  
    st_write(., dsn = file.path(crew_dir, 'Geodata/Admin/Surface', 'BLM_Surface.shp'), quiet = T)
  st_intersection(fs_surf , focal_bbox) %>% 
    st_write(., dsn = file.path(crew_dir, 'Geodata/Admin/Surface', 'USFS_Surface.shp'), quiet = T)
  
  # write out invasive species
  st_intersection(fire, focal_bbox) %>% 
    st_write(., dsn =  file.path(crew_dir, 'Geodata/Disturb/Fire', 'Fire.shp'), quiet = T)
  
  crop(invasives, focal_vect, mask = T, threads = T, filename =
         file.path(crew_dir, 'Geodata/Disturb/Invasive', 'Invasive.tif'))
  
  # write out species occurrence data
  
  occurrences_sub <- filter(occurrences, species %in% t)
  occurrences_list <- st_intersection(occurrences_sub, focal_bbox) %>% 
    split(., f = .$species)
  
  occ_writer <- function(x){
    x_df <- st_drop_geometry(x)
    binomial <- paste0(x_df['species'][[1]][1], '.shp')
    st_write(x,  dsn = file.path(crew_dir, 'Geodata/Species/Occurrences', binomial),
             quiet = T, append = F)
  }
  
  lapply(occurrences_list, occ_writer)
    
  #  st_write(., dsn = file.path(crew_dir, 'Geodata/Species/Occurrences', 'Occurrences.shp'), quiet = T)
  st_intersection(historic_SOS, focal_bbox) %>% 
    st_write(., dsn = file.path(crew_dir, 'Geodata/Species/Historic_SoS', 'Historic_SoS.shp'), quiet = T)
  
  # write out assorted data
  st_intersection(roads, focal_bbox) %>% 
    st_write(., dsn = file.path(crew_dir, 'Geodata/Roads', 'roads.shp'), quiet = T)
  st_intersection(seed_transfer, focal_bbox) %>% 
    st_write(., dsn = file.path(crew_dir, 'Geodata/STZ', 'STZ.shp'), quiet = T)
  
  # drought
  crop(drought6, focal_vect, mask = T, threads = T, filename =
         file.path(crew_dir, 'Geodata/Drought', 'drought-6.tif'))
  crop(drought12, focal_vect, mask = T, threads = T, filename =
         file.path(crew_dir, 'Geodata/Drought', 'drought-12.tif'))
  
  # write out original species information
  sdm_fo <- crop(sub, focal_vect, mask = T) # need to make a vect of this... 
  fnames <- paste0(crew_dir, '/Geodata/Species/SDM/', str_remove(names(sdm_fo),
                                                                 '_[0-9].*$'), ".tif")
  writeRaster(sdm_fo, fnames)
  
  options(warn = defaultW)
}


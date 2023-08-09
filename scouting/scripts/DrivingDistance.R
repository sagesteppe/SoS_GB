library(tidyverse)
library(sf)

setwd('/media/sagesteppe/ExternalHD/SoS_GB/scouting/scripts')

st_layers('../data/explore-extract.gpx')

track_pt_cols <- c('track_fid', 'track_seg_point_id', 'time', 'desc', 'geometry')

tracks <- st_read('../data/explore-extract.gpx', layer = 'tracks') 
track_pts <- st_read('../data/explore-extract.gpx', layer = 'track_points') |>
  dplyr::select(dplyr::all_of(track_pt_cols))

tracks <- tracks[ as.numeric(st_length(tracks)) > 0, ] |> 
  dplyr::select(name, desc) |> 
  dplyr::mutate(across(name:desc, ~ stringr::str_replace_all(., "\\(|\\).*$", "")))

ggplot(tracks) +
  geom_sf(aes(colour = name))

rm(track_pt_cols)

# process, identify each crews FO's and base location
# bbox the above
# intersect all points with bbox, identify points to the crew with maximum match

# use lead names to identify appropriate tracks. 
# identify points using intersect of tracks

#

crews2023 <- data.frame(
  CrewName = 'El Centro',
  Lead = 'Anile',
  Field_Office = c('El Centro')
)

p <- '../../geodata/ADMU/CA_ADMU/'
admu <- st_read(paste0(p, 'BLM_CA_Administrative_Unit_Boundary_Polygons.shp')) %>% 
  mutate(Field_Office = str_remove(ADMU_NAME, ' Field Office')) %>% 
  select(Field_Office, geometry) %>% 
  st_as_sf() 

# reduce all BLM administrative units to only those with active crews
crew_areas <- dplyr::left_join(admu, crews2023, by = 'Field_Office') %>% 
  tidyr::drop_na(CrewName) 

# creating a bonding box over the field offices
total_area <- crew_areas |> 
  dplyr::group_by(CrewName) |> 
  sf::st_union() |> 
  sf::st_bbox() |> 
  sf::st_as_sfc() |> 
  sf::st_as_sf() |> 
  dplyr::rename(geometry = x)

# combine the field(s) office names with the polygon bounding box
bboxes <- dplyr::bind_cols(sf::st_drop_geometry(crew_areas), total_area) %>% 
  sf::st_as_sf() %>% 
  sf::st_transform(sf::st_crs(track_pts))

# identify points within the crews working areas 
fid_areas <- st_intersection(track_pts, bboxes) |>  
  sf::st_drop_geometry() |> 
  dplyr::group_by(track_fid) |> 
  dplyr::count(CrewName) %>% 
  dplyr::slice_max(n) 

## split out track_fid 
track_pts_fid <- dplyr::left_join(fid_areas, track_pts) |>
  sf::st_as_sf()

## subset to the potential crew associated with the track

ob <- st_intersects(tracks, track_pts_fid)
names(ob) <- tracks$name
ob <- data.frame(
  Track = gsub("\\(|\\).*$", "", names(unlist(ob))), 
  Point = unlist(ob)
  ) 

cbind(ob, track_pts_fid)

ggplot() +  
  geom_sf(data = total_area) +  
  geom_sf(data = tracks)  

rm(crew_areas)




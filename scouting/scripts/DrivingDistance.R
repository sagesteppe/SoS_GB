library(tidyverse)
library(sf)

setwd('/media/sagesteppe/ExternalHD/SoS_GB/scouting/scripts')

st_layers('../data/explore-extract.gpx')

tracks <- st_read('../data/explore-extract.gpx', layer = 'tracks') 
track_pts <- st_read('../data/explore-extract.gpx', layer = 'track_points')

tracks <- tracks[ as.numeric(st_length(tracks)) > 0, ] %>% 
  select(name, desc)

ggplot(tracks) +
  geom_sf(aes(colour = name))

rm(dat)


fid3 <- track_pts %>% 
  filter(track_fid == 3) 


ggplot() +
  geom_sf(data = fid3, size = 5) #+
#  geom_sf(data = tracks)



# Line strings need to be combined with tracking points. The tracking
# points contain the date time stamps required to determine hitches. 


# need to loop through each FID set of points 

test <- st_intersects(tracks, fid3)

which.max ( lapply(test, length) )  # identifies the track with most overlaps



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

crew_areas <- left_join(admu, crews2023, by = 'Field_Office') %>% 
  drop_na(CrewName) 

total_area <- crew_areas %>% 
  group_by(CrewName) %>% 
  st_union %>% 
  st_bbox %>% 
  st_as_sfc() %>% 
  st_as_sf() %>% 
  rename(geometry = x)

st_bbox(crew_areas)

rm(crew_areas)

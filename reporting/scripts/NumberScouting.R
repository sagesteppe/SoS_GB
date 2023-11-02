setwd('/media/sagesteppe/ExternalHD/SoS_GB/scouting/scripts')

mypeople <- c('112phoenixmcfarlane', 'lmartin49', 'paytonlott00', 'hazeyserm')
opco <- c('Operational_SOS_Collection,Standard_SOS_Collection|Standard_SOS_Collection,Operational_SOS_Collection')

library(tidyverse)
library(sf)

dat <- read.csv('../data/GreatBasin_Scouting_2023_Group-AUG-08.csv') %>% 
  filter(Creator.1 %in% mypeople) %>% 
  select(taxa, NRCS.PLANTS.Code, Future.Potential.,
         Potential.Collection.Type, Creator.1, Editor.1, 
         scoutDate, CreationDate.1, uniqueID, Scouting.ID, Latitude, Longitude
         ) %>% 
  mutate(
    Potential.Collection.Type = str_replace(Potential.Collection.Type, opco, 'Operational_SOS_Collection'),
    Potential.Collection.Type = na_if(Potential.Collection.Type, ""), 
    Potential.Collection.Type = replace_na(Potential.Collection.Type, 'Rejected')) %>% 
  st_as_sf(coords = c('Longitude', 'Latitude'), crs = 4269)

rm(opco, mypeople)
# determine by field office area rather than collector. 

fo_lkp <- data.frame(
  Crew = rep(c('NW', 'NE', 'SW', 'SE'), times = c(3, 3, 3, 2)), 
  Field_Off = c('Burns Andrews', 'Burns Three Rivers', 'Vale Malheur',
                'Wells', 'Tuscarora', 'Bristlecone', 
                'Tonopah', 'Mount Lewis', 'Stillwater',
                'Fillmore', 'Cedar City')
)

p <- '../../geodata/ADMU/GRT_BASIN/'
admu <- st_read(paste0(p, 'GB_FieldO.shp')) %>% 
  left_join(fo_lkp) %>% 
  select(Crew)

dat <- st_intersection(dat, admu)

rm(p, fo_lkp, admu)

# Determine Efforts per unit

dat <- group_by(dat, Crew) %>% 
  st_drop_geometry()

dat %>% 
  count(Potential.Collection.Type) %>% 
  pivot_wider(id_cols = Crew, names_from = 'Potential.Collection.Type',
              values_from = n) %>% 
  mutate(Total_Pops = sum(c_across(Operational_SOS_Collection:other), na.rm = T))
  

setwd('/media/sagesteppe/ExternalHD/SoS_GB/reporting/scripts')

mypeople <- c('112phoenixmcfarlane', 'lmartin49', 'paytonlott00', 'hazeyserm')
opco <- c('Operational_SOS_Collection,Standard_SOS_Collection|Standard_SOS_Collection,Operational_SOS_Collection')

library(tidyverse)
library(sf)

dat <- read.csv('../data/GreatBasin_Scouting_2023_1.csv') %>% 
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
  Crew = rep(c('NW', 'NE', 'SW', 'SE'), times = c(3, 5, 3, 2)), 
  Field_Off = c('Burns Andrews', 'Burns Three Rivers', 'Vale Malheur',
                'Wells', 'Tuscarora', 'Bristlecone', 'Basin And Range Nm', 'Caliente',
                'Tonopah', 'Mount Lewis', 'Stillwater',
                'Fillmore', 'Cedar City')
)

p <- '../../geodata/ADMU/GRT_BASIN/'
admu <- st_read(paste0(p, 'GB_FieldO.shp')) %>% 
  left_join(fo_lkp) %>% 
  select(Crew)

dat <- st_intersection(dat, admu)

plot(admu)

# rm(p, fo_lkp, admu)


## determine whether species is IDIQ. 

targets <- read.csv('../data/IDIQ_targets.csv') %>% 
  mutate(Crew2 = Crew)

d1 <- select(dat, taxa, NRCS.PLANTS.Code, Future.Potential., Potential.Collection.Type, Crew)

idiq_c <- d1 %>% 
  inner_join(., targets, by = c('NRCS.PLANTS.Code' = 'USDA.Code', 'Crew')) %>% 
  filter(Potential.Collection.Type == 'Operational_SOS_Collection')
## 135 collectible

## number of non-idiq increase species  - BOGR2, HEMU3
increase <- d1 %>% 
  filter(NRCS.PLANTS.Code %in% c('BOGR2', 'HEMU3'))
## 5 collectible

idiq_nc <- d1 %>% 
  inner_join(., targets, by = c('NRCS.PLANTS.Code' = 'USDA.Code', 'Crew')) %>% 
  filter(Potential.Collection.Type != 'Operational_SOS_Collection')
# 47 not collectible

## target species outside the target zones
idiq_not_geo_target <- d1 %>% 
  filter(
    NRCS.PLANTS.Code %in% unique(targets$USDA.Code),
    taxa != 'Heliomeris multiflora',
    Potential.Collection.Type == 'Operational_SOS_Collection') %>% 
  anti_join(., targets, by = c('NRCS.PLANTS.Code' = 'USDA.Code', 'Crew')) 
## 10 collectible

## rescouts ## 
rescout <- read.csv('../data/GreatBasin_Rescouting_2023_0.csv', na.strings = "") %>% 
  filter(str_detect(COLL_ID, 'FWS', negate = T) )

rescoutYES <- filter(rescout, str_detect(Potential.Collection.Type, 'Operational_SOS_Collection'))
## 9 collectible
rescoutNO <- filter(rescout, Future.Potential. == 'Reject')
## 6 nc

## shrubs 
shrubbies <- d1 %>% 
  filter(
    !NRCS.PLANTS.Code %in% c(unique(targets$USDA.Code), 'BOGR2', 'HEMU3'), 
    Potential.Collection.Type == 'Operational_SOS_Collection'
  )
# 89


## reed is an idiot cleomella point


mypeople <- c('112phoenixmcfarlane', 'lmartin49', 'paytonlott00', 'hazeyserm')

opco <- c('Operational_SOS_Collection,Standard_SOS_Collection|Standard_SOS_Collection,Operational_SOS_Collection')

library(sf)

dat <- read.csv('../data/GreatBasin_Scouting_2023_Group-AUG-08.csv') %>% 
  filter(Creator.1 %in% mypeople) %>% 
  select(taxa, NRCS.PLANTS.Code, Future.Potential.,
         Potential.Collection.Type, Creator.1, Editor.1, 
         scoutDate, CreationDate.1, uniqueID, Scouting.ID, Latitude, Longitude
         ) %>% 
  mutate(
    Potential.Collection.Type = str_replace(Potential.Collection.Type, opco, 'Operational_SOS_Collection'),
    Potential.Collection.Type = na_if(Potential.Collection.Type, "")) %>% 
  st_as_sf(coords = c('Longitude', 'Latitude'), crs = 4326)

ggplot(dat) + 
  geom_sf()

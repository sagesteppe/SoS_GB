setwd('/media/steppe/ExternalHD/SoS_GB/QAQC')

library(tidyverse)
library(sf)
library(janitor)

manual_cols <- c(
  'ObjectID', 'COLL_ID', 'Collection.Number', 'Seed.Collection.Reference.Number',
  'COLL_DT', 'adjusted_date', 'Did.you.collect.on.a.second.date.', 'SECOND_COLL_DT',
  'Collector.Name.s.', 'Taxa', 'NRCS.PLANTS.Code', 'Approximate.Number.of.Plants.Found',
  'Number.of.Plants.Sampled', 'Collection.Area.Sampled.in.Acres', 'Seeds.Collected.From', 
  'Average.Plant.Height.in.Feet', 'Field.Notes', 'Elevation.in.feet', 'Subunit',
  'Area.within.subunit', 'Location.Details', 'Seed.Zone', 
  'Ecological.Site.Description..Habitat.Type.and.or.National.Vegetation.Classification', 
  'Associated.Species.List', 'Aspect', 'Soil.Texture', 'SOIL_COLOR', 'Number.of.pressed.specimens', 
  'Date.voucher.taken', 'Herbaria.Receiving.the.Specimen', 'Identified.by', 'Location.of.Identification',
  'Date.Identified', 'Empirical.Seed.Zone', 'Elevation.in.meters', 'adjusted_date2'
)

crew_ids = c('NV010', 'NV040', 'NV060', 'UT040', 'UT010', 'OR020')

data <- read.csv('data/Great_Basin_X_Utah_Seed_Collection_2023_0.csv', na.strings = "") %>% 
  st_as_sf(coords = c('x', 'y'), crs = 4326)  %>% 
  select(any_of(manual_cols)) %>% 
  clean_names() %>% 
  filter(coll_id %in% crew_ids)

rm(crew_ids)

collectors <- c('Rees, L.', 'Martin, L.', 'Sermersheim, H.', 'Rytting, G.', 'Lott, P.', 
                'Aguilar-McFarlane, P.', 'Bateman, C.')
collectors <- paste0(collectors, collapse = "|")

crews <- data.frame(
  Lead = c('Hailey', 'Hailey', 'Payton', 'Phoenix', 'Phoenix', 'Logan'),
  coll_id = c('NV010', 'NV040', 'NV060', 'UT040', 'UT010', 'OR020')
)

textures <- c(
  'Clay', 'Silt', 'Sand', 'Silty_Clay', 'Silty_Clay_Loam', 'Silt_Loam', 'Sandy_Loam',
  'Loamy_Sand', 'Sandy_Clay_Loam', 'Sandy_Clay', 'Clay_Loam', 'Loam')

emp_sz <- c('PLJA', 'POSE', 'ELE5', 'KOMA', 'LECI4', 'PSSP6', 'ALAC4', 'ACHY', 'HODI', 
            'ARTRW8', 'ARTRT', 'ARTRV', 'BRCAM2', 'BRCA5', 'BOGR2', 'HEMU3', 
            'SPPA2',  'SPAM2', 'SPCR')

data <- data %>% 
  mutate(
    
    # values in look up vectors
    'collectors-FLAG' = if_else(str_detect(collector_name_s, collectors), NA, 'ERROR'),
    'soil_texture-FLAG' = if_else(soil_texture %in% textures, NA, 'ERROR'),
    
    # these all rely on regex
    'soil_color-FLAG' = if_else(str_detect(soil_color ,'[1-9]/[1-9]'), NA, 'ERROR'),
    'seed_zone-FLAG' = if_else(str_detect(seed_zone, '[0-9]{1,2} - [0-9]{1,2} / [a-z]'), NA, 'ERROR'),
    'identified_by-FLAG' = if_else(str_detect(identified_by, '[A-Z][.] .*, .*'), NA, 'ERROR'),
    'herbaria_receiving-FLAG' = if_else(
      str_detect(herbaria_receiving_the_specimen, 'Smithsonian Institution [(]US[)],'), NA, 'ERROR'), 
    
    # these all rely on na. 
    'location_of_identification-FLAG' = if_else(is.na(location_of_identification), 'ERROR', NA),
    'number_of_pressed_specimens-FLAG' = if_else(is.na(number_of_pressed_specimens), 'ERROR', NA),
    'date_identified-FLAG' = if_else(is.na(location_of_identification) != is.na(date_identified), 'ERROR', NA),
    'date_voucher_taken-FLAG' = if_else(is.na(date_voucher_taken), 'ERROR', NA),
    'elevation_in_meters-FLAG' = if_else(is.na(elevation_in_meters), 'ERROR', NA),
    
    # multiple conditions
    'empirical_seed_zone-FLAG' = if_else(nrcs_plants_code %in% emp_sz & is.na(empirical_seed_zone), 'ERROR', NA)
  ) %>% 
  select(object_id, coll_id, collection_number, seed_collection_reference_number, taxa, ends_with('FLAG')) %>% 
  arrange(coll_id, collection_number) %>% 
  st_drop_geometry() %>% 
  
  ## remove rows without any flags right here
  rowwise() %>% 
  filter( sum(is.na( across(ends_with('FLAG')))) < 11) %>% 
  ungroup() %>% 

  ## drop the flag part of name
  rename_with( ~ stringr::str_remove(., '-FLAG'), matches("-FLAG"))

rm(collectors,  emp_sz, textures, manual_cols)

data <- left_join(data, crews, by = 'coll_id')
data <- split(data, data$Lead)

all_na <- function(x) all(is.na(x))

data <- data %>% 
  map(., janitor::remove_empty, which = "cols") 

mapply(FUN = write.csv, data, file = paste0('results/', names(data), '.csv'), row.names = F)

rm(all_na, data, crews)




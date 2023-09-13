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

data <- read.csv('data/Great_Basin_X_Utah_Seed_Collection_2023.csv', na.strings = "") %>% 
  st_as_sf(coords = c('x', 'y'), crs = 4326)  %>% 
  select(any_of(manual_cols)) %>% 
  clean_names() %>% 
  filter(coll_id %in% crew_ids)

collectors <- c('L. Rees', 'L. Martin', 'Sermersheim, H.', 'Rytting, G.', 'Lott, P.', 
                'Aguilar-McFarlane, P.', 'Bateman, C.')
collectors <- paste0(collectors, collapse = "|")

crew_ids <- c('NV010', 'NV040', 'NV060', 'UT040', 'UT010', 'OR020')

textures <- c(
  'Clay', 'Silt', 'Sand', 'Silty_Clay', 'Silty_Clay_Loam', 'Silt_Loam', 'Sandy_Loam',
  'Loamy_Sand', 'Sandy_Clay_Loam', 'Sandy_Clay', 'Clay_Loam', 'Loam')

emp_sz <- c('PLJA', 'POSE', 'ELE5', 'KOMA', 'LECI4', 'PSSP6')


t <- data %>% 
  mutate(
    'soil_texture-FLAG' = if_else(soil_texture %in% textures, NA, 'ERROR'),
    'soil_color-FLAG' = if_else(str_detect(soil_color ,'[1-9]/[1-9]'), NA, 'ERROR'),
    'coll_id-FLAG' = if_else(coll_id %in% crew_ids, NA, 'ERROR'),
    'collectors-FLAG' = if_else(str_detect(collector_name_s, collectors), NA, 'ERROR'),
    'location_of_identification-FLAG' = if_else(is.na(location_of_identification), 'ERROR', NA),
    'date_identified-FLAG' = if_else(is.na(location_of_identification) != is.na(date_identified), 'ERROR', NA),
    'identified_by-FLAG' = if_else( str_detect(identified_by, '[A-Z][.] .*, .*'), NA, 'ERROR'),
    'date_voucher_taken-FLAG' = if_else(is.na(date_voucher_taken), 'ERROR', NA),
    'number_of_pressed_specimens-FLAG' = if_else(is.na(number_of_pressed_specimens), 'ERROR', NA),
    'empirical_seed_zone-FLAG' = if_else(nrcs_plants_code %in% emp_sz & is.na(empirical_seed_zone), 'EROR', NA)
  )



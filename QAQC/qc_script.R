#setwd('/media/steppe/ExternalHD/SoS_GB/QAQC')
setwd('/media/sagesteppe/ExternalHD/SoS_GB/QAQC')

library(tidyverse)
library(sf)
library(janitor)
library(tigris)

manual_cols <- c(
  'ObjectID', 'COLL_ID', 'Collection.Number', 'Seed.Collection.Reference.Number',
  'COLL_DT', 'adjusted_date', 'Did.you.collect.on.a.second.date.', 'SECOND_COLL_DT',
  'Date.range', 'Creator',
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

taxa_lkp <- read.csv('data/USDA_PLANTS.csv') %>% 
  rename(clean_taxa = Scientific.Name)

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
    'empirical_seed_zone-FLAG' = if_else(nrcs_plants_code %in% emp_sz & is.na(empirical_seed_zone), 'ERROR', NA),
    
    # dates broken on gov't end
    'adjusted_date-FLAG' = if_else(str_detect(adjusted_date, '1970'), 'ERROR', NA),
    'adjusted_date2-FLAG' = if_else(str_detect(adjusted_date2, '1970'), 'ERROR', NA),
    'date_range-FLAG' = if_else(str_detect(date_range, '-'), 'ERROR', NA)
    
    
  ) %>% 
  select(object_id, creator, coll_id, collection_number, seed_collection_reference_number, nrcs_plants_code, app_taxa = taxa, 
         ends_with('FLAG')) %>% 
  arrange(coll_id, collection_number) %>% 
  mutate(long = unlist(map(.$geometry,1)),
         lat = unlist(map(.$geometry,2))) %>% 
  st_drop_geometry() %>%

  ## remove rows without any flags right here
  rowwise() %>% 
  filter( sum(is.na( across(ends_with('FLAG')))) < sum(str_detect( colnames(.), 'FLAG'))) %>% 
  ungroup() %>% 

  ## drop the flag part of name
  rename_with( ~ stringr::str_remove(., '-FLAG'), matches("-FLAG")) %>% 
  
  ## add on the cleaned taxonomic name
  left_join(., taxa_lkp, by = c('nrcs_plants_code' = 'Symbol')) %>% 
  relocate(clean_taxa, .after = app_taxa) %>% 
  mutate(clean_taxa = if_else(clean_taxa == app_taxa, NA, clean_taxa))

rm(collectors,  emp_sz, textures, manual_cols)

data <- left_join(data, crews, by = 'coll_id') %>% 
  arrange(Lead, lat, long) %>% 
  mutate(across(lat:long, \(x) round(x, 4)))

data <- split(data, data$creator)

all_na <- function(x) all(is.na(x))

data <- data %>% 
  map(., janitor::remove_empty, which = "cols")

mapply(FUN = write.csv, data, file = paste0('results/', names(data), '-collect', '.csv'), row.names = F)

rm(all_na, data)

############### QC for Scouting ##################

long <- 'have_you_submitted_the_associated_collection_equation_form_s_and_sos_collection_form_and_are_they_in_your_outbox'
manual_cols <- c('objectid', 'coll_id', 'nrcs_plants_code', 'idiq', 'scout_date', 'elevation_ft',
                 'date', 'taxa', 'estimated_population_size', 'number_of_acres', 'future_potential', 
                 'subunit', 'area_within_subunit', 'state', 'county', 'seed_zone', 
                 'did_you_collect_a_voucher_specimen', 'voucher_number',
                 'collection_number', 'equation_form_submitted', 'x', 'y', 'creator_1')

idiq_spp <- read.csv('../scouting/data/target_taxa_2023.csv', na.strings = "") %>% 
  filter(Group %in% c('Grass', 'Forb')) %>% 
  select(USDA.Code, Universal:ELFO) %>% 
  pivot_longer(Universal:ELFO) %>% 
  drop_na() %>% 
  filter(name != 'ELFO', ! USDA.Code %in% c('', '')) %>% 
  distinct(USDA.Code) %>% 
  pull(USDA.Code)

idiq_spp <- c(idiq_spp, 'SPPA2')

scouting <- read.csv('data/GreatBasin_Scouting_2023_1.csv', na.strings = "") %>% 
  clean_names() %>% 
  rename(equation_form_submitted = all_of(long)) %>% 
  filter(!str_detect(coll_id, 'FWS|FS')) %>% 
  select(all_of(manual_cols)) %>% 
  rename(creator = creator_1) %>% 
  st_as_sf(coords = c('x', 'y'), crs = 4326, remove = F) %>% 
  st_transform(4269)

rm(long, manual_cols)

states <- tigris::states() %>% 
  select(STATE_CB = NAME) 
scouting <- st_join(scouting, states)

counties <- tigris::counties(state = scouting$STATE_CB) %>% 
  select(COUNTY_CB = NAME)
scouting <- st_join(scouting, counties)

seed_zones <- st_read('../geodata/WWETAC_STZ/GB_2013_revised_reduced.shp', quiet = T) %>% 
  select(BOWER_SZ = seed_zone) %>% 
  mutate(
    BOWER_SZ = str_replace(BOWER_SZ, '/ 6 - 12', '/ semi-arid'),
    BOWER_SZ = str_replace(BOWER_SZ, '/ 3 - 6', '/ semi-humid'),
    BOWER_SZ = str_replace(BOWER_SZ, '/ 10 - 15', '/ semi-arid'),
    BOWER_SZ = str_replace(BOWER_SZ, '/ 12 - 30', '/ arid'),
    BOWER_SZ = str_replace(BOWER_SZ, '/ 2 - 3', '/ humid'),
    BOWER_SZ = str_replace(BOWER_SZ, '/ < 2', '/ very humid'),
    BOWER_SZ = str_remove(BOWER_SZ, 'Deg. F. ')
  )

scouting <- st_join(scouting, seed_zones)

field_office <- sf::st_read('../geodata/ADMU/GRT_BASIN/GB_FieldO.shp', quiet = T) %>% 
  mutate(Field_Off = str_remove(Field_Off, '^Lakeview Distict|^Burns |^Lakeview |^Vale'))
allotment <- sf::st_read(
  '../geodata/ALLOT/BLM_Natl_Grazing_Allotment_Polygons.shp', quiet = T) %>% 
  select(ALLOT_NAME) %>% 
  st_make_valid()

scouting <- st_join(scouting, field_office)
scouting <- st_join(scouting, allotment)

rm(allotment, field_office)

# tried to run this only if NA, but tricky at end of Monday afternoon; computes on them.
usgs_elev <- function(x){
  elev <- elevatr::get_elev_point(x, src = "epqs")[,'elevation'] |>
    sf::st_drop_geometry() |>
    dplyr::mutate(elevation = round(elevation * 3.28084)) |>
    dplyr::pull(elevation)
  return(elev)
}

scouting$USGS_FT <- usgs_elev(scouting)

# rm(states, counties, seed_zones, usgs_elev)

scouting <- scouting %>% 
  mutate(
    
    # values in look up vectors
    'voucher_number-FLAG' = if_else(str_length(voucher_number) > 1, 
                                    'ERROR - This values reflects the # of duplicates', NA) ,
    # hard to imagine someone collecting more than 9 dupes
    'collection_number-FLAG' = if_else(is.na(voucher_number) != is.na(collection_number),
                                       'WARNING - Vouchers or Collection number missing!', NA),
    'state-FLAG' = if_else(state == STATE_CB, NA, paste0('ERROR: "', STATE_CB, '" is answer')),
    'county-FLAG' = if_else(county == COUNTY_CB, NA, paste0('ERROR: "', COUNTY_CB, '" is answer')),
    'voucher_collect-FLAG' = if_else(future_potential == 'Yes' & is.na(did_you_collect_a_voucher_specimen), 'Error: "No"', NA),
    'seed_zone-FLAG' = if_else(seed_zone != BOWER_SZ, paste0('ERROR: "', BOWER_SZ, '" is answer'), NA),
    
    'actual_idiq' = if_else(nrcs_plants_code %in% idiq_spp, 'Yes', 'No'),
    'idiq-FLAG' = if_else(idiq == actual_idiq, NA, paste0('ERROR: "', actual_idiq, '" is answer')),
  #  'elevation-FLAG' = if_else(is.na(elevation_ft), paste0('ERROR: "', USGS_FT, '" is answer'), NA), 
    'new_subunit.FLAG' = paste0(Field_Off, ' Field Office, ', str_to_title(ALLOT_NAME)),
    new_subunit.FLAG = str_remove(new_subunit.FLAG, ', NA$'),
    ) %>% 
  rename('new_subunit-FLAG' = new_subunit.FLAG) %>% 
  select(objectid, coll_id, nrcs_plants_code, app_taxa = taxa, creator, ends_with('FLAG')) %>% 
  arrange(coll_id, objectid) %>% 
  mutate(long = unlist(map(.$geometry,1)),
         lat = unlist(map(.$geometry,2))) %>% 
  st_drop_geometry() %>% 
  
  ## remove rows without any flags right here
  rowwise() %>% 
  filter( sum(is.na( across(ends_with('FLAG')))) < 11) %>% 
  ungroup() %>% 
  
  ## drop the flag part of name
  rename_with( ~ stringr::str_remove(., '-FLAG'), matches("-FLAG")) %>% 
  
  ## add on the cleaned taxonomic name
  left_join(., taxa_lkp, by = c('nrcs_plants_code' = 'Symbol')) %>% 
  relocate(clean_taxa, .after = app_taxa) %>% 
  mutate(clean_taxa = if_else(clean_taxa == app_taxa, NA, clean_taxa))

scouting <- left_join(scouting, crews, by = 'coll_id') %>% 
  arrange(Lead, lat, long) %>% 
  mutate(across(lat:long, \(x) round(x, 4))) %>% 
  filter(creator %in% c('hazeyserm', 'lmartin49', 'loganrees', 'paytonlott00', '112phoenixmcfarlane'))

scouting <- split(scouting, scouting$creator)

all_na <- function(x) all(is.na(x))

scouting <- scouting %>% 
  map(., janitor::remove_empty, which = "cols")  %>% 
  map(., select, -creator )

mapply(FUN = write.csv, scouting, file = paste0('results/', names(scouting), '-scout', '.csv'), row.names = F)

rm(all_na, scouting, crews, idiq_spp)



########## submitted collection form ################


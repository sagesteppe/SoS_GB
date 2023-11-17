p <- '../data/'
files <- list.files(p, recursive = T, pattern = 'csv')
year <- sub('-.*', '', Sys.Date())

library(tidyverse)
library(janitor)

## import collections data ##
coll_eq <- read.csv(paste0(p, files[grep(paste0('Collection_Equation_', year, '_0'), files)])) %>% 
  clean_names() %>% 
  select(ref_no = seed_collection_reference_number, PLS_estimate = estimated_pls_collected)

collections <- read.csv(paste0(p, files[grep(paste0('Seed_Collection_', year, '_0'), files)])) %>% 
  clean_names() %>% 
  select(ref_no = seed_collection_reference_number, nrcs_plants_code, crew = coll_id,
              no_pls_sampled = number_of_plants_sampled, frst_coll_dt = coll_dt,
              coll_area = collection_area_sampled_in_acres) 

collections <- inner_join(collections, coll_eq, by = 'ref_no') %>% 
  filter(str_detect(ref_no, 'FWS', negate = T), ref_no != "")

rm(coll_eq)

## import the scouting data ##
scouting <- read.csv(paste0(p, files[grep(paste0('_Scouting_', year, '_1'), files)])) %>% 
  clean_names() %>% 
  select(nrcs_plants_code, coll_id, future_potential, potential_collection_type, latitude, longitude)%>% 
  mutate(Scout = 'Initial')
rescout <- read.csv(paste0(p, files[grep(paste0('Rescouting_', year, '_0'), files)])) %>% 
  clean_names() %>% 
  select(coll_id, nrcs_plants_code, future_potential, potential_collection_type, latitude = y, longitude = x) %>% 
  mutate(Scout = 'Rescout')

opco <- c('Operational_SOS_Collection,Standard_SOS_Collection|Standard_SOS_Collection,Operational_SOS_Collection')

scouting <- bind_rows(scouting, rescout)  %>% 
  filter(str_detect(coll_id, 'FWS|FS', negate = T), coll_id != "") %>% 
  mutate(
    potential_collection_type = str_replace(potential_collection_type, opco, 'Operational_SOS_Collection'),
    potential_collection_type = na_if(potential_collection_type, ""), 
    potential_collection_type = replace_na(potential_collection_type, 'Rejected'))

idiq <- read.csv(paste0(p, files[grep('IDIQ_targets', files)])) %>% 
  clean_names()

rm(p, files, year, rescout, opco)

## write out collections data

# prepare some columns and rearrange column order
collections %>% 
  mutate(
    crew = case_when(
      str_detect(ref_no, 'UT') ~ 'CBG Cedar City', 
      str_detect(ref_no, 'OR') ~ 'CBG Burns', 
      str_detect(ref_no, 'NV010|NV040') ~ 'CBG Elko/Ely', 
      str_detect(ref_no, 'NV060') ~ 'CBG Tonopah'
  ),
  frst_coll_dt = mdy_hms(frst_coll_dt), 
  frst_coll_dt = paste(month(frst_coll_dt), day(frst_coll_dt), year(frst_coll_dt), sep = '/'), 
  survey_123_eq = if_else(is.na(PLS_estimate), 'No', 'Yes'), 
  Collection_type = 
    case_when(
     PLS_estimate < 30000 ~ 'Standard', 
      PLS_estimate >= 30000 & PLS_estimate < 90000 ~ 'Operational-1',
      PLS_estimate >= 90000 ~ 'Operational',
    ), 
  Collection_type = if_else()
  ) 
  
  select(crew, ref_no, nrcs_plants_code, Collection_type, frst_coll_dt, PLS_estimate,  survey_123_eq, acres)

colnames <- c('Field Crew', 'Collection ID',	'USDA plants code',	'Type of Collection',	'First Date of Collection',	'Average Estimated PLS from Viability Equation (XX,000)', 'Estimated PLS from Bend',	'Submitted Collection Equation Survey123 Form?',	'Acres (For conservation, operational SOS collections)', 'Raw weight in lbs.')

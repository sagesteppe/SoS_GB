p <- '../data/'
files <- list.files(p, recursive = T, pattern = 'csv')
year <- sub('-.*', '', Sys.Date())

library(tidyverse)
library(janitor)

## import collections data ##
coll_eq <- read.csv(paste0(p, files[grep(paste0('Collection_Equation_', year, '_0'), files)])) %>% 
  clean_names() %>% 
  select(ref_no = seed_collection_reference_number, PLS_estimate = estimated_pls_collected) %>% 
  group_by(ref_no) %>% 
  slice_min(PLS_estimate, n = 1, with_ties = F) %>% 
  ungroup()

collections <- read.csv(paste0(p, files[grep(paste0('Seed_Collection_', year, '_0'), files)])) %>% 
  clean_names() %>% 
  select(ref_no = seed_collection_reference_number, nrcs_plants_code, crew = coll_id,
              no_pls_sampled = number_of_plants_sampled, frst_coll_dt = coll_dt,
              coll_area = collection_area_sampled_in_acres, latitude = y, longitude = x) %>% 
  distinct()

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
    potential_collection_type = replace_na(potential_collection_type, 'Rejected'), 
    crew = case_when(
        str_detect(coll_id, 'UT') ~ 'CBG Cedar City', 
        str_detect(coll_id, 'OR') ~ 'CBG Burns', 
        str_detect(coll_id, 'NV010|NV040') ~ 'CBG Elko/Ely', 
        str_detect(coll_id, 'NV060') ~ 'CBG Tonopah'
      ))

idiq <- read.csv(paste0(p, files[grep('IDIQ_targets', files)])) %>% 
  clean_names() %>% 
  pull(usda_code) %>% 
  unique()

rm(p, files, year, rescout, opco)

## write out collections data

# prepare some columns and rearrange column order
collections <- collections %>% 
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
  Collection_type = if_else(nrcs_plants_code %in% c(idiq, 'MACAC3', 'ELMU3', 'ERUMD3'), 
                            Collection_type, paste0(Collection_type, ' - not IDIQ')), 
  Est_PLS_bend = '',
  coll_numeric = as.numeric(gsub('.*-', '', ref_no))) %>% 
  arrange(crew, coll_numeric) %>% 
  select(crew, ref_no, nrcs_plants_code, Collection_type, 
         frst_coll_dt, PLS_estimate, Est_PLS_bend, survey_123_eq, coll_area) 

## write out scouting and collection count data


# no pops scouted
all_scouted <- scouting %>% 
  group_by(crew) %>% 
  count(name = 'TotalScouted') %>%  # no pops scouted total
  drop_na()
  
rejected <- scouting %>% 
  filter(future_potential == 'Reject') %>% 
  group_by(crew) %>% 
  count(name = 'RejectedScouted') # no pops visited and rejected

postpone_scouted <- scouting %>% # no pops visited, need to subtract # collected from each ! 
  filter(future_potential == 'Yes', 
         potential_collection_type == 'Operational_SOS_Collection') %>% 
  group_by(crew) %>% 
  count(name = 'PostponedScouted') 

op30 <- collections %>% # no colls >30k < 90k 
  filter(str_detect(Collection_type, 'Operational-1')) %>% 
  group_by(crew) %>% 
  count(name = 'Operational30k') 
  
op90 <- collections %>% # no colls > 90k
  filter(str_detect(Collection_type, 'Operational -|Operational$')) %>% 
  group_by(crew) %>% 
  count(name = 'Operational90k') 

standard <- collections %>% # no standards
  filter(str_detect(Collection_type, 'Standard')) %>% 
  group_by(crew) %>% 
  count(name = 'Standard') 

purrr::reduce(
  list(all_scouted, rejected, postpone_scouted, op90, op30,standard), 
  dplyr::left_join, by = 'crew') %>% 
  relocate(TotalScouted, .after = last_col()) %>% 
  rowwise() %>% 
  mutate(Populations = 
           sum(c_across(Operational90k:Standard), na.rm = T), .after = PostponedScouted,
         PostponedScouted = PostponedScouted - Populations) 

rm(all_scouted, rejected, postpone_scouted, op90, op30,standard)

## write out table of collection data
out_names <- c('Field Crew', 'Collection ID',	'USDA plants code',	'Type of Collection',	
               'First Date of Collection',	'Average Estimated PLS from Viability Equation (XX,000)', 
               'Estimated PLS from Bend',	'Submitted Collection Equation Survey123 Form?',
               'Acres (For conservation, operational SOS collections)')

colnames(collections) <- out_names

rm(idiq, out_names)

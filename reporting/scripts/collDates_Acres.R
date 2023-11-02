setwd('/media/sagesteppe/ExternalHD/SoS_GB/reporting')

library(tidyverse)

crew_ids = c('NV010', 'NV040', 'NV060', 'UT040', 'UT010', 'OR020')

read.csv('data/Great_Basin_X_Utah_Seed_Collection_2023_0.csv', na.strings = "") %>% 
  janitor::clean_names() %>% 
  filter(coll_id %in% crew_ids) %>% 
  select(
    nrcs_plants_code, collection_id = seed_collection_reference_number, 
    coll_dt, #did_you_collect_on_a_second_date, second_coll_dt, did_you_collect_on_additional_days, 
  #  adjusted_date2,
    area_acres = collection_area_sampled_in_acres) %>% 
  mutate(
    coll_dt = format( as.Date(coll_dt, format = '%m/%d/%Y'), '%m/%d/%Y'),
    crew = str_extract(collection_id, '^.*-'), 
    coll = as.numeric(gsub('-', '', str_extract(collection_id, '-.*$')))) %>% 
  arrange(crew, coll) %>% 
  select(-crew, -coll) %>% 
  write.csv(., 'results/CollectionDatesAcres.csv', row.names = F)


rm(crew_ids)

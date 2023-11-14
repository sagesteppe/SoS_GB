setwd("/media/steppe/ExternalHD/SoS_GB/herbarium_collections/scripts")

processed <- read_sheet('1iOQBNeGqRJ3yhA-Sujas3xZ2Aw5rFkktUKv3N_e4o8M',
                        sheet = 'Processed - Examples') 

processed_crews <- read_sheet('1iOQBNeGqRJ3yhA-Sujas3xZ2Aw5rFkktUKv3N_e4o8M',
                        sheet = 'Processed') 

InHouse <- bind_rows(processed, processed_crews) %>% 
  select(-UNIQUEID, -Feature, -Aspect, -Slope, -Site_name, -Directions,
         -starts_with('POW'), -ends_with('issues')) %>% 
  filter(State == 'Oregon')

write.csv(InHouse, row.names = F, 'Inhouse_subset.csv')

rm(processed, processed_crews)

cname_lkp <- read.csv('symbiota_fields.csv') 

cname_lkp_no_na <- drop_na(cname_lkp)
lkp <- cname_lkp_no_na$BarnebyLives
names(lkp) <- cname_lkp_no_na$Symbiota

col_names <- cname_lkp$Symbiota[is.na(cname_lkp$BarnebyLives)]
empty_cols <- setNames(data.frame(matrix(ncol = length(col_names), 
                           nrow = nrow(InHouse))), col_names)

Symbiota_crosswalk <- InHouse %>% 
  unite(., col = "Vegetation_Associates",  Vegetation, Associates, na.rm=TRUE, sep = ", ") %>% 
  mutate(AUTHORS_TRUNC = if_else(
    is.na(Infraspecific_authority), Binomial_authority, Infraspecific_authority),
    elevation_m_copy = elevation_m) %>% 
  rename(., any_of(lkp)) %>% 
  select(all_of(names(lkp))) %>% 
  bind_cols(., empty_cols) %>% 
  relocate(cname_lkp$Symbiota) 
  

write.csv(Symbiota_crosswalk, row.names = F, 'Symbiota_crosswalk_OSC.csv')

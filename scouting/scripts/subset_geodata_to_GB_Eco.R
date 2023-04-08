# here we reduced the extent of the geodata to only field offices straddling the
# great basin ecoregion.

setwd('/media/reed/ExternalHD/SoS_GB/scouting/scripts')

library(tidyverse)
library(sf)
library(terra)

p <- '../../geodata'
f <- list.files(p, recursive = T, pattern = 'shp$')

# create simple consensus data set for all field offices in/bordering the floristic
# great basin

admin <- f[grep('ADMU', f)]

gb_fo <- bind_rows(
  
  st_read(file.path(p, admin[grep('CA', admin)]), quiet = T) %>% 
    filter(str_detect(ADMU_NAME, 'Applegate|Eagle|Bishop' )) %>% 
    select(ADMU_NAME, ADMIN_ST) %>% 
    st_transform(4269),

  st_read(file.path(p, admin[grep('NV', admin)]), quiet = T) %>% 
    filter(str_detect(ADMU_NAME, 'Vegas|Sloan|Pahrump', negate = T)) %>% 
    select(ADMU_NAME, ADMIN_ST) %>% 
    st_transform(4269),

  st_read(file.path(p, admin[grep('ID', admin)]), quiet = T) %>% 
    filter(str_detect(ADMU_NAME,
                    'Burley|Jarbidge|Bruneau|Pocatello|Owyhee|Shoshone')) %>% 
    select(ADMU_NAME, ADMIN_ST) %>% 
    st_transform(4269),

 st_read(file.path(p, admin[grep('OR', admin)]), quiet = T) %>% 
    filter(str_detect(ADMU_NAME, 'BURNS|MALHEUR|LAKEVIEW')) %>% 
    mutate(ADMIN_ST = 'OR') %>% 
    select(ADMU_NAME, ADMIN_ST) %>% 
    st_transform(4269),

  st_read(file.path(p, admin[grep('UT', admin)]), quiet = T) %>% 
    filter(str_detect(ADMU_NAME, 'Cedar|George|Fillmore|Salt')) %>% 
    select(ADMU_NAME, ADMIN_ST) %>% 
    st_transform(4269)
 
) %>% 
  mutate(ADMU_NAME = str_to_title(ADMU_NAME), 
         ADMU_NAME = str_remove(ADMU_NAME, 'Field.*$')) %>% 
  rename(Field_Off = ADMU_NAME, State = ADMIN_ST)

ifelse(!dir.exists(file.path(p, 'ADMU', 'GRT_BASIN')), 
       dir.create(file.path(p, 'ADMU', 'GRT_BASIN')), FALSE)
st_write(gb_fo, dsn = file.path(p, 'ADMU', 'GRT_BASIN', 'GB_FieldO.shp'),
         append = F)

rm(admin)

gb_fo_union <- st_union(gb_fo) %>% 
  st_cast('POLYGON') %>% 
  st_as_sf() %>% 
  st_make_valid()

# Now intersect all other spatial data products to this area. 
# note we are overwriting the original NLCS on disc

nlcs <- st_read(file.path(p, f[grep('NLCS', f)]), quiet = T)  %>% 
 # filter(ADMIN_ST %in% c('OR', 'CA', 'UT', 'ID', 'NV')) %>% 
  select(NLCS_NAME) %>% 
  st_make_valid()

nlcs <- nlcs[st_covered_by(nlcs, st_union(gb_fo)) %>% lengths > 0,]
st_write(nlcs, dsn = file.path(p, f[grep('NLCS', f)]), append = F)

rm(nlcs)

# perform a similar operation for 

fire <- st_read(file.path(p, f[grep('FIRE', f)]), quiet = T)  %>% 
  filter(ADMIN_ST %in% c('OR', 'CA', 'UT', 'ID', 'NV')) %>% 
  select(FIRE_DSCVR) 

f_vad <- st_is_valid(fire)
fire <- fire[which(f_vad == T), ]

fire <- fire[st_covered_by(fire, gb_fo_union) %>% lengths > 0,]
fire <- st_simplify(fire, dTolerance = 1000)

st_write(fire, dsn = file.path(p, f[grep('FIRE', f)]), append = F)

rm(f_vad, fire)

# import 2013 provisional seed zones

prov2013 <- st_read(file.path(p, f[grep('WWETAC', f)]), quiet = T) %>% 
  select(seed_zone) %>% 
  group_by(seed_zone) %>% 
  summarize(geometry = st_union(geometry)) %>% 
  separate(seed_zone, sep = '/', remove = F, 
    into = c('Tmin_Class',  'AHM_class')) %>% 
  st_transform(4269)

prov2013 <- st_simplify(prov2013, dTolerance = 100)
prov2013 <- st_intersection(prov2013, gb_fo_union)

st_write(prov2013, dsn = file.path(p, f[grep('WWETAC', f)]), append = F)

rm(prov2013)

## import invasive annual grass raster

ras <- list.files(p,  recursive = T, pattern = 'tif$')
inv <- rast(file.path(p, ras))

gb_fo_union_spat <- vect(gb_fo_union) %>% 
  project(crs(inv))
inv <- crop(inv, gb_fo_union_spat)

writeRaster(inv, filename = file.path(p, ras), overwrite = T)

## Reduce historic Scouting and collections to extent of GB

hist <- list.files('../data', recursive = T, pattern = 'Historic.*csv')

scouting <- read.csv(file.path('../data', hist[grep('Scouting', hist)])) %>% 
  select(x, y, OBJECTID = OBJECTID_1, ABBREV_NAM, Location_D, 
         scoutingNo, Future_Pot) %>% 
  mutate(x_new = if_else(x > 0, y, x), 
         y_new = if_else(y < 0, x, y)) %>% 
  filter(x_new < 0) %>% 
  select(-x, -y) %>% 
  st_as_sf(coords = c('x_new', 'y_new'), crs = 4269) %>% 
  mutate(across(where(is.character),
                ~ if_else(. %in% c("", "<Null>"), NA_character_, .)),
         across(where(is.character),
               ~ str_trim(.)
         )) %>% 
  filter(is.na(Future_Pot)|Future_Pot!="No")

scouting <- scouting[st_covered_by(scouting, gb_fo_union) %>% lengths > 0,]
st_write(scouting,
         file.path('../data', dirname(hist[grep('Scouting', hist)]), 
                   'Scouting.shp' ))

historic <- read.csv(file.path('../data', hist[grep('Collections', hist)])) %>% 
  select(ABBREV_NAME, COLL_DT, x, y) %>% 
  st_as_sf(coords = c('x', 'y'), crs = 4269) %>% 
  mutate(across(where(is.character), ~ replace_na(.x, '')), 
         collection_year = paste0('20', str_extract_all(COLL_DT, '[0-9]{2}$')), 
         .before = geometry) %>% 
  filter(str_detect(collection_year, 'character', negate = T), 
         str_detect(ABBREV_NAME, 'INTRODUCED', negate = T)) %>% 
  mutate(collection_year = as.numeric(collection_year))

historic <- historic[st_covered_by(historic, gb_fo_union) %>% lengths > 0,]
st_write(historic,
         file.path('../data', dirname(hist[grep('Collections', hist)]), 
                   'Collections.shp' ))

rm(historic, scouting, hist)





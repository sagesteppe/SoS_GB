library(tidyverse)
library(BarnebyLives)
library(googlesheets4)

setwd('/media/steppe/ExternalHD/SoS_GB/herbarium_collections/scripts')
dir.create('../HerbariumLabels')
dir.create('../HerbariumLabels/raw')
getwd()

p2libs <- .libPaths()[ 
  grepl(paste0(version$major, '.', sub('\\..*', "", version$minor)), 
        .libPaths())]
folds <- c('BarnebyLives/rmarkdown/templates/labels/skeleton/skeleton.Rmd')

# copy the rmarkdown template to a local location
file.copy(from = file.path(p2libs, folds), '.')

data <- read_sheet('1iOQBNeGqRJ3yhA-Sujas3xZ2Aw5rFkktUKv3N_e4o8M', 
                   sheet = 'Processed') %>% 
  mutate(UNIQUEID = paste0(Primary_Collector, Collection_number)) %>% 
  data.frame()

dir <- read.csv('BACKUP-DIRECTIONS.csv') %>% 
  rename(Directions_BL = Directions_final)

processed <- left_join(data, dir, by = c('Primary_Collector', 'Collection_number')) %>% 
  sf::st_drop_geometry()

processed <- data.frame( apply(processed, 2, as.character) )

processed_r <- read_sheet('1iOQBNeGqRJ3yhA-Sujas3xZ2Aw5rFkktUKv3N_e4o8M', 
                          sheet = 'Processed - Examples')%>% 
  select(1:10)
#  mutate(UNIQUEID = paste0(Primary_Collector, Collection_number)) %>% 
#  data.frame() %>% 
#  filter(Collection_number %in% c(2933, 2916, 2923, 2842 ))
processed_r <- data.frame(apply(processed_r, 2, as.character))
write.csv(processed_r, '../results/collections-Reed.csv', row.names = F)

processed_l <- filter(processed, Primary_Collector == 'Logan Rees')%>% 
  select(1:10)
write.csv(processed_l, '../results/collections-Logan.csv', row.names = FALSE)

processed_h <- filter(processed, Primary_Collector == 'Hailey Sermersheim')%>% 
  select(1:10)
write.csv(processed_h, '../results/collections-Hailey.csv', row.names = FALSE)

processed_p <- processed %>% 
  mutate(Collection_number = as.numeric(Collection_number)) %>% 
  filter(Primary_Collector == 'Payton Lott')%>% 
  select(1:10)
write.csv(processed_p, '../results/collections-Payton.csv', row.names = FALSE)

processed_ph <-  data %>% 
  mutate(Collection_number = as.numeric(Collection_number)) %>% 
  filter(Primary_Collector == 'Phoenix McFarlane') %>% 
  mutate(Vegetation = if_else(is.na(Vegetation), 'none listed', Vegetation)) %>% 
  select(1:10)
write.csv(processed_ph, '../results/collections-Phoenix.csv', row.names = FALSE)

# dir.create('../HerbariumLabels/logan/raw')
p <- '/media/steppe/ExternalHD/SoS_GB/herbarium_collections/HerbariumLabels/logan/raw'
purrr::walk(
  .x = processed_l$Collection_number,
  ~ rmarkdown::render(
    input = 'skeleton-logan.Rmd',
    output_file = file.path(p, glue::glue("{.x}.pdf")),
    params = list(Collection_number = {.x})
  )
)

# dir.create('../HerbariumLabels/hailey/raw')
p <- '/media/steppe/ExternalHD/SoS_GB/herbarium_collections/HerbariumLabels/hailey/raw'
purrr::walk(
  .x = processed_h$Collection_number,
  ~ rmarkdown::render(
    input = 'skeleton-hailey.Rmd',
    output_file = file.path(p, glue::glue("{.x}.pdf")),
    params = list(Collection_number = {.x})
  )
)

# dir.create('../HerbariumLabels/payton/raw')
p <- '/media/steppe/ExternalHD/SoS_GB/herbarium_collections/HerbariumLabels/payton/raw'
purrr::walk(
  .x = processed_p$Collection_number,
  ~ rmarkdown::render(
    input = 'skeleton-payton.Rmd',
    output_file = file.path(p, glue::glue("{.x}.pdf")),
    params = list(Collection_number = {.x})
  )
)

# dir.create('../HerbariumLabels/phoenix/raw')
p <- '/media/steppe/ExternalHD/SoS_GB/herbarium_collections/HerbariumLabels/phoenix/raw'
purrr::walk(
  .x = processed_ph$Collection_number,
  ~ rmarkdown::render(
    input = 'skeleton-phoenix.Rmd',
    output_file = file.path(p, glue::glue("{.x}.pdf")),
    params = list(Collection_number = {.x})
  )
)

p <- '/media/steppe/ExternalHD/SoS_GB/herbarium_collections/HerbariumLabels/reed/raw'
processed_r$Collection_number <- as.numeric(processed_r$Collection_number)
purrr::walk(
  .x = processed_r$Collection_number,
  ~ rmarkdown::render(
    input = 'skeleton-reed.Rmd',
    output_file = file.path(p, glue::glue("{.x}.pdf")),
    params = list(Collection_number = {.x}),
  )
)

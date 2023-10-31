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

processed <- read_sheet('1iOQBNeGqRJ3yhA-Sujas3xZ2Aw5rFkktUKv3N_e4o8M',
                        sheet = 'Processed') %>% 
  mutate(UNIQUEID = paste0(gsub(' ', '_', Primary_Collector), Collection_number))

data <- read_sheet('1iOQBNeGqRJ3yhA-Sujas3xZ2Aw5rFkktUKv3N_e4o8M', 
                   sheet = 'Processed - Examples') %>% 
  mutate(UNIQUEID = paste0(Primary_Collector, Collection_number)) %>% 
  data.frame()

write.csv(data, '../results/collections-Reed.csv', row.names = F)

processed_l <- filter(processed, Primary_Collector == 'Logan Rees')
write.csv(processed_l, '../results/collections-Logan.csv', row.names = FALSE)

processed_h <- filter(processed, Primary_Collector == 'Hailey Sermershein')
write.csv(processed_h, '../results/collections-Hailey.csv', row.names = FALSE)

processed_p <- filter(processed, Primary_Collector == 'Payton Lott')
write.csv(processed_p, '../results/collections-Payton.csv', row.names = FALSE)

processed_ph <- filter(processed, Primary_Collector == 'Phoenix McFarlane') %>% 
  mutate(Vegetation = if_else(is.na(Vegetation), 'none listed', Vegetation))
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


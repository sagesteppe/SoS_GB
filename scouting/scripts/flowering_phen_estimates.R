library(tidyverse)
library(sf)
library(lubridate)

setwd('/media/sagesteppe/ExternalHD/SoS_GB/scouting/scripts')


records <- st_read( '../data/BIEN/BIEN_cleaned.shp', quiet = T) %>% 
  filter(datasrc != 'VegBank', datawnr != 'iNaturalist') %>% 
  select(species = scrbb__, year, date)

# slice some weird early late records from micro-environments
records <- records %>% 
  mutate(DOY = yday(date)) %>% 
  arrange(DOY) %>% 
  slice_head(prop = 0.9) %>% 
  slice_tail(prop = 0.9)

# reduce window to when more than a few populations are flowering

breaks <- c(121, 152, 182, 213, 244)
labels <- c('May', 'June', 'July', 'Aug.', 'Sept.')

spliecies <- split(records, records$species)

phen_maker_fn <- function(x){
  
  species <- gsub('_', ' ', x$species[1])

  ggplot(x) +
    geom_density(aes(x = DOY), fill = '#FF7B9C', color = '#FFC759', alpha = 0.5) +
    theme_bw() + 
    labs(title = 'Estimated Flowering') + 
    theme(aspect.ratio = 6/16, 
          plot.title = element_text(
            hjust = 0.5, colour = "black", size = 7, face = "bold"),
          axis.text.x= element_text(
            family = "Tahoma", face = "bold", colour = "black", size=5),
          panel.background = element_rect(fill='#607196'),
          plot.background = element_rect(fill='#607196'),
          panel.border = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks.y = element_blank(),
          axis.title.y = element_blank(),
          axis.title.x = element_blank(),
          panel.grid.major.x = element_blank(),
          panel.grid.major.y = element_blank(),
          panel.grid.minor.x = element_blank(), 
          panel.grid.minor.y = element_blank()) +
    scale_x_continuous(breaks = breaks, labels=labels, limits = c(120, 245) )
  
  ggsave(filename = paste0('../results/phen/', species, '.png'), plot = last_plot(), 
         dpi = 150, width = 260, height = 150,  units = "px",  bg = 'transparent')
}

lapply(spliecies, phen_maker_fn)

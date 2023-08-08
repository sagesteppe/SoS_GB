library(tidyverse)
setwd('/media/sagesteppe/ExternalHD/SoS_GB/scouting/scripts')

dat <- read.csv('../data/CedarCity.csv') %>% 
  mutate(across(ends_with('date'), ~ str_remove(.x, '\\/2023')),
         Date = paste(sdate, '-',  edate),
         Miles = emile -smile, 
         Crew = 'Cedar City') %>% 
  select(Crew, Date, Miles)

dat <- read.csv('../data/Senior.csv') %>% 
  mutate(across(ends_with('date'), ~ str_remove(.x, '\\.2023')),
         across(ends_with('date'), ~ str_replace(.x, '\\.', '/')),
         Date = paste(sdate, '-',  edate),
         Miles = emile -smile, 
         Crew = 'Senior Botanist') %>% 
  select(Crew, Date, Miles)

dat <- read.csv('../data/Elko.csv') %>% 
  mutate(across(ends_with('date'), ~ str_remove(.x, '\\/2023')),
         Date = paste(sdate, '-',  edate),
         Miles = emile -smile, 
         Crew = 'Elko') %>% 
  select(Crew, Date, Miles)

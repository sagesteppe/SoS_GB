#' Number the weeks of the year
dayNamesFN <- function(){
  yearDAYS <- if(lubridate::leap_year(Sys.Date()) == F) {
    365
  } else {
    366
  }

  dayNms <- data.frame(
    DOY = 1:yearDAYS, 
    Weekday = weekdays( as.Date(1:yearDAYS, origin = paste(
      as.numeric(format(Sys.Date(), "%Y")) - 1, 
      '12', '31', sep = '-')) )
  )

  weekNO <- c(rep(1, times = min(which( dayNms$Weekday == 'Monday')) -1), 
     rep(2:52, each = 7))
  weekNO <- c(weekNO, rep(max(weekNO + 1), times =  yearDAYS - length(weekNO)))
  
  dayNms <- cbind(dayNms, weekNO)
  return(dayNms)
}

fromTO <- function(x, date){
  
  dayNames <- dayNamesFN()
  bookend_dates <- function(x, y){y[ which.min(abs(y$DOY - x)), 'DOY'] }
  ydoy2date <- function(x){as.Date(x, origin = paste(
    as.numeric(format(Sys.Date(), "%Y")) - 1, 
    '12', '31', sep = '-')) }
  
  x1 <- sf::st_drop_geometry(x) 
  
  travel_days <- sort(unique(x1[,date]))
  travel_bouts <- split(travel_days, cumsum(c(1, diff(travel_days) != 1)))
  long_bouts <- travel_bouts[ lapply(travel_bouts, length) > 5 ]
  
  eightSIX_s <- data.frame(From = lapply(X = long_bouts, FUN = min) )
  eightSIX_e <- data.frame(To = lapply(X = long_bouts, FUN = max))
  eightSIX <- cbind(eightSIX_s, eightSIX_e)
  colnames(eightSIX) <- c('From', 'To') 
  eightSIX <- mutate(eightSIX, 
    Trip = paste(format( min(From), '%m/%d'), '-', format(max(To), '%m/%d'))
    )
  
  short_bouts <- travel_bouts[lapply(travel_bouts, length) < 5]
  other_s <- data.frame(From = lapply(X = short_bouts, FUN = min) )
  other_e <- data.frame(To = lapply(X = short_bouts, FUN = max))
  bankers <- data.frame(cbind(do.call("c", other_s), do.call("c", other_e)))
  colnames(bankers) <- c('From', 'To')
  bankers$From <- as.Date(bankers$From)
  bankers$To <- as.Date(bankers$To)
    
  MON <- filter(dayNames, Weekday == 'Monday')
  FRI <- filter(dayNames, Weekday == 'Friday')
  
  bankers$From <- vapply(X = yday(bankers[,'From']), FUN = op, y = MON, numeric(1))
  bankers$To <- vapply(X = yday(bankers[,'To']), FUN = op, y = FRI, numeric(1))
  
  bankers <- dplyr::mutate(bankers, 
                    across(.cols = From:To, ydoy2date),
                     Trip = paste(format( From, '%m/%d'), '-', format(To, '%m/%d'))
  ) 
  
  # combine input data and date ranges
  hitches <- bind_rows(bankers, eightSIX)
  data.table::setDT(hitches); setDT(x1)
  hitches[, join_time:=From];  x1[, join_time:=date]
  data.table::setkey(hitches,  join_time); data.table::setkey(x1, join_time)
  ob <- hitches[x1, roll = Inf][,join_time:=NULL]
  
  return(ob)
}

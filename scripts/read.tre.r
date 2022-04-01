read.tre <- function(fname) {
  
  dat <- read.fwf(fname, c(6, 4, rep(c(4, 3), 10)),
                  skip = 1,
                  colClasses = c("character", rep("integer", 21)),
                  strip.white = TRUE)
  
  series <- dat[[1]]
  series.ids <- unique(series)
  decade.yr <- dat[[2]]
  nseries <- length(series.ids)
  
  series.index <- match(series, series.ids)
  min.year <- (min(decade.yr) %/% 10) * 10
  max.year <- ((max(decade.yr)+10) %/% 10) * 10
  span <- max.year - min.year + 1
  ncol.crn.mat <- nseries
  crn.mat <- matrix(NA_real_, ncol=ncol.crn.mat, nrow=span)
  colnames(crn.mat) <- c(as.character(series.ids))#, "samp.depth")
  rownames(crn.mat) <- min.year:max.year
  
  ## RWI
  x <- as.matrix(dat[seq(from=3, to=21, by=2)])
  ## All sample depths
  y <- as.matrix(dat[seq(from=4, to=22, by=2)])
  for(i in seq_len(nseries)){
    idx <- which(series.index == i)
    for(j in idx) {
      yr <- (decade.yr[j] %/% 10) * 10
      row.seq <- seq(from = yr - min.year + 1, by = 1, length.out = 10)
      crn.mat[row.seq, i] <- x[j, ]
      if(i == 1) {
        crn.mat[row.seq, ncol.crn.mat] <- y[j, ]
      }
    }
  }
  crn.mat[which(crn.mat[, -ncol.crn.mat] == 9990)] <- NA
  seq.series <- seq_len(nseries)
  crn.mat[, seq.series] <- crn.mat[, seq.series] / 1000
  crn.df <- as.data.frame(crn.mat)
  crn.df
}
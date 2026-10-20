#' Converts anything to a numeric
numextract <- function(string){
  require(stringr)
  as.numeric(str_extract(string, "\\-*\\d+\\.*\\d*"))
}

# Modify a fishresp file into long format, and include filename as a grouping identifier 
modify_respfile <- function(filename){
    read_tsv(filename, col_types=cols()) %>%
    mutate(name_file=filename) %>%
    rename(
      Ox_1=Ox.1, Ox_2=Ox.2, Ox_3=Ox.3, Ox_4=Ox.4,
      Temp_1=Temp.1, Temp_2=Temp.2, Temp_3=Temp.3, Temp_4=Temp.4
    ) %>%
    pivot_longer(
      cols = -c(Date.Time,Phase,name_file),
      names_to = c(".value","Channel"),
      names_sep = "_"
    )
  }

# iqr_outliers_toNA: Function for turning outliers to NA
# takes vector x, and turns values outside of "range" interquartile ranges (e.g 5*IQR) to NA
# bound specifies if only to use upper range, lower, or both
# returns vector x with outliers turned NA
iqr_outliers_toNA <- function(x, range=5, bound="both"){
  
  upperBound = mean(x, na.rm=T) + IQR(x,na.rm=T)*range
  lowerBound = mean(x, na.rm=T) - IQR(x,na.rm=T)*range
  
  print(glue::glue("Upper outliers:{paste(x[x > upperBound],' ',collapse='')}"))
  print(glue::glue("Lower outliers:{paste(x[x < lowerBound],' ',collapse='')}"))
  
  if(bound=="both")  x[x > upperBound | x < lowerBound] = NA
  if(bound=="lower") x[x < lowerBound] = NA
  if(bound=="upper") x[x > upperBound] = NA
  
  return(x)
}

#' funkyTranspose
#' https://stackoverflow.com/questions/6645524/what-is-the-best-way-to-transpose-a-data-frame-in-r-and-to-set-one-of-the-column
#' Credits: mortonjt and nzcoops
funkyTranspose = function(df){
  # Transpose table YOU WANT
  df_t <- t(df[,2:ncol(df)])
  # Set the column headings from the first column in the original table
  colnames(df_t) <- t(df[,1])
  return(df_t)
}


#' calcSMR
#' From: Chabot, D., Steffensen, J. F. and Farrell, A. P. (2016). The determination of standard metabolic rate in fishes: measuring smr in fishes. J Fish Biol 88, 81-121.
#' 
#' R script to compute the standard metabolic rate (SMR) using the following methods:
#' MLND: mean of the lowest normal distribution, after splitting data into several normal distributions
#' Quantiles: quantiles with 5 p-values ranging from 0.1 to 0.3 (by default),
#' Low10: the mean of the 10 lowest á¹€O2 values
#' Low10pc: the mean of the lowest 10% of the values, after the 5 lowest have been removed as outliers (Low10pc, see Herrmann & Enders, 2000).
#'
#' The user must provide a vector containing the values of á¹€O2 recorded for a fish.
#' All values of á¹€O2 provided by the user will be used, so if the user intends to remove some values because of low reliability (e.g., low R2), or because they belong to the habituation period, etc., they need to be removed first. Regardless of the name of this variable, it is known as Y within the function.
#'
#' The function returns a list containing SMR estimated by the various methods, as well as the identity of the normal distribution assigned to each á¹€O2 value (useful to plot with different symbols), and the number (1 = lowest) of the distribution assumed to represent SMR. This is almost always 1, but in some rare cases, outliers are numerous enough to form a normal distribution that is even lower than SMR. To insure that the mean of the outliers is not used to estimate SMR, a test is made to verify that the lowest distribution contains at least 10% of the á¹€O2 values, otherwise the second lowest distribution is used to estimate SMR. With extensive testing, this has always correctly identified the distribution representing SMR, as long as the maximum number of distributions that the function Mclust is allowed to fit is limited to 4 (the maximum could be as high as 9; it is limited to 4 by default with this script). Finally, the coefficient of variation of the MLND is also calculated (CVmlnd). This function will be part of a R package providing several functions facilitating the analysis of oxygen consumption data acquired with intermittent-flow respirometry.
calcSMR = function(Y, q=c(0.1,0.15,0.2,0.25,0.3), G=1:4){
  require(mclust)
	u = sort(Y)
	the.Mclust <- Mclust(Y,G=G,verbose=F)
	cl <- the.Mclust$classification
	# sometimes, the class containing SMR is not called 1
	# the following presumes that when class 1 contains > 10% of cases,
	# it contains SMR, otherwise we take class 2
	cl2 <- as.data.frame(table(cl))
	cl2$cl <- as.numeric(levels(cl2$cl))
	valid <- cl2$Freq>=0.1*length(time)
	the.cl <- min(cl2$cl[valid])
	left.distr <- Y[the.Mclust$classification==the.cl]
	mlnd = the.Mclust$parameters$mean[the.cl]
	CVmlnd = sd(left.distr)/mlnd * 100
	quant=quantile(Y, q)
	low10=mean(u[1:10])
	low10pc = mean(u[6:(5 + round(0.1*(length(u)-5)))])
	# remove 5 outliers, keep lowest 10% of the rest, average
	# Herrmann & Enders 2000
	return(list(mlnd=mlnd, quant=quant, low10=low10, low10pc=low10pc,
		      cl=cl, CVmlnd=CVmlnd))
}


f_avgTemp <- function(tb_temp,date_start,date_end,SD=F){
  temps <- 
    tb_temp %>% 
    filter(dateTime > date_start & dateTime < date_end) %>% 
    pull(temp) 
  
  if (SD==T) return(meanSD(temps))
  else return(mean(temps,na.rm=T))
}

# Functions for returning means pluss minus SD or SE (incl n)
sem <- function(x) sqrt(var(x, na.rm=T)/(sum(!is.na(x))))

meanSem <- function(x,dec_mean=2,dec_spread=2){
  require(glue)
  .mean <- round(mean(x,na.rm=T),dec_mean)
  .sem  <- round(sem(x),dec_spread)
  .n    <- length(x[!is.na(x)])
  glue("{.mean}±{.sem} (±SE, n={.n})")
} 

meanSD <- function(x,dec_mean=2,dec_spread=2){
  require(glue)
  .mean <- round(mean(x,na.rm=T),dec_mean)
  .sd   <- round(sd(x),dec_spread)
  .n    <- length(x[!is.na(x)])
  glue("{.mean}±{.sd} (±SD, n={.n})")
} 

range(c(1,2,3,4,5))

rangePrint <- function(x){
  return(glue("[{min(x)},{max(x)}]"))
}

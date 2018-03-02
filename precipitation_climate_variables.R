##---- Obtain the known datasets:----

## import nc datafile (precipitation 1900-2016)
library(xlsx)
library(ncdf4)
library(chron)
library(dplyr)

ncname <- "pre_new"
ncfname <- paste0(ncname,".nc")
dname <- "pre"

ncin <- nc_open(ncfname)
print(ncin)

lon <- ncvar_get(ncin, "lon")
nlon <- dim(lon)

lat <- ncvar_get(ncin, "lat", verbose = F)
nlat <- dim(lat)


t <- ncvar_get(ncin, "time")
tunits <- ncatt_get(ncin, "time", "units")
nt <- dim(t)

pre.array <- ncvar_get(ncin,dname)
dlname <- ncatt_get(ncin, dname, "long_name")
dunits <- ncatt_get(ncin,dname,"units")
fillvalue <- ncatt_get(ncin, dname, "_FillValue")

title <- ncatt_get(ncin, 0, "title")
institution <- ncatt_get(ncin, 0, "institution")
datasource <- ncatt_get(ncin, 0, "source")
references <- ncatt_get(ncin, 0, "references")
history <- ncatt_get(ncin, 0, "history")
Conventions <- ncatt_get(ncin, 0, "Conventions")

tustr <- strsplit(tunits$value, " ")
tdstr <- strsplit(unlist(tustr)[3], "-")
tmonth = as.integer(unlist(tdstr)[2])
tday = as.integer(unlist(tdstr)[3])
tyear = as.integer(unlist(tdstr)[1])
chron(t, origin = c(tmonth, tday, tyear))

pre.array[pre.array == fillvalue$value] <- NA

m <- 1
pre.slice <- pre.array[ , , m]

lonlat <- expand.grid(lon, lat)
pre.vec <- as.vector(pre.slice)
length(pre.vec)

pre.vec.long <- as.vector(pre.array)

## Slice the data of 30 years (1987 - 2016)

pre.mat <- matrix(pre.vec.long, nrow = nlon * nlat, ncol = nt)
eval.pre.mat <- pre.mat[,1033:1392]

## Create a dataframe with coordinates
eval.pre.mat.coordinates <- data.frame(cbind(lonlat,eval.pre.mat))
## Remove the N.A. values
pre.df.omit.na <- na.omit(eval.pre.mat.coordinates)

names(pre.df.omit.na)[1] <- "lon"
names(pre.df.omit.na)[2] <- "lat"

## Slice the data of China region

china.precipitation <- subset(pre.df.omit.na, lon > 83 & lon < 130 & lat < 50 & lat > 20)

#---- Obtain the unkown coordinates ---------

my.data <- read.xlsx("E:/Yu/Dropbox/Paper with Ami/Data/with climate data and WWTP coordinate.xlsx", 
                     sheetName = "bundled")
wwtp.coordinates <- data.frame(my.data$Longitude, my.data$Latitude)
colnames(wwtp.coordinates) <- c("lon", "lat")

#---- Interpolation by inverse distance weighting----

## For the idw function: input variables:
## knowndt; unknowndt (coordinates) 
knowndt <- china.precipitation
known.matrix <- as.matrix(knowndt)
attributes <- known.matrix[, 3:362]
coordinates(knowndt) <- ~ lon + lat


unknowndt <- wwtp.coordinates
coordinates(unknowndt) <- ~ lon + lat

idwmodel.list <- list()
pred.precipitation <- matrix(rep(0, 165 * 360), ncol = 360, byrow = TRUE)
for (i in 1: 360) {
  idwmodel.list[[i]] <- idw(attributes[, i] ~1, knowndt, unknowndt, maxdist = 0.5, idp = 2)
  pred.precipitation[,i] <- idwmodel.list[[i]]@data$var1.pred
}



## add the coordinates to the precipitation (IDW) data
wwtp.precipitation.dataset <- cbind(wwtp.coordinates, pred.precipitation)
write.xlsx(wwtp.precipitation.dataset, "E:/Yu/Dropbox/Paper with Ami/Data/monthly_mean_precipitation.xlsx")

#---------------------- Statistical calculation----------------

# Convert monthly precipitation value to annual precipitation for 30 years (1987-2016)
pre.array <- array(pred.precipitation,dim=c(nrow(pred.precipitation),12,30))
annual.pre <- apply(pre.array, c(1,3),sum)
##---- Mean annual precipitation----

mean.annual.precipitation <- as.data.frame(apply(annual.pre, 1, mean))
write.xlsx(mean.annual.precipitation, "E:/Yu/Dropbox/Paper with Ami/Data/mean_precipitation.xlsx")

##---- Minimum annual precipitation ----

min.annual.precipitation <- as.data.frame(apply(annual.pre, 1, min))
write.xlsx(min.annual.precipitation, "E:/Yu/Dropbox/Paper with Ami/Data/min_precipitation.xlsx")

##---- Maximum annual precipitation ----

max.annual.precipitation <- as.data.frame(apply(annual.pre, 1, max))
write.xlsx(max.annual.precipitation, "E:/Yu/Dropbox/Paper with Ami/Data/max_precipitation.xlsx")

##---- Inter-annual variance and CV of precipitation----

## The WWTP dataset: annual.pre (165*30)
## Calculate the variance of the inter-annual precipitation

var.inter.annual.pre <- as.data.frame(apply(annual.pre, 1, var))
write.xlsx(var.inter.annual.pre, "E:/Yu/Dropbox/Paper with Ami/Data/var_inter_precipitation.xlsx")

## Calculate the Coefficient of Variation for inter-annual
library(raster)
cv.inter.annual.pre <- as.data.frame(apply(annual.pre,1, cv))
write.xlsx(cv.inter.annual.pre, "E:/Yu/Dropbox/Paper with Ami/Data/cv_inter_precipitation.xlsx")

##-----Intra-annual variance of precipitation----

## Transpose the matrix so that when filling a new matrix, the order of the value is correct

transpose.wwtp.pre.mat <- t(pred.precipitation)

## Create a new matrix
month.matrix <- matrix(transpose.wwtp.pre.mat, ncol=12, byrow=TRUE)

## Create an array, each 3d array represents a month
month.array <- array(month.matrix, dim = c(nrow(transpose.wwtp.pre.mat) * 
                                             ncol(transpose.wwtp.pre.mat) / 12
                                           ,1,12))
## Calculate the mean monthly precipitation (30 years) for each WWTP coordinate

store.list <- list()
month.data.frame <- data.frame(rep(0,nrow(wwtp.coordinates)))
for (i in 1:12){
  store.list[[i]]<- matrix(month.array[,,i], ncol = 30, byrow = TRUE)
  month.data.frame <- cbind(month.data.frame, 
                            data.frame(c(apply(store.list[[i]],1,mean))))
  
}
colnames(month.data.frame) <- c("empty","Jan", "Feb", "Mar", "April",
                                "May", "Jun", "Jul", "Aug",
                                "Sep", "Oct", "Nov", "Dec")
month.data.frame <- month.data.frame[2:13]

## Calculate the intra-annual variance of the precipitation
pre.intra.var <- as.data.frame(apply(month.data.frame,1,var))
write.xlsx(pre.intra.var, "E:/Yu/Dropbox/Paper with Ami/Data/var_intra_precipitation.xlsx")

## Calculate the intra-annual CV of the precipitation
cv.intra.annual.pre <- as.data.frame(apply(month.data.frame,1, cv))
write.xlsx(cv.intra.annual.pre, "E:/Yu/Dropbox/Paper with Ami/Data/cv_intra_precipitation.xlsx")


##-----Intra-annual variance on an annual basis-------
## The WWTP dataset: pred.precipitation

intra.annual.wwtp.pre.var <- apply(pre.array, c(1,3), var)
write.xlsx(intra.annual.wwtp.pre.var, "E:/Yu/Dropbox/Paper with Ami/Data/annual_var_intra_precipitation.xlsx")

##-----Intra-annual CV on an annual basis----

intra.annual.wwtp.pre.cv <- apply(pre.array, c(1,3), cv)
write.xlsx(intra.annual.wwtp.pre.cv, "E:/Yu/Dropbox/Paper with Ami/Data/annual_cv_intra_precipitation.xlsx")



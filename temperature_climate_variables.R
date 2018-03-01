##---- Obtain the known datasets:----

## import nc datafile (temperature 1900-2016)
ncname <- "tmp_new"
ncfname <- paste0(ncname,".nc")
dname <- "tmp"

ncin <- nc_open(ncfname)
print(ncin)

lon <- ncvar_get(ncin, "lon")
nlon <- dim(lon)

lat <- ncvar_get(ncin, "lat", verbose = F)
nlat <- dim(lat)

t <- ncvar_get(ncin, "time")
tunits <- ncatt_get(ncin, "time", "units")
nt <- dim(t)

tmp.array <- ncvar_get(ncin,dname)
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

tmp.array[tmp.array == fillvalue$value] <- NA

m <- 1
tmp.slice <- tmp.array[ , , m]

lonlat <- expand.grid(lon, lat)
tmp.vec <- as.vector(tmp.slice)
length(tmp.vec)

tmp.vec.long <- as.vector(tmp.array)

## Slice the data of 30 years (1987 - 2016)
tmp.mat <- matrix(tmp.vec.long, nrow = nlon * nlat, ncol = nt)
eval.tmp.mat <- tmp.mat[,1033:1392]
## Create a dataframe with coordinates
eval.tmp.mat.coordinates <- data.frame(cbind(lonlat,eval.tmp.mat))
## Remove the N.A. values
tmp.df.omit.na <- na.omit(eval.tmp.mat.coordinates)

names(tmp.df.omit.na)[1] <- "lon"
names(tmp.df.omit.na)[2] <- "lat"

china.temperature <- subset(tmp.df.omit.na, lon > 83 & lon < 130 & lat < 50 & lat > 20)

## Slice the data of China region





#---- Obtain the unkown coordinates ---------

my.data <- read.xlsx("E:/Yu/Dropbox/Paper with Ami/Data/with climate data and WWTP coordinate.xlsx", 
                     sheetName = "bundled")
wwtp.coordinates <- data.frame(my.data$Longitude, my.data$Latitude)
colnames(wwtp.coordinates) <- c("lon", "lat")

#---- Interpolation by inverse distance weighting----

## For the idw function: input variables:
## knowndt; unknowndt (coordinates) 
knowndt <- china.temperature
known.matrix <- as.matrix(knowndt)
attributes <- known.matrix[, 3:362]
coordinates(knowndt) <- ~ lon + lat


unknowndt <- wwtp.coordinates
coordinates(unknowndt) <- ~ lon + lat

idwmodel.list <- list()
pred.temperature <- matrix(rep(0, 165 * 360), ncol = 360, byrow = TRUE)
for (i in 1: 360) {
  idwmodel.list[[i]] <- idw(attributes[, i] ~1, knowndt, unknowndt, maxdist = 0.5, idp = 2)
  pred.temperature[,i] <- idwmodel.list[[i]]@data$var1.pred
}



## add the coordinates to the temperature (IDW) data
wwtp.temperature.dataset <- cbind(wwtp.coordinates, pred.temperature)
write.xlsx(wwtp.temperature.dataset, "E:/Yu/Dropbox/Paper with Ami/Data/monthly_mean_temperature.xlsx")

#---------------------- Statistical calculation----------------
##---- Mean annual temperature----

mean.annual.temperature <- as.data.frame(apply(pred.temperature, 1, mean))
write.xlsx(mean.annual.temperature, "E:/Yu/Dropbox/Paper with Ami/Data/mean_temperature.xlsx")


##---- Inter-annual variance and CV of temperature----

## The WWTP dataset: pred.temperature
## Create an array from the matrix of 30 years' temperature data
wwtp.tmp.array <- array(pred.temperature, dim=c(nrow(pred.temperature),12,30))

## Calculate the mean temperature of each year for all 30 years

annual.wwtp.tmp.array <- apply(wwtp.tmp.array, c(1,3),mean)

## Calculate the variance of the inter-annual temperature

var.inter.annual.tmp <- as.data.frame(apply(annual.wwtp.tmp.array,1,var))
write.xlsx(var.inter.annual.tmp, "E:/Yu/Dropbox/Paper with Ami/Data/var_inter_temperature.xlsx")

## Calculate the Coefficient of Variation for inter-annual
library(raster)
cv.inter.annual.tmp <- as.data.frame(apply(annual.wwtp.tmp.array,1, cv))
write.xlsx(cv.inter.annual.tmp, "E:/Yu/Dropbox/Paper with Ami/Data/cv_inter_temperature.xlsx")

##-----Intra-annual variance of temperature----

## Transpose the matrix so that when filling a new matrix, the order of the value is correct

transpose.wwtp.tmp.mat <- t(pred.temperature)

## Create a new matrix
month.matrix <- matrix(transpose.wwtp.tmp.mat, ncol=12, byrow=TRUE)

## Create an array, each 3d array represents a month
month.array <- array(month.matrix, dim = c(nrow(transpose.wwtp.tmp.mat) * 
                                             ncol(transpose.wwtp.tmp.mat) / 12
                                           ,1,12))
## Calculate the mean monthly temperature (30 years) for each WWTP coordinate

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

## Calculate the intra-annual variance of the temperature
tmp.intra.var <- as.data.frame(apply(month.data.frame,1,var))
write.xlsx(tmp.intra.var, "E:/Yu/Dropbox/Paper with Ami/Data/var_intra_temperature.xlsx")

## Calculate the intra-annual CV of the temperature
cv.intra.annual.tmp <- as.data.frame(apply(month.data.frame,1, cv))
write.xlsx(cv.intra.annual.tmp, "E:/Yu/Dropbox/Paper with Ami/Data/cv_intra_temperature.xlsx")


##-----Intra-annual variance on an annual basis-------
## The WWTP dataset: pred.temperature
## Create an array from the matrix of 30 years' temperature data
wwtp.tmp.array <- array(pred.temperature, dim=c(nrow(pred.temperature),12,30))

intra.annual.wwtp.tmp.var <- apply(wwtp.tmp.array, c(1,3), var)
write.xlsx(intra.annual.wwtp.tmp.var, "E:/Yu/Dropbox/Paper with Ami/Data/annual_var_intra_temperature.xlsx")

##-----Intra-annual CV on an annual basis----

intra.annual.wwtp.tmp.cv <- apply(wwtp.tmp.array, c(1,3), cv)
write.xlsx(intra.annual.wwtp.tmp.cv, "E:/Yu/Dropbox/Paper with Ami/Data/annual_cv_intra_temperature.xlsx")



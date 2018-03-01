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

pre.mat <- matrix(pre.vec.long, nrow = nlon * nlat, ncol = nt)
eval.pre.mat <- pre.mat[,1033:1392]
eval.pre.array <- array(eval.pre.mat,dim=c(nrow(eval.pre.mat),12,30))

annual.pre.array <- apply(eval.pre.array, c(1,3),sum)

max.pre <- as.data.frame(apply(annual.pre.array,1,max))
results.pre <- cbind(lonlat, max.pre)
results.pre.omit.na <- na.omit(results.pre)
colnames(results.pre.omit.na) <- c("lon", "lat", "pre")

china.pre.omit.na <- subset(results.pre.omit.na,lon>83 & lon <  130 & lat < 50 & lat > 20)
 
 my.data <- read.xlsx("E:/Yu/Dropbox/Paper with Ami/Data/with climate data and WWTP coordinate.xlsx", 
                      sheetName = "bundled")
 location <- data.frame(my.data$Longitude, my.data$Latitude)
 colnames(location) <- c("lon", "lat")

lon.check <- as.numeric(china.pre.omit.na$lon)
lat.check <- china.pre.omit.na$lat
my.lon.check <- location$lon
my.lat.check <- location$lat

precipitation.result <- data.frame(rep(0,length(my.lon.check)))
lon.result <- data.frame(rep(0,length(my.lon.check)))
lat.result <- data.frame(rep(0,length(my.lon.check)))
for (i in seq_along(my.lon.check)) {
  
  a <- which(abs(lon.check-my.lon.check[i])== min(abs(lon.check - my.lon.check[i])))
  b <- which(abs(lat.check-my.lat.check[i])== min(abs(lat.check - my.lat.check[i])))
  k <- Reduce(intersect,list(a,b))
  lon.result[i,1] <- china.pre.omit.na[k,1]
  lat.result[i,1] <- china.pre.omit.na[k,2]
   precipitation.result[i,1] <- china.pre.omit.na[k,3]
}
compare.result <- as.data.frame(cbind(lon.result, lat.result, precipitation.result))
colnames(precipitation.result) <- "mean annual precipitation"

write.xlsx(precipitation.result, "E:/Yu/Dropbox/Paper with Ami/Data/precipitation.xlsx")




##---- obtain the known datasets:----

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
## Slice the data of China region

china.temperature <- subset(tmp.df.omit.na, lon > 83 & lon < 130 & lat < 50 & lat > 20)


#---- Obtain the unkown coordinates ---------

my.data <- read.xlsx("E:/Yu/Dropbox/Paper with Ami/Data/with climate data and WWTP coordinate.xlsx", 
                     sheetName = "bundled")
wwtp.coordinates <- data.frame(my.data$Longitude, my.data$Latitude)
colnames(wwtp.coordinates) <- c("lon", "lat")

#---- Use the original temperature data to interpolate the unknown to obtan the datasets for WWTP----

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
for (i in 1:nrow(wwtp.coordinates)){
  idwmodel.list[[i]] <- idw(attributes[, i] ~1, knowndt, unknowndt, maxdist = 0.5, idp = 2)
  pred.temperature[,i] <- idwmodel.list[[i]]@data$var1.pred
}



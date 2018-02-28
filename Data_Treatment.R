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

tmp.mat <- matrix(tmp.vec.long, nrow = nlon * nlat, ncol = nt)
eval.tmp.mat <- tmp.mat[,1033:1392]
tmp.df.mean <- data.frame(cbind(lonlat,eval.tmp.mat))
mean.tmp <- as.data.frame(apply(tmp.df.mean[3:362],1,mean))
results.tmp <- cbind(lonlat, mean.tmp )
results.tmp.omit.na <- na.omit(results.tmp)
colnames(results.tmp.omit.na) <- c("lon", "lat", "tmp")

china.tmp.omit.na <- subset(results.tmp.omit.na,lon>83 & lon <  130 & lat < 50 & lat > 20)

my.data <- read.xlsx("E:/Yu/Dropbox/Paper with Ami/Data/with climate data_yuan.xlsx", 
                     sheetName = "bundled")
location <- data.frame(my.data$Longtitude, my.data$Latitude)
colnames(location) <- c("lon", "lat")


lon.check <- as.numeric(china.tmp.omit.na$lon)
lat.check <- china.tmp.omit.na$lat
my.lon.check <- location$lon
my.lat.check <- location$lat

temperature.result <- data.frame(rep(0,length(my.lon.check)))
lon.result <- data.frame(rep(0,length(my.lon.check)))
lat.result <- data.frame(rep(0,length(my.lon.check)))
for (i in seq_along(my.lon.check)) {

  a <- which(abs(lon.check-my.lon.check[i])== min(abs(lon.check - my.lon.check[i])))
  b <- which(abs(lat.check-my.lat.check[i])== min(abs(lat.check - my.lat.check[i])))
  k <- Reduce(intersect,list(a,b))
  lon.result[i,1] <- china.tmp.omit.na[k,1]
  lat.result[i,1] <- china.tmp.omit.na[k,2]
  temperature.result[i,1] <- china.tmp.omit.na[k,3]
}
compare.result <- as.data.frame(cbind(lon.result, lat.result, temperature.result))
colnames(temperature.result) <- "mean annual temperature"

write.xlsx(temperature.result, "E:/Yu/Dropbox/Paper with Ami/Data/temperature.xlsx")




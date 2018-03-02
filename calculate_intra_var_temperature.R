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

## Calculate the monthly mean of the 30 years


transpose.eval.tmp.mat <- t(eval.tmp.mat)
month.matrix <- matrix(transpose.eval.tmp.mat, ncol=12, byrow=TRUE)
month.array <- array(month.matrix, dim = c(nrow(transpose.eval.tmp.mat) * 
                                             ncol(transpose.eval.tmp.mat) / 12
                                           ,1,12))


store.list <- list()
month.data.frame <- data.frame(rep(0,3))
for (i in 1:12){
  store.list[[i]]<- matrix(month.array[,,i], ncol = 30, byrow = TRUE)
  month.data.frame <- cbind(month.data.frame, 
                            data.frame(c(apply(store.list[[i]],1,mean))))
  
}
colnames(month.data.frame) <- c("empty","Jan", "Feb", "Mar", "April",
                                "May", "Jun", "Jul", "Aug",
                                "Sep", "Oct", "Nov", "Dec")
month.data.frame <- month.data.frame[2:13]



##------Calculate the intra-annual variance------------------
tmp.intra.var <- apply(month.data.frame,1,var)



results.tmp.intra.var<- cbind(lonlat, tmp.intra.var)
results.tmp.intra.var <- na.omit(results.tmp.intra.var)
colnames(results.tmp.intra.var) <- c("lon", "lat", "tmp.var")





eval.tmp.array <- array(eval.tmp.mat,dim=c(nrow(eval.tmp.mat),12,30))

eval.tmp.matrix <- matrix(eval.tmp.array, ncol=12, byrow = TRUE)

#annual.tmp.array <- apply(eval.tmp.array, c(1,3),mean)

monthly.mean.tmp <- apply(eval.tmp.matrix, 2, mean)

results.tmp <- cbind(lonlat, inter.annual.var.tmp)
results.tmp.omit.na <- na.omit(results.tmp)
colnames(results.tmp.omit.na) <- c("lon", "lat", "tmp")



## Calculate the variance of the inter-annual temperature

inter.annual.var.tmp <- as.data.frame(apply(annual.tmp.array,1,var))



#mean.tmp <- as.data.frame(apply(tmp.df.mean[3:362],1,mean))
results.tmp <- cbind(lonlat, inter.annual.var.tmp)
results.tmp.omit.na <- na.omit(results.tmp)
colnames(results.tmp.omit.na) <- c("lon", "lat", "tmp")

china.tmp.omit.na <- subset(results.tmp.omit.na,lon>83 & lon <  130 & lat < 50 & lat > 20)

my.data <- read.xlsx("E:/Yu/Dropbox/Paper with Ami/Data/with climate data and WWTP coordinate.xlsx", 
                     sheetName = "bundled")
location <- data.frame(my.data$Longitude, my.data$Latitude)
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




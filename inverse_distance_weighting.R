my.data <- read.xlsx("E:/Yu/Dropbox/Paper with Ami/Data/with climate data and WWTP coordinate.xlsx", 
                     sheetName = "bundled")
location <- data.frame(my.data$Longitude, my.data$Latitude)
colnames(location) <- c("lon", "lat")

library(rworldmap)
newmap <- getMap(resolution = "low")
plot(newmap, xlim = c(70,135), ylim=c(20,50), asp = 1)
points(location$lon,location$lat, col="red", cex = .6)
points(china.pre.omit.na$lon,china.pre.omit.na$lat, col = "green", cex = .6)




library(spatstat)
library(inline)
library(rgdal)
library(maptools)
library(ncf)
library(sp)

dsp <- SpatialPoints(china.pre.omit.na[,1:2], proj4string = CRS("+proj=longlat +datum=NAD83"))
dsp <- SpatialPointsDataFrame(dsp, china.pre.omit.na)
cuts <- c(0,1000,2000,3000,4000,5000,6000)
blues <- colorRampPalette(c('yellow', 'orange', 'blue', 'dark blue','black'))
pols <- list("sp.polygons", newmap, fill = "lightgray")
spplot(dsp, 'prec', cuts=cuts, col.regions=blues(6), sp.layout = pols, pch=20, cex=2)


TA <- CRS("+proj=aea +lat_1=34 +lat_2=40.5 +lat_0=0 +lon_0=-120 +x_0=0 +y_0=-4000000 +datum=NAD83 +units=m +ellps=GRS80 +towgs84=0,0,0")
dta <- spTransform(dsp, TA)


RMSE <- function(observed, predicted) {
  sqrt(mean((predicted - observed)^2, na.rm=TRUE))
}

null <- RMSE(mean(dsp$pre), dsp$prec)


coordinates(china.pre.omit.na) <- ~lon + lat
proj4string(china.pre.omit.na) <- CRS('+proj=longlat +datum=NAD83')
TA <- CRS("+proj=aea +lat_1=34 +lat_2=40.5 +lat_0=0 +lon_0=-120 +x_0=0 +y_0=-4000000 +datum=NAD83 +units=km +ellps=GRS80")
prec <- spTransform(china.pre.omit.na, TA)


## Check one single point
surroundings <- matrix(c(116.75, 40.25,
                         116.75, 39.75,
                         116.25, 39.75,
                         116.25, 40.25), ncol = 2, byrow= TRUE)
point <- c(116.44552, 39.85517)

distance <- spDistsN1(surroundings, point, longlat = FALSE)

attributes <- c(12.1419447, 13.2750002, 13.0644446, 10.9350002)

weight.square <- 1 / (distance ^ 2)

interpolation.point <- sum(attributes * weight.square) / sum(weight.square)
print(479.1147)


## Using gstat idw function
knowndt <- data.frame(surroundings, attributes)
colnames(knowndt) <- c("lon", "lat", "prec")

coordinates(knowndt) <- ~ lon + lat

unknowndt <- data.frame(116.44552, 39.85517)
colnames(unknowndt) <- c("lon", "lat")
coordinates(unknowndt) <- ~ lon + lat



idwmodel <- idw(attributes ~1, knowndt, unknowndt, maxdist = Inf, idp = 2)

predZ <- idwmodel@data$var1.pred
predZ
print(479.1147)

## For the whole dataset

knowndt <- china.pre.omit.na
attributes <- china.pre.omit.na$pre
coordinates(knowndt) <- ~ lon + lat

unknowndt <- location
coordinates(unknowndt) <- ~ lon + lat

idwmodel <- idw(attributes ~1, knowndt, unknowndt, maxdist = 0.5, idp = 2)
predZ <- idwmodel@data$var1.pred

write.xlsx(predZ, "E:/Yu/Dropbox/Paper with Ami/Data/min_precipitation_idw.xlsx")



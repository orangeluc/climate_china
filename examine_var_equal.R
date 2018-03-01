## The known dataset (with coordinates and attribues values (e.g. temperature))
known.data <- data.frame(t1 = c(1, 4, 7.8), 
                         t2 = c(5, 3.5, 8),
                         t3 = c(4, 6, 9.5))

known.data
## The unkown point

location <- data.frame(lon = 116.5, lat = 30.5)
## change the rownames of the dataframe
rownames(known.data) = c("loc1", "loc2", "loc3")

## assign coordinates to each coordinate in the known dataset
known.data$lon <- c(118, 117, 115)
known.data$lat <- c(30, 31, 32)
## calculate the mean temperature for each coordinate in the known dataset

max.known.data <- as.data.frame(apply(known.data[1:3], 1, max))
max.known.data
colnames(max.known.data) <- "max.temperature"

## calculate the variance of the temperature for each coordinate in the known dataset

var.known.data <- as.data.frame(apply(known.data[1:3], 1, var))
colnames(var.known.data) <- "variance"
var.known.data
##---------- Calculation flow 1: use the mean of the known datasets to interpolate the unkown mean----
## use inverse distance weighting method to interpolate the unkown 
knowndt <- cbind(known.data$lon, known.data$lat, max.known.data)
colnames(knowndt) <- c("lon", "lat", "max.temperature")
knowndt

attributes <- knowndt$max.temperature
coordinates(knowndt) <- ~ lon + lat


unknowndt <- location
coordinates(unknowndt) <- ~ lon + lat

idwmodel <- idw(attributes ~1, knowndt, unknowndt, maxdist = Inf, idp = 2)
predZ <- idwmodel@data$var1.pred
predZ
##-----Calculation flow 2: use the original temperature data to interpolate the unknown, then calculate----
## the mean 


knowndt.alternative <- known.data
knowndt.alternative
known.alternative.matrix <- as.matrix(known.data)
known.alternative.matrix


attributes.alternative <- known.alternative.matrix[, 1:3]
attributes.alternative
coordinates(knowndt.alternative) <- ~ lon + lat

unknowndt <- location
coordinates(unknowndt) <- ~ lon + lat

idwmodel.list <- list()
predZ.alternative <- matrix(rep(0,3), ncol = 3, byrow = TRUE)
predZ.alternative
for (i in 1:3){
  
idwmodel.list[[i]] <- idw(attributes.alternative[, i] ~1, knowndt.alternative, unknowndt, maxdist = Inf, idp = 2)
predZ.alternative[,i] <- idwmodel.list[[i]]@data$var1.pred
}

rowMeans(predZ.alternative)

## Verification result: both calculation methods are equal with regard to the calculation of the mean temperature


##-----Calculate the var using the first method (flow)-------------


knowndt.var <- cbind(known.data$lon, known.data$lat, var.known.data)
colnames(knowndt.var) <- c("lon", "lat", "var.temperature")
knowndt.var

attributes <- knowndt.var$var.temperature
coordinates(knowndt.var) <- ~ lon + lat


unknowndt <- location
coordinates(unknowndt) <- ~ lon + lat

idwmodel <- idw(attributes ~1, knowndt.var, unknowndt, maxdist = Inf, idp = 2)   
predZ.var <- idwmodel@data$var1.pred
View(predZ.var) #1

##----Calculate the var using the second method----

var(predZ.alternative)
apply(predZ.alternative, 1, max)


### Conclusions:
### It is OK to use both methods to calculate the means, but only the second method can be used 
### to calculate the variance
//
// code to get corsica deer movement rasters
//

// get corsica mask
var Corsica = ee.FeatureCollection("FAO/GAUL/2015/level1").filter("ADM1_NAME == 'Corse'").first();
//var mask = ee.Image.constant(1).clip(Corsica).mask();
//Map.addLayer(mask, {}, 'mask');

// get elevation and land cover data
var dataset = ee.Image('CGIAR/SRTM90_V4');
var elevation = dataset.select('elevation').clip(Corsica);
var slope = ee.Terrain.slope(elevation);


var dataset = ee.Image('COPERNICUS/CORINE/V20/100m/2018');
var landCover = dataset.select('landcover').clip(Corsica);

// get road data and distances
//var grip4_europe = ee.FeatureCollection("projects/sat-io/open-datasets/GRIP4/Europe");
// load data provided by Stevan
var distance = CorsicaMainRoads.distance({searchRadius: 50000, maxError: 50}).clip(Corsica);

//
//output data at standard resolution
//

//Map.addLayer(landCover, {}, 'Land Cover');
//Map.addLayer(elevation, {}, 'elevation');
//Map.addLayer(slope, {}, 'slope');
//Map.addLayer(distance, {}, 'Distance to roads');

//projection extraction    
var lcProjection = ee.Image('COPERNICUS/CORINE/V20/100m/2018').projection();        
var lcScale =lcProjection.nominalScale();
var lcCrs = lcProjection.getInfo().crs;
var lcTransform = lcProjection.getInfo().transform;
print(lcProjection);
print(lcScale);
print(lcCrs);
print(lcTransform);

//export
Export.image.toDrive({
  image: landCover,                   
  description: "Corsica_landCover",
  crs: lcCrs,
  crsTransform: lcTransform,
  region: Corsica.geometry().bounds(),
  maxPixels: 1e13
});

//export
Export.image.toDrive({
  image: elevation,                   
  description: "Corsica_elevation",
  crs: lcCrs,
  crsTransform: lcTransform,
  region: Corsica.geometry().bounds(),
  maxPixels: 1e13
});

//export
Export.image.toDrive({
  image: slope,                   
  description: "Corsica_slope",
  crs: lcCrs,
  crsTransform: lcTransform,
  region: Corsica.geometry().bounds(),
  maxPixels: 1e13
});

//export
Export.image.toDrive({
  image: distance,                   
  description: "Corsica_roadDistance",
  crs: lcCrs,
  crsTransform: lcTransform,
  region: Corsica.geometry().bounds(),
  maxPixels: 1e13
});

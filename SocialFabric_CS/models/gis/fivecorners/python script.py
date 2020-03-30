import shapefile as shp
sf = shp.Reader("new_buildings_3d.shp")
print (sf.shapeRecords()[0].shape.shapeType)
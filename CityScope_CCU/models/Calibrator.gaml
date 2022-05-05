/**
* Name: Calibrator
* Based on the internal empty template. 
* Author: gamaa
* Tags: 
*/


model Calibrator
import "constants.gaml"

global{
	file margins_shp <- file(cityscope_shape_filename);
	file blocks_shp <- file(main_shp_path+"scenario1/poligonos.shp");
	geometry shape <- envelope(margins_shp);
	float delta <- 0.01;
	float location_x <- 1006.2548;
	float location_y <- 657.1804;
	float location_z <- 1679.7139;
	
	init{
		create blocks from:blocks_shp;
		create limits from:margins_shp;
	}
	reflex write_camera{
		write ""+location_x + ","+location_y+","+location_z;		
	}
	action add_x{
		location_x <- location_x + delta;
	}
	action sub_x{
		location_x <- location_x - delta;
	}
	action add_y{
		location_y <- location_y + delta;
	}
	action sub_y{
		location_y <- location_y - delta;
	}
	action add_z{
		location_z <- location_z + delta;
	}
	action sub_z{
		location_z <- location_z - delta;
	}
}
species limits{
	aspect default{
		draw shape wireframe:true color:#red width:3.0;
	}
}
species blocks{
	aspect default{
		draw shape color:rgb(100,100,100,0.5);
	}
}
experiment gui{
	output{
		display main fullscreen:0 type:opengl  background:#black axes:false{
			//camera 'default' location: {1006.2548,657.1804,1679.7139} target: {1004.6164,667.1629,0.0};
			//camera 'default' location: {1006.2548,657.1804,1679.7139} target: {1004.6164,667.1629,0.0}; //ULTIMA
			//camera 'default' dynamic:true location: {location_x,location_y,location_z} target: {1004.6164,667.1629,0.0};
			//camera 'default' location: {1006.2548,657.1804,1679.7139} target: {1004.6164,667.1629,0.0};
			//camera 'default' location: {1014.0462,674.2913,1668.1599} target: {1014.0508,674.2625,0.0};//NEW
			//camera 'default' location: {1003.8194,682.3901,1679.7139} target: {1005.4578,672.4076,0.0};//NEW
			camera 'default' location: {1007.3931,681.2155,1668.1296} target: {1009.0202,671.3018,0.0};
			species limits aspect:default;
			species blocks aspect:default;
			
			event w action:add_y;
			event s action:sub_y;
			event a action:sub_x;
			event d action:add_x;
			event q action:sub_z;
			event e action:add_z;
		}
	}
	
}
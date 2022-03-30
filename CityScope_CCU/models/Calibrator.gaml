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
	geometry shape <- envelope(margins_shp);	
}

experiment gui{
	output{
		display main type:opengl fullscreen:0 background:#black axes:true{
			
		}
	}
}
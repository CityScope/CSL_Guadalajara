/**
* Name: Preprocess
* This model takes as input all scenario files then, as output, produces the files needed by Core.gaml
* Author: Gamaliel Palomo
* Tags: 
*/


model Preprocess
import "constants.gaml"
global {
	
	file blocks_scenarioA_shp <- file(inegi_blocks_filename);
	file blocks_scenarioB_shp <- file(zonification_ccu_filename);
	geometry shape <- envelope(blocks_scenarioA_shp);
	init{
		//1. Create blocks extracting features from shp files
		create block from:blocks_scenarioA_shp with:[nb_people::int(read("POBTOT"))]{
			create people number:nb_people with:[location::any_location_in(self),scenario::"a"];
			do die;
		}
		create block from:blocks_scenarioB_shp with:[nb_people::int(read("POBLACION_"))]{
			create people number:nb_people with:[location::any_location_in(self),scenario::"b"];
		}
	}
	
	
}
species block{
	int nb_people;
	aspect default{
		draw shape color:rgb(100,100,100,0.2) border:#gray;
	}
}
species people skills:[moving]{
	
	//Individual characteristics
	string scenario;
	int age;
	string activity_type;
	string activity_id;
	string mobility_mode;
	
	//Accessibility Indicators
	float ind_mobility_accessibility		<- 0.0;
	float ind_education_accessibility	<- 0.0;
	float ind_health_accessibility			<- 0.0;
	float ind_culture_accessibility		<- 0.0;
	
	reflex movement{
		do wander;
	}
	
	aspect default{
		draw circle(8) color:scenario="a"?#yellow:#green;
	}
}
experiment run type:gui{
	output{
		display scenario type:opengl{
			species block aspect:default;
			species people aspect:default;
		}
	}
}
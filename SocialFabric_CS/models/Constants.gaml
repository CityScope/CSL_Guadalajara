/**
* Name: Constants
* Initialization constant parameters 
* Author: gamaa
* Tags: 
*/


model Constants

global{
	
	float p_workers <- 0.5;
	float p_students <- 0.3;
	float p_foreign_workers <- 0.7;
	
	
	float agentSpeed <- 1.4;
	int agent_size <- 3;
	date starting_date <- date([2020,9,28,0,0,0]);
	
	//Environmental parameters 
	string case_study <-"fivecorners" among:["centinela", "miramar", "fivecorners"];
	
	//Import data
	file mask_file <- file("/gis/"+case_study+"/world_shape.shp"); 
	file roads_file <- file("/gis/"+case_study+"/roads.shp");
	file buildings_file <- file("/gis/"+case_study+"/buildings.shp");
	file terrain_texture <- file('/gis/fivecorners/texture.jpg') ;
	file grid_data <- file("/gis/"+case_study+"/terrain.asc");
	file block_fronts_file <- file("/gis/"+case_study+"/block_fronts.shp");
	file crimes_file <- file("/gis/"+case_study+"/crimes.shp");
	file denue_file <- file("/gis/"+case_study+"/denue.shp");
	file public_transportation_file <- file("/gis/"+case_study+"/public_transportation.shp");
	
	
}
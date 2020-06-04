/**
 *  Social Fabric Model 
 *  Author: Gamaliel Palomo, Leticia Izquierdo and Arnaud Grignard
 *  Description: Model for Social Fabric. This approach follows the idea that social interactions depend on the physical layer of an urban space. 
 * 				This means that if the infrastructure conditions (lightning, paving, etc) are good for an agent's perception, this will prefer to
 * 				walk through this space and it will feel confortable, and social interactions emerge as a result.
 */

model SocialFabric
global torus:false{

	//Environmental parameters 
	string case_study parameter: "Case study:" category: "Environment" <-"fivecorners" among:["centinela", "miramar", "fivecorners"];
	//Model parameters
	bool showInteractions parameter: "Show interactions" category:"Model" <- false;
	float agentSpeed parameter: "Agents Speed" category: "Model" <- 1.4 min:0.5 max: 10.0;
	//Visualization parameters
	bool showBuildings parameter: "Buildings" category: "Visualization" <- false;
	bool showPerception parameter: "Perception" category: "Visualization" <- false;
	string agent_mode parameter: "Indicator" category: "Visualization" <- "Layers" among:["Overall perception","Police","Natural surveillance","Lighting","Public transportation","Street condition", "Physical isolation", "Age range", "Layers"];
	bool showOverallPerception parameter: "Perception on streets" category:"Visualization" <- false;
//	float buildings_z parameter: "buildings_z" category: "Visualization" <- 0.0;
//	float buildings_y parameter: "buildings_y" category: "Visualization" <- 0.0;
//	float buildings_x parameter: "buildings_x" category: "Visualization" <- 0.0;
//	float terrain_z parameter: "terrain_z" category: "Visualization" <- -65.0 min:-500.0 max:1000.0;
//	float terrain_y parameter: "terrain_y" category: "Visualization" <- 1080.0 min:-500.0 max:1000.0;
//	float terrain_x parameter: "terrain_x" category: "Visualization" <- 790.0 min:-500.0 max:1000.0;
	//people related parameters
	int nb_people <- 800;
	int agent_size <- 3;
	list<rgb> colors <- [rgb(218, 210, 69,255),rgb(228, 167, 39,255),rgb(34, 74, 193,255),rgb(204, 43, 107,255),rgb(17, 183, 34,255),rgb(40, 244, 230,255),#red];
	
	//SUNLIGHT
	float sunlight <- 0.0 update:max([float(-0.03*(list(current_date)[3]+(list(current_date)[4]/60)-13)^2+1) with_precision 2,0.0]); //Estimated function to get the sunlight [0.0 to 1.0]
	
	date starting_date <- date([2020,4,23,6,0,0]);
	graph road_network;
	map<road, float> weight_map;
	
	//Camera related variables
	people agent_to_follow;
	point camera_position <- {world.shape.width/2,world.shape.height/2,50};
	float camera_radius <- 30.0;
	float camera_elevation <- 15.0;
	
	//Temporal
	list<float> tmp_isolation_values <- [];
	
	//Import data
	file mask_file <- file("/gis/"+case_study+"/world_shape.shp"); 
	file roads_file <- file("/gis/"+case_study+"/roads.shp");
	file buildings_file <- file("/gis/"+case_study+"/buildings.shp");
	file terrain_texture <- file('/gis/fivecorners/texture.jpg') ;
	file grid_data <- file("/gis/"+case_study+"/terrain.asc");
	file blocks_file <- file("/gis/"+case_study+"/blocks.shp");
	file block_fronts_file <- file("/gis/"+case_study+"/block_fronts.shp");
	file crimes_file <- file("/gis/"+case_study+"/crimes.shp");
	file denue_file <- file("/gis/"+case_study+"/denue.shp");
	file commerce_file <- csv_file("/gis/"+case_study+"/comercios.csv",true);
	file public_transportation_file <- file("/gis/"+case_study+"/public_transportation.shp");
	geometry shape <- envelope(mask_file);
	
	init{
		step <- 10#s;
		create block from:blocks_file with:[blockID::string(read("CVEGEO")), str_lightning::string(read("ALUMPUB_C")), str_paving::string(read("RECUCALL_C")), str_sidewalk::string(read("BANQUETA_C")), str_access::string(read("ACESOPER_C")), str_trees::string(read("ARBOLES_C"))]{
			if str_lightning = "Todas las vialidades"{ int_lightning <- 2; }
			else if str_lightning = "Alguna vialidad"{ int_lightning <- 1; }
			else{ int_lightning <- 0; }
			if str_paving = "Todas las vialidades"{ int_paving <- 2; }
			else if str_paving = "Alguna vialidad"{ int_paving <- 1; }
			else{ int_paving <- 0; }
			if str_sidewalk = "Todas las vialidades"{ int_sidewalk <- 2; }
			else if str_sidewalk = "Alguna vialidad"{ int_sidewalk <- 1; }
			else{ int_sidewalk <- 0; }
			if str_access = "Restricción en ninguna vialidad"{ int_access <- 2; }
			else if str_access = "Restricción en alguna vialidad"{ int_access <- 1; }
			else{ int_access <- 0; }
			if str_trees = "Todas las vialidades"{ int_trees <- 2; }
			else if str_trees = "Alguna vialidad"{ int_trees <- 1; }
			else{ int_trees <- 0; }
			do updateValuation;
		}
		create block_front from:block_fronts_file with:[block_frontID::string(read("CVEGEO")), road_id::int(read("CVEVIAL")),int_lightning::int(read("ALUMPUB_")), int_paving::int(read("RECUCALL_")), int_sideWalk::int(read("BANQUETA_")), int_access::int(read("ACESOPER_"))]{ do init_condition; }
		create road from:roads_file with:[road_id::int(read("CVEVIAL"))];
		create building from:buildings_file;
		//create building_obj;
		create places from:denue_file{do computePhysicalIsolation;}
		ask places{
			isolation_value <- isolation_value / max(tmp_isolation_values);
		}
		do mapValues;		
		weight_map <- road as_map(each::each.shape.perimeter);
		road_network <- as_edge_graph(road);
		create people number:nb_people;
		create police_patrol number:5;
		ask people{do init_social_circle;}
		agent_to_follow <- one_of(people);
		create crime from:crimes_file with:[type::string(read("DEL"))];
		create commerce from: commerce_file with:[
			commerce_name::string(get("name")),
			description::string(get("description")),
			longitude::float(get("longitude")),
			latitude::float(get("latitude")),
			altitude::float(get("altitude"))
		]{
			location <- {latitude,longitude};
		}
		create public_transportation from:public_transportation_file;
	}
	action mapValues{
	//Information about roads condition is in block_fronts file, copy it to road species.
		loop bf_element over:block_front{
			int st_id <- bf_element.road_id;
			list<road> auxroads <- road where (each.road_id = st_id);
			if(auxroads!=[]){
				ask auxroads{
					float_lightning <- bf_element.int_lightning/2;
					float_paving <- bf_element.int_paving/2;
					float_sideWalk <- bf_element.int_sideWalk/2;
					float_access <- bf_element.int_access/2;
					do init_condition;
				}
			}
		}
	}
	reflex update_camera_position{
		float agent_heading <- agent_to_follow.heading;
		camera_position <- {camera_radius*cos(agent_heading)+agent_to_follow.location.x,camera_radius*sin(agent_heading)+agent_to_follow.location.y,camera_elevation};
	}
}

species road{
	int road_id;
	float valuation;
	float weight;
	float float_lightning;
	float float_paving;
	float float_sideWalk;
	float float_access;
	action init_condition{
		valuation <- (float_lightning+float_paving+float_sideWalk+float_access)/4;
		weight <- valuation; //Normalization of valuation 0 to 1 according to the model
		weight <- 100*(1 - weight); //In weighted networks, a path is shorter than other if it has smaller value. 0 <- best road, 1 <- worst road
	}
	aspect default{draw shape color: rgb(255-(127*valuation),0+(127*valuation),50,255);}
	//aspect default{draw shape color: rgb(255*weight,50,50,100);}
	aspect white{draw shape color: #white;}
}

species public_transportation{
	int id;
	string route_name;
	aspect default{
		draw shape color:rgb (255, 0, 128,255) width:5.0;
	}
}

species block{
	string blockID;
	string str_lightning;
	string str_sidewalk;
	string str_paving;
	string str_access;
	string str_trees;
	int int_lightning;
	int int_sidewalk;
	int int_paving;
	int int_access;
	int int_trees;
	float valuation;
	float heigth;
	init{
		heigth <- float(rnd(10));
	}
	action updateValuation{
		int sum <- int_lightning+int_sidewalk+int_paving+(1-int_access)+int_trees;
		valuation <- sum/5;
	}
	aspect gray_scale{draw shape color: rgb(valuation*180,valuation*180,valuation*180,180);}
}

species block_front{
	int road_id;
	string block_frontID;
	int int_lightning;
	int int_paving;
	int int_sideWalk;
	int int_access;
	float valuation;
	string road_name;
	action init_condition{
		if int_lightning = 1 { int_lightning <-2; }
			else if int_lightning = 2 { int_lightning <- 0; }
			else{ int_lightning <- 1; }
			if int_paving = 1 or int_paving = 2 { int_paving <- 2; }
			else if int_paving = 2 { int_paving <- 0; }
			else{ int_paving <- 1; }
			if int_sideWalk = 1 {int_sideWalk <- 2;}
			else if int_sideWalk = 2 {int_sideWalk <- 0;}
			else {int_sideWalk <- 1;}
			if int_access = 2 {int_access <- 2;}
			else {int_access <- 0;}
			do init_Valuation;
	}
	action init_Valuation{
		valuation <- 0.0;
		int sum <- int_lightning + int_paving + int_sideWalk + int_access;
		valuation <- sum / 8;  
	}
	aspect default{
		if showOverallPerception{
			draw shape color: rgb(255-(255*valuation),0+(255*valuation),0,255);
		}
		else {draw shape color: rgb (83, 83, 83,125);}
	}
}

species places{
	string place_name;
	string activity;
	float isolation_value;
	action computePhysicalIsolation{//The objective of this function is to calculate, at the begining of the simulation, a value of isolation for every place.
		places closest_place <- places closest_to(self);
		float distance_to_closest <- self distance_to closest_place;
		isolation_value <- distance_to_closest;
		add isolation_value to: tmp_isolation_values;
	}
	aspect default{ 
		draw geometry:square(50#m)  color:rgb (86, 140, 158,255) border:#indigo;
	}
}

species commerce{
	string commerce_name;
	string description;
	float latitude;
	float altitude;
	float longitude;
	aspect default{
		draw circle(10) color:rgb (134, 217, 11,255) empty:true depth:10.0;
	}
}

species building {
	//show some important buildings
	//geometry shape <- obj_file("/gis/"+case_study+"/buildings_obj.obj") as geometry;
	aspect flat{
		if showBuildings{draw shape color:rgb (145,145,145) texture:["/img/roof_top.jpg",("/img/texture"+int(rnd(9)+1)+".jpg")];}
	}
	aspect terrain{
		//draw shape at:{buildings_x,buildings_y,buildings_z} color:rgb (79, 176, 98,255);
		float loc_x <- location.x;
		float loc_y <- location.y;
		cell tmp_cell <- cell({loc_x,loc_y});
		float loc_z <- tmp_cell.grid_value;
		draw shape color:rgb (61, 148, 85,255) texture:["/img/roof_top.jpg",("/img/texture"+int(rnd(9)+1)+".jpg")] at:{loc_x,loc_y,loc_z} depth:rnd(3)+5#m;
	}
}

species people skills:[moving] parallel:true{
	
	//Importar datos de csv para rutinas, relaciones, perfil.
	//Perception related variables

	map<string,float> indicators_values;  	//indicator->value
	map<string,float> indicators_weights; 	//indicator->weight
	list indicators <- ["police_patrols","other_people","lighting_uniformity_radius","safe_mobility","pavement_condition","physical_isolation"];
	float safety_perception <- 0.0;			//Value of perception of security
	float vision_radius <- 30.0#m;			//Size of the circle of co-presence
	list<people> social_circle <- [];		//List of other people this aget relates with
	list<people> family <- [];

	//Routine related variables
	map<string,point> locations;				//A map containing the locations and their coordinates
	point current_objective;					//The current objective in the routine
	path current_route;							//The current route to follow, this varies according to the current objective
	string current_state <- "stay";				//Wheter this agent is onTheWay or stay
	
	//personal variables
	point location_3d <- {location.x,location.y,location.z};
	string occupation;						//The role of this agent
	int age <- rnd(80);						//Age of this agent
	int age_group;
	rgb agent_color;
	rgb family_color;
	list<string> preferences; 				//EXPERIMENTAL FOR NETWORK ANALYSIS: People interact and make relationships with people according to an affinity value, which is obtained from preferences. (Read Yuan et al)
	
	//Visualization variables
	bool show_social_graph <- false;
	bool show_family <- false;
	float max_elevation <- 1000.0;
	float current_max <- 0.0;
	
	user_command "Show Social Graph"{
		show_social_graph <- true;
	}
	user_command "Show Family"{
		do show_family;
		ask social_circle{
			show_family <- myself.show_family;
		}
	}
	
	init{
		indicators_weights <- [													//How important is each indicator for this agent. All of them sum 1.
			"police_patrols"::0.1,//C1
			"other_people"::0.2,//C1
			"lighting_uniformity_radius"::0.15,//C2
			"safe_mobility"::0.1,//C3			
			"pavement_condition"::0.15,//C4
			"physical_isolation"::0.3];//C5
		
		occupation <- one_of("inactive","student","worker");							//Role of this agent
		add "home"::building[rnd(length(building)-1)].location to: locations;			//Home location
		add "school"::places[rnd(length(places)-1)].location to: locations;			//School location
		add "work"::places[rnd(length(places)-1)].location to: locations;			//Work location
		add "leisure"::places[rnd(length(places)-1)].location to: locations;		//Leisure location
		location <- locations["home"];													//Initial location
		//Defining the age group depending
		if age<=5{age_group<-0;}
		else if age>5 and age<=14{age_group<-1;}
		else if age>14 and age<=19{age_group<-2;}
		else if age>19 and age<=34{age_group<-3;}
		else if age>34 and age<=54{age_group<-4;}
		else if age>54{age_group<-5;}
	}
	action init_social_circle{
		list<people> auxList <- people at_distance(vision_radius);
		add all:auxList to:social_circle;										//Init of social circle as all people at "vision_radius" distance
	}
	action show_family{
		if show_family{show_family <- false;}
		else{show_family <- true;}
	}
	action update_perception_value{
		if sunlight>0 and vision_radius<60#m{
			vision_radius <- vision_radius + vision_radius*sunlight;
		}
		float sum<-0.0;
		loop auxKey over:indicators_values.keys{
			sum <- sum + indicators_values[auxKey]*indicators_weights[auxKey];
		}
		safety_perception <- sum;
	}
	reflex update_indicators_values when:every(90#second) and flip(0.1){
		//In this function, all environmental indicators are perceived by the agent. Only indicators_values are updated here.
		//The importance of these indicators_values depends on every agent profile (women, men, child, etc.).
		//Considerar la introducción de crimenes a lo largo del día considerando como entrada datos georreferenciados. Además estos tienen que clasificarse porque 
		//dependiendo del tipo de caracteristicas pueden cometerse distintos tipos de crimen.
		
		//C1__FORMAL SURVEILLANCE
		//police_patrols_range
		list<police_patrol> auxPolice <- police_patrol at_distance(vision_radius);
		put auxPolice!=[]? 1.0:0.0 at:"police_patrols" in:indicators_values;
		//active_pedestrians (interaction)
			//1.número de personas que interactúan - Radio 1
				// M+W+N+N    +  M
				// W+N+N    + car   (kidnapping)
				// relación de los agentes niños con agentes adultos por ciertas horas del día
			//2.si se conocen o no - Radio 2   (definir en la descripción de los agentes)
			//3.Si no se conocen: W-M   Si se conocen: W-W
		list<people> auxPeople <- people at_distance(vision_radius);
		put auxPeople!=[]?1.0:0.0 at:"other_people" in:indicators_values;
		do update_perception_value;
		
		//C2__ARTIFICIAL LIGHTING
		//lighting_uniformity_radius
			//TO DO: differenciate between daytime and nighttime
		list<road> auxLighting <- road at_distance(vision_radius);
		put auxLighting!=[]? auxLighting[0].float_lightning:0.0 at:"lighting_uniformity_radius" in:indicators_values;
		
		//C3__SAFE MOBILITY
		list<point> auxMobility <- geometry(public_transportation) closest_points_with(self);
		float aux_distance <- auxMobility[0] distance_to auxMobility[1];
		float distance <- min(200,aux_distance);
		distance <- distance / 200;
		put 1-distance at:"public_transportation" in:indicators_values;
		
		//C4__MAINTENANCE
		//pavement_condition
		list<road> auxPavement <- road at_distance(vision_radius);
		put auxPavement!=[]? auxPavement[0].float_paving:0.0 at:"pavement_condition" in:indicators_values;
		
		//C5__PHYSICAL ISOLATION 
		list<places> auxPlaces <- places at_distance(vision_radius);
		put auxPlaces!=[]?auxPlaces[0].isolation_value:1.0 at:"physical_isolation" in:indicators_values;
		
	}
	reflex build_routine when:current_state="stay"{
		if age_group=0{}
		else if age_group=1{
			agent_color <- rgb (228, 167, 39,255);
			if current_date.hour>=19{current_objective <- locations["home"];current_state <- "onTheWay";}
			else if current_date.hour>=14{current_objective <- locations["leisure"];current_state <- "onTheWay";}
			else if current_date.hour>=9{current_objective <- locations["school"];current_state <- "onTheWay";}
		}
		else if age_group=2{
			if current_date.hour>20{current_objective <- locations["home"]; current_state <- "onTheWay";}
			if current_date.hour>13{current_objective <- locations["work"]; current_state <- "onTheWay";}
			if current_date.hour>7{current_objective <- locations["school"]; current_state <- "onTheWay";}
		}
		else if age_group=3{
			if current_date.hour>19{current_objective <- locations["home"]; current_state <- "onTheWay";}
			if current_date.hour>6{current_objective <- locations["work"]; current_state <- "onTheWay";}
		}
		else if age_group=4{
			if current_date.hour>19{current_objective <- locations["home"]; current_state <- "onTheWay";}
			if current_date.hour>6{current_objective <- locations["work"]; current_state <- "onTheWay";}
		}
		else if age_group=5{
			if current_date.hour>13{current_objective <- locations["home"]; current_state <- "onTheWay";}
			if current_date.hour>8{current_objective <- locations["work"]; current_state <- "onTheWay";}
		}
	}
	reflex execute_routine when:current_state="onTheWay" and mod(cycle,2)=0{
		if location = {current_objective.x,current_objective.y}{current_state <- "stay";}
		do goto target:current_objective on:road_network move_weights:weight_map;
	}
	action update_elevation{
		cell tmp_cell <- cell(location);
		location_3d <- {location.x,location.y,tmp_cell.grid_value}; 
	}
	action update_location{
		location <- {location.x,location.y,200};
	}
	reflex update_flat_elevation when:current_max < max_elevation and agent_mode = "layers"{
		current_max <- current_max + 10.0;
	}
	aspect flat{
		rgb current_color;
		//"Overall perception","Police","Lighting","Street condition","Natural surveillance"
		//list indicators <- ["police_patrols","lighting_uniformity_radius","pavement_condition","other_people"];
		if agent_mode = "Layers"{
			int nb_indicators <- 6;
			float color_value;
			float elevation_rate <- 150.0; //meters by second of elevation
			//This is for the formal surveillance layer
			color_value <- indicators_values["police_patrols"];
			draw circle(agent_size) color: rgb(255-(255*color_value),0+(255*color_value),0,255) at:{location.x,location.y,current_max/nb_indicators};
			color_value <- indicators_values["other_people"];
			draw circle(agent_size) color: rgb(255-(255*color_value),0+(255*color_value),0,255) at:{location.x,location.y,(current_max/nb_indicators)*2};
			color_value <- indicators_values["lighting_uniformity_radius"];
			draw circle(agent_size) color: rgb(255-(255*color_value),0+(255*color_value),0,255) at:{location.x,location.y,(current_max/nb_indicators)*3};
			color_value <- indicators_values["public_transportation"];
			draw circle(agent_size) color: rgb(255-(255*color_value),0+(255*color_value),0,255) at:{location.x,location.y,(current_max/nb_indicators)*4};
			color_value <- indicators_values["pavement_condition"];
			draw circle(agent_size) color: rgb(255-(255*color_value),0+(255*color_value),0,255) at:{location.x,location.y,(current_max/nb_indicators)*5};
			color_value <- indicators_values["physical_isolation"];
			draw circle(agent_size) color: rgb(255-(255*color_value),0+(255*color_value),0,255) at:{location.x,location.y,current_max};
		}
		else{
			if agent_mode = "Overall perception" {current_color <- rgb(255-(255*safety_perception),255*safety_perception,0);}
			else if agent_mode = "Police" {
				float color_value <- indicators_values["police_patrols"];
				current_color <- rgb(255-(255*color_value),255*color_value,0);
			}
			else if agent_mode = "Natural surveillance" {
				float color_value <- indicators_values["other_people"];
				current_color <- rgb(255-(255*color_value),255*color_value,0);
			}
			else if agent_mode = "Lighting" {
				float color_value <- indicators_values["lighting_uniformity_radius"];
				current_color <- rgb(255-(255*color_value),255*color_value,0);
			}
			else if agent_mode = "Public transportation" {
				float color_value <- indicators_values["public_transportation"];
				current_color <- rgb(255-(255*color_value),255*color_value,0);
			}
			else if agent_mode = "Street condition" {
				float color_value <- indicators_values["pavement_condition"];
				current_color <- rgb(255-(255*color_value),255*color_value,0);
			}
			else if agent_mode = "Physical isolation" {
				float color_value <- indicators_values["physical_isolation"];
				current_color <- rgb(255*color_value,255-(255*color_value),0);
			}
			else if agent_mode = "Age range"{current_color <- colors[age_group];}
			draw circle(agent_size) color: current_color at:location;
		}
		
		if showPerception{draw circle(vision_radius) color:rgb(255-(255*safety_perception),255*safety_perception,0) at:location empty:true;}
		if showInteractions{
			loop connection over:social_circle{
				draw curve(location, connection.location,1.0, 200, 90) color:rgb (79, 194, 210,100);
			}
		}
		if show_social_graph{
			loop connection over:social_circle{
				draw curve(location, connection.location,1.0, 200, 90) color:rgb (255, 128, 0,255) width:3.0;
			}
		}
		if show_family{
			loop connection over:social_circle{
				draw curve(location, connection.location,1.0, 200, 90) color:rgb (79, 194, 210,100) width:3.0;
			}
		}
	}
	aspect terrain{
		rgb current_color;
		//"Overall perception","Police","Lighting","Street condition","Natural surveillance"
		//list indicators <- ["police_patrols","lighting_uniformity_radius","pavement_condition","other_people"];
		if agent_mode = "Overall perception" {current_color <- rgb(255-(255*safety_perception),255*safety_perception,0);}
		else if agent_mode = "Police" {
			float color_value <- indicators_values["police_patrols"];
			current_color <- rgb(255-(255*color_value),255*color_value,0);
		}
		else if agent_mode = "Lighting" {
			float color_value <- indicators_values["lighting_uniformity_radius"];
			current_color <- rgb(255-(255*color_value),255*color_value,0);
		}
		else if agent_mode = "Street condition" {
			float color_value <- indicators_values["pavement_condition"];
			current_color <- rgb(255-(255*color_value),255*color_value,0);
		}
		else if agent_mode = "Natural surveillance" {
			float color_value <- indicators_values["other_people"];
			current_color <- rgb(255-(255*color_value),255*color_value,0);
		}
		else if agent_mode = "Age range"{current_color <- colors[age_group];}
		draw sphere(agent_size) color: current_color at:location_3d;
		if(showPerception){draw circle(vision_radius) color:rgb(255-(255*safety_perception),255*safety_perception,100) at:location_3d empty:true;}
		if showInteractions{
			loop connection over:social_circle{
				draw curve(location_3d, connection.location_3d,1.0, 200, 90) color:rgb (79, 194, 210,100) width:3.0;
			}
		}
		if show_social_graph{
			loop connection over:social_circle{
				draw curve(location_3d, connection.location_3d,1.0, 200, 90) color:rgb (255, 128, 0,255) width:3.0;
			}
		}
		if show_family{
			loop connection over:social_circle{
				draw curve(location_3d, connection.location_3d,1.0, 200, 90) color:rgb (79, 194, 210,100) width:3.0;
			}
		}
	}
}

species police_patrol skills:[moving]{ //for indicator "police_patrols_range"
	point target;
	image_file car;
	path route;
	init{
		location <- building[rnd(length(building)-1)].location;
		target <- building[rnd(length(building)-1)].location;
	}
	reflex move{
		if location = target{target <- building[rnd(length(building)-1)].location;}
		do goto target:target on:road_network move_weights:weight_map;
	}
	aspect flat{
		draw rectangle(10,3) color:#red;
	}
	aspect flat_obj{
		draw obj_file("/img/police.obj",90::{-1,0,0}) size: 20 at: {location.x,location.y,10} rotate: heading color: #red;
	}
	aspect terrain{
		float loc_x <- location.x;
		float loc_y <- location.y;
		cell tmp_cell <- cell({loc_x,loc_y});
		float loc_z <- tmp_cell.grid_value;
		point location_3d <- {loc_x,loc_y,loc_z+5};
		draw obj_file("/img/police.obj",90::{-1,0,0}) size: 10 at: location_3d rotate: heading color: #red;
	}
}
	
grid cell file:grid_data{
	rgb color;
	init{
		grid_value <- grid_value-1480;
		color <- rgb(255-grid_value,255-grid_value,255-grid_value);
	}
}

species crime{
	string type;
	aspect default{
		draw circle(30) color:#red empty:true width:5.0;
	}
}

experiment Flat_2D type:gui {
	output{
		layout #split;
		//display "Main" type: opengl background:rgb(sunlight/5*255,sunlight/5*255,sunlight/5*255) draw_env:false{
		//display "Main" type: opengl draw_env:false camera_pos: {world.shape.width*cos(cycle),world.shape.height*sin(cycle),1328.5421} camera_look_pos: {world.shape.width/2,world.shape.height/2,500} camera_up_vector: {0,1,0} {
		display "Main" type: opengl draw_env:false{
			
			graphics "world" refresh:false{
				//draw rectangle(world.shape.width,world.shape.height) texture:["/gis/"+case_study+"/texture.jpg"];
			}
			//species road aspect:default;
			//species crime aspect:default refresh:false;
			//species commerce aspect:default refresh:false;
			//species places aspect:default refresh:false;
			//species public_transportation aspect:default refresh:false;
			species block_front aspect:default refresh:false;
			species police_patrol aspect:flat_obj;
			species building aspect:flat refresh:false;
			species people aspect:flat;
			overlay position: { 40#px, 30#px } size: { 480,1200 } background: # black transparency: 0.5 border: #black {
				string minutes;
				if current_date.minute < 10{minutes <- "0"+current_date.minute; }
				else {minutes <- string(current_date.minute);}
				draw ".:-0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ()[],>=" at: {0#px,0#px} color:rgb(0,0,0,0) font:font("Arial",20,#plain);
				draw ":0123456789" at:{ 0#px, 0#px} color:rgb(0,0,0,0) font:font("Arial",55,#bold);
				draw "People: " +  length(people) at: { 40#px, 60#px } color: #white font:font("Arial",20,#plain);
				draw ""+current_date.hour+":"+minutes at:{ 40#px, 800#px} color:#white font:font("Arial",55,#bold);
				draw "Sunlight: "+ sunlight at:{ 40#px, 90#px} color:#white font:font("Arial",20,#plain);
				draw "Age Range" color:#white at:{40#px,130#px} font:font("Arial",25,#bold);
				draw circle(10) color:colors[1] at:{40#px, 160#px};
				draw "(5,14]" color:#white at:{50#px,165#px} font:font("Arial",20,#plain);
				draw circle(10) color:colors[2] at:{40#px, 190#px};
				draw "(14,19]" color:#white at:{50#px,195#px} font:font("Arial",20,#plain);
				draw circle(10) color:colors[3] at:{40#px, 220#px};
				draw "(19,34]" color:#white at:{50#px,225#px} font:font("Arial",20,#plain);
				draw circle(10) color:colors[4] at:{40#px, 250#px};
				draw "(34,54]" color:#white at:{50#px,255#px} font:font("Arial",20,#plain);
				draw circle(10) color:colors[5] at:{40#px, 280#px};
				draw ">54" color:#white at:{50#px,285#px} font:font("Arial",20,#plain);
				draw  "Social Circle" color:#white at:{40#px,320#px} font:font("Arial",23,#bold);
				draw line({40#px,345#px},{65#px,345#px}) color:rgb (79, 194, 210,100) width:5;
				draw "Family" color:#white at:{70#px,350#px} font:font("Arial",20,#plain);
				draw line({40#px,375#px},{65#px,375#px}) color:rgb (255, 128, 0,255) width:5;
				draw "Friends" color:#white at:{70#px,380#px} font:font("Arial",20,#plain);
				draw  "Safety" color:#white at:{40#px,420#px} font:font("Arial",22,#bold);
				draw circle(10) color:rgb (0,255,0) width:2 empty:true at:{45#px,450#px};
				draw circle(10) color:rgb (125,125,100) width:2 empty:true at:{60#px,450#px};
				draw circle(10) color:rgb (255,0,0) width:2 empty:true at:{75#px,450#px};
				draw "Perception" color:#white at:{85#px,455#px} font:font("Arial",19,#bold);
            }
		}
		
	}
}

experiment Flat_2D_FollowAgent type:gui {
	output{
		layout #split;
		//display "Main" type: opengl background:rgb(sunlight/5*255,sunlight/5*255,sunlight/5*255) draw_env:false{
		//display "Main" type: opengl draw_env:false camera_pos: {world.shape.width*cos(cycle),world.shape.height*sin(cycle),1328.5421} camera_look_pos: {world.shape.width/2,world.shape.height/2,500} camera_up_vector: {0,1,0} {
		display "Main" type: opengl draw_env:false camera_pos: camera_position camera_look_pos: {agent_to_follow.location.x,agent_to_follow.location.y,0} camera_up_vector: {0,1,0}{
			graphics "world" refresh:false{
				//draw rectangle(world.shape.width,world.shape.height) texture:["/gis/"+case_study+"/texture.jpg"];
			}
			//species road aspect:default;
			//species crime aspect:default refresh:false;
			//species commerce aspect:default refresh:false;
			//species places aspect:default refresh:false;
			species block_front aspect:default refresh:false;
			species police_patrol aspect:flat_obj;
			species building aspect:flat refresh:false;
			species people aspect:flat;
			
		}
		
	}
}

experiment Flat_2D_Moving type:gui {
	output{
		layout #split;
		//display "Main" type: opengl background:rgb(sunlight/5*255,sunlight/5*255,sunlight/5*255) draw_env:false{
		//display "Main" type: opengl draw_env:false camera_pos: {world.shape.width*cos(cycle),world.shape.height*sin(cycle),1328.5421} camera_look_pos: {world.shape.width/2,world.shape.height/2,500} camera_up_vector: {0,1,0} {
		display "Main" type: opengl draw_env:false camera_pos: {2*world.shape.width*cos(cycle)+world.shape.width/2,2*world.shape.width*sin(cycle)+world.shape.width/2,1500} camera_look_pos: {world.shape.width/2,world.shape.height/2,0} camera_up_vector: {0,1,0} {
			
			graphics "world" refresh:false{
				//draw rectangle(world.shape.width,world.shape.height) texture:["/gis/"+case_study+"/texture.jpg"];
			}
			//species road aspect:default;
			//species crime aspect:default refresh:false;
			//species commerce aspect:default refresh:false;
			//species places aspect:default refresh:false;
			species block_front aspect:default refresh:false;
			species police_patrol aspect:flat_obj;
			species building aspect:flat refresh:false;
			species people aspect:flat;
			/*overlay position: { 40#px, 30#px } size: { 480,1200 } background: # black transparency: 0.5 border: #black {
				string minutes;
				if current_date.minute < 10{minutes <- "0"+current_date.minute; }
				else {minutes <- string(current_date.minute);}
				draw ".:-0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ()[],>=" at: {0#px,0#px} color:rgb(0,0,0,0) font:font("Arial",20,#plain);
				draw ":0123456789" at:{ 0#px, 0#px} color:rgb(0,0,0,0) font:font("Arial",55,#bold);
				draw "People: " +  length(people) at: { 40#px, 60#px } color: #white font:font("Arial",20,#plain);
				draw ""+current_date.hour+":"+minutes at:{ 40#px, 800#px} color:#white font:font("Arial",55,#bold);
				draw "Sunlight: "+ sunlight at:{ 40#px, 90#px} color:#white font:font("Arial",20,#plain);
				draw "Age Range" color:#white at:{40#px,130#px} font:font("Arial",25,#bold);
				draw circle(10) color:colors[1] at:{40#px, 160#px};
				draw "(5,14]" color:#white at:{50#px,165#px} font:font("Arial",20,#plain);
				draw circle(10) color:colors[2] at:{40#px, 190#px};
				draw "(14,19]" color:#white at:{50#px,195#px} font:font("Arial",20,#plain);
				draw circle(10) color:colors[3] at:{40#px, 220#px};
				draw "(19,34]" color:#white at:{50#px,225#px} font:font("Arial",20,#plain);
				draw circle(10) color:colors[4] at:{40#px, 250#px};
				draw "(34,54]" color:#white at:{50#px,255#px} font:font("Arial",20,#plain);
				draw circle(10) color:colors[5] at:{40#px, 280#px};
				draw ">54" color:#white at:{50#px,285#px} font:font("Arial",20,#plain);
				draw  "Social Circle" color:#white at:{40#px,320#px} font:font("Arial",23,#bold);
				draw line({40#px,345#px},{65#px,345#px}) color:rgb (79, 194, 210,100) width:5;
				draw "Family" color:#white at:{70#px,350#px} font:font("Arial",20,#plain);
				draw line({40#px,375#px},{65#px,375#px}) color:rgb (255, 128, 0,255) width:5;
				draw "Friends" color:#white at:{70#px,380#px} font:font("Arial",20,#plain);
				draw  "Safety" color:#white at:{40#px,420#px} font:font("Arial",22,#bold);
				draw circle(10) color:rgb (0,255,0) width:2 empty:true at:{45#px,450#px};
				draw circle(10) color:rgb (125,125,100) width:2 empty:true at:{60#px,450#px};
				draw circle(10) color:rgb (255,0,0) width:2 empty:true at:{75#px,450#px};
				draw "Perception" color:#white at:{85#px,455#px} font:font("Arial",19,#bold);
            }*/
		}
		
	}
}

experiment Terrain_3D type:gui{
	output{
		layout #split;
		display main background:#black type:opengl draw_env:false{
			graphics "interaction_graph" {
				if showInteractions{
					loop person over: people{
						float loc_x <- person.location.x;
						float loc_y <- person.location.y;
						cell tmp_cell <- cell({loc_x,loc_y});
						float loc_z <- tmp_cell.grid_value;
						point location_3d <- {loc_x,loc_y,loc_z};
						loop connection over:person.social_circle{
							float loc2_x <- connection.location.x;
							float loc2_y <- connection.location.y;
							tmp_cell <- cell({loc2_x,loc2_y});
							float loc2_z <- tmp_cell.grid_value;
							point location2_3d <- {loc2_x,loc2_y,loc2_z};
							draw curve(location_3d, location2_3d,1.0, 200, 90) color:rgb (79, 194, 210,100);
						}
					}
				}
			}
			grid cell elevation:grid_value texture:terrain_texture triangulation:true refresh:false;
			species building aspect:terrain refresh:false;
			//species building_obj aspect:terrain;
			species police_patrol aspect:terrain;
			species people aspect:terrain;
			overlay position: { 40#px, 30#px } size: { 480,1200 } background: # black transparency: 0.5 border: #black {
				string minutes;
				if current_date.minute < 10{minutes <- "0"+current_date.minute; }
				else {minutes <- string(current_date.minute);}
				draw ".:-0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ()[],>=" at: {0#px,0#px} color:rgb(0,0,0,0) font:font("Arial",20,#plain);
				draw ":0123456789" at:{ 0#px, 0#px} color:rgb(0,0,0,0) font:font("Arial",55,#bold);
				draw "People: " +  length(people) at: { 40#px, 60#px } color: #white font:font("Arial",20,#plain);
				draw ""+current_date.hour+":"+minutes at:{ 40#px, 800#px} color:#white font:font("Arial",55,#bold);
				draw "Sunlight: "+ sunlight at:{ 40#px, 90#px} color:#white font:font("Arial",20,#plain);
				draw "Age Range" color:#white at:{40#px,130#px} font:font("Arial",25,#bold);
				draw circle(10) color:colors[1] at:{40#px, 160#px};
				draw "(5,14]" color:#white at:{50#px,165#px} font:font("Arial",20,#plain);
				draw circle(10) color:colors[2] at:{40#px, 190#px};
				draw "(14,19]" color:#white at:{50#px,195#px} font:font("Arial",20,#plain);
				draw circle(10) color:colors[3] at:{40#px, 220#px};
				draw "(19,34]" color:#white at:{50#px,225#px} font:font("Arial",20,#plain);
				draw circle(10) color:colors[4] at:{40#px, 250#px};
				draw "(34,54]" color:#white at:{50#px,255#px} font:font("Arial",20,#plain);
				draw circle(10) color:colors[5] at:{40#px, 280#px};
				draw ">54" color:#white at:{50#px,285#px} font:font("Arial",20,#plain);
				draw  "Social Circle" color:#white at:{40#px,320#px} font:font("Arial",23,#bold);
				draw line({40#px,345#px},{65#px,345#px}) color:rgb (79, 194, 210,100) width:5;
				draw "Family" color:#white at:{70#px,350#px} font:font("Arial",20,#plain);
				draw line({40#px,375#px},{65#px,375#px}) color:rgb (255, 128, 0,255) width:5;
				draw "Friends" color:#white at:{70#px,380#px} font:font("Arial",20,#plain);
				draw  "Safety" color:#white at:{40#px,420#px} font:font("Arial",22,#bold);
				draw circle(10) color:rgb (0,255,0) width:2 empty:true at:{45#px,450#px};
				draw circle(10) color:rgb (125,125,100) width:2 empty:true at:{60#px,450#px};
				draw circle(10) color:rgb (255,0,0) width:2 empty:true at:{75#px,450#px};
				draw "Perception" color:#white at:{85#px,455#px} font:font("Arial",19,#bold);
            }
		}
		
	}
}

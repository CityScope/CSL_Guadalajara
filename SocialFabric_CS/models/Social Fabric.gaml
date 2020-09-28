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
	bool save_results parameter: "Save results" category: "Model" <- false;
	//Visualization parameters
	bool showBuildings parameter: "Buildings" category: "Visualization" <- true;
	bool showPerception parameter: "Perception" category: "Visualization" <- false;
	bool showEncounters parameter: "Encounters" category: "Visualization" <- false;
	string agent_mode parameter: "Indicator" category: "Visualization" <- "Overall perception" among:["Overall perception","Police","Natural surveillance","Lighting","Public transportation","Street condition", "Physical isolation","Social cohesion","Anti-social behavior","Age range", "Layers"];
	bool showOverallPerception parameter: "Perception on streets" category:"Visualization" <- false;
	//Heatmap
	bool compute_heatmap parameter: "Compute heatmap" category: "Heatmap" <- true;
	string heatmap_type parameter: "Heatmap type" category:"Heatmap" <- "user_point" among:["user_point","street"];
	string heatmap_street_name parameter: "Street" category:"Heatmap" <- "Camino a la Mesa";
	
	//people related parameters
	int nb_people <- 800;
	int agent_size <- 6;
	int people_encountered <- 0;// update: length(people where (length(each.encounters)>0));
	list<rgb> colors <- [rgb(218, 210, 69,255),rgb(228, 167, 39,255),rgb(34, 74, 193,255),rgb(204, 43, 107,255),rgb(17, 183, 34,255),rgb(40, 244, 230,255),#red];
	
	//SUNLIGHT
	float sunlight <- 0.0 update:max([float(-0.03*(list(current_date)[3]+(list(current_date)[4]/60)-13)^2+1) with_precision 2,0.1]); //Estimated function to get the sunlight [0.0 to 1.0]
	
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
	file block_fronts_file <- file("/gis/"+case_study+"/block_fronts.shp");
	file crimes_file <- file("/gis/"+case_study+"/crimes.shp");
	file denue_file <- file("/gis/"+case_study+"/denue.shp");
	file public_transportation_file <- file("/gis/"+case_study+"/public_transportation.shp");
	geometry shape <- envelope(mask_file);
	
	//Heatmap and experiments with case studies
	list<heatmap> enabled_cells <- [];
	map<string,list<heatmap>> case_studies;
	map<string,float> mean_values;
	
	init{
		step <- 1#minute;
		create block_front from:block_fronts_file with:[block_frontID::string(read("CVEGEO")), road_id::int(read("CVEVIAL")),int_lightning::int(read("ALUMPUB_")), int_paving::int(read("RECUCALL_")), int_sideWalk::int(read("BANQUETA_")), int_access::int(read("ACESOPER_"))]{ do init_condition; }
		create road from:roads_file with:[road_id::int(read("CVEVIAL")),street_name::string(read("NOMVIAL"))];
		create building from:buildings_file;
		do mapValues;		
		road_network <- as_edge_graph(road);
		create people number:nb_people;
		create police_patrol number:5;
		//ask people{do init_social_circle;}
		create crime from:crimes_file with:[type::string(read("DEL"))];
		create public_transportation from:public_transportation_file;
		
	
		case_studies <- [
			"Cinco esquinas"::[heatmap closest_to({693,637})],
			"Camino a la Mesa"::getStreetCells("Camino a la Mesa"),
			"El Arroyo"::[heatmap closest_to({735,943})],
			"El Cristo"::[heatmap closest_to({945,1350})],
			"El Bosque"::[heatmap closest_to({567,943})]
		];
		loop key over:case_studies.keys{
			write key+":"+length(case_studies[key]);
		}
		do expand_case_studies(2);
		loop key over:case_studies.keys{
			write key+":"+length(case_studies[key]);
		}
		do cleanup;
	}
	
	reflex mean_safety{
		float sum <- 0.0;
		float mean <- 0.0;
		ask people{
			sum <- sum + safety_perception;
		}
		mean <- sum / length(people);
		//save ""+time+","+mean to:"../results/mean_safety.csv" rewrite:false type:csv;
	}
	
	action expand_case_studies(int level){
		loop key over:case_studies.keys{
			loop times:level{
				list<heatmap> case_cells <-[];
				case_cells <- case_studies[key];
				ask case_studies[key]{
					list<heatmap> cells_to_add <- neighbors - case_cells;
					case_cells <- case_cells + cells_to_add;
				}
				case_studies[key] <- case_cells;
			}	
		}
	}
	
	reflex update_case_studies when:every(1#minutes) and compute_heatmap{
		loop key over:case_studies.keys{
			float sum <- 0.0;
			ask case_studies[key]{
				do update_value;
				sum <- sum + perception_value;
			}		
			mean_values[key] <- sum/length(case_studies[key]);
		}
		/*float sum <- 0.0;
		ask enabled_cells{
			do update_value;
			sum <- sum + perception_value;
		}
		enabled_cells_mean_value <- sum / length(enabled_cells);
		save ""+time+","+enabled_cells_mean_value to:"../results/cinco_esquinas.csv" rewrite:false type:csv;*/
	}
	
	/*reflex export_results when:every(1#minute) and save_results=true{
		string csv_output <- "\n";
		ask enabled_cells{
			csv_output <- csv_output+""+cycle+","+name+","+perception_value+","+current_date.hour+":"+current_date.minute+"\n";
		}
		save csv_output to:"../results/heatmap_history.csv" rewrite:false type:csv;
	}*/
	list<heatmap> getStreetCells(string street){
		list<road> streets_of_interest <- road where(each.street_name=street);
		list<heatmap> result <- [];
		ask streets_of_interest{
			street_color <- #yellow;
		}
		ask streets_of_interest{
			list<heatmap> cells_to_add <- heatmap where(each overlaps self);
			if not empty(cells_to_add){
				loop heatmap_element over:cells_to_add{
					add heatmap_element to:result;
				}		
			}
		}
		return result;
	}
	action init_whole_heatmap_cells{
		loop street over:road{
			list<heatmap> cells_to_add <- heatmap where(each overlaps street);
			if cells_to_add != [] and cells_to_add != nil{
				loop heatmap_element over:cells_to_add{
					if !(heatmap_element in enabled_cells){
						add heatmap_element to:enabled_cells;
					}
				}
			}
		}
	}
	action init_enabled_cells_by_name(string place_name, int level){
		list<road> streets_of_interest <- road where(each.street_name=place_name);
		ask streets_of_interest{
			street_color <- #yellow;
		}
		ask streets_of_interest{
			list<heatmap> cells_to_add <- heatmap where(each overlaps self);
			if cells_to_add != [] and cells_to_add!=nil{
				loop heatmap_element over:cells_to_add{
					add heatmap_element to:enabled_cells;
				}		
			}
		}
		loop times:level{
			list<heatmap> new_enabled <-[];
			new_enabled <- enabled_cells;
			ask enabled_cells{
				list<heatmap> cells_to_add <- neighbors - new_enabled;
				new_enabled <- new_enabled + cells_to_add;
			}
			enabled_cells <- new_enabled;
		}
	}
	action init_enabled_cells(point place_location, int level){
		heatmap initial_cell <- heatmap closest_to(place_location);
		ask initial_cell{
			add self to:enabled_cells;
			enabled_cells <- enabled_cells+neighbors;
		}
		loop times:level{
			list<heatmap> new_enabled <-[];
			new_enabled <- enabled_cells;
			ask enabled_cells{
				list<heatmap> cells_to_add <- neighbors - new_enabled;
				new_enabled <- new_enabled + cells_to_add;
			}
			enabled_cells <- new_enabled;
		}
	}
	
	action cleanup{
		mask_file <- nil; 
		roads_file <- nil;
		buildings_file <- nil;
		terrain_texture <- nil;
		grid_data <- nil;
		block_fronts_file <- nil;
		crimes_file <- nil;
		denue_file <- nil;
		public_transportation_file <- nil;
		ask block{do die;}
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
	
}

species road{
	int road_id;
	string street_name;
	float valuation;
	float weight;
	float float_lightning;
	float float_paving;
	float float_sideWalk;
	float float_access;
	rgb street_color;
	init{
		street_color <- #gray;
	}
	action init_condition{
		valuation <- (float_lightning+float_paving+float_sideWalk+float_access)/4;
		weight <- valuation; //Normalization of valuation 0 to 1 according to the model
		weight <- 100*(1 - weight); //In weighted networks, a path is shorter than other if it has smaller value. 0 <- best road, 1 <- worst road
	}
	aspect default{draw shape color: rgb(255-(127*valuation),0+(127*valuation),50);}
	//aspect default{draw shape color: rgb(255*weight,50,50,100);}
	aspect street_of_interest{draw shape color: street_color;}
}

grid heatmap width:35 height:35 parallel:true neighbors:8{
	float perception_value;
	rgb cell_color;
	list<people> people_inside <- [];
	init{
		perception_value <- 0.0;
		//cell_color <- rgb(30,30,30,0.5);
		cell_color <- #black;
	}
	action update_value{
		people_inside <- people where(each overlaps self);
		if people_inside!=[] and people_inside!=nil{
			float sum <- 0.0;
			ask people_inside{
				sum <- sum + self.safety_perception;
			}	
			perception_value <- sum/length(people_inside);
			cell_color <- rgb(230-(perception_value*230),230*perception_value,0,0.5);
		}
		else{
			cell_color <- rgb(30,30,30,0.3);
		}
	}
	aspect default{
		draw shape color:cell_color;
	}
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
	float isolation_value;
	action computePhysicalIsolation{//The objective of this function is to calculate, at the begining of the simulation, a value of isolation for every place.
		building closest_building <- building closest_to(self);
		float distance_to_closest <- self distance_to closest_building;
		isolation_value <- distance_to_closest;
		add isolation_value to: tmp_isolation_values;
	}
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

species people skills:[moving]{
	
	//Importar datos de csv para rutinas, relaciones, perfil.
	//Perception related variables

	map<string,float> indicators_values;  	//indicator->value
	map<string,float> indicators_weights; 	//indicator->weight
	list indicators <- ["police_patrols","other_people","lighting_uniformity_radius","safe_mobility","pavement_condition","physical_isolation","social_cohesion","crimes"];
	float safety_perception <- 0.0;			//Value of perception of security
	float vision_radius <- 1.0#m;			//Size of the circle of co-presence
	list<people> social_circle <- [];		//List of other people this aget relates with
	list<people> family <- [];
	list<people> encounters <- [];			//List of people encountered in the public space

	//New agenda-based variables
	point home;
	map<date,point> agenda_day;
	point target;
	
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
	float max_elevation <- 1500.0;
	float current_max <- 0.0;
	
	init{
		//pedestrian_model <- "SFM";
		//obstacle_species <- [block_front,people];
		write "created"+name;
		home <- any_location_in(one_of(road));
		indicators_weights <- [													//How important is each indicator for this agent. All of them sum 1.
			"police_patrols"::0.1,//C1
			"other_people"::0.1,//C1
			"lighting_uniformity_radius"::0.1,//C2
			"safe_mobility"::0.1,//C3			
			"pavement_condition"::0.1,//C4
			"physical_isolation"::0.2,//C5
			"social_cohesion"::0.2,
			"crime"::0.1
			];
		float init_value <- 1.0;
		indicators_values <- [													
			"police_patrols"::init_value,//C1
			"other_people"::init_value,//C1
			"lighting_uniformity_radius"::init_value,//C2
			"safe_mobility"::init_value,//C3			
			"pavement_condition"::init_value,//C4
			"physical_isolation"::init_value,//C5
			"social_cohesion"::init_value,//C6
			"crime"::init_value//C7
			];
		
		occupation <- one_of("inactive","student","worker");							//Role of this agent
		location <- home;
		target <- home;
	}
	/*reflex init when:cycle=1{
		indicators_values <- [													
			"police_patrols"::0.0,//C1
			"other_people"::0.0,//C1
			"lighting_uniformity_radius"::0.0,//C2
			"safe_mobility"::0.0,//C3			
			"pavement_condition"::0.0,//C4
			"physical_isolation"::0.0,//C5
			"social_cohesion"::0.0,
			"crime"::0.0
		];
	}*/
	reflex create_new_agenda when:empty(agenda_day){
		int hours_for_activities <- rnd(6,12);
		int hour_for_go_out <- rnd(0,24-hours_for_activities);
		int nb_activities <- rnd(2,5);
		int hours_per_activity <- int(hours_for_activities/nb_activities);
		int sum <- 0;
		loop times:nb_activities{
			agenda_day <+ (date(current_date.year,current_date.month, hour_for_go_out+sum>=24?current_date.day+1:current_date.day,hour_for_go_out+sum>=24?mod(hour_for_go_out+sum,24):hour_for_go_out+sum, rnd(0,59),0)::any_location_in(one_of(road)));
			sum <- sum + hours_per_activity;
		}
		agenda_day <+ (date(current_date.year,current_date.month,hour_for_go_out+sum>24?current_date.day+1:current_date.day,hour_for_go_out+sum>=24?mod(hour_for_go_out+sum,24):hour_for_go_out+sum, rnd(0,59),0)::home);
	}
	reflex update_activity when:not empty(agenda_day) and (after(agenda_day.keys[0])){
		target <- agenda_day.values[0];
		agenda_day>>first(agenda_day);
	}
	reflex mobility when:target!=location{
		do goto target:target on:road_network;
	}
	action update_encounters{//} when:mod(cycle,6)=0 and flip(0.5){
		encounters <- [];
		if rnd(1) < safety_perception{encounters <- people at_distance(vision_radius);}
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
		
		float sum<-0.0;
		loop auxKey over:indicators_values.keys{
			sum <- sum + indicators_values[auxKey]*indicators_weights[auxKey];
		}
		safety_perception <- sum;
	}
	reflex update_indicators_values when:every(3#minute) and flip(0.3){
		vision_radius <- sunlight*30#m;
	//action update_indicators_values{	
		//In this function, all environmental indicators are perceived by the agent. Only indicators_values are updated here.
		//The importance of these indicators_values depends on every agent profile (women, men, child, etc.).
		//Considerar la introducción de crimenes a lo largo del día considerando como entrada datos georreferenciados. Además estos tienen que clasificarse porque 
		//dependiendo del tipo de caracteristicas pueden cometerse distintos tipos de crimen.
		
		//C1__ACCESS TO HELP AND SURVEILLANCE
		//police_patrols_range
		list<police_patrol> auxPolice <- police_patrol at_distance(5*vision_radius);
		if auxPolice != []{
			police_patrol auxP <- auxPolice[0];
			float distance <- self.location distance_to auxP.location;
			float auxValue <- distance/(5*vision_radius);
			put 1-auxValue at:"police_patrols" in:indicators_values;
		}
		else{put 0.0 at:"police_patrols" in:indicators_values;}
		//active_pedestrians (interaction)
			//1.número de personas que interactúan - Radio 1
				// M+W+N+N    +  M
				// W+N+N    + car   (kidnapping)
				// relación de los agentes niños con agentes adultos por ciertas horas del día
			//2.si se conocen o no - Radio 2   (definir en la descripción de los agentes)
			//3.Si no se conocen: W-M   Si se conocen: W-W
		list<people> auxPeople <- people at_distance(vision_radius);
		if auxPeople != []{
			people auxAgent <- one_of(auxPeople);
			float distance <- auxAgent distance_to(self);
			float auxValue <- distance/vision_radius;
			put 1-auxValue at:"other_people" in:indicators_values;
		}
		else{put 0.0 at:"other_people" in:indicators_values;}	
		
		//C2__VISIVILITY
		//lighting_uniformity_radius
			//TO DO: differenciate between daytime and nighttime
		list<road> auxLighting <- road at_distance(vision_radius);
		put auxLighting!=[]? auxLighting[0].float_lightning:0.0 at:"lighting_uniformity_radius" in:indicators_values;
		
		//C3__SAFE MOBILITY
		list<point> auxMobility <- geometry(public_transportation) closest_points_with(self);
		float aux_distance <- auxMobility[0] distance_to auxMobility[1];
		float distance <- min(200,aux_distance);
		distance <- distance / 200;
		put 1-distance at:"safe_mobility" in:indicators_values;
		
		//C4__PHYSICAL DISORDER
		//pavement_condition
		list<road> auxPavement <- road at_distance(vision_radius);
		put auxPavement!=[]? auxPavement[0].float_paving:0.0 at:"pavement_condition" in:indicators_values;
		
		//C5__PHYSICAL ISOLATION 
		list<building> auxPlaces <- building at_distance(vision_radius);
		put auxPlaces!=[]?auxPlaces[0].isolation_value:1.0 at:"physical_isolation" in:indicators_values;
		
		//C7__SOCIAL COHESION
		int counter <- 0;
		loop element over:social_circle{if element in encounters{counter <- counter + 1;}}
		put social_circle!=[]?counter/length(social_circle):0.0 at:"social_cohesion" in:indicators_values;
		
		//C8__ANTI-SOCIAL BEHAVIOR
		list<crime> auxCrime <- crime at_distance(2*vision_radius);
		if auxCrime != []{
			float crime_distance <- one_of(auxCrime) distance_to(self);
			float value <- crime_distance / (2*vision_radius);
			put value at:"crime" in:indicators_values;
		}
		else {put 1.0 at:"crime" in:indicators_values;}
		
		//Update the overall value		
		do update_perception_value;
	}
	action update_elevation{
		cell tmp_cell <- cell(location);
		location_3d <- {location.x,location.y,tmp_cell.grid_value}; 
	}
	action update_location{
		location <- {location.x,location.y,200};
	}
	aspect layers{
		int nb_indicators <- 8;
		float color_value;
		float elevation_rate <- 150.0; //meters by second of elevation
		//This is for the formal surveillance layer
		color_value <- indicators_values["police_patrols"];
		draw circle(agent_size) color: rgb(255-(255*color_value),255*color_value,0) at:{location.x,location.y,current_max/nb_indicators};
		color_value <- indicators_values["other_people"];
		draw circle(agent_size) color: rgb(255*color_value, 255-(255*color_value),0) at:{location.x,location.y,(current_max/nb_indicators)*2};
		color_value <- indicators_values["lighting_uniformity_radius"];
		draw circle(agent_size) color: rgb(255-(255*color_value),0+(255*color_value),0,255) at:{location.x,location.y,(current_max/nb_indicators)*3};
		color_value <- indicators_values["public_transportation"];
		draw circle(agent_size) color: rgb(255-(255*color_value),0+(255*color_value),0,255) at:{location.x,location.y,(current_max/nb_indicators)*4};
		color_value <- indicators_values["pavement_condition"];
		draw circle(agent_size) color: rgb(255-(255*color_value),0+(255*color_value),0,255) at:{location.x,location.y,(current_max/nb_indicators)*5};
		color_value <- indicators_values["physical_isolation"];
		draw circle(agent_size) color: rgb(255-(255*color_value),0+(255*color_value),0,255) at:{location.x,location.y,(current_max/nb_indicators)*6};
		color_value <- indicators_values["social_cohesion"];
		draw circle(agent_size) color: rgb(255-(255*color_value),0+(255*color_value),0,255) at:{location.x,location.y,(current_max/nb_indicators)*7};
		color_value <- indicators_values["crimes"];
		draw circle(agent_size) color: rgb(255*color_value,255-(255*color_value)) at:{location.x,location.y,current_max};
	}
	
	aspect indicator1{
		float color_value;
		color_value <- indicators_values["police_patrols"];
		draw circle(agent_size) color: rgb(255-(255*color_value),255*color_value,0);
	}
	aspect indicator2{
		float color_value;
		color_value <- indicators_values["other_people"];
		draw circle(agent_size) color: rgb(255*color_value, 255-(255*color_value),0);
	}
	aspect indicator3{
		float color_value;
		color_value <- indicators_values["lighting_uniformity_radius"];
		draw circle(agent_size) color: rgb(255-(255*color_value),0+(255*color_value),0,255);
	}
	aspect indicator4{
		float color_value;
		color_value <- indicators_values["safe_mobility"];
		draw circle(agent_size) color: rgb(255-(255*color_value),0+(255*color_value),0,255);
	}
	aspect indicator5{
		float color_value;
		color_value <- indicators_values["pavement_condition"];
		draw circle(agent_size) color: rgb(255-(255*color_value),0+(255*color_value),0,255);
	}
	aspect indicator6{
		float color_value;
		color_value <- indicators_values["physical_isolation"];
		draw circle(agent_size) color: rgb(255-(255*color_value),0+(255*color_value),0,255);
	}
	aspect indicator7{
		float color_value;
		color_value <- indicators_values["social_cohesion"];
		draw circle(agent_size) color: rgb(255-(255*color_value),255*color_value,0);
	}
	aspect indicator8{
		float color_value;
		color_value <- indicators_values["crime"];
		draw circle(agent_size) color: rgb(255-(255*color_value),255*color_value,0);
	}
	
	aspect flat{
		rgb current_color;
		//"Overall perception","Police","Lighting","Street condition","Natural surveillance"
		//list indicators <- ["police_patrols","lighting_uniformity_radius","pavement_condition","other_people"];
		if agent_mode = "Overall perception" {
			current_color <- rgb(255-(255*float(safety_perception)),255*float(safety_perception),0);
		}
		else if agent_mode = "Police" {
			float color_value <- indicators_values["police_patrols"];
			current_color <- rgb(255-(255*color_value),255*color_value,0);
		}
		else if agent_mode = "Natural surveillance" {
			float color_value <- indicators_values["other_people"];
			current_color <- rgb(255*color_value, 255-(255*color_value),0);
		}
		else if agent_mode = "Lighting" {
			float color_value <- indicators_values["lighting_uniformity_radius"];
			current_color <- rgb(255-(255*color_value),255*color_value,0);
		}
		else if agent_mode = "Public transportation" {
			float color_value <- indicators_values["safe_mobility"];
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
		else if agent_mode = "Social cohesion" {
			float color_value <- indicators_values["social_cohesion"];
			current_color <- rgb(255-(255*color_value),255*color_value,0);
		}
		else if agent_mode = "Anti-social behavior" {
			float color_value <- indicators_values["crime"];
			write name+":"+color_value;
			current_color <- rgb(255-(255*color_value),255*color_value,0);
		}
		else if agent_mode = "Age range"{current_color <- colors[age_group];}
		draw circle(agent_size) color: current_color at:location;
		if showEncounters{
			loop connection over:encounters{
				//draw curve(location, connection.location,1.0, 200, 90) color:rgb (255, 255, 255,255);
				draw line(location, connection.location) color:rgb (255, 255, 255,255);
			}
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
	/* aspect terrain{
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
	}*/
	
}

species police_patrol skills:[moving]{ //for indicator "police_patrols_range"
	point target;
	image_file car;
	path route <- nil;
	init{
		location <- any_location_in(one_of(road));
		target <- any_location_in(one_of(road));
		do update_path;
	}
	reflex move when:flip(0.1){
		if location = target{
			target <- any_location_in(one_of(road));
			do update_path;
		}
		do follow path:route speed:1.0;
	}
	action update_path{
		route <- path_between(road_network,location,target);
		loop while: route=nil{
			target <- any_location_in(one_of(road));
			route <- path_between(road_network,location,target);
		}
		
	}
	aspect flat{
		draw rectangle(10,3) color:#red;
	}
	aspect flat_obj{
		draw obj_file("/img/police.obj",90::{-1,0,0}) size: 20 at: {location.x,location.y,10} rotate: heading color: mod(cycle,2)=0?#red:#blue;
	}
	aspect terrain{
		float loc_x <- location.x;
		float loc_y <- location.y;
		cell tmp_cell <- cell({loc_x,loc_y});
		float loc_z <- tmp_cell.grid_value;
		point location_3d <- {loc_x,loc_y,loc_z+5};
		draw obj_file("/img/police.objm",90::{-1,0,0}) size: 10 at: location_3d rotate: heading color: #red;
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
		draw circle(30) color:#red empty:true width:1.0;
	}
}

experiment Overall type:gui until:(cycle/60)=24{
	output{
		layout #split;
		//display "Main" type: opengl background:rgb(sunlight/5*255,sunlight/5*255,sunlight/5*255) draw_env:false{
		//display "Main" type: opengl draw_env:false camera_pos: {world.shape.width*cos(cycle),world.shape.height*sin(cycle),1328.5421} camera_look_pos: {world.shape.width/2,world.shape.height/2,500} camera_up_vector: {0,1,0} {
		display "Main" type: opengl draw_env:false{
			
			//species road aspect:street_of_interest;
			//species crime aspect:default refresh:false;
			//species commerce aspect:default refresh:false;
			//species places aspect:default refresh:false;
			//species public_transportation aspect:default refresh:false;
			species heatmap aspect:default;
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
				draw ".:-0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ()[],>=" at: {0#px,0#px} color:rgb(0,0,0,0) font:font("Arial",19,#bold);
				draw "People: " +  length(people) at: { 40#px, 60#px } color: #white font:font("Arial",20,#plain);
				draw ""+current_date.hour+":"+minutes at:{ 40#px, 800#px} color:#white font:font("Arial",55,#bold);
				draw "Sunlight: "+ sunlight at:{ 40#px, 90#px} color:#white font:font("Arial",20,#plain);
				
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
				draw "Interactions: "+people_encountered/nb_people color: #white at: {40#px,480#px} font:font("Arial",19,#bold);
            }
		}
		//"Cinco esquinas","Camino a la Mesa","El Arroyo","El Cristo","El Bosque"
		display "chart" type: java2D{
			chart "Safety perception" title_font:font("arial",26,#bold) legend_font:font("arial",24,#plain) y_label:"Value" x_label:"Minutes" x_serie_labels:int(cycle){
				data "Cinco esquinas" value:mean_values["Cinco esquinas"] color:#red;
				data "Camino a la Mesa" value:mean_values["Camino a la Mesa"] color:#blue;
				data "El Arroyo" value:mean_values["El Arroyo"] color:#green;
				data "El Cristo" value:mean_values["El Cristo"] color:#blueviolet;
				data "El Bosque" value:mean_values["El Bosque"] color:#gamaorange;
			}
		}
	}
}

/*
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
}*/

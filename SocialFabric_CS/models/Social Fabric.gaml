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
	int nbAgents parameter: "Number of people" category: "Environment" <-0 min:0 max: 1000;
	//Model parameters
	bool showInteractions parameter: "Show interactions" category:"Model" <- false;
	float agentSpeed parameter: "Agents Speed" category: "Model" <- 1.4 min:0.5 max: 10.0;
	//Visualization parameters
	bool showPerception parameter: "Show perception" category: "Visualization" <- false;
	float buildings_z parameter: "buildings_z" category: "Visualization" <- 0.0;
	float buildings_y parameter: "buildings_y" category: "Visualization" <- 0.0;
	float buildings_x parameter: "buildings_x" category: "Visualization" <- 0.0;
	float terrain_z parameter: "terrain_z" category: "Visualization" <- -65.0 min:-500.0 max:1000.0;
	float terrain_y parameter: "terrain_y" category: "Visualization" <- 1080.0 min:-500.0 max:1000.0;
	float terrain_x parameter: "terrain_x" category: "Visualization" <- 790.0 min:-500.0 max:1000.0;
	graph road_network;
	map<road, float> weight_map;
	map<string, rgb> color_type <- ["offender"::rgb(255,255,0), "victim"::rgb (255, 0, 255), "people"::rgb (10, 192, 83,255)];
	
	//people
	int nb_people <- 0;
	int flux_node_size <- 20;
	int fluxid <- 1;
	graph<people,people> interaction_graph;
	
	//SUNLIGHT
	float sunlight   <- 0.0 update:max([float(-0.03*(list(current_date)[3]+(list(current_date)[4]/60)-13)^2+1) with_precision 2,0.0]); //Estimated function to get the sunlight [0.0 to 1.0]

	date starting_date <- date([2020,4,23,6,0,0]);
	file roads_file <- file("/gis/"+case_study+"/roads.shp");
	file buildings_file <- file("/gis/"+case_study+"/Buildings_DepthHeight.shp");
	file terrain_texture <- file('/gis/fivecorners/texture.jpg') ;
	file grid_data <- file("/gis/"+case_study+"/output_srtm.asc");
	geometry shape <- envelope(roads_file);
	
	init{
		step <- 30#s;
		file blocks_file <- nil;
		file terrain_file <- nil;
		file block_fronts_file <- nil;
		file places_file <- nil;
		file crime_file <- nil;
		
		
		string inputFileName <- "";
		
		inputFileName <- "/gis/"+case_study+"/blocks.shp";
		if file_exists(inputFileName){ blocks_file <- file(inputFileName);}
		
		inputFileName <- "/gis/"+case_study+"/block_fronts.shp";
		if file_exists(inputFileName){ block_fronts_file <- file(inputFileName);}
		
		//inputFileName <- "/gis/"+case_study+"/crime.shp";
		//if file_exists(inputFileName){ crime_file <- file(inputFileName);}		
		
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
		do mapValues;		
		weight_map <- road as_map(each::each.shape.perimeter);
		road_network <- as_edge_graph(road);
		create people number:2000;
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
	//aspect default{draw shape color: rgb(255-(127*valuation),0+(127*valuation),50,255);}
	aspect default{draw shape color: rgb(255*valuation,50,50,100);}
	aspect white{draw shape color: #white;}
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
		valuation <- sum / 4;  
	}
	aspect default{	draw shape color: rgb(255-(127*int_lightning),0+(127*int_lightning),50,255); }
}

species places{
	string id;
	string name_str;
	float height;
	string type;
	init{ height <- float(50+rnd(100)); }
	aspect default{ 
		draw geometry:square(50#m)  color:rgb (86, 140, 158,255) border:#indigo depth:height;
	}
	aspect interland{
		if type="interland"{draw square(flux_node_size) color: rgb (232, 64, 126,255) border: #maroon;}
	}
	action interactWithroads{
		list<road> inRank <- [];
		inRank <- road at_distance(40);
		if inRank!=[]{
			ask inRank{
				valuation <- 1.0;
			}
		}
	}
}

species building {
	//geometry shape <- obj_file("/gis/"+case_study+"/buildings_obj.obj") as geometry;
	
	aspect terrain {
		//draw shape at:{buildings_x,buildings_y,buildings_z} color:rgb (79, 176, 98,255);
		float loc_x <- location.x;
		float loc_y <- location.y;
		cell tmp_cell <- cell({loc_x,loc_y});
		float loc_z <- tmp_cell.grid_value;
		draw shape color:rgb (61, 148, 85,255) at:{loc_x+buildings_x,loc_y+buildings_y,loc_z+buildings_z} depth:rnd(3)+3#m;
	}
}

species people skills:[moving]{
	
	//Importar datos de csv para rutinas, relaciones, perfil.
	//Perception related variables

	map<string,float> indicators_values;  	//indicator->value
	map<string,float> indicators_weights; 	//indicator->weight
	float safety_perception <- 0.0;			//Value of perception of security
	float vision_radius <- 30.0#m;			//Size of the circle of co-presence
	list<people> social_circle <- [];		//List of other people this aget relates with

	//Routine related variables
	map<string,point> locations;				//A map containing the locations and their coordinates
	point current_objective;					//The current objective in the routine
	path current_route;							//The current route to follow, this varies according to the current objective
	string current_state <- "stay";				//Wheter this agent is onTheWay or stay
	
	//personal variables
	string occupation;						//The role of this agent
	int age <- rnd(80);						//Age of this agent
	list<string> preferences; 				//EXPERIMENTAL FOR NETWORK ANALYSIS: People interact and make relationships with people according to an affinity value, which is obtained from preferences. (Read Yuan et al)
	
	init{
		indicators_weights <- [													//How important is each indicator for this agent. All of them sum 1.
			"police_patrols"::0.25,
			"lighting_uniformity_radius"::0.25,
			"pavement_condition"::0.1,
			"wm_ratio"::0.4];
		occupation <- one_of("inactive","student","worker");					//Role of this agent
		add "home"::building[rnd(length(building)-1)].location to: locations;			//Home location
		add "school"::building[rnd(length(building)-1)].location to: locations;			//School location
		add "work"::building[rnd(length(building)-1)].location to: locations;			//Work location
		add "leisure"::building[rnd(length(building)-1)].location to: locations;			//Leisure location
		location <- locations["home"];/**/											//Initial location
		list<people> auxList <- people at_distance(vision_radius);
		add all:auxList to:social_circle;										//Init of social circle as all people at "vision_radius" distance
	}
	action update_perception {
		if sunlight>0 and vision_radius<60#m{
			vision_radius <- vision_radius + vision_radius*sunlight;
		}
		float sum<-0.0;
		loop auxKey over:indicators_values.keys{
			sum <- sum + indicators_values[auxKey]*indicators_weights[auxKey];
		}
		safety_perception <- sum;
	}
	action update_indicators_values {
		//In this function, all environmental indicators are perceived by the agent. Only indicators_values are updated here.
		//The importance of these indicators_values depends on every agent profile (women, men, child, etc.).
		//Considerar la introducción de crimenes a lo largo del día considerando como entrada datos georreferenciados. Además estos tienen que clasificarse porque 
		//dependiendo del tipo de caracteristicas pueden cometerse distintos tipos de crimen.
		//C1__FORMAL SURVEILLANCE
		//police_patrols_range
		list<police_patrol> auxPolice <- police_patrol at_distance(vision_radius);
		put auxPolice!=[]? 1.0:0.0 at:"police_patrols" in:indicators_values;
		
		//C2__ARTIFICIAL LIGHTING
		//lighting_uniformity_radius
			//TO DO: differenciate between daytime and nighttime
		list<road> auxLighting <- road at_distance(vision_radius);
		put auxLighting!=[]? auxLighting[0].float_lightning:0.0 at:"lighting_uniformity_radius" in:indicators_values;
		
		//C7__MAINTENANCE
		//pavement_condition
		list<road> auxPavement <- road at_distance(vision_radius);
		put auxPavement!=[]? auxPavement[0].float_paving:0.0 at:"pavement_condition" in:indicators_values;
		
		//C1__NATURAL SURVEILLANCE
		//active_pedestrians (interaction)
			//1.número de personas que interactúan - Radio 1
				// M+W+N+N    +  M
				// W+N+N    + car   (kidnapping)
				// relación de los agentes niños con agentes adultos por ciertas horas del día
			//2.si se conocen o no - Radio 2   (definir en la descripción de los agentes)
			//3.Si no se conocen: W-M   Si se conocen: W-W
		list<people> nearPeople <- []; //People arround
	}
	reflex build_routine when:current_state="stay"{
		if age<=5{}
		else if age>5 and age<=14{
			if current_date.hour>=19{current_objective <- locations["home"];current_state <- "onTheWay";}
			else if current_date.hour>=14{current_objective <- locations["leisure"];current_state <- "onTheWay";}
			else if current_date.hour>=9{current_objective <- locations["school"];current_state <- "onTheWay";}
		}
		else if age>14 and age<=19{
			if current_date.hour>20{current_objective <- locations["home"]; current_state <- "onTheWay";}
			if current_date.hour>13{current_objective <- locations["work"]; current_state <- "onTheWay";}
			if current_date.hour>7{current_objective <- locations["school"]; current_state <- "onTheWay";}
		}
		else if age>19 and age<=34{
			if current_date.hour>19{current_objective <- locations["home"]; current_state <- "onTheWay";}
			if current_date.hour>6{current_objective <- locations["work"]; current_state <- "onTheWay";}
		}
		else if age>34 and age<=54{
			if current_date.hour>19{current_objective <- locations["home"]; current_state <- "onTheWay";}
			if current_date.hour>6{current_objective <- locations["work"]; current_state <- "onTheWay";}
		}
		else if age>54 and age<=64{
			if current_date.hour>13{current_objective <- locations["home"]; current_state <- "onTheWay";}
			if current_date.hour>8{current_objective <- locations["work"]; current_state <- "onTheWay";}
		}
		else if age>64{}
	}
	reflex execute_routine when:current_state="onTheWay"{
		if location = {current_objective.x,current_objective.y}{current_state <- "stay";}
		do goto target:current_objective on:road_network recompute_path:false move_weights:weight_map;
	}
	
	aspect plain{
		rgb safety_color <- #yellow;
		draw circle(3.0) color: safety_color at:{location.x,location.y,0};
	}
	aspect terrain{
		float loc_x <- location.x;
		float loc_y <- location.y;
		cell tmp_cell <- cell({loc_x,loc_y});
		//agent tmp_cell <- cell grid_at {int(loc_x/length(grid[0])),int(loc_y/length(grid))};
		float loc_z <- tmp_cell.grid_value;
		point location_3d <- {loc_x,loc_y,loc_z};
		//rgb safety_color <- rgb (255-(255*safety_perception), safety_perception*255, 0,200);
		rgb safety_color <- #yellow;
		draw sphere(1.0) color: safety_color at:location_3d;
		if(showPerception){draw circle(vision_radius) border:safety_color empty:true;}
	}
}

species police_patrol skills:[moving]{ //for indicator "police_patrols_range"
	point target;
	image_file car;
	path route;
	init{
		location <- any_location_in(one_of(road));
		target <- any_location_in(one_of(road));
		do rebuildPath;
	}
	action move{
		if location = target{
			target <- any_location_in(one_of(road));
			do rebuildPath;
		}
		do follow path:route move_weights:route.edges as_map(each::each.perimeter);
		location <- {location.x,location.y};
	}
	action rebuildPath{
		route <- path_between(road_network, location, target);
		loop while: route = nil{
			route <- path_between(road_network, location, target);	
		}
	}
	aspect car{
		draw rectangle(3,2) color:#red;
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
	aspect default{
		draw circle(mod(cycle,10)+10) color:rgb (245, 66, 14,125);
	}
}

experiment Plain_test type:gui{
	output{
		/*display dem type:opengl{
			graphics "elevation"{
				draw dem(dem_file,terrain_texture,0.1);
			}
		}*/
		display gridWithElevationTriangulated type: opengl {
			//grid cell elevation: grid_value triangulation: true refresh:false;
			species road aspect:white refresh:false;
			species crime aspect:default;
			//species building aspect:default refresh:false;
			species people aspect:plain;
		}
	}
}

experiment Simulation type:gui{
	
	output{
		
		layout #split;
		display main background:#black type:opengl{
			graphics "interaction_graph" {
				if interaction_graph != nil and showInteractions {
					loop eg over: interaction_graph.edges {
						people src <- interaction_graph source_of eg;
						people target <- interaction_graph target_of eg;
						geometry edge_geom <- geometry(eg);
						draw line(edge_geom.points) color: rgb(0, 125, 0, 75);
					}
				}
				if showInteractions{
					loop person over: people{
						loop connection over:person.social_circle{
							draw curve(person.location, connection.location,0.5, 200, 90) color:rgb (79, 194, 210,100);
						} 
					}
				}
			}
			grid cell elevation:grid_value texture:terrain_texture triangulation:true refresh:false;
			species building aspect:terrain refresh:false;	
			species people aspect:terrain;
			overlay position: { 10, 10 } size: { 0.7,0.3 } background: # black border: #black rounded: true{
                float y <- 30#px;
               	draw ".:-0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" at: {0#px,0#px} color:rgb(0,0,0,0) font: font("SansSerif", 20, #plain);
                draw "People: " +  length(people) at: { 40#px, y + 10#px } color: #white font: font("SansSerif", 20, #plain);
                draw "Time: "+current_date[3]+":"+current_date[4] at:{ 40#px, y + 50#px} color:#white font:font("SansSerif",20, #plain);
                draw "Sunlight: "+ sunlight at:{ 40#px, y + 70#px} color:#white font:font("SansSerif",20, #plain);
               /*draw square(flux_node_size) color:#mediumseagreen at:{50#px, y+30#px};
				draw "Flux I/O" at:{50+30#px, y+30#px}  color: #white font: font("SansSerif", 15);
				draw square(flux_node_size) at:{50#px, y+60#px} color: rgb (232, 64, 126,255) border: #maroon;
				draw "Interland" at:{50+30#px, y+60#px}  color: #white font: font("SansSerif", 15);
				draw "Tejido Social" at:{600#px, 10#px} color: #white font: font("SansSerif", 25);*/
            }
		}
		
	}
}

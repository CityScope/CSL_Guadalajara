/**
 *  Social Fabric Model 
 *  Author: Gamaliel Palomo and Arnaud Grignard
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
	bool showInteractions parameter: "Show encounters" category:"Model" <- false;
	float agentSpeed parameter: "Agents Speed" category: "Model" <- 1.4 min:0.5 max: 10.0;
	//Visualization parameters
	bool showPerception parameter: "Show perception" category: "Visualization" <- false;
	
	graph road_network;
	map<road, float> weight_map;
	map<string, rgb> color_type <- ["offender"::rgb(255,255,0), "victim"::rgb (255, 0, 255), "people"::rgb (10, 192, 83,255)];
	
	//people
	int nbpeoples <- 0;
	int flux_node_size <- 20;
	list<flux_node> source_places <- [];
	list<flux_node> sink_places <- [];
	int fluxid <- 1;
	map<list<flux_node>,path> paths <- nil;
	graph<people,people> interaction_graph;
	
	//SUNLIGHT
	float sunlight <- 0.0 update:-0.025*(list(current_date)[3]+(list(current_date)[4]/60)-13)^2+1; //Estimated function to get the sunlight [0.0 to 1.0]

	date starting_date <- date([2020,3,3,6,30,0]);
	file roads_file <- file("/gis/"+case_study+"/roads.shp");
	geometry shape <- envelope(roads_file);
	init{
		
		file blocks_file <- nil;
		file block_fronts_file <- nil;
		file places_file <- nil;
		file interlands_file;
		
		string inputFileName <- "";
		
		inputFileName <- "/gis/"+case_study+"/blocks.shp";
		if file_exists(inputFileName){ blocks_file <- file(inputFileName);}
		
		inputFileName <- "/gis/"+case_study+"/block_fronts.shp";
		if file_exists(inputFileName){ block_fronts_file <- file(inputFileName);}
		
		inputFileName <- "/gis/"+case_study+"/places.shp";
		if file_exists(inputFileName){ places_file <- file(inputFileName);}
		
		inputFileName <- "/gis/"+case_study+"/interlands.shp";
		if file_exists(inputFileName){ interlands_file <- file(inputFileName);}
		
		
		
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
		do mapValues;
		create places from: interlands_file with:[type::"interland"]{do interactWithroads;}				
		weight_map <- road as_map(each::each.valuation);
		road_network <- as_edge_graph(road);
		create police_patrol number:10{location <- any_location_in(one_of(road));}
	
	
		create flux_node from: file("/gis/"+case_study+"/flux.shp") with:[id::int(read("id")),way::string(read("way"))];
		if length(flux_node where(each.way="input"))=0{
			create flux_node with:[id::-1,way::"input",location::one_of(road_network.vertices)]{fluxid<-fluxid+1;}
		}
		if length(flux_node where(each.way="output"))=0{
			create flux_node with:[id::0,way::"output",location::one_of(road_network.vertices)]{fluxid<-fluxid+1;}
		}
		create women number:100;
		write "Total of roads: "+length(road); 
	}
	
	reflex main{
		//create women number:1;
	}
	user_command "police_patrol"{
		point newPoint <- #user_location;
		create police_patrol with:[location::newPoint];
	}
	user_command "source_place here"{
		point newPoint <- #user_location;
		create flux_node with:[id::fluxid,way::"input",location::newPoint]{fluxid<-fluxid+1;}
	}
	user_command "sink_place here"{
		point newPoint <- #user_location;
		create flux_node with:[id::fluxid,way::"output",location::newPoint]{fluxid<-fluxid+1;}
	}
	user_command "interland"{
		create places{
			type <- "interland";
			location <- #user_location;
			do interactWithroads;
		}
		weight_map <- road as_map(each::each.valuation);
		do rebuildPaths;
	}
	action rebuildPaths{
		loop keylist over:paths.keys{
			put path_between(road_network with_weights weight_map, keylist[0], keylist[1]) at:keylist in:paths;
		}
	}
	action mapValues{
	//Information about roads condition is in block fronts file, copy it to road species.
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

species flux_node{
	int id;
	string way;
	aspect default{
		//draw way="input"?square(flux_node_size):triangle(flux_node_size) color:way="input"?#mediumseagreen:#crimson;
		draw square(flux_node_size) color:#mediumseagreen;
	}
}

species flux_node_ mirrors:flux_node{
	aspect default{
		draw circle(15) color:rgb (77, 107, 251,255);
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
	aspect gray{draw shape color: rgb (174, 174, 174,200);}
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
	aspect gray_scale{draw shape color: rgb(sunlight*valuation*180,sunlight*valuation*180,sunlight*valuation*180,180);}
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

species people skills:[moving]{
	point target; //importar datos de csv para rutinas, relaciones, perfil.
	map<string,float> indicators_values;  //indicator->value
	map<string,float> indicators_weights; //indicator->weight
	float safety_perception;
	float vision_ratio;
	init{
		safety_perception <- 0.0;
		vision_ratio <- 50.0#m;
	}
	reflex update_perception{
		float sum<-0.0;
		loop auxKey over:indicators_values.keys{
			sum <- sum + indicators_values[auxKey]*indicators_weights[auxKey];
		}
		safety_perception <- sum;
	}
	reflex update_indicators{
		//In this function, all environmental indicators are perceived by the agent. Only indicators_values are updated here.
		//The importance of these indicators_values depends on every agent profile (women, men, child, etc.).
		
		//C1__FORMAL SURVEILLANCE
		//police_patrols_range
		list<police_patrol> auxPolice <- police_patrol at_distance(vision_ratio);
		put auxPolice!=[]? 1.0:0.0 at:"police_patrols" in:indicators_values;
		
		//C2__ARTIFICIAL LIGHTING
		//lighting_uniformity_ratio
			//TO DO: differenciate between daytime and nighttime
		list<road> auxLighting <- road at_distance(vision_ratio);
		put auxLighting!=[]? auxLighting[0].float_lightning:0.0 at:"lighting_uniformity_ratio" in:indicators_values;
		
		//C7__MAINTENANCE
		//pavement_condition
		list<road> auxPavement <- road at_distance(vision_ratio);
		put auxPavement!=[]? auxPavement[0].float_paving:0.0 at:"pavement_condition" in:indicators_values;
		
		//C1__NATURAL SURVEILLANCE
		//active_pedestrians (interaction)
			//1.número de personas que interactúan - Radio 1
				// M+W+N+N    +  M
				// W+N+N    + car   (kidnapping)
				// relación de los agentes niños con agentes adultos por ciertas horas del día
			//2.si se conocen o no - Radio 2   (definir en la descripción de los agentes)
			//3.Si no se conocen: W-M   Si se conocen: W-W		
	}
}

species women parent:people{
	map<string,point> activities_locations;
	path current_route;
	string current_state;
	point current_objective_location;
	
	init{
		/*ROUTINE
		 *Possible activities: staying, on_the_way.
		* */ 
		add "police_patrols"::0.45 to:indicators_weights;
		add "lighting_uniformity_ratio"::0.45 to:indicators_weights;
		add "pavement_condition"::0.1 to:indicators_weights;
		add "home"::any_location_in(one_of(road)) to: activities_locations;
		add "work"::any_location_in(one_of(road)) to: activities_locations;
		add "leisure"::any_location_in(one_of(road)) to: activities_locations;
		current_state <- "stay";
		safety_perception <- 0.0;
		vision_ratio <- 50.0#m;
		location <- activities_locations["home"];
	}
	reflex make_routine{
		//People give indicators different values depending on the hour of the day.
		if list(current_date)[3] >= 7 and list(current_date)[3] < 17 and current_state = "stay"{
			//morning
			current_objective_location <- activities_locations["work"];
			current_route <- path_between(road_network, location, current_objective_location);
			current_state <- "on_the_way";
			
		}
		else if list(current_date)[3] >= 17 and list(current_date)[3] < 21 and current_state = "stay"{
			//time to go
			current_objective_location <- activities_locations["leisure"];
			current_route <- path_between(road_network, location, current_objective_location);
			current_state <- "on_the_way";
		}
		else if list(current_date)[3] >= 21 and current_state = "stay" or list(current_date)[3] < 7 and current_state = "stay"{
			//time to go home
			current_objective_location <- activities_locations["home"];
			current_route <- path_between(road_network, location, current_objective_location);
			current_state <- "on_the_way";
		}
		
	}
	reflex execute_routine{
		if location = current_objective_location{
			current_state <- "stay";
		}
		if current_state = "on_the_way"{
			do follow path:current_route move_weights:current_route.edges as_map(each::each.perimeter);
		}
		else if current_state = "stay"{
			do wander;
		}
	}
	aspect default{
		rgb safety_color <- rgb (255-(255*safety_perception), safety_perception*255, 0,200);
		draw circle(0.65) color: safety_color;
		if(showPerception){draw circle(vision_ratio) border:safety_color empty:true;}
	}
}

species man parent:people{
}

species police_patrol skills:[moving]{ //for indicator "police_patrols_range"
	list<point> destinations;
	image_file car;
	init{}
	reflex moving{
		do wander;
	}
	aspect car{
		draw rectangle(3,2) color:#red;
	}
}

experiment Flow type:gui parallel:false {
	
	output{
		
		layout #split;
		display environment background:#black type:opengl draw_env:false name:"Tejido Social" ambient_light:sunlight{
			graphics "interaction_graph" {
				if (interaction_graph != nil and (showInteractions = true)) {
					loop eg over: interaction_graph.edges {
						people src <- interaction_graph source_of eg;
						people target <- interaction_graph target_of eg;
						geometry edge_geom <- geometry(eg);
						draw line(edge_geom.points) color: rgb(0, 125, 0, 75);
					}
				}

			}
			species block aspect:gray_scale;
			species women aspect:default;
			species police_patrol aspect:car;
			overlay position: { 10, 10 } size: { 50 #px, 50 #px } background: # black border: #black rounded: true{
                float y <- 30#px;
                draw "Women: " +  length(women) at: { 40#px, y + 5#px } color: #white font: font("SansSerif", 15);
                draw "Men: " +  length(man) at: { 40#px, y + 20#px } color: #white font: font("SansSerif", 15);
                draw "Time: "+  current_date at:{ 40#px, y + 40#px} color:#white font:font("SansSerif",15);
                draw "Sunlight: "+ sunlight at:{ 40#px, y + 60#px} color:#white font:font("SansSerif",15);
				/*draw square(flux_node_size) color:#mediumseagreen at:{50#px, y+30#px};
				draw "Flux I/O" at:{50+30#px, y+30#px}  color: #white font: font("SansSerif", 15);
				draw square(flux_node_size) at:{50#px, y+60#px} color: rgb (232, 64, 126,255) border: #maroon;
				draw "Interland" at:{50+30#px, y+60#px}  color: #white font: font("SansSerif", 15);
				draw "Tejido Social" at:{600#px, 10#px} color: #white font: font("SansSerif", 25);*/
            }
		}
		/*
		display network background:#black type:opengl name:"Network analysis" draw_env:false{
			graphics "nodes"{
            	point reference <- location;
            	map<flux_node,flux_node_> location_translation;
            	int diameter <- 300;
            	int n <- length(flux_node);
            	float alpha <- 360/n;
            	loop it from: 0 to:n-1{
            		point point_location <- (location+{diameter*cos(alpha*it),diameter*sin(alpha*it)});
            		ask flux_node_[it]{location <- point_location;}
            		add flux_node[it]::flux_node_[it] to:location_translation;
            	}
            	loop key over:paths.keys{
            		geometry edge <- curve(location_translation[key[0]].location,location_translation[key[1]].location, 0.5, 200, 90);
            		draw edge color:#green;
	            }
			}
			species flux_node_ aspect:default refresh:false;
		}*/
	}
}

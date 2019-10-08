/**
 *  Social Fabric Model 
 *  Author: Gamaliel Palomo and Arnaud Grignard
 *  Description: Model for Social Fabric. This approach follows the idea that social interactions depend on the physical layer of an urban space. 
 * 				This means that if the infrastructure conditions (lightning, paving, etc) are good for an agent's perception, this will prefer to
 * 				walk through this space and it will feel confortable, and social interactions emerge as a result.
 */

model SocialFabric
global torus:false{

	//Initialization parameters 
	string case_study parameter: "Case study:" category: "Initialization" <-"Centinela" among:["Centinela", "Miramar", "Tijuana"];
	int nbAgents parameter: "Number of agents" category: "Initialization" <-200 min:50 max: 1000;
	bool allowRoadsKnowledge parameter: "Allow knoledge" category: "Initialization" <- false;
	//Model parameters
	bool showInteractions parameter: "Interactions" category:"Model" <- false;
	int interactionDistance parameter: "Interaction distance" category:"Model" <- 50 min: 50 max: 500;
	float agentSpeed parameter: "Agents Speed" category: "Model" <- 1.4 min:0.5 max: 10.0;
	//Visualization parameters
	bool showPerception parameter: "Show perception" category: "Visualization" <- false;
	bool showPlace parameter: "Show Places" category: "Visualization" <- false;
	int agentSize parameter: "Agents Size" category: "Visualization" <- 15 min: 5 max: 50;
	
	int timeStep;
	graph road_network;
	map<road, float> weight_map;
	list<int> usedRoads;
	
	//Output variables
	int encounters;
	float maxEncounters;
	int lights;
	int paving;
	int sideWalks;

	date starting_date <- date("now");

	file roads_file <- file("/gis/"+case_study+"/roads.shp");
	file blocks_file <- file("/gis/"+case_study+"/blocks.shp");
	file block_fronts_file <- file("/gis/"+case_study+"/block_fronts.shp");
	file places_file <- file("/gis/"+case_study+"/places.shp");
	geometry shape <- envelope(roads_file);
	

	init{
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
			
		}
		create block_front from:block_fronts_file with:[block_frontID::string(read("CVEGEO")), int_lightning::int(read("ALUMPUB_")), int_paving::int(read("RECUCALL_")), int_sideWalk::int(read("BANQUETA_")), int_access::int(read("ACESOPER_"))]{ do init_condition; }
		create road from:roads_file{ do init_condition;	}
		create places from: places_file with:[id::string(read("id")),name_str::string(read("nom_estab"))];			
		weight_map <- road as_map(each::each.valuation);
		road_network <- as_edge_graph(road);
		usedRoads <- list_with(length(road_network),-1);
		create people number:nbAgents;
		maxEncounters <- nbAgents*(nbAgents-1)/2;
		write "Total of places: "+length(places);
		write "Total of roads: "+length(road); 
	}
	
	reflex main{
		//Compute encounters-related variables
		encounters <- length(list(relationships));
		//Compute perception-related variables
	}
	
}


species road{
	string road_name;
	float valuation;
	float weight;
	int int_lightning;
	int int_paving;
	int int_sideWalk;
	int int_access;
	action init_condition{
		valuation <- 0.0;
		list nearBlockFronts;
		nearBlockFronts <- block_front at_distance(50);
		if length(nearBlockFronts)>0{
			block_front tmpBlockFront <- one_of(nearBlockFronts);
			valuation <- tmpBlockFront.valuation;
			int_lightning <- tmpBlockFront.int_lightning;
			int_paving <- tmpBlockFront.int_paving;
			int_sideWalk <- tmpBlockFront.int_sideWalk;
			int_access <- tmpBlockFront.int_access;
			if int_access = 0{valuation <- 0.0;}
		}
		weight <- valuation / 2; //Normalization of valuation 0 to 1 according to the model
		weight <- 100*(1 - weight); //In weighted networks, a path is shorter than other if it has smaller value. 0 <- best road, 1 <- worst road
	}
	aspect default{draw shape color: rgb(255-(127*valuation),0+(127*valuation),50,255);}
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
	aspect default{	draw shape color: rgb(255-(127*int_lightning),0+(127*int_lightning),50,255);}
	aspect simple{ draw shape color: rgb (218, 179, 61,120);}
}

species block_front{
	string block_frontID;
	int int_lightning;
	int int_paving;
	int int_sideWalk;
	int int_access;
	float valuation;
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
	init{ height <- float(50+rnd(100)); }
	aspect default{ 
		if(showPlace){
		  draw geometry:square(50#m)  color:rgb (86, 140, 158,255) border:#indigo depth:height;	
		}
	}
}

species targets{ aspect name:default{ draw geometry:triangle(100#m) color:rgb("red");  } }

species people skills:[moving] parent: graph_node edge_species: relationships{
	int routineCount;
	point target;
	path shortestPath;
	map<road, float> roads_knowledge;
	list<places> routine;
	
	init{
		routineCount <- 0;
		roads_knowledge <- weight_map;
		speed <- agentSpeed;
		do buildRoutine;
		do updateTarget;
		loop while: shortestPath = nil or shortestPath = []{
			routine[routineCount] <- places[rnd(length(places)-1)];
			target <- routine[routineCount].location;
			do updateShortestPath;
		}
		create targets{ location <- myself.target; }
	}
	bool related_to(people other){
	  	using topology:topology(world) {return (self.location distance_to other.location < interactionDistance);}
	}
	action buildRoutine{
		int tmpRnd <- rnd(length(places)-1);
		add places[tmpRnd] to:routine;
		location <- routine[0].location;
		loop times: 2{
			seed <- rnd(100.0);
			tmpRnd <- rnd(length(places));
			add places[tmpRnd] to: routine;
		}
	}
	action updateTarget{
		if length(routine)-1 = routineCount{
			target <- routine[0].location;
			routineCount <- 0;
		}else{
			routineCount <- routineCount + 1;
			target <- routine[routineCount].location;	
		}
		do updateShortestPath;
	}
	action updateShortestPath{
		if allowRoadsKnowledge{ shortestPath <- path_between(road_network with_weights roads_knowledge, location, target); }
		else{ shortestPath <- path_between(road_network, location, target); }
	}
	reflex move{
		speed <- agentSpeed;
		do follow path:shortestPath move_weights: shortestPath.edges as_map(each::each.perimeter);
		if(location = target){
			do updateTarget;
			loop while: shortestPath = nil or shortestPath = []{
				routine[routineCount] <- places[rnd(length(places)-1)];
				target <- routine[routineCount].location;
				do updateShortestPath;
			}
			ask targets{ location<-myself.target; }
		}
		
	}
	aspect name:default{ draw geometry:circle(agentSize#m) color:rgb (255, 242, 9,255); }
}

species relationships parent: base_edge {aspect default {if showInteractions{draw shape color:#blue;}}}

experiment GUI type:gui{
	parameter "Roads_Knowledge" var: allowRoadsKnowledge  <- false;
	output{
		layout #split;
		display Main type:opengl ambient_light:50{
			species block aspect:default;
			species people aspect:default;
			species relationships aspect:default;
		}
		display Output type:opengl{
			chart "Current state" type: radar position:{5,5} background: # black x_serie_labels: [ "+ Encounters", "- Encounters", "+ Safety perception", "- Safety perception", "Segregation"] color:#white series_label_position: xaxis
			{
				data "Encounters" value: [encounters/maxEncounters,1,1,1,1] color: # green;
			}
		}
	}
}
experiment Batch type:batch repeat:100 keep_seed:true until:(time>3600){
	parameter "Roads_Knowledge" var: allowRoadsKnowledge  <- true;
}
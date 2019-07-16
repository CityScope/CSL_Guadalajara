/**
 *  Social Fabric Model 
 *  Author: Gamaliel Palomo and Arnaud Grignard
 *  Description: Model for Social Fabric. This approach follows the idea that social interactions depend on the physical layer of an urban space. 
 * 				This means that if the infrastructure conditions (lightning, paving, etc) are good for an agent's perception, this will prefer to
 * 				walk through this space and it will feel confortable, and social interactions emerge as a result.
 */

model SocialFabric

global torus:false{
	
	//Declaration of the global variables
	//Model parameters 
	int numAgents <- 500;
	bool allowRoadsKnowledge <- true;
	float agentSpeed <- 1.4; //This is the mean walk speed of a person.
	int agentSize <- 15;
	bool dodie; //The simulation has to die when the file is written.
	
	int sumEncounters;
	int acumEncounters;
	int meanEncounters;
	int timeStep;
	float distanceForInteraction;
	graph road_network;
	map<road, float> weight_map;
	list<int> usedRoads;
	
	date starting_date <- date([2019,7,1,20,0,0]);

	file roads_file <- file("/gis/test/test.shp");
	file blocks_file <- file("/gis/test/manzanas.shp");
	file block_fronts_file <- file("/gis/test/frente_de_manzanas.shp");
	file places_file <- file("/gis/test/interest.shp");
	geometry shape <- envelope(roads_file);
	
	string outputFile <- "/output/output.txt";
	
	//The graph for the representation of the relations between people in the physical space
	graph Encounters <- graph([]);
	float networkDensity <- 0.0;
	float maxNumOfEdges;
	
	reflex output when: time=3600{
		int tmpCounter <- 0;
		loop i from:0 to: length(usedRoads)-1{
			if usedRoads[i]=1{	
				tmpCounter <- tmpCounter + 1;
			}
		}
		save tmpCounter type:text to:outputFile rewrite:false;
	}
	action updateGraph{
		Encounters <- graph([]);
		ask people{
			loop contact over:self.pEncounters{
				if !(Encounters contains_edge (self::contact)){ Encounters <- Encounters add_edge(self::contact); }
			}
		}
	}
	init{
		create block from:blocks_file with:[blockID::string(read("CVEGEO")), str_lightning::string(read("ALUMPUB_C"))]{
			if str_lightning = "Todas las vialidades"{ int_lightning <- 2; }
			else if str_lightning = "Alguna vialidad"{ int_lightning <- 1; }
			else{ int_lightning <- 0; }
		}
		create block_front from:block_fronts_file with:[block_frontID::string(read("CVEGEO")), int_lightning::int(read("ALUMPUB_")), int_paving::int(read("RECUCALL_")), int_sideWalk::int(read("BANQUETA_")), int_access::int(read("ACESOPER_"))]{ do init_condition; }
		create road from:roads_file{ do init_condition;	}
		create places from: places_file with:[id::string(read("id")),name_str::string(read("nom_estab")),economic_activity::string(read(""))];			
		weight_map <- road as_map(each::each.valuation);
		road_network <- as_edge_graph(road);
		usedRoads <- list_with(length(road_network),-1);
		create people number:numAgents{ add node(self) to: Encounters; }
	}
}

grid cell width:world.shape.width/100 height:world.shape.height/100{
	int attractivity;
	action initialize{
		attractivity <- 0;
		int result<-0;
		ask block_front inside self{
			result <- result + int_lightning;
		}
		if length(block_front inside self)>0 { attractivity <- int(result / length(block_front inside self)); }
		else{ attractivity <- 0; }
	}
	aspect default{
		draw shape color:rgb(0,100*attractivity,0,200);
	}
}

species road{
	string road_type;
	string road_name;
	float valuation;
	float weight;
	int int_lightning;
	int int_paving;
	int int_sideWalk;
	int int_access;
	float weight_value;
	bool using;
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
		weight <- 100*(1 - weight); //In weighted networks, a path is shorted than other if it has smaller value. 0 <- best road, 1 <- worst road
	}
	aspect default{
		draw shape color: rgb(255-(127*valuation),0+(127*valuation),50,255);
	}
	aspect gray{
		draw shape color: rgb (174, 174, 174,200);
	}
}

species block{
	string blockID;
	string str_lightning;
	int int_lightning;
	aspect default{	draw shape color: rgb(255-(127*int_lightning),0+(127*int_lightning),50,255) depth:rnd(30);}
	aspect simple{ draw shape color: rgb (218, 179, 61,120) depth:0;}
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
	string economic_activity;
	float height;
	init{ height <- float(50+rnd(100)); }
	aspect default{ draw geometry:square(60#m)  color:rgb (86, 140, 158,255) border:#indigo depth:height; }
}

species targets{ aspect default{ draw geometry:triangle(agentSize#m) color:rgb("red"); } }

species people skills:[moving]{
	int routineCount;
	bool interacting;
	list pEncounters;
	point target;
	path shortestPath;
	map<road, float> roads_knowledge;
	list<places> routine;
	bool onTheWay;
	
	init{
		onTheWay <- false;
		routineCount <- 0;
		roads_knowledge <- weight_map;
		interacting <- false;
		speed <- agentSpeed;
		do buildRoutine;
		do updateTarget;
		loop while: shortestPath = nil or shortestPath = []{
				routine[routineCount] <- one_of(places at_distance(2#km));
				target <- routine[routineCount].location;
				do updateShortestPath;
			}
		create targets{ location <- myself.target; }
		pEncounters <- [];
	}
	action buildRoutine{ 
		add one_of(places) to:routine;
		location <- routine[0].location;
		loop times: 2{ add one_of(places at_distance(2#km)) to: routine; }
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
		do follow path:shortestPath move_weights: shortestPath.edges as_map(each::each.perimeter);
		if(location = target){
			do updateTarget;
			loop while: shortestPath = nil or shortestPath = []{
				routine[routineCount] <- one_of(places at_distance(2#km));
				target <- routine[routineCount].location;
				do updateShortestPath;
			}
			ask targets{ location<-myself.target; }
		}
		if current_edge=nil or string(current_edge)="" {write name+": Current edge is nil";}
		else{
			//write length(usedRoads);
			string tmpStr <- replace(string(current_edge),"road(","");
			tmpStr <- replace(tmpStr,")","");
			int tmpInt <- int(tmpStr);
			if !(usedRoads contains tmpInt){usedRoads[tmpInt] <- 1;}
		}
		//usedRoads(tmpRoad) <- 1;
		/*pEncounters <- people at_distance(distanceForInteraction) where(each != self);
		if length(pEncounters) > 0{ self.interacting <- true; }
		else{ self.interacting<-false; }*/
	}
	aspect name:default{ draw geometry:circle(agentSize#m) color:rgb (255, 242, 9,255); }
}

experiment GUI type:gui{
	parameter var:dodie <- true;
	output{
		layout #split;
		display Main type:opengl ambient_light:50{
			species block aspect:default refresh:false;
			species people aspect:default;
		}
		/*display Mobility type:opengl ambient_light:100{
			graphics "paths"{
				loop person over:people{
					if person.shortestPath != nil{draw person.shortestPath.shape color:rgb (255, 0, 128,255) width:2.0;}
				}
			}
			species road aspect:gray refresh:false;
		}*/
	}
}
experiment Batch_StreetsUsage type:batch repeat:10 keep_seed:true until:(time>3600){
	
}
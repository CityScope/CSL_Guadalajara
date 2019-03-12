/***
* Name: Violence
* Author: gamalielpalomo
* Description: This GAMA model implements a ABM model for violence based on the Levy equation for movements.
* Tags: Tag1, Tag2, TagN
***/

model Violence

global torus:false{
	int crimes;
	float mu parameter: 'Mu:' category: 'Model' <- 1.0 min: 0.0 max: 2.0; 
	graph road_network;
	string case_study <- "centinela" ;
	file<geometry> osmfile <- osm_file("/gis/"+case_study + "/" +case_study +".osm");
	file hospitals_file <- file("gis/"+case_study+"/"+"hospitals"+".shp");
	file transport_file <- file("gis/"+case_study+"/"+"transport"+".shp");
	file proposal_file <- file("gis/"+case_study+"/"+"proposal"+".shp");
	file proposal_file2 <- file("gis/"+case_study+"/"+"proposal_interno"+".shp");
	//file neighborhood <- file("gis/case_study/neighborhood.shp");
	geometry shape <- envelope(osmfile);
	float maxDistance <- sqrt(world.shape.width^2+world.shape.height^2)#m;
	transport busRoute;
		
	init{
		crimes <- 0;
		mu <- 1.0;
		create osm_agent from:osmfile with:[name_str::string(read("name")), type_str::string(read("highway"))]{
			if(type_str != nil and type_str != "" and type_str != "turning_circle" and type_str != "traffic_signals" and type_str != "bus_stop"){
				create road with: [shape::shape, type::type_str, name_str::name_str];
			}
			do die;
		}
		
		road_network <- as_edge_graph(road);
		//create suburb from:neighborhood with:[name_str::string(read(name))];
		create transport from:transport_file with:[name_str::string(read("name"))];
		//create transport from:proposal_file with:[name_str::string(read("name_str"))];
		create transport from:proposal_file2 with:[name_str::string(read("name_str"))];
		create hospital from:hospitals_file with:[name_str::string(read("name_str"))];
		create people number:250;
		
		//busRoute <- one_of(transport where(each.name_str = "637"));
		ask cell{
			do computeClosestRoute;
			do computeDistance;
		}
	}
	reflex main{
		ask cell where(each.distance<800){
			do computeNearIndex;
		}
	}
}

species osm_agent{
	string name_str;
	string type_str;
}

grid cell width:world.shape.width/100 height:world.shape.height/100{
	int near_index;
	float distance;
	transport closestRoute;
	int tension; //Tension is refered as the perception of security, and its value depends on social and environmental factors 
				 // such as crimes commited and physical layer conditions. 
	init{
		near_index <- 0;
		tension <- 0;
		distance <- 0.0;
	}
	aspect connectionIndex{
		draw shape color:rgb(0,int(near_index*2.56),0,100);
	}
	aspect tension{
		draw shape color:rgb(tension*50, 0, 0) border:rgb(tension*50, 0, 0) empty:false;
	}
	action computeDistance{
		using topology(world){
			distance <- distance_to(self,closestRoute);
		}
	}
	action computeClosestRoute{
		using topology(world){
			closestRoute <- transport closest_to(self);
			//closestRoute <- one_of(transport);
		}
	}
	action computeNearIndex{
		//road closestRoad <- list(road) closest_to(centroid(self));
		//road closestRoad <- list(road) closest_to(centroid(self));
		
		if closestRoute != nil{
			using topology(world){
				float ratio <- distance/1000;
				float index <- 1-ratio;
				near_index <- int(index*50);			
			}
		}
		else{
			write "Bus route error";
		}
	}
}

species road{
	string name_str;
	string type;
	
	aspect default{
		draw shape color:rgb (121, 121, 121,255);
	}
}

species transport{
	string name_str;
	aspect default{
		draw shape color:rgb (27, 90, 186,255) width:4.0;
	}
}

species hospital{
	image_file icon;
	string name_str;
	init {
		icon <- file("img/health.png");
	}
	aspect default{
		draw icon size:100;
	}	
}

species people skills:[moving]{
	point target;
	bool victimized;
	init{
		victimized <- false;
		target 		<- any_location_in(one_of(road));
		location 	<- any_location_in(one_of(road));
		speed <- 1.39;
	}
	reflex move{
		if(location = target or path_between(road_network,location,target)=nil){
			location <- location + 1;
			target <- any_location_in(one_of(road));
		}
		do goto on:road_network target:target speed:10.0;
	}
	
	aspect default{
		if (victimized = true){
	      draw circle(35) color:rgb (255, 0, 255,255) ;
		}
		else{
		  draw circle(15) color:rgb (10, 192, 83,255);	
		}
	}
}

experiment raw type:gui{
	output{
		display view type:opengl background:#black{
			species road;
			species transport;
			species hospital;
			species people;
			species cell aspect:connectionIndex;
		}
	}
}

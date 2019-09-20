/***
* Name: Violence
* Author: gamalielpalomo
* Description: This model is an agent-based visualization, to show the connectivity as a heatmap for any transport network
* In this current model the current transport network (in blue) and the proposed one (in yellow) are instantiated. 
* Tags: Tag1, Tag2, TagN
***/

model Violence

global torus:false{
	string case_study <- "centinela" ;
	file<geometry> osmfile <- osm_file("../gis/"+case_study + "/" +case_study +".osm");
	file hospitals_file <- file("../gis/"+case_study+"/"+"hospitals"+".shp");
	file transport_file <- file("../gis/"+case_study+"/"+"transport"+".shp");
	file proposal_file <- file("../gis/"+case_study+"/"+"proposal"+".shp");
	file proposal_file2 <- file("../gis/"+case_study+"/"+"proposal_interno"+".shp");
	geometry shape <- envelope(osmfile);
	float maxDistance <- sqrt(world.shape.width^2+world.shape.height^2)#m;
	transport busRoute;
		
	init{
		// Initial step to create road from the osm file (whcih contains more elements than just the road)
		create osm_agent from:osmfile with:[name_str::string(read("name")), type_str::string(read("highway"))]{
			if(type_str != nil and type_str != "" and type_str != "turning_circle" and type_str != "traffic_signals" and type_str != "bus_stop"){
				create road with: [shape::shape, type::type_str, name_str::name_str];
			}
			do die;
		}
		create transport from:transport_file with:[name_str::string(read("name")),type::"current",color::#blue];
		create transport from:proposal_file with:[name_str::string(read("name_str")),type::"proposal",color::#yellow];
		create transport from:proposal_file2 with:[name_str::string(read("name_str")),type::"proposal",color::#red];
		create hospital from:hospitals_file with:[name_str::string(read("name_str"))];
		
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
		distance <- 0.0;
	}
	aspect connectionIndex{
		draw shape color:rgb(0,int(near_index*2.56),0,100);
	}

	action computeDistance{
		using topology(world){
			distance <- distance_to(self,closestRoute);
		}
	}
	action computeClosestRoute{
		using topology(world){
			closestRoute <- transport closest_to(self);
		}
	}
	action computeNearIndex{		
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
	string type;
	rgb color;
	aspect default{
		draw shape color:color width:4.0;
	}
}

species hospital{
	image_file icon;
	string name_str;
	init {
		icon <- file("../img/health.png");
	}
	aspect default{
		draw icon size:100;
	}	
}

experiment raw type:gui{
	output{
		display connectionIndex type:opengl background:#black{
			species road;
			species transport;
			species hospital;
			species cell aspect:connectionIndex;
		}
	}
}

/***
* Name: Violence
* Author: gamalielpalomo
* Description: This GAMA model implements a ABM model for violence based on the Levy equation for movements.
* Tags: Tag1, Tag2, TagN
***/

model Violence

/* Insert your model definition here */

global torus:false{
	graph road_network;
	file<geometry> roads <- osm_file("/gis/centinela/centinela.osm");
	geometry shape <- envelope(roads);	
	init{
		create osm_agent from:roads with:[name_str::string(read("name")), type_str::string(read("highway"))]{
			if(type_str != nil and type_str != "" and type_str != "turning_circle" and type_str != "traffic_signals" and type_str != "bus_stop"){
				create road with: [shape::shape, type::type_str, name::name_str];
			}
			do die;
		}
		road_network <- as_edge_graph(road);
		create people number:100;
	}
}

species osm_agent{
	string name_str;
	string type_str;
}

grid cell width:10 height:10{
	int current_people_inside;
	rgb current_color; 
	init{
		current_color <- #black;
	}
	reflex update{
		current_people_inside <- length(people inside self);
		if(current_people_inside >= 1){
			current_color <- #red;
		}
		else{current_color <- #black;}
	}
	aspect basic{
		draw square(world.shape.width/10) color:current_color border:rgb (255, 0, 128,255) width:2.0;
	}
}

species road{
	string name;
	string type;
}

species people skills:[moving]{
	point target;
	rgb current_color;
	int current_size;
	int attractive_cluster_size;
	init{
		current_color <- rgb (255, 255, 0,255);
		shape <- sphere(30);
		attractive_cluster_size <- rnd(10);
		target 		<- any_location_in(one_of(road));
		location 	<- any_location_in(one_of(road));	
	}
	reflex move{
		if(location = target or target = nil or path_between(road_network,location,target)=nil){
			cell tgt <- one_of(cell where (each.current_people_inside >= attractive_cluster_size) );
			if (tgt != nil){
				target <- any_location_in(tgt);
				current_color <- rgb (255, 0, 128,255);
			}
			else {
				target <- any_location_in(one_of(road));
				shape <- sphere(30);
				current_color <- rgb (255, 255, 0,255);
			}
		}
		do goto on:road_network target:target speed:3.0;
	}
}

experiment experiment1 type:gui{
	output{
		display display1 type:opengl{
			species cell aspect:basic transparency:0;
			graphics "people"{
				loop element over:people{
					draw element color:element.current_color;
				}
			}
			graphics "roads"{
				rgb road_Color <- rgb (199, 219, 241,255);
				loop element over:road{
					draw element color:road_Color;
				}
			}
		}
	}
}
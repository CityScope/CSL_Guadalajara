/***
* Name: Violence
* Author: gamalielpalomo
* Description: This GAMA model implements a ABM model for violence based on the Levy equation for movements.
* Tags: Tag1, Tag2, TagN
***/

model Violence

/* Insert your model definition here */

global torus:false{
	int crimes;
	int xCells;
	int yCells;
	float mu parameter: 'Mu:' category: 'Model' <- 1.0 min: 0.0 max: 2.0; 
	graph road_network;
	file<geometry> roads <- osm_file("/gis/centinela/centinela.osm");
	file neighborhood <- file("gis/centinela/neighborhood.shp");
	geometry shape <- envelope(roads);
		
	init{
		crimes <- 0;
		xCells <- 20;
		yCells <- 20;
		mu <- 1.0;
		create osm_agent from:roads with:[name_str::string(read("name")), type_str::string(read("highway"))]{
			if(type_str != nil and type_str != "" and type_str != "turning_circle" and type_str != "traffic_signals" and type_str != "bus_stop"){
				create road with: [shape::shape, type::type_str, name::name_str];
			}
			do die;
		}
		road_network <- as_edge_graph(road);
		create suburb from:neighborhood with:[name::string(read(name))];
		create people number:200{
			possibleOffender <- false;
			do updateProperties;
		}
		create people number: 10{
			possibleOffender <- true;
			do updateProperties;
		}
	}
	reflex update{
		ask cell{
			do updateState;
		}
	}
}

species osm_agent{
	string name_str;
	string type_str;
}

grid cell width:world.shape.width/100 height:world.shape.height/100{
	int current_people_inside;
	int tension;
	rgb current_color; 
	init{
		current_color <- #black;
		current_people_inside <- 0;
		tension <- 0;
	}
	reflex main{
		do updateState;
	}
	action updateState{
		current_people_inside <- 0;
		current_people_inside <- length(people inside self);
	}
	aspect default{
		if(current_people_inside>=5){
		    if(tension>0){
				draw shape color:rgb (255, 0, 0,255);	
			}
			else{
				draw shape color:rgb (255, 128, 0,255);
			}
		}
	}
	aspect heatmap{
      draw shape color:rgb(current_people_inside*50, 0,0) border:rgb(current_people_inside*50, 0, 0) empty:false;	
	}
}

species road{
	string name;
	string type;
	
	aspect default{
		draw shape color:rgb (121, 121, 121,255);
	}
}

species suburb{
	string name;
	aspect default{
		draw square(30) depth:10 color:rgb (145, 101, 197,255);
	}
}

species people skills:[moving]{
	point target;
	int clusteringAttractivity;
	bool victimized;
	bool possibleOffender; // Walker or Offender
	bool offenderOnTheWay;
	rgb current_color;
	init{
		victimized <- false;
		offenderOnTheWay <- false;
		clusteringAttractivity <- rnd(1,5);
		target 		<- any_location_in(one_of(road));
		location 	<- any_location_in(one_of(road));
	}
	reflex updateState{
		if(possibleOffender and !offenderOnTheWay){
			list<cell> attractiveCells <- cell where (each.current_people_inside >= clusteringAttractivity);
			if(length(attractiveCells)>0){			
				cell selected <- one_of(attractiveCells);
				float delta <- distance_to(selected,self);
				float maxDistance <- sqrt(world.shape.width^2+world.shape.height^2);
				delta <- (delta / maxDistance)*100;
				//float pi <- delta/100;
				float pi <- delta^(-mu)*10;
				float rndVar <- rnd(100) / 100;
				write "rndVar: "+rndVar+" pi: "+pi;
				if(rndVar>pi){
					target <- selected.location;
				}
				offenderOnTheWay <- true;
			}
		}
	}
	reflex move{
		if(location = target or path_between(road_network,location,target)=nil){
			location <- location + 1;
			target <- any_location_in(one_of(road));
			if (possibleOffender = true){
				do commitCrime;
				offenderOnTheWay <- false;
			}
		}
		do goto on:road_network target:target speed:10.0;
	}
	action commitCrime{
		cell current <- one_of(cell at_distance(0));
		people victim <- one_of(people at_distance(50));
		if(victim != nil){
			victim.victimized <- true;
			current.tension <- current.tension + 1;
			crimes <- crimes + 1;
		}
	}
	action updateProperties{
		current_color <- possibleOffender?rgb (210, 23, 23,255):rgb (11, 157, 44,255); 
	}
	
	aspect default{
		if (victimized = true){
	      draw circle(40) color:rgb (255, 0, 255,255) ;
		}
		else{
		  draw circle(20) color:current_color;	
		}
	}
}

experiment experiment1 type:gui{
	output{
		layout #split;
		display scenario type:opengl background:#black{
			species road;
			species suburb;
			species people trace:10;
		}
		display grid type:opengl background:#black{
			species cell aspect:heatmap;
			species road;
		}
		display chart background:#black{
			chart "Crimes" type:series{
				data "Crimes" value:crimes color:rgb (255, 0, 0,255);
			}
		}
	}
}
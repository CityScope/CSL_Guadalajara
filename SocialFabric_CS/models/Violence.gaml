/***
* Name: Violence
* Author: gamalielpalomo
* Description: This GAMA model implements a ABM model for violence based on the Levy equation for movements.
* Tags: Tag1, Tag2, TagN
***/

model Violence

global torus:false{

	string case_study parameter: 'Case Study:' category: 'Initialization' <-"centinela" among:["centinela", "miramar", "tijuana"];
	int  nbPeople parameter: 'Number of people:' category: 'Initialization' <- 250 min: 100 max: 1000;  
	int  nbOffender parameter: 'Number of offender:' category: 'Initialization' <- 20 min: 10 max: 100;
	int  cellSize parameter: 'Cells Size:' category: 'Initialization' <- 150 min: 50 max: 1000;  
	float mu parameter: 'Mu:' category: 'Model' <- 1.0 min: 0.0 max: 2.0;
	int crimes;
	
	
	file<geometry> roads <- osm_file("/gis/"+case_study + "/" +case_study +".osm");
	graph road_network;
	geometry shape <- envelope(roads);
		
	init{
		crimes <- 0;
		mu <- 1.0;
		create osm_agent from:roads with:[name_str::string(read("name")), type_str::string(read("highway"))]{
			if(type_str != nil and type_str != "" and type_str != "turning_circle" and type_str != "traffic_signals" and type_str != "bus_stop"){
				create road with: [shape::shape, type::type_str, name_str::name_str];
			}
			do die;
		}
		road_network <- as_edge_graph(road);
		create people number:nbPeople;
		create offender number: 20;
	}
}

species osm_agent{
	string name_str;
	string type_str;
}

grid cell width:world.shape.width/cellSize height:world.shape.height/cellSize{
	int current_people_inside;
	int tension; //Tension is refered as the perception of security, and its value depends on social and environmental factors 
				 // such as crimes commited and physical layer conditions. 
	init{
		current_people_inside <- 0;
		tension <- 0;
	}
	reflex updateNbPeople{
		current_people_inside <- length(people inside self);
	}
	aspect crimeAttractiveAreas{
		draw shape color:rgb(current_people_inside*100, 0,0) border:rgb(current_people_inside*100, 0, 0);	
	}
	aspect tension{
		draw shape color:rgb(tension*50, 0, 0) border:rgb(tension*50, 0, 0) empty:false;
	}
}

species road{
	string name_str;
	string type;
	aspect default{
		draw shape color:rgb (121, 121, 121,255);
	}
}

species offender skills:[moving]{
	point target;
	int clusteringAttractivity;
	bool onTheWay;
	init{
		onTheWay <- false;
		clusteringAttractivity <- rnd(1,5);
		target <- any_location_in(one_of(road));
		location <- any_location_in(one_of(road));
	}
	reflex updateState{
		if !onTheWay{
			list<cell> attractiveCells <- cell where (each.current_people_inside >= clusteringAttractivity);
			if length(attractiveCells)>0{
				cell selected <- one_of(attractiveCells);
				float delta <- distance_to(selected,self);
				float maxDistance <- sqrt(world.shape.width^2+world.shape.height^2);
				delta <- (delta/maxDistance)*100;
				//float pi <- delta/100;
				float pi <- delta^(-mu)*10;
				float rndVar <- rnd(100)/100;
				if(rndVar>pi){
					target <- selected.location;
					onTheWay <- true;
				}
			}
		}
	}
	reflex move{
		if(location = target or path_between(road_network,location,target)=nil){
			location <- location + 1; //sometimes it is not possible to find a path between the current agent and its target, move until it is foud.
			target <- any_location_in(one_of(road));
			do commitCrime;
			onTheWay <- true;
		}
		do goto on:road_network target:target speed:10.0;
	}
	action commitCrime{
		//cell currentCell <- one_of(cell at_distance(0));
		cell currentCell <- cell closest_to(self);
		people victim <- one_of(people at_distance(50));
		if(victim != nil){
			victim.victimized <- true;
			currentCell.tension <- currentCell.tension + 1;
			crimes <- crimes + 1;
		}
	}
	aspect default{
		draw circle(25) color:rgb (255, 255, 0,255);
	}	
}

species people skills:[moving]{
	point target;
	bool victimized;
	init{
		victimized <- false;
		target 		<- any_location_in(one_of(road));
		location 	<- any_location_in(one_of(road));
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

experiment experiment1 type:gui{
	output{
		layout #split;
		display view type:opengl background:#black{
			species road;
			species people trace:0;
			species offender trace:0;
		}
		display risk type:opengl background:#black{
			species cell aspect:crimeAttractiveAreas;
			species road;
			//species people trace:0;
			//species offender trace:0;
		}
		display tension type:opengl background:#black{
			species cell aspect:tension;
			species road;
		}
		/*display chart background:#black{
			chart "Crimes" type:series{
				data "Crimes" value:crimes color:rgb (255, 0, 0,255);
			}
		}*/
	}
}

experiment multi_city type: gui {
	init {
		create simulation with: [case_study::"miramar"];
		create simulation with: [case_study::"tijuana"];
	}
	output {
		display view1  type:opengl  {	
			species road;
			species people;
			species offender;
		}	
	}
	permanent {
		display Comparison background: #white {
			chart "Crime" type: series {
				loop s over: simulations {
					data string(s.case_study) value: s.crimes color: s.color marker: false style: line thickness:4;
				}
			}
		}
	}
}
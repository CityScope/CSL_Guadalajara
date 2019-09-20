/***
* Name: Violence
* Author: Gamaliel Palomo, Arnaud Grignard
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
	int offenderPerception parameter: 'Offender Perception Distance:' category: 'Model' <- 50 min: 10 max: 500;
	float offenderSpeed parameter: 'Offender Speed:' category: 'Model' <- 10.0 min: 5.0 max: 15.0;
	float peopleSpeed parameter: 'People Speed:' category: 'Model' <- 10.0 min: 5.0 max: 15.0;
	bool showPerception parameter: "Show Perception" category: "Visualization" <-false;
	bool showNbCrime parameter: "Show Number of Crime" category: "Visualization" <-false;
	bool showOffenderTarget parameter: "Show Offender Target" category: "Visualization" <-false;
	bool showOffenderPath parameter: "Show Offender Path" category: "Visualization" <-false;
	int totalCrimes;
	map<string, rgb> color_type <- ["offender"::rgb(255,255,0), "victim"::rgb (255, 0, 255), "people"::rgb (10, 192, 83,255)];
	
	
	file<geometry> roads <- osm_file("/gis/"+case_study + "/" +case_study +".osm");
	graph road_network;
	geometry shape <- envelope(roads);
		
	init{
		totalCrimes <- 0;
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
	//Tension is refered as the perception of security, and its value depends on social and environmental factors 
	// such as crimes commited and physical layer conditions. 
	int tension; 
				 
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
	int nbCrimeCommited;
	init{
		onTheWay <- false;
		nbCrimeCommited<-0;
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
				//Levy Equation. 
				//FIXME: Why not just chosing the closest among attractiveCells
				delta <- (delta/maxDistance)*100;
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
			do commitCrime;
			onTheWay <- false;
		}
		do goto on:road_network target:target speed:offenderSpeed;
	}
	action commitCrime{
		cell currentCell <- cell closest_to(self);
		people victim <- one_of(people at_distance(offenderPerception));
		if(victim != nil){
			victim.victimized <- true;
			currentCell.tension <- currentCell.tension + 1;
			totalCrimes <- totalCrimes + 1;
			nbCrimeCommited<-nbCrimeCommited+1;
		}
	}
	aspect default{
		if (onTheWay){
		  draw circle(25) color:color_type["offender"];	
		}else{
		  draw circle(10) color:color_type["offender"];		
		}
		if(showPerception){
			draw circle(offenderPerception) empty:true color:#red;
			draw circle(offenderPerception) color:rgb(255,0,0,0.5);
		}
		if(showNbCrime){
			draw "crime:" + nbCrimeCommited size:6#px color:#white;
		}
		if(showOffenderTarget){
			draw line(location,target) width:0.5 color:color_type["offender"];
		}
		if(showOffenderPath){
	 	 	draw current_path.shape color: color_type["offender"];
		}
		
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
			target <- any_location_in(one_of(road));
		}
		do goto on:road_network target:target speed:peopleSpeed;
	}
	
	aspect default{
		if (victimized = true){
	      draw circle(35) color:color_type["victim"] ;
		}
		else{
		  draw circle(15) color:color_type["people"];	
		}
	}
}


experiment dev type:gui{
	output{
		layout #split;
		display view type:opengl background:#black{
			species road;
			species people;
			species offender;
			overlay position: { 5, 5 } size: { 180 #px, 100 #px } background: # black transparency: 0.5 border: #black rounded: true
            {
                float y <- 30#px;
                loop type over: color_type.keys
                {
                    draw circle(5#px) at: { 20#px, y } color: color_type[type] border: color_type[type]+1;
                    draw string(type) at: { 40#px, y + 4#px } color: #white font: font("SansSerif", 12);
                    y <- y + 25#px;
                }
                draw "Crimes: " +  totalCrimes at: { 40#px, y + 4#px } color: #white font: font("SansSerif", 12);

            }
		}
	}
}

experiment city type:gui parent:dev{
	output{
		display risk type:opengl background:#black{
			species cell aspect:crimeAttractiveAreas;
			species road;
		}
		display tension type:opengl background:#black{
			species cell aspect:tension;
			species road;
		}
		display chart background:#black{
			chart "Crimes" type:series{
				data "Crimes" value:totalCrimes color:rgb (255, 0, 0,255);
			}
		}
	}
}

experiment multi_city type: gui parent:dev{
	init {
		create simulation with: [case_study::"miramar"];
		create simulation with: [case_study::"tijuana"];
	}
	permanent {
		display Comparison background: #white {
			chart "Crime" type: series {
				loop s over: simulations {
					data string(s.case_study) value: s.totalCrimes color: s.color marker: false style: line thickness:4;
				}
			}
		}
	}
}
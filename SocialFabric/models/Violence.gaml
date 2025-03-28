/***
* Name: Violence
* Author: Gamaliel Palomo, Arnaud Grignard
* Description: This GAMA model implements a ABM model for violence based on the Levy equation for movements.
* Tags: Tag1, Tag2, TagN
***/

model Violence

global torus:false{

	string case_study<-"fivecorners" among:["fivecorners", "miramar", "tijuana"] ;//parameter: 'Case Study:' category: 'Initialization'  ;
	int  nbPeople <- 250 min: 100 max: 1000;//parameter: 'Number of people:' category: 'Initialization' ;  
	int  nbOffender <- 20 min: 10 max: 100;// parameter: 'Number of offender:' category: 'Initialization' ;
	int  cellSize <- 150 min: 50 max: 1000 ;//parameter: 'Cells Size:' category: 'Initialization' ;  
	float mu <- 1.0 min: 0.0 max: 2.0;//parameter: 'Mu:' category: 'Model' ;
	int offenderPerception<- 50 min: 10 max: 500 ;//parameter: 'Offender Perception Distance:' category: 'Model' ;
	float offenderSpeed <- 10.0 min: 5.0 max: 15.0;//parameter: 'Offender Speed:' category: 'Model' ;
	float peopleSpeed <- 10.0 min: 5.0 max: 15.0;//parameter: 'People Speed:' category: 'Model' ;
	bool showPerception<-false ;//parameter: "Show Perception" category: "Visualization" ;
	bool showNbCrime <-false;//parameter: "Show Number of Crime" category: "Visualization" ;
	bool showOffenderTarget<-false;// parameter: "Show Offender Target" category: "Visualization" ;
	bool showOffenderPath <-false;// parameter: "Show Offender Path" category: "Visualization" ;
	int totalCrimes;
	map<string, rgb> color_type <- ["offender"::rgb(255,255,0), "victim"::rgb (255, 0, 255), "people"::rgb (10, 192, 83,255)];
	
	file roads_file <- file("/gis/"+case_study+"/roads.shp");
	graph road_network;
	geometry shape <- envelope(roads_file);
		
	init{
		totalCrimes <- 0;
		mu <- 1.0;
		create road from:roads_file;
		road_network <- as_edge_graph(road);
		create people number:nbPeople;
		create offender number: 20;
	}
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
		draw shape color:rgb(tension*50, 0, 0) border:rgb(tension*50, 0, 0) wireframe:false;
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
			draw circle(offenderPerception) wireframe:true color:#red;
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
			species road refresh:false;
			species people ;
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
			species road refresh:false;
		}
		display tension type:opengl background:#black{
			species cell aspect:tension;
			species road refresh:false;
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
		create simulation with: [case_study::"centinela"];
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
/**
* Name: cityscope
* Based on the internal empty template. 
* Author: gamaa
* Tags: 
*/

//TODO: Cada agente llega al punto exacto DENUE, hacer que lleguen a algún lugar dentro del block.

model cityscope
import "constants.gaml"

global{
	
	file limits_shp <- file(dcu_limits_filename);
	file roads_shp <- file(dcu_roads_filename);
	file denue_shp <- file(denue_filename);
	file blocks_shp <- file(ppdu_blocks_filemane);
	file ppdu_blocks_shp <- file(ppdu_s2_blocks_filename);
	file entry_points_shp <- file(entry_points_filename);
	file transport_shp <- file(dcu_transport);
	file massive_shp <- file(dcu_massive_transport_filename);
	file cycling_shp <- file(dcu_cycling_way_filename);
	file students_shp <- file(dcu_students_filename);
	file zonification_shp <- file(zonification_ccu_filename);
	file hex_zones_shp <- file(hex_zones_filename);
	file cityscope_shp <- file(cityscope_shape_filename);
	file facilities_schools_shp <- file(facilities_schools_filename);
	file facilities_health_shp <- file(facilities_health_filename);
	file facilities_culture_shp <- file(facilities_culture_filename);
	file facilities_green_shp <- file(facilities_greenarea_filename);
	
	geometry shape <- envelope(limits_shp);
	graph road_network;
	list<denue> schools;
	map<string,int> mobility_count;
	map<string,path> agent_routes;
	bool show_accessibility_by_agent parameter:"Accesibilidad por persona" <- false;
	bool show_use parameter:"Uso de suelo" <- false;
	bool show_entropy parameter:"Diversidad" <- false;
	string scenario parameter:"Escenario" <- "a" among:["a","b"];
	string parameter2show parameter:"Parameter" <- "Education" among:["Education","Health","Culture","Parks"];
	//bool use_percentage parameter:"Población a partir de porcentaje" <- false;
	string case_study <- "students";
	//Diversity
	float max_entropy_a<-0.0;
	float max_entropy_b<-0.0;
	bool scenario_changed <- false;
	string last_scenario <- scenario;
	
	//Scenario indicators
	list<float> scenario_a <- [0.0,0.0,0.0,0.0,0.0,0.0,0.0];
	list<float> scenario_b <- [0.0,0.0,0.0,0.0,0.0,0.0,0.0];
	float diversity <- 0.0;
	float transport_accessibility <- 0.0;
	float hab_emp_ratio <- 0.0;
	float density <- 0.0;
	float education_accessibility <- 0.0;
	float culture_accessibility <- 0.0;
	float health_accessibility <- 0.0;
	float inc <- 1.5;
	
	//Visualization
	bool show_satellite <- false;
	image_file satellite_png <- image_file(satellite_file);
	init{
		step <-3#seconds;
		starting_date <- date("2022-3-7 06:00:00");
		create roads from:roads_shp;
		//road_network <- as_edge_graph(roads);
		create dcu from: limits_shp;
		create transport_station from:transport_shp;
		create facilities from:facilities_schools_shp with:[type::"school"];
		create facilities from:facilities_culture_shp with:[type::"culture"];
		create facilities from:facilities_health_shp with:[type::"health"];
		create facilities from:facilities_green_shp with:[type::"green"];
		create massive_transport from:massive_shp with:[type::string(read("Sistema"))];
		create cycling_way from:cycling_shp;
		create block from:blocks_shp with:[id::string(read("fid")),use::string(read("Descripci2")),area::float(read("Area"))]{	area <- area=0.0?1.0:area;	}
		create denue from:denue_shp with:[id::string(read("id")),activity_code::string(read("codigo_act"))]{
			my_block <- first(block closest_to self);
		}
		schools <- denue where(each.activity_code in universities);
		loop i from:0 to:length(mobility_colors.keys)-1{
			add mobility_colors.keys[i]::0 to:mobility_count;
		}
		create block from:zonification_shp with:[id::string(read("fid")),use::string(read("Uso_1")),nb_people::int(read("POB_VIV")),area::float(read("SUP_E2"))]{
			area <- area=0.0?1.0:area;	
			from_scenario <- "b";
			if id = "NULL"{do die;}
			if parking = nil {do die;}
			if use = "Mixto"{
				create people number:nb_people{
					from_scenario <- "b";
					activity_type <- "student";//one_of(["student","worker"]);
					location <- any_location_in(myself);
					home <- location;
					home_block <- myself;
					if home_block = nil{
						home_block <- block closest_to self;
					}
					mobility_mode <- one_of(student_mobility_percentages.keys);//"Automóvil propio";
					
					my_activity <- activity_type="student"?one_of(schools):one_of(denue);
					mobility_count[mobility_mode] <- mobility_count[mobility_mode] + 1;
				}
			}
			
		}
		
		/*ask schools{
			ask block{
				path the_path <- path_between(road_network,self,myself);
				add string(myself.id)::the_path to:route_to;
			}
		}*/
		create people from:students_shp with:[my_activity_id::string(read("school")),home_block_id::string(read("home_block")),mobility_mode::string(read("mobility_m"))]{
			activity_type <- "student";
			home <- location;
			my_activity <- first(denue where(each.id = my_activity_id));
			home_block <- block closest_to self;
			if my_activity = nil {
				write "nil school";
			}
			mobility_count[mobility_mode] <- mobility_count[mobility_mode] + 1;
		}

		float sum <- 0.0;
		ask people{
			if from_scenario = "a"{home_block.nb_people_a <- home_block.nb_people_a + 1;}
			else if from_scenario = "b"{home_block.nb_people_b <- home_block.nb_people_b + 1;}
			transport_station the_station <- transport_station closest_to self;
			float distance1 <- the_station distance_to self;
			sum <- sum + distance1;
			massive_transport closest_brt <- massive_transport where(each.type="BRT (Bus Rapid Transit)") closest_to self;
			float distance2 <- closest_brt distance_to self;
			massive_transport closest_light_train <- massive_transport where(each.type="Tren Eléctrico") closest_to self;
			float distance3 <- closest_light_train distance_to self;
			cycling_way closest_cycling_way <- cycling_way closest_to self;
			float distance4 <- closest_cycling_way distance_to self;
			if distance1 < 300{
				transport_accessibilty_count <- transport_accessibilty_count + 1;
			} 
			if distance2 < 500{
				transport_accessibilty_count <- transport_accessibilty_count + 1;
			}
			if distance3 < 800{
				transport_accessibilty_count <- transport_accessibilty_count + 1;
			}
			if distance4 < 300{
				transport_accessibilty_count <- transport_accessibilty_count + 1;
			}
			nb_schools_near2me <- length(schools at_distance(500));
			nb_hospitals_near2me <- length(facilities where(each.type="health") at_distance(1000));
			nb_culture_near2me <- length(facilities where(each.type="culture") at_distance(1000));			
		}
		create entry_points from:entry_points_shp;
		create hex_zone from:hex_zones_shp with:[diversity_index_a::float(read("IDU"))]{
			diversity_index <- diversity_index_a;
		}
		max_entropy_a <- max(hex_zone collect(each.diversity_index_a));
		max_entropy_b <- max(hex_zone collect(each.diversity_index_b));
		create cityscope_shape from:cityscope_shp;
		
		//Clean files
		blocks_shp <- [];
		roads_shp <- [];
		denue_shp <- [];
		entry_points_shp <- [];
		transport_shp <- [];
		students_shp <- [];
		zonification_shp <- [];
		hex_zones_shp <- [];
		cityscope_shp <- [];
		facilities_health_shp <- [];
		facilities_culture_shp <- [];
		facilities_health_shp <- [];
		facilities_schools_shp <- [];
		facilities_green_shp <- [];
	}
	action select_scenario_a{scenario <- "a";ask cell{do update_grid_value(self.current_indicator);}}
	action select_scenario_b{scenario <- "b";ask cell{do update_grid_value(self.current_indicator);}}
	action heatmap_diversity{ask cell{do update_grid_value("diversity");}}
	action heatmap_density{ask cell{do update_grid_value("density");}}
	action heatmap_health{ask cell{do update_grid_value("health");}}
	action heatmap_culture{ask cell{do update_grid_value("culture");}}
	action heatmap_education{ask cell{do update_grid_value("education");}}
	action land_use{show_use <- show_use? false:true;}
	action satellite{show_satellite <- show_satellite?false:true;}
	reflex update_inc when:(cycle=5){	inc <- 0.1;}
	reflex check_changes{
		if scenario !=last_scenario{
			scenario_changed <- true;
			last_scenario <- scenario;
		}
		else{
			scenario_changed <- false;
		}
	}
	reflex update_radar when:cycle=10{
		transport_accessibility <- sum(people where(each.from_scenario="a") collect(each.ind_mobility_accessibility))/length(people where(each.from_scenario="a"));
		transport_accessibility <- transport_accessibility/max_transport_accessibility;
		diversity <- sum(hex_zone collect(each.diversity_index_a))/length(hex_zone);
		diversity <- diversity / max_diversity;
		hab_emp_ratio <- length(people where(each.from_scenario="a"))/length(denue);
		hab_emp_ratio <- hab_emp_ratio/max_hab_emp_ratio;
		density <- sum(block where(each.from_scenario="a") collect(each.my_density))/length(block where(each.from_scenario="a"));
		density <- density/max_density;
		education_accessibility <- sum(people where(each.from_scenario="a") collect(each.ind_education_accessibility))/length(people where(each.from_scenario="a"));
		culture_accessibility <- sum(people where(each.from_scenario="a") collect(each.ind_culture_accessibility))/length(people where(each.from_scenario="a"));
		health_accessibility <- sum(people where(each.from_scenario="a") collect(each.ind_health_accessibility))/length(people where(each.from_scenario="a"));
		scenario_a <- [transport_accessibility,education_accessibility,diversity,hab_emp_ratio,density,health_accessibility,culture_accessibility];
		
		transport_accessibility <- sum(people collect(each.ind_mobility_accessibility))/length(people);
		transport_accessibility <- transport_accessibility/max_transport_accessibility;
		diversity <- sum(hex_zone collect(each.diversity_index_b))/length(hex_zone);
		diversity <- diversity / max_diversity;
		hab_emp_ratio <- length(people)/length(denue);
		hab_emp_ratio <- hab_emp_ratio/max_hab_emp_ratio;
		density <- sum(block collect(each.my_density))/length(block);
		density <- density/max_density;
		education_accessibility <- sum(people collect(each.ind_education_accessibility))/length(people);
		culture_accessibility <- sum(people collect(each.ind_culture_accessibility))/length(people);
		health_accessibility <- sum(people collect(each.ind_health_accessibility))/length(people);
		scenario_b <- [transport_accessibility,education_accessibility,diversity,hab_emp_ratio,density,health_accessibility,culture_accessibility];
	}
	reflex update_scenario_indicators when:cycle=0 or scenario_changed{
		transport_accessibility <- scenario="a"?sum(people where(each.from_scenario="a") collect(each.ind_mobility_accessibility))/length(people where(each.from_scenario="a")):sum(people collect(each.ind_mobility_accessibility))/length(people);
		transport_accessibility <- transport_accessibility/max_transport_accessibility;
		diversity <- sum(hex_zone collect(each.diversity_index))/length(hex_zone);
		diversity <- diversity / max_diversity;
		hab_emp_ratio <- scenario ="a"?length(people where(each.from_scenario="a"))/length(denue):length(people)/length(denue);
		hab_emp_ratio <- hab_emp_ratio/max_hab_emp_ratio;
		density <- scenario="a"? sum(block where(each.from_scenario="a") collect(each.my_density))/length(block where(each.from_scenario="a")): sum(block collect(each.my_density))/length(block);
		density <- density/max_density;
		education_accessibility <- scenario="a"?sum(people where(each.from_scenario="a") collect(each.ind_education_accessibility))/length(people where(each.from_scenario="a")):sum(people collect(each.ind_education_accessibility))/length(people);
		culture_accessibility <- scenario="a"?sum(people where(each.from_scenario="a") collect(each.ind_culture_accessibility))/length(people where(each.from_scenario="a")):sum(people collect(each.ind_culture_accessibility))/length(people);
		health_accessibility <- scenario="a"?sum(people where(each.from_scenario="a") collect(each.ind_health_accessibility))/length(people where(each.from_scenario="a")):sum(people collect(each.ind_health_accessibility))/length(people);
		//heat <- field(grid);
	}
}
grid cell width:world.shape.width/40 height:world.shape.height/40 parallel:true{
	string current_indicator <- "";
	/*int nb_culture_near2me <- 0;	
	int nb_hospitals_near2me <- 0;
	int  nb_schools_near2me <- 0;*/
	bool valid <- false;
	float grid_value <- 0.0;
	rgb color <- rgb (10, 252, 227,grid_value);
	action update_grid_value(string indicator){
		if indicator = "diversity"{
			current_indicator <- indicator;
			hex_zone my_hex_zone <- hex_zone closest_to self;
			grid_value <- my_hex_zone.diversity_index/max_diversity;
		}
		else if indicator = "density"{
			current_indicator <- indicator;
			block my_block <- block closest_to self;
			grid_value <- my_block.my_density/max_density;
		}
		else if indicator = "education"{
			current_indicator <- indicator;
			list<people> people_here <- people inside self;
			if not empty(people_here){
				grid_value <- sum(people_here collect(each.ind_education_accessibility))/length(people_here);
			}
		}
		else if indicator= "culture"{
			current_indicator <- indicator;
			list<people> people_here <- people inside self;
			if not empty(people_here){
				grid_value <- sum(people_here collect(each.ind_culture_accessibility))/length(people_here);
			}
		}
		else if indicator = "health"{
			current_indicator <- indicator;
			list<people> people_here <- people inside self;
			if not empty(people_here){
				grid_value <- sum(people_here collect(each.ind_health_accessibility))/length(people_here);
			}
		}
		/*if grid_value <= 0.2{color <- rgb(180,20,20,grid_value);}
		else if grid_value <= 0.4{color <- rgb (207, 99, 33,grid_value);}
		else if grid_value <= 0.6{color <- rgb (120, 220, 153,grid_value);}
		else {color <- rgb(43,131,186,grid_value);}*/
		if show_use{
			color <- rgb(0,0,0,0.0);
		}
		else{
			color <- grid_value<0.5?rgb(180,30,30,0.6-grid_value):rgb (10, 252, 227,grid_value);
		}
		
	}
	/*reflex init_values when:cycle=1{
		nb_culture_near2me <- length(facilities where(each.type="culture") at_distance(1000));	
		nb_hospitals_near2me <- length(facilities where(each.type="health") at_distance(1000));
		nb_schools_near2me <- length(schools at_distance(500));
	}*/
	/*reflex update_value when:scenario_changed{
		if parameter2show = "Education"{
			grid_value <- length(schools at_distance(500))/max_schools_near;
		}
		else if parameter2show = "Health"{
			grid_value <- length(facilities where(each.type="health") at_distance(1000))/max_hospitals_near;
		}
		else if parameter2show = "Culture"{
			grid_value <- length(facilities where(each.type="culture") at_distance(1000))/max_hospitals_near;
		}
	}*/
	//rgb color <- hsb(grid_value,0.8,0.8) update:hsb(grid_value,0.8,0.8);
}
species facilities{
	string type;
	aspect default{
		draw square(20) color:#mediumturquoise;
	}
}
species school{
	string id;//
}
species cityscope_shape{
	aspect default{
		//if show_satellite{draw shape wireframe:false border:#gray texture:satellite_png;}
		draw shape wireframe:true border:#gray;
	}
	init{
		ask cell inside(self){
			valid <- true;
		}
		ask cell where(each.valid = false){do die;}
	}
}
species hex_zone{
	float diversity_index_a <- 0.0;
	float diversity_index_b <- 0.0;
	float diversity_index <- 0.0;
	float area;
	list<block> my_blocks;
	init{
		area <- shape.area;
		my_blocks <- block at_distance(300#m);
		map<string,int> count_map;
		loop key over:use_type_color.keys{
			add key::0 to:count_map;
		}
		ask my_blocks{
			count_map[self.use] <- count_map[self.use] + 1;
		}
		float sum<-0.0;
		loop i over:count_map.keys{
			float pi <- count_map[i]/length(my_blocks);
			if pi != 0{
				sum <- sum + (pi*ln(pi));
			}
		}
		sum <- -1*sum;
		diversity_index_b <- sum;
		
	}
	reflex update_diversity_index when:scenario_changed{
		if scenario = "a"{
			diversity_index <- diversity_index_a;
		}
		else if scenario = "b"{
			diversity_index <- diversity_index_b;
		}
	}
	aspect default{
		float max_entropy <- scenario = "a"?max_entropy_a:max_entropy_b;
		if show_entropy{
			draw shape color:rgb (46, 194, 194,diversity_index/max_entropy);
		}
	}
}
species cycling_way{
	
}
species transport_station{
	image_file my_icon <- image_file("../includes/img/bus.png") ;
	aspect default{
		draw my_icon size:40;
	}
}
species massive_transport{
	string type;
}
species entry_points{
	aspect default{
		draw circle(10) color:#red;
	}
}
species denue{
	string id;
	string activity_code;
	block my_block;
	aspect default{
		draw triangle(10) color:rgb (44, 177, 201,0.5);
	}
}
species people skills:[moving] parallel:true{
	point home;
	string home_block_id;
	string activity_type;
	denue my_activity;
	string my_activity_id;
	map<date,string> agenda_day;
	//Mobility
	float ind_mobility_accessibility <- 0.0;
	string mobility_mode;
	int transport_accessibilty_count <- 0;
	string current_activity;
	block home_block;
	int point_index;
	list<point>  my_route;
	bool new_one <- false;
	string from_scenario <- "a";
	//Education accessibility
	int nb_schools_near2me <- 0;
	float ind_education_accessibility <- 0.0;
	//Health accessibility
	int nb_hospitals_near2me <- 0;
	float ind_health_accessibility <- 0.0;
	//Culture accessibility
	int nb_culture_near2me <- 0;
	float ind_culture_accessibility <- 0.0;
	
	reflex update_indicators when:cycle=1{
		ind_mobility_accessibility <- transport_accessibilty_count /4;
		ind_education_accessibility <- nb_schools_near2me / max_schools_near; 
		ind_health_accessibility <- nb_hospitals_near2me / max_hospitals_near;
		ind_culture_accessibility <- nb_culture_near2me / max_culture_near;
	}
	/*reflex update_agenda when: empty(agenda_day) or (every(#day) and (!(from_scenario="b") or ((from_scenario="b") and scenario="b"))){
		agenda_day <- [];
		point the_activity_location <- my_activity.location;
		int activity_time <- rnd(2,12);
		int init_hour <- rnd(6,12);
		int init_minute <- rnd(0,59);
		date activity_date <- date(current_date.year,current_date.month,current_date.day,init_hour,init_minute,0);
		agenda_day <+ (activity_date::"activity");
		activity_date <- activity_date + activity_time#hours;
		init_minute <- rnd(0,59);
		activity_date <- activity_date + init_minute#minutes;
		agenda_day <+ (activity_date::"home");
	}
	reflex update_activity when:not empty(agenda_day) and (after(agenda_day.keys[0])) and (!(from_scenario="b") or ((from_scenario="b") and scenario="b")){
		current_activity <-agenda_day.values[0];
		if current_activity = "activity"{
			my_route <- home_block.route_to[my_activity.id].shape.points;
		}
		else{
			my_route <- home_block.route_to[my_activity.id].shape.points;
			list<point> reverse;
			loop i from:0 to:length(my_route)-1{
				add my_route[length(my_route)-1-i] to: reverse;
			}
			my_route <- reverse;
		}
		point_index <- 0;
		agenda_day>>first(agenda_day);
	}
	reflex movement when:point_index<length(my_route) and (!(from_scenario="b") or ((from_scenario="b") and scenario="b")){
		do goto target:my_route[point_index] speed:mobility_speed[mobility_mode]#km/#h;
		if location = my_route[point_index]{
			point_index<- point_index + 1;
		}
	}*/
	
	string select_mobility_mode{
		float sum <- 0.0;
		float selection <- rnd(100)/100;
		loop mode over:activity_type="student"?student_mobility_percentages.keys:worker_mobility_percentages.keys{
			if selection < student_mobility_percentages[mode] + sum{
				return mode;
			}
			sum <- sum + student_mobility_percentages[mode];
		}
		return one_of(student_mobility_percentages.keys);
	}
	aspect mobility_accessibility{
		if show_accessibility_by_agent{
			
			rgb my_color <- rgb((1-ind_mobility_accessibility)*255,ind_mobility_accessibility*255,100);
			if ((from_scenario="b") and (scenario="b")) or !(from_scenario="b"){
				draw circle(5) color:my_color;
			}
		}
		else{
			if ((from_scenario="b") and (scenario="b")) or !(from_scenario="b"){
				draw circle(5) color:mobility_colors[mobility_mode];
			}
		}		
	}
}

species dcu{
	aspect default{
		draw shape wireframe:true border:#gray;
	} 
}

species block{
	string id;
	string from_scenario <- "a";
	string use;
	int parking <- 0;
	map<string,path> route_to;
	int nb_people <- 0;
	int nb_people_a <- 0;
	int nb_people_b <- 0;
	int nb_workers;
	float area;
	float my_density <- 0.0;
	
	rgb my_color <- rgb(0,0,0,0.3);
	
	aspect default{
		if  from_scenario="a" and scenario="a"{
			if show_use{
				my_color <- use in use_type_color.keys?use_type_color[use]:rgb(0,0,0,0);
				my_color <- rgb(my_color.red,my_color.green,my_color.blue,0.6);
			}
			else{
				my_color <- rgb(0,0,0,0.3);
			}
			draw shape color:my_color border:#white;
		}
		if from_scenario="b" and scenario="b"{
			if show_use{
				my_color <- use in use_type_color.keys?use_type_color[use]:rgb(0,0,0,0);
				my_color <- rgb(my_color.red,my_color.green,my_color.blue,0.6);
			}
			else{
				my_color <- rgb(0,0,0,0.3);
			}
			draw shape color:my_color border:#white;
			
		}
	}
	aspect only_border{
		draw shape wireframe:true border:#white;
	}
	reflex update_density_index when:scenario_changed{
		if scenario = "a"{
			my_density <- nb_people_a / (area*0.0001);
		}
		else if scenario = "b"{
			my_density <- (nb_people_a+nb_people_b)/(area*0.0001);
		}
	}
	aspect use_type{
		if show_use{
			if scenario = "a"{
				my_color <- use in use_type_color.keys?use_type_color[use]:rgb(0,0,0,0);
				my_color <- rgb(my_color.red,my_color.green,my_color.blue,0.6);
				draw shape color:from_scenario="a"?my_color:rgb(0,0,0,0) border:#gray;
			}
			else if scenario = "b"{
				my_color <- use in use_type_color.keys?use_type_color[use]:rgb(0,0,0,0);
				my_color <- rgb(my_color.red,my_color.green,my_color.blue,0.6);
				draw shape color:my_color border:#gray;
			}
		}
		else{
			draw shape color:rgb(100,100,100,0.2);
		}
	}
}

species roads{
	aspect default{
		draw shape color:#gray;
	}
}


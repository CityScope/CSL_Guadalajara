/**
* Name: Application
* Based on the internal empty template. 
* Author: Francisco Aleman, Gamaliel Palomo, and Mario Siller
* Tags: 
*/


model Application

/* Insert your model definition here */
global{
	
	
	//variable that activates the sending of data to the python server
	int send_message_activator <- 0; 
	
	int Number_transactions <- 0; //variable to update number of transactions
	int received_transactions <- 0;//variable to update the number of transactions received in the python server
	int ethereum_transactions <- 0;//variable to update the number of successful ethereum transactions
	list<people> people_priority_1 <- nil update:people where(each.priority = 1);
	
	bool enable_sending_data <- false;
	
	string case_study <- "Guadalajara/small" among:["Guadalajara/small","Guadalajara/big","Tlaquepaque"];
	file blocks_file <- file("../includes/"+case_study+"/blocks.shp");//apple files
	file streets_file <- file("../includes/"+case_study+"/roads.shp"); //streets_file files
	
	geometry shape <- envelope(streets_file);//Ambient take the form of the streets_file file
	graph roads_network; //We declare a street graph
	map<string,rgb> people_color <- ["infected"::#red,"immune"::#gray, "vaccinated"::#green]; //map colors with status
	
	init{
		create block from:blocks_file with:[cvegeo::string(read("CVEGEO")),pob_60_mas::int(read("P_60YMAS"))]; //we create the block agent
		create street from:streets_file; //We create the street agent
		roads_network <- as_edge_graph(street);//We create a graph with the agent street
		
		//UDP server to receive confirmations of successful ethereum transactions
		create UDP_Server1 number:1{
			if enable_sending_data{
				do connect to: "localhost" protocol: "udp_server" port: 9876 ;
			}
		}
		////UDP server to receive transaction confirmations received from the python server
		create UDP_Server number:1{
			if enable_sending_data{
				do connect to: "localhost" protocol: "udp_server" port: 9877 ;
			}
		}
		
		//TCP Client to send data to smart contracts 
		create TCP_Client number:1{
			if enable_sending_data{
				do connect to: "localhost" protocol: "tcp_client" port: 9999 with_name: "Client";	
			}
		}
		ask block{
			create people number:int(pob_60_mas/10){
				self.home <- any_location_in(myself.shape);
				self.location <- home;
			}
		}
		create vaccination_point;
		ask vaccination_point{
			create manager{
				location <- myself.location;
				assigned_to <- myself;
			}
		}
		
		step <- 5#minute;
	}
}

//***************************** ROADS AGENT *************************************
species street{
	aspect basic{ //Street aspect
		draw shape color:#black;
	}
	aspect gray{
		draw shape color:#gray;
	}
}

//****************************** BLOCK AGENT ************************************
species block{ 
	string cvegeo;
	int pob_60_mas;
	aspect basic{ //Block aspect
		draw shape color:rgb (26, 82, 119,80);
	}
	aspect pob_60_mas{
		draw shape color:rgb(
			0,
			0,
			int((pob_60_mas/100)*255),
			0.5		
		) border:rgb(200,200,200,0.5);
	}
}

species vaccination_point{
	block belongs_to;
	int applications_per_day <- int(length(people)/10);
	list<people> vaccination_queue <- [];
	init{
		belongs_to <- one_of(block where(each.cvegeo = "1403900012183008"));
		shape <- belongs_to.shape;
	}
	action register_person(people the_person){
		add the_person to:vaccination_queue;
	}  
	aspect basic{
		draw shape color:#darkviolet;
	}
}

//************************************ VACCINE MANAGER AGENT ***************************************************
species manager{
	float honesty;
	float motivation;
	float risk_aversion;
	float reward;
	vaccination_point assigned_to;
	int nb_applications <- 0;
	
	init{
		honesty <- float(rnd(100))/100;
		risk_aversion <- float(rnd(100))/100;
		reward <- float(rnd(100))/100;
	}
	
	float compute_motivation{
		//Probabilidad de cometer un acto de corrupción
		float result <- 0.0;
		
		return result;
	}
	
	//reflex to evaluate which agent person to vaccinate and send the data to the python server
	reflex call_for_vaccination when:every(1#day){
		if length(people_priority_1) > assigned_to.applications_per_day{
			int index <- 0;
			loop times:assigned_to.applications_per_day{
				people current_person <- people_priority_1[index];
				ask current_person{
					do update_target(myself.assigned_to);//Diciendo a la persona que se dirija a este punto de vac.
				}
				index <- index + 1;
			}
		}
		else{
			int counter <- length(people_priority_1);
			int index <- 0;
			loop times:counter{
				people current_person <- people_priority_1[index];
				ask current_person{
					do update_target(myself.assigned_to);//Diciendo a la persona que se dirija a este punto de vac.
				}
				index <- index + 1;
			}
		}
	}
	
	reflex apply_vaccine when:not empty(assigned_to.vaccination_queue){
		
		ask assigned_to.vaccination_queue[0]{
			status <- "vaccinated";
			last_change <- cycle;
			registered <- false;
			target <- self.home;
			immunity <- true;
		}
		nb_applications <- nb_applications + 1;
		if enable_sending_data{
			//send blockchain data
			do application_data(assigned_to.vaccination_queue[0]);
			Number_transactions <- Number_transactions + 1;
		}
		remove index:0 from:assigned_to.vaccination_queue;
		
	}
		
	//Reflex to get the size of the transacctions list according the number of agents
	reflex sens_size_list when:nb_applications = assigned_to.applications_per_day{
		if length(people where(each.priority = 1)) = length(people where(each.status = "vaccinated")){
			string data <- size_list_send();
			//write "Ya envie el tamaño";
		}
	
	}
	
	string size_list{
			return "Size" + " " + string(nb_applications);
		}
	
	//Send data of transactions list size 
	action size_list_send{
		string mydata <- size_list();
		ask TCP_Client{
			data <- mydata;
			do send_message;
		}
	}
	

	
	
	//Send data when a vaccine is aplicated
	string aplication_vaccine(people the_person){
		
		int date_application <- 2015;
		return "Aplicar" + " " + string(date_application) + " " + string(the_person.age) + " " + the_person.morbidity;
	}
	
	//Send data of vaccine application
	action application_data(people the_person){
		string mydata <- aplication_vaccine(the_person);
		if enable_sending_data{
			ask TCP_Client{
				data <- mydata;
				do send_message;
				send_message_activator <-0;
				
			}
		}
	}
	
	aspect default{
		draw circle(5) color:rgb (210, 115, 203,255);
	}
	
}

//************************************ PEOPLE AGENT ***************************************************
species people skills:[moving]{
	point home;
	point target; //target that the people follows
	path path_to_follow;//path that the epeople follows
	string status <- "susceptible" among:["susceptible","infected","immune", "vaccinated"];
	int age; //People's age
	bool morbidity; //Morbidity of the people
	float inmunity_time <- 0#days; //time of infection of the people
	int priority; //priority of the person to receive the vaccine
	
	//Agenda related variables
	bool immunity <- false;
	bool to_vaccinate <- false;
	bool registered <- false;
	int last_change;
	vaccination_point vp; //Punto de vacunación que le corresponde
	
	init{
		age <- rnd(61,100);
		morbidity <- flip(0.5);
		last_change <- cycle;
	}
	
	action update_target(vaccination_point tgt){
		vp <- tgt;
		target <- any_location_in(vp);
		//do update_path;
	}	
	
	reflex update_priority when:every(1#day){
		priority <- immunity?2:1;
		//priority <- inmunity_time>4#months?1:2;
	}
	
	reflex movement when:target != location{
		do goto target:target;
		//do follow path: path_to_follow;
	}
	
	reflex arrive when:target=location{
		if location != home and not registered{
			ask vp{
				do register_person(myself);//Al llegar, la persona se registra
				myself.registered <- true;
			}
		}
	}
	
	action update_path{
		path_to_follow <- nil;
		path_to_follow <- path_between(roads_network,location,target);
		loop while: path_to_follow = nil{
			write name;
			do wander speed:5.0;
			target <- any_location_in(vp);
			path_to_follow <- path_between(roads_network,location,target);
		}		
	}
	
	//Reflex of how long you have been infected when you become immune
	/*reflex when_is_infected when:status = "infected"{
		inmunity_time <- inmunity_time + step;
		if inmunity_time > 30#minutes and flip(0.2){
			status <- "immune";
			//write "Empieza inmunidad";
			inmunity_time <- 0#seconds;
		}
	}
	
	//reflex to determine priority
	reflex when_immune when:status="immune"{ 
		inmunity_time <- inmunity_time + step;
		if age > 59{
			if inmunity_time > 4#hours{
				priority <- 1;
				//write "Tengo prioridada 1";
			}
		}
		if age < 60{
			if inmunity_time < 4#hours{
				priority <- 2;
				//write "Tengo prioridada 2";
			}
		}
	}
	
	
	*/
	aspect basic{
		draw circle(10) color:people_color[status];//people's aspect according to their status
		//draw string(morbidity) color:#black;
		//draw string(age) color:#black;
	}
}


//************************************ TCP CLIENT (SEND DATA TO PYTHON [SMART CONTRACT IN BLOCKCHAIN]) ***********************************

species TCP_Client skills:[network]{
	string data; //Data to send to blockchain

	//action to send message
	action send_message{
		if send_message_activator = 0{
			string mm <- data;
			do send contents: mm;
			send_message_activator <- 1;
		}
		
	}
}

//****************************************UDP SERVERS***************************************

//UDP server that receives the confirmation of the transactions received in the python server
species UDP_Server skills: [network]
{
	reflex fetch when:has_more_message() {	
		loop while:has_more_message() and enable_sending_data
		{
			message s <- fetch_message();
			string transactions <- string(s.contents);
			write transactions;
			if transactions != " " and transactions != "Yahoo"{
				received_transactions <- received_transactions + 1;
				write received_transactions;
			}
		}
	}
}



//UDP server that receives the confirmation of successful ethereum transactions
species UDP_Server1 skills: [network]
{
	reflex fetch when:has_more_message() {	
		loop while:has_more_message() and enable_sending_data
		{
			message s <- fetch_message();
			string transactions <- string(s.contents);
			write transactions;
			if transactions != " "{
				ethereum_transactions <- ethereum_transactions + 1;
				write ethereum_transactions;
			}
			
		}
	}
}

experiment main type:gui{
	output{
		layout #split;
		display GUI type:opengl draw_env:false{
			species block aspect:pob_60_mas;
			species vaccination_point aspect:basic;
			//species street aspect:gray;
			species people aspect:basic;
			species manager aspect:default;
		}
		display "Vaccination plan"{
			chart "Vaccination" type:series y_label:"Number of people"{
				data "Vaccinated" value:length(people where(each.status = "vaccinated")) color:people_color["vaccinated"] marker:false;
				data "Priority 1" value:length(people_priority_1) color:#blue marker:false;
			}
		}
		/*display "Status_pie"{
			chart "Status of people" type: pie{
				data "Infected" value:length(people where(each.status = "infected")) color:people_color["Infected"] marker:false;
				data "immune" value:length(people where(each.status = "immune")) color:people_color["immune"] marker:false;
				data "vaccinated" value:length(people where(each.status = "vaccinated")) color:people_color["vaccinated"] marker:false;
			}
		}
		display "Status_serie"{
			chart "Status of people" type: series y_label:"Number of people"{
				data "Infected" value:length(people where(each.status = "infected")) color:people_color["Infected"] marker:false;
				data "immune" value:length(people where(each.status = "immune")) color:people_color["immune"] marker:false;
				data "vaccinated" value:length(people where(each.status = "vaccinated")) color:people_color["vaccinated"] marker:false;
			}
		}
		display "Priority"{
			chart "Priority of people" type:series y_label:"Number of people"{
				data "Priority 1" value:length(people where(each.priority = 1)) color:#green marker:false;
				data "Priority 2" value:length(people where(each.priority = 2)) color:#blue marker:false;
			}
		}
		display "Transactions"{
			chart "Transactions" type:series y_label:"Number of transactions"{
				data "GAMA Sent Transactions" value:Number_transactions color:#blue marker:false;
				data "Transactions received on the Python server" value:received_transactions color:#green marker:false;
				data "Ethereum Transactions" value:ethereum_transactions color:#red marker:false;
			}
		}
		display "Transactions2"{
			chart "Transactions" type:histogram y_label:"Number of transactions"{
				data "GAMA Sent Transactions" value:Number_transactions color:#blue marker:false;
				data "Transactions received on the Python server" value:received_transactions color:#green marker:false;
				data "Ethereum Transactions" value:ethereum_transactions color:#red marker:false;
			}
		}*/
	}
	
}
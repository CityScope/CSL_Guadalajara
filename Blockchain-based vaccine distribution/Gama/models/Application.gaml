/**
* Name: Application
* Based on the internal empty template. 
* Author: Francisco
* Tags: 
*/


model Application

/* Insert your model definition here */
global{
	
	int tam; //transaction list size
	
	//variable that activates the sending of data to the python server
	int send_message_activator <- 0; 
	
	int Number_transactions <- 0; //variable to update number of transactions
	int received_transactions <- 0;//variable to update the number of transactions received in the python server
	int ethereum_transactions <- 0;//variable to update the number of successful ethereum transactions
	
	file apple_files <- file("../includes/blocks.shp");//apple files
	file streets <- file("../includes/roads.shp"); //Streets files
	geometry shape <- envelope(streets);//Ambient take the form of the streets file
	graph network_streets; //We declare a street graph
	map<string,rgb> people_color <- ["infected"::#red,"immune"::#gray, "vaccinated"::#green]; //map colors with status
	
	init{
		create block from:apple_files; //we create the block agent
		create street from:streets; //We create the street agent
		network_streets <- as_edge_graph(street);//We create a graph with the agent street
		
		
		//UDP server to receive confirmations of successful ethereum transactions
		create UDP_Server1 number:1{
			do connect to: "localhost" protocol: "udp_server" port: 9876 ;
		}
		////UDP server to receive transaction confirmations received from the python server
		create UDP_Server number:1{
			do connect to: "localhost" protocol: "udp_server" port: 9877 ;
		}
		
		//TCP Client to send data to smart contracts 
		create TCP_Client number:1{
			do connect to: "localhost" protocol: "tcp_client" port: 9999 with_name: "Client";
		}
		
		//number of agent people
		create people number:500{
			status <- "infected";
		}
		
		step <- 1#minute;
	}
}

//***************************** ROADS AGENT *************************************
species street{
	aspect basic{ //Street aspect
		draw shape color:#black;
	}
}

//****************************** BLOCK AGENT ************************************
species block{ 
	aspect basic{ //Block aspect
		draw shape color:rgb (26, 82, 119,80);
	}
}

//************************************ PEOPLE AGENT ***************************************************
species people skills:[moving]{
	point target; //target that the people follows
	path path_to_follow;//path that the epeople follows
	string status <- "infected" among:["infected","immune", "vaccinated"];
	int age; //People's age
	string morbidity; //Morbidity of the people
	int firs_contact <- 0; //variable to activate the first place the agent follows
	float inmunity_time <- 0#seconds; //time of infection of the people
	int priority; //priority of the person to receive the vaccine
	int count <-0;	
	
	
	init{
		age <- rnd(100);
		morbidity <- one_of("si", "no");
		location <- any_location_in(one_of(block)); //the initial location of the people
		target <- any_location_in(one_of(street));
		do update_path;
	}
	
	//Reflex for the agent´s movement
	reflex movement{
		//If the agent arrived the target
		if location = target{
			//write "Ya llegue al hospital";
			path_to_follow <- nil; //Put the path to follow as empty
			do update_path; //Call the function update_path
		}
		do follow path: path_to_follow; 
	}
	
	action update_path{
		firs_contact <- firs_contact + 1;
		//write firs_contact;
		loop while:path_to_follow = nil{//si el camino es vacio o (si no encuentra un camino)
		if firs_contact = 2{
			ask block where(each.name = "block37"){
				myself.target <- self.location; 
				//write myself.target;
			}
		}
		else{
			target <- any_location_in(one_of(block));
		}
			path_to_follow <- path_between(network_streets,location,target.location);//camino a seguir
		}
		
	}
	
	//Reflex of how long you have been infected when you become immune
	reflex when_is_infected when:status = "infected"{
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
		
		/* 
		if age >64 or morbidity = "si"{
			if inmunity_time > 4#hours{
				priority <- 1;
				//write "Tengo prioridada 1";
			}
		}
		if age <64 and morbidity = "no"{
			priority <- 2;
		}
		if age >64 or morbidity ="si"{
			if inmunity_time < 4#hours{
				priority <- 2;
				//write "Tengo prioridada 2";
			}
		}
		* */
		
	
	
	//every so often he visits the hospital
	reflex visit_hospital when:every(rnd(3#hours)){
		if status = "immune"{
			firs_contact <- 0;
			do update_path();
		}
	}
	
	//reflex to evaluate which agent person to vaccinate and send the data to the python server
	reflex Decide{
		ask block where (each.location = location){
			if myself.priority = 1{
					
					myself.status <- "vaccinated";
					myself.count <- myself.count + 1;
					if myself.count = 1{
						//Send data on the application of the vaccine
						string data <- myself.application_data();
						send_message_activator <- 0;
						Number_transactions <- Number_transactions + 1;
					}
					
			}
			else{
				
			}
		}
	}
		
	//Reflex to get the size of the transacctions list according the number of agents
	reflex sens_size_list when:length(people where(each.priority = 1)) > 1{
		if length(people where(each.priority = 1)) = length(people where(each.status = "vaccinated")){
			tam <- length(people where(each.priority = 1));
			string data <- size_list_send();
			//write "Ya envie el tamaño";
		}
	
	}
	
	string size_list{
			return "Size" + " " + string(tam);
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
	string aplication_vaccine{
		
		int date_application <- 2015;
		return "Aplicar" + " " + string(date_application) + " " + string(age) + " " + morbidity;
	}
	
	//Send data of vaccine application
	action application_data{
		string mydata <- aplication_vaccine();
		ask TCP_Client{
			data <- mydata;
			do send_message;
			send_message_activator <-0;
			
		}
	}
	

	aspect basic{
		draw circle(3) color:people_color[status];//people's aspect according to their status
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
		loop while:has_more_message()
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
		loop while:has_more_message()
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
		display GUI type:opengl{
			species block aspect:basic;
			species street aspect:basic;
			species people aspect:basic;
		}
		display "Status_pie"{
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
		}
	}
	
}
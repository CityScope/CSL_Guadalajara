/**
* Name: Covid
* Based on the internal empty template. 
* Author: francisco
* Tags: 
*/


model Covid

/* Insert your model definition here */
//global agent
global{
	
	
	int acti <- 0; //variable to activate the sending of data  according to the place
	int amount_vaccine;//number of vaccines sent to the country
	int acti_send <-0; //Variable to activate the data to send (Data shipping)
	string name_pais;//Name of the pais
	int tam; //transaction list size
	int Number_transactions <- 0; //variable to update number of transactions
	int received_transactions <- 0;//variable to update the number of transactions received in the python server
	int ethereum_transactions <- 0;//variable to update the number of successful ethereum transactions
	
	int vuelta <- 0;
	int send_message_activator <- 0; //variable that activates the sending of data to the python server
	
	file apple_files <- file("../includes/blocks.shp");//apple files
	file streets <- file("../includes/small_roads.shp"); //Streets files
	geometry shape <- envelope(streets);//Ambient take the form of the streets file
	graph network_streets; //We declare a street graph
	map<string,rgb> people_color <- ["infected"::#red,"immune"::#gray, "vaccinated"::#green]; //map colors with status
	
	
	init{
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
		create block from:apple_files; //we create the block agent
		create street from:streets; //We create the street agent
		network_streets <- as_edge_graph(street);//We create a graph with the agent street
		
		//number of agent people
		create people number:10;
		//transport agent
		create transport number:1;
		
		
		
		//Create places of diferent type
		create places number:1{
			type <- "COVAX";
			location <- any_location_in(one_of(block));
		}
		create places number:1{
			type <- "fabrica";
			location <- any_location_in(one_of(block));
		}
		create places number:1{
			type <- "pais";
			location <- any_location_in(one_of(block));
		}
		create places number:1{
			type <- "estado";
			location <- any_location_in(one_of(block));
		}
		create places number:1{
			type <- "hospital";
			location <- any_location_in(one_of(block));
		}
		
		//Puts a people as infected
		ask one_of(people){
			status <- "infected";
		
		}
		
		step <- 1#minute;
	}
}



//------------------Agent street-------------------------------------
species street{
	aspect basic{ //Street aspect
		draw shape color:#black;
	}
}

//---------------------Agent apples (blocks)--------------------------
species block{ 
	aspect basic{ //Block aspect
		draw shape color:rgb (26, 82, 119,80);
	}
}

//--------------------------Agent people----------------------------
species transport skills:[moving]{
	
	point target; //point where the people should go
	path path_to_follow; //path to follow for the people 
	
	init{
		location <- any_location_in(one_of(block)); //the initial location of the people	
		target <- {438.1037929647038,168.9687552701777,0.0};
		do update_path;
	}
	
	
	
	//Reflex for the agent´s movement
	reflex movement{
		//If the agent arrived the target
		if location = target{
			
			path_to_follow <- nil; //Put the path to follow as empty
			do update_path; //Call the function update_path
		}
		do follow path: path_to_follow; 
	}
	
	

	//Update path
	action update_path{
		vuelta <- vuelta + 1;
		//write "yo soy vuelta" + " " + vuelta;
		loop while:path_to_follow = nil or path_to_follow = []{ //If the path is empty
		 //Change the target to other places
		 switch vuelta{
		 	match 2{
		 		//Target fabrica
		 		ask places where(each.type = "fabrica"){
		 		myself.target <- self.location;
		 		}
		 	}
		 	match 3{
		 		//target covax
		 		ask places where (each.type = "COVAX"){
		 			myself.target <- self.location;
		 		}
		 	}
		 	match 4{
		 		//targey pais
		 		ask places where (each.type = "pais"){
		 			myself.target <- self.location;
		 		}
		 	}
		 	match 5{
		 		//target estado
		 		ask places where (each.type = "estado"){
		 			myself.target <- self.location;
		 		}
		 	}
		 	match 6{
		 		//targeet hospital
		 		ask places where (each.type = "hospital"){
		 			myself.target <- self.location;
		 		}
		 	}
		 	default {
		 		target <- any_location_in(one_of(block));
		 	}
		 }
		path_to_follow <- path_between(network_streets,location,target.location);
		}
	}
	
	aspect basic{
		draw circle(4#m) color:#black;
	}
}


//--------------Agent to represent places)------------------//
species places skills:[messaging]{
	string type;
	//Data for send to blockchain (Receive)
	int address_who_send <- 0;
	int addres_to_send <- 1;
	string type_vaccine <- "VACC1925";
	string process <- "Creación";
	string no_serie <- "XXXD123";
	int date_of_expiry <- 2020;
	int shipping_date <- 2020;
	int date_reception <- 2020;
	string state <- "Good_state";
	
	
		
	//Send data for firs time from fabric to COVAX
	string send_data_fabric{
		string pre_amount_vaccine <- "2000000000000";//Total of vaccines
		return "Enviar" + " " + string(address_who_send) + " " + string(addres_to_send) + " " + type_vaccine + " " + pre_amount_vaccine + " " + process + " " + no_serie + " " + string(date_of_expiry) + " " + string(shipping_date);
	}
	//String for send data from received_data_COVAX
	string receive_data_COVAX{
		string pre_amount_vaccine <- "2000000000000";//Total of vaccines
		return "Recibir" + " " + string(address_who_send) + " " + string(addres_to_send) + " " + no_serie + " " + pre_amount_vaccine + " " + type_vaccine + " " + state + " " + string(date_reception);
	}

	
	
	
	//Function to collect data for send function
	string send_data{
		return "Enviar" + " " + string(address_who_send) + " " + string(addres_to_send) + " " + type_vaccine + " " + string(amount_vaccine) + " " + process + " " + no_serie + " " + string(date_of_expiry) + " " + string(shipping_date);
	}
	
	//Send to blockchain when the data is received
	string receive_data{
		return "Recibir" + " " + string(address_who_send) + " " + string(addres_to_send) + " " + no_serie + " " + string(amount_vaccine) + " " + type_vaccine + " " + state + " " + string(date_reception);	
	}
	
	
	//string to send the name of the pais
	//string send_data_pais{
		//return name_pais;
	//}
	
	//Reflex to evaluate the data to send when the transport agent arrives at a place
	reflex places_question{
		//if the transport reaches the destination
		ask transport where (each.location = location){
			switch myself.type{
				match "fabrica" {
					//Account 1
					//string data <- myself.send_pais();
					send_message_activator <- 0;
					acti <- 1;
					
				}
				match "COVAX" {
					//Account 2
					
					//string data <- myself.data_shipping()
					myself.address_who_send <- 0;
					myself.addres_to_send <- 1;
					string data <- myself.data_received_COVAX();
					Number_transactions <- Number_transactions + 1;
					send_message_activator <- 0;
					acti <- 2;
				}
				match "pais" {
					//Account 3
					myself.address_who_send <- 1;
					myself.addres_to_send <- 2;
					string data <- myself.data_received();
					Number_transactions <- Number_transactions + 1;
					send_message_activator <- 0;
					acti <- 2;
				
				}
				match "estado" {
					//Account 4
					//string _data <- myself.data_received();
					myself.address_who_send <- 2;
					myself.addres_to_send <- 3;
					string data <- myself.data_received();
					Number_transactions <- Number_transactions + 1;
					send_message_activator <- 0;
					acti <- 2;
				}
				match "hospital" {
					//Account 5
					myself.address_who_send <- 3;
					myself.addres_to_send <- 4;
					string data <- myself.data_received();
					Number_transactions <- Number_transactions + 1;
					send_message_activator <- 0;
				}
			}
		}
	}
	
	//Send data of shipping from fabric to COVAX
	reflex acti_1 when: acti = 1{
		string data <- data_fabric();
		Number_transactions <- Number_transactions + 1;
		send_message_activator <- 0;
		acti <-0;
	}
	// send data (Data shipping) from COVAX to pais
	reflex acti_2 when:acti = 2{
		if acti_send = 0{
			process <- "Envio_país";
			address_who_send <- 1;
			addres_to_send <- 2;
			string data <- data_shipping();
			Number_transactions <- Number_transactions + 1;
			send_message_activator <- 0;
			acti <-0;
			
		}
		// send data (Data shipping) from pais to estado
		if acti_send = 1{
			process <- "Envio_estado";
			amount_vaccine <- int(amount_vaccine / 2);
			address_who_send <- 2;
			addres_to_send <- 3;
			string data <- data_shipping();
			Number_transactions <- Number_transactions + 1;
			send_message_activator <- 0;
			acti <-0;
			
		}
		// send data (Data shipping) from estado to hospital
		if acti_send = 2{
			process <- "Envio_hospital";
			amount_vaccine <- int(amount_vaccine / 2);
			address_who_send <- 3;
			addres_to_send <- 4;
			string data <- data_shipping();
			Number_transactions <- Number_transactions + 1;
			send_message_activator <- 0;
			acti <-0;
			
		}
		acti_send <- acti_send + 1;
		
	}
	
	
	
	//Action to send data from fabric to COVAX
	action data_fabric{
		string mydata <- send_data_fabric();
			ask TCP_Client{
			data <- mydata;
			do send_message;
		}
	}
	
	//Send data mediante TCP Blockchain
	action data_shipping{
		string mydata <- send_data();
			ask TCP_Client{
			data <- mydata;
			do send_message;
		}
		
	}
	
	//Send data of reception of vaccine
	action data_received_COVAX{
		string mydata <- receive_data_COVAX();
		ask TCP_Client{
			data <- mydata;
			do send_message;
		}
	}
	
	//Send data of reception of vaccine
	action data_received{
		string mydata <- receive_data();
		ask TCP_Client{
			data <- mydata;
			do send_message;
		}
	}
	
	
	//Aspect of the place
	aspect basic{
		draw square(40#m) color:#red;
		draw string(type) color:#black;
		
	}
}

//--------------------------Agent to represent people--------------------
species people skills:[moving]{
	point target; //target that the people follows
	path path_to_follow;//path that the epeople follows
	float inmunity_time <- 0#seconds; //time of infection of the people
	int firs_contact <- 0; //variable to activate the first place the agent follows
	int age; //People's age
	string morbidity; //Morbidity of the people
	int priority; //priority of the person to receive the vaccine
	int activator <- 0; //
	string status <- "infected" among:["infected","immune", "vaccinated"];
	int count <-0;	
	
	init{
		age <- rnd(100);
		morbidity <- one_of("si", "no");
		location <- any_location_in(one_of(block)); //the initial location of the people
		target <- {438.1037929647038,168.9687552701777,0.0};
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
		loop while:path_to_follow = nil or path_to_follow = []{//si el camino es vacio o (si no encuentra un camino)
		if firs_contact = 2{
			ask places where(each.type = "hospital"){
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
	}
	
	//every so often he visits the hospital
	reflex visit_hospital when:every(rnd(3#hours)){
		if status = "immune"{
			firs_contact <- 0;
			do update_path();
		}
	}
	
	//reflex to evaluate which agent person to vaccinate and send the data to the python server
	reflex Decide{
		ask places where (each.location = location){
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
		return "Aplicar" + " " + string(date_application) + " " + string(age) + " " + string(morbidity);
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


//------------------ TCP CLiente (Send data to Python [Smart Contracts in Blockchain])------------------------

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

//-------------UDP Server (Receive the name amount of the vaccines according to the population)


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


experiment simulacion type:gui{//experiment
	output{//in out do this
		layout #split;
		display GUI type:opengl{//display with black background
			species street aspect:basic;
			species block aspect:basic;
			species transport aspect:basic;
			species places aspect:basic;
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
		
	


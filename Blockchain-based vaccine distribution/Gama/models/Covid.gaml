/**
* Name: COVID
* Based on the internal empty template. 
* Author: Francisco
* Tags: 
*/


model COVID

/* Insert your model definition here */
global{
	int tam; //transaction list size
	int acti <- 0; //variable to activate the sending of data  according to the place
	int acti_send <-0; //Variable to activate the data to send (Data shipping)
	//variable 
	int round <- 0;
	//variable that activates the sending of data to the python server
	int send_message_activator <- 0; 
	
	int Number_transactions <- 0; //variable to update number of transactions
	int received_transactions <- 0;//variable to update the number of transactions received in the python server
	int ethereum_transactions <- 0;//variable to update the number of successful ethereum transactions
	
	bool corruption <- true;
	
	
	//Variables para los envios de vacunas
	int reported_vaccines <-0;
	int reported_vaccines_korea <- 0;
	int reported_vaccines_mexico <-0;
	int reported_vaccines_guadalajara <- 0;
	
	
	//variables para las recepciones de vacunas
	int amount_vaccine <- 0;//number of vaccines sent to the country
	int receive_vaccines_mexico <- 0;
	int receive_vaccines_guadalajara <- 0;
	
	int receive_vaccines_hospital <- 0;
	
	
	
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
		
		//Create places of diferent type
		create places number:1{
			type <- "Mexico";
			location <- any_location_in(one_of(block));
		}
		create places number:1{
			type <- "korea";
			location <- any_location_in(one_of(block));
		}
		create places number:1{
			type <- "Guadalajara";
			location <- any_location_in(one_of(block));
		}
		create places number:1{
			type <- "hospital";
			location <- any_location_in(one_of(block));
		}
		
		//transport agent
		create transport number:1;
		
		//number of agent people
		create people number:10{
			status <- "infected";
		}
		
		create container_vaccine number:1;
		
		step <- 1#minute;
		
	}
}



//***************************** STREET AGENT *************************************
species street{
	aspect basic{ //Street aspect
		draw shape color:#black;
	}
}

//****************************** APPLES AGENT ************************************
species block{ 
	aspect basic{ //Block aspect
		draw shape color:rgb (26, 82, 119,80);
	}
}

//****************************** PLACES AGENT ************************************
species places{
	string type;
	
	int address_who_send <- 0;
	int addres_to_send <- 1;
	
	//string pre_amount_vaccine <- "800000";//Total of vaccines
	string process <- "Creación";
		
	//Send data for firs time from fabric to COVAX
	/* 
	string send_data_fabric{
		
		string prel_amount_vaccine <- "2000000000000";//Total of vaccines
		return "Enviar" + " " + string(address_who_send) + " " + string(addres_to_send) + " " + type_vaccine + " " + pre_amount_vaccine + " " + process + " " + no_serie + " " + string(date_of_expiry) + " " + string(shipping_date);
	}
	* */

	//String for send data from received_data_COVAX
	/* 
	string receive_data_COVAX{
		string pre_amount_vaccine <- "2000000000000";//Total of vaccines
		return "Recibir" + " " + string(address_who_send) + " " + string(addres_to_send) + " " + no_serie + " " + pre_amount_vaccine + " " + type_vaccine + " " + state + " " + string(date_reception);
	}
*/
	
	
	
	//Function to collect data for send function
	/* 
	string send_data{
		return "Enviar" + " " + string(address_who_send) + " " + string(addres_to_send) + " " + type_vaccine + " " + string(amount_vaccine) + " " + process + " " + no_serie + " " + string(date_of_expiry) + " " + string(shipping_date);
	}
	*/
	/* 
	//Send to blockchain when the data is received
	string receive_data{
		return "Recibir" + " " + string(address_who_send) + " " + string(addres_to_send) + " " + no_serie + " " + string(amount_vaccine) + " " + type_vaccine + " " + state + " " + string(date_reception);	
	}
	*/
	
	//string to send the name of the pais
	//string send_data_pais{
		//return name_pais;
	//}
	
	//Reflex to evaluate the data to send when the transport agent arrives at a place
	reflex places_question{
		//if the transport reaches the destination
		ask transport where (each.location = location){
			switch myself.type{
				match "korea" {
					//Account 1
					//string data <- myself.send_pais();
					send_message_activator <- 0;
					acti <- 1;
		
					
				}
				match "Mexico" {
					//Account 2
					
					//string data <- myself.data_shipping()
					myself.address_who_send <- 0;
					myself.addres_to_send <- 1;
					string data <- myself.data_received_COVAX();
					Number_transactions <- Number_transactions + 1;
					send_message_activator <- 0;
					acti <- 2;
				
				}
				match "Guadalajara" {
					//Account 3
					myself.address_who_send <- 1;
					myself.addres_to_send <- 2;
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
					acti <- 2;
				}
			}
		}
	}
	
	//Send data of shipping from korea to mexico
	reflex acti_1 when: acti = 1{
		amount_vaccine <- 5000;
		if corruption = true{
			reported_vaccines <- rnd(amount_vaccine, amount_vaccine + 10);
		}
		else{
			reported_vaccines <- amount_vaccine;
		}
		reported_vaccines_korea <- reported_vaccines;
		write reported_vaccines;
		string data <- data_fabric();
		Number_transactions <- Number_transactions + 1;
		send_message_activator <- 0;
		acti <-0;
	}
	// send data (Data shipping) from mexico to pais
	reflex acti_2 when:acti = 2{
		if acti_send = 0{
			process <- "Envio_país";
			address_who_send <- 1;
			addres_to_send <- 2;
			
			receive_vaccines_mexico <- amount_vaccine;
			if corruption = true{
				reported_vaccines <- rnd(amount_vaccine, amount_vaccine + 10);
			}
			else{
				reported_vaccines <- amount_vaccine;
			}
			
			reported_vaccines_mexico <- reported_vaccines;
			write reported_vaccines;
			string data <- data_shipping();
			Number_transactions <- Number_transactions + 1;
			send_message_activator <- 0;
			acti <-0;
			
		}
		// send data (Data shipping) from pais to estado
		if acti_send = 1{
			process <- "Envio_estado";
			//ask container_vaccine{
			receive_vaccines_guadalajara <- amount_vaccine;
				amount_vaccine <- int(amount_vaccine / 2);
				
				if corruption = true{
					reported_vaccines <-rnd(amount_vaccine, amount_vaccine + 10);
				}
				else{
					reported_vaccines <- amount_vaccine;
				}
				
				reported_vaccines_guadalajara <- reported_vaccines;
				write reported_vaccines;
			//}
			address_who_send <- 2;
			addres_to_send <- 3;
			string data <- data_shipping();
			Number_transactions <- Number_transactions + 1;
			send_message_activator <- 0;
			acti <-0;
			
		}
		// send data (Data shipping) from estado to hospital
		if acti_send = 2{
			receive_vaccines_hospital <- amount_vaccine;
		}
		acti_send <- acti_send + 1;
	}
	
	
	
	//Action to send data from korea to mexico
	action data_fabric{
		string send_datakar;
		ask container_vaccine{
			send_datakar <- "Enviar" + " " + string(myself.address_who_send) + " " + string(myself.addres_to_send) + " " + type_vaccine + " " + string(reported_vaccines) + " " + myself.process + " " + no_serie + " " + string(date_of_expiry) + " " + string(shipping_date);
		}
		string mydata <- send_datakar;
			ask TCP_Client{
			data <- mydata;
			do send_message;
		}
	}
	
	//Send data mediante TCP Blockchain
	action data_shipping{
		string send_data;
		ask container_vaccine{
			send_data <- "Enviar" + " " + string(myself.address_who_send) + " " + string(myself.addres_to_send) + " " + type_vaccine + " " + string(reported_vaccines) + " " + myself.process + " " + no_serie + " " + string(date_of_expiry) + " " + string(shipping_date);
		}
		string mydata <- send_data;
			ask TCP_Client{
			data <- mydata;
			do send_message;
		}
		
	}
	
	//Send data of reception of vaccine
	action data_received_COVAX{
		string receive_data_mexico;
		
		ask container_vaccine{
			receive_data_mexico <- "Recibir" + " " + string(myself.address_who_send) + " " + string(myself.addres_to_send) + " " + no_serie + " " + string(amount_vaccine) + " " + type_vaccine + " " + state + " " + string(date_reception);
		}
		string mydata <- receive_data_mexico;
		ask TCP_Client{
			data <- mydata;
			do send_message;
		}
	}
	
	//Send data of reception of vaccine
	action data_received{
		string receive_data;
		ask container_vaccine{
			receive_data <- "Recibir" + " " + string(myself.address_who_send) + " " + string(myself.addres_to_send) + " " + no_serie + " " + string(amount_vaccine) + " " + type_vaccine + " " + state + " " + string(date_reception);	
		}
		string mydata <- receive_data;
		ask TCP_Client{
			data <- mydata;
			do send_message;
		}
	}
	
	
	//Aspect of the place
	aspect basic{
		draw square(40#m) color:#red;
		draw type color:#black;
	}
}

species container_vaccine{
	//Data for send to blockchain (Receive)
	string type_vaccine <- "VACC1925";
	
	string no_serie <- "XXXD123";
	int date_of_expiry <- 2020;
	int shipping_date <- 2020;
	int date_reception <- 2020;
	string state <- "Good_state";
}

//****************************** TRANSPORT AGENT **********************************
species transport skills:[moving]{
	
	point target; //point where the transport should go
	path path_to_follow; //path to follow for the transport
	
	init{
		location <- any_location_in(one_of(block)); //the initial location of the people	
		target <- any_location_in(one_of(street));
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
		round <- round + 1;
		//write "yo soy vuelta" + " " + vuelta;
		loop while:path_to_follow = nil{ //If the path is empty
		 //Change the target to other places
		 switch round{
		 	match 2{
		 		//Target fabrica
		 		ask places where(each.type = "korea"){
		 		myself.target <- self.location;
		 		write "Voy a la fabrica";
		 		}
		 	}
		 	match 3{
		 		//target mexico
		 		ask places where (each.type = "Mexico"){
		 			myself.target <- self.location;
		 			write "Voy a Mexico";
		 		}
		 	}
		 	match 4{
		 		//targey pais
		 		ask places where (each.type = "Guadalajara"){
		 			myself.target <- self.location;
		 			write "Voy a pais";
		 		}
		 	}
		 	match 5{
		 		//targeet hospital
		 		ask places where (each.type = "hospital"){
		 			myself.target <- self.location;
		 			write "Voy a hospital hospital";
		 		}
		 	}
		 	match 7{
		 		do die;
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

//******************************** EXPERIMENT ***********************************
experiment simulation type:gui{
	output{
		layout #split;
		monitor Shipped_korea value: reported_vaccines_korea;
		monitor Received_Mexico value: receive_vaccines_mexico;
		monitor Shipped_mexico value: reported_vaccines_mexico;
		monitor Received_Guadalajara value: receive_vaccines_guadalajara;
		monitor Shipped_Guadalajara value: reported_vaccines_guadalajara;
		monitor Received_hospital value: receive_vaccines_hospital;
		
		display GUI type:opengl{//display with black background
			species street aspect:basic;
			species block aspect:basic;
			species places aspect:basic;
			species transport aspect:basic;
			species people aspect:basic;
		}
		/* 
		display "Transacciones Reportadas"{
			chart "Transactions" type:histogram y_label:"Number of transactions"{
				data "Transacciones rep factory " value:reported_vaccines_factory color:#blue marker:false;
				data "Transacciones rep COVAX" value:reported_vaccines_COVAX color:#red marker:false;
				data "Transacciones rep Country" value:reported_vaccines_country color:#red marker:false;
				data "Transacciones rep State" value:reported_vaccines_state color:#red marker:false;
			}
		}
		display "Transacciones Recibidas"{
			chart "Transactions" type:histogram y_label:"Number of transactions"{
				data "Transacciones rec COVAX " value:receive_vaccines_COVAX color:#blue marker:false;
				data "Transacciones rec Country" value:receive_vaccines_country color:#red marker:false;
				data "Transacciones rec State" value:receive_vaccines_state color:#red marker:false;
				data "Transacciones rec Hospital" value:receive_vaccines_hospital color:#red marker:false;
			}
		}
		* */
		
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
/**
* Name: GDLHosp
* Based on the internal empty template. 
* Author: Francisco
* Tags: 
*/


model GDLHosp

/* Insert your model definition here */

global{
	
	//variables for the ethereum accounts
	int address_who_send <- 2;
	int addres_to_send <- 3;
	
	bool corruption <- true;
	
	string process <- "Shipping";
	
	int amount_vaccine <- 0;
	
	//Variables para los envios de vacunas
	int reported_vaccines <-0;
	int reported_vaccines_mexico <-0;
	int receive_vaccines_guadalajara <- 0;
	
	//variable that activates the sending of data to the python server
	int send_message_activator <- 0; 
	
	file map_file <- file("../includes/Guadalajara/hosp/Blocks.shp");//apple files
	file streets <- file("../includes/Guadalajara/hosp/Roads.shp"); //Streets files
	geometry shape <- envelope(streets);//Ambient take the form of the streets file
	graph network_streets; //We declare a street graph
	
	init{
		create block from:map_file; //we create the block agent
		create street from:streets; //We create the street agent
		network_streets <- as_edge_graph(street);//We create a graph with the agent street
		
		//TCP Client to send data to smart contracts 
		create TCP_Client number:1{
			do connect to: "localhost" protocol: "tcp_client" port: 9999 with_name: "Client";
		}
		
		create container_vaccine number:1;
		
		//transport agent
		create transport number:1;
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

//****************************** TRANSPORT AGENT ************************************
species transport skills:[moving]{
	point target; //point where the transport should go
	path path_to_follow; //path to follow for the transport
	
	init{
		ask block where(each.name = "block59"){
			myself.location <- location;
		}
		ask block where(each.name = "block243"){
			myself.target <- location;
		}
		do update_path;
	} 
	
	//Reflex for the agent´s movement
	reflex movement{
		//If the agent arrived the target
		if location = target{
			do receive_vaccine;
			path_to_follow <- nil; //Put the path to follow as empty
			do update_path; //Call the function update_path
		}
		do follow path: path_to_follow; 
	}
	
	action update_path{
		loop while:path_to_follow = nil{ //If the path is empty
			path_to_follow <- path_between(network_streets,location,target.location);
		}
	}
	
	 reflex llegue when:time= 2{
    		do send_vaccine;
    }
   
   //*************************send Vaccine**************************************
	action send_vaccine{
			amount_vaccine <- 160000;
			process <- "Envio_país";
			
			if corruption = true{
				reported_vaccines <- rnd(amount_vaccine, amount_vaccine + 10);
			}
			else{
				reported_vaccines <- amount_vaccine;
			}
			reported_vaccines_mexico <- reported_vaccines;
			write reported_vaccines;
			string data <- data_shipping();
			send_message_activator <- 0;
			
		}
		
		//Send data mediante TCP Blockchain
	action data_shipping{
		string send_data;
		ask container_vaccine{
			send_data <- "Enviar" + " " + string(address_who_send) + " " + string(addres_to_send) + " " + type_vaccine + " " + string(reported_vaccines) + " " + process + " " + no_serie + " " + string(date_of_expiry) + " " + string(shipping_date);
		}
		string mydata <- send_data;
			ask TCP_Client{
			data <- mydata;
			do send_message;
		}
	}
	
	 //*************************get Vaccine**************************************
	action receive_vaccine{
		//Account 3
		receive_vaccines_guadalajara <- amount_vaccine;
		string data <- data_received();
	}
	
	//Send data of reception of vaccine
	action data_received{
		string receive_data;
		ask container_vaccine{
			receive_data <- "Recibir" + " " + string(address_who_send) + " " + string(addres_to_send) + " " + no_serie + " " + string(amount_vaccine) + " " + type_vaccine + " " + state + " " + string(date_reception);	
		}
		string mydata <- receive_data;
		ask TCP_Client{
			data <- mydata;
			do send_message;
		}
	}
	
	aspect basic{
		draw circle(10) color:#red;
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

experiment main type:gui{
	output{
		layout #split;
		monitor Shipped_Mexico value: reported_vaccines_mexico;
		monitor Received_Gdl value: receive_vaccines_guadalajara;
		display GUI type:opengl{
			species block aspect:basic;
			species street aspect:basic;
			species transport aspect:basic;
		}
	}
}

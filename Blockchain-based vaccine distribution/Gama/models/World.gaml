/**
* Name: World
* Based on the internal empty template. 
* Author: Francisco
* Tags: 
*/


model World

/* Insert your model definition here */
global{
	//variables for the ethereum accounts
	int address_who_send <- 0;
	int addres_to_send <- 1;
	
	int send_message_activator <- 0; 
	
	bool corruption <- true;
	
	int amount_vaccine <- 0;
	
	string process <- "Shipping";
	
	bool rec <- false;
	
	//Variables para los envios de vacunas
	int reported_vaccines <-0;
	int reported_vaccines_korea <- 0;
	int receive_vaccines_mexico <- 0;
	
	
	file map_file <- file("../includes/mapa.shp");//apple files
	geometry shape <- envelope(map_file);//Ambient take the form of the streets file
	init{
		create block from:map_file; //we create the block agent
		create transport number:1;
		
		//TCP Client to send data to smart contracts 
		create TCP_Client number:1{
			do connect to: "localhost" protocol: "tcp_client" port: 9999 with_name: "Client";
		}
		
		create container_vaccine number:1;
		
	}
}

//****************************** MAP AGENT ************************************
species block{ 
	aspect basic{ //Block aspect
		draw shape color:rgb(26, 82, 119,80);
	}
	
	
}

//****************************** Transport AGENT ************************************
species transport skills:[moving]{
	
	point target; //point where the transport should go
	path path_to_follow; //path to follow for the transport
	
	init{
		
		ask block where(each.name = "block122"){
			myself.location <- location;
		}
		ask block where(each.name = "block155"){
			myself.target <- location;
		}
		
	}
	 //Transport agent goes to the target
	reflex follow when: target!=nil {
    //speed <- 0.8;
    	do goto target: target;
    	if location = target{
    		do received_vaccines;
    		if rec = false{
    			if corruption = true{
					receive_vaccines_mexico <- rnd(amount_vaccine, amount_vaccine - 10);
				}
				if corruption = false{
					receive_vaccines_mexico <- amount_vaccine;
				}
				rec <- true;
    		}
    		
    	}
    }
    
   
    reflex llegue when:time= 2{
    		do send_vaccines;
    }
    
    //******************* send data from Korea****************************
    //Send data of shipping from korea to mexico
	action send_vaccines{
		amount_vaccine <- 5500000;
	
		reported_vaccines <- amount_vaccine;
		
		reported_vaccines_korea <- reported_vaccines;
		write reported_vaccines;
		string data <- data_fabric();
		send_message_activator <- 0;
	}
	
	//Action to send data from korea to mexico
	action data_fabric{
		string send_datakar;
		ask container_vaccine{
			send_datakar <- "Enviar" + " " + string(address_who_send) + " " + string(addres_to_send) + " " + type_vaccine + " " + string(reported_vaccines) + " " + process + " " + no_serie + " " + string(date_of_expiry) + " " + string(shipping_date);
		}
		string mydata <- send_datakar;
			ask TCP_Client{
			data <- mydata;
			do send_message;
		}
	}
	
	//**********************data received in Mexico************************
	
	action received_vaccines{
		//Account 2
		
	
	//string data <- myself.data_shipping()
		string data <- data_received_MX();
		
	}
	
	//Send data of reception of vaccine
	action data_received_MX{
		string receive_data_mexico;
		
		ask container_vaccine{
			receive_data_mexico <- "Recibir" + " " + string(address_who_send) + " " + string(addres_to_send) + " " + no_serie + " " + string(amount_vaccine) + " " + type_vaccine + " " + state + " " + string(date_reception);
		}
		string mydata <- receive_data_mexico;
		ask TCP_Client{
			data <- mydata;
			do send_message;
		}
	}
	
	aspect basic{
		draw circle(1#m) color:#black;
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
		monitor Shipped_korea value: reported_vaccines_korea;
		monitor Received_Mexico value: receive_vaccines_mexico;
		display GUI type:opengl{
			species block aspect:basic;
			species transport aspect:basic;	
		}
	}
}

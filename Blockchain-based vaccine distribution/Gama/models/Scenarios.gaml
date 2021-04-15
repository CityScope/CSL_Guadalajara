/**
* Name: Simulations
*  
* Author: Gamaliel
* Tags: 
*/

model Simulations
import "Application_v2.gaml"

experiment Several_simulations type:batch until:int(timeElapsed/86400)=60{
	init{
		create simulation with:[
			scenario::"scenario1",
			enable_sending_data::true,
			case_study::"Guadalajara/small",
			save_to_csv::true
		];
	}
}

experiment gui type:gui{
	parameter 'enable_sending_data' var:enable_sending_data <- true;
	parameter 'case_study' var:case_study <- "Guadalajara/small";
	output{
		monitor "aplicaciones" value:nb_applications;
		layout #split;
		display GUI type:opengl draw_env:false background:#black{
			species block aspect:pob_60_mas;
			species vaccination_point aspect:basic;
			//species street aspect:gray;
			species people aspect:basic;
			species manager aspect:default;
		}
		display "Vaccination plan"{
			chart "Vaccination" type:series y_label:"Number"{
				data "Used Physical Tokens" value:length(people where(each.status = "vaccinated")) color:people_color["vaccinated"] marker:false;
				data "Priority 1 people" value:length(people_priority_1) color:#blue marker:false;
				data "Priority 2 vaccinated" value:length(people where(each.age<60 and each.status ="vaccinated")) marker:false;
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

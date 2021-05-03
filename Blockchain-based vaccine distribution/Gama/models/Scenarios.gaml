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
	parameter 'enable_sending_data' var:enable_sending_data <- false;
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
				data "Priority 1 people" value:length(people where(each.age > 59 and each.status="vaccinated")) color:#blue marker:false;
				data "Priority 2 vaccinated" value:length(people where(each.age<60 and each.status ="vaccinated")) marker:false;
			}
		}
		
	}
	
}

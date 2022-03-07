/**
* Name: Simulations
* Based on the internal empty template. 
* Author: Gamaliel Palomo
* Tags: 
*/


model Simulations
import "Core.gaml"
/* Insert your model definition here */

experiment Bar type:gui{
	parameter "case study" var:case_study <- "students";
	output{
		layout #split;
		display Simulation type:opengl background:#black draw_env:false {
			species block aspect:use_type;
			species cityscope_shape aspect:default;
			species hex_zone aspect:default;
			//species facilities aspect:default;
		}
		display Movement type:opengl background:#black draw_env:false{
			species block aspect:use_type;
			species roads aspect:default;
			species cityscope_shape aspect:default;
			species people aspect:mobility_accessibility;
		}
		display Overall type:java2D background:#black draw_env:false refresh:every(10#cycles) toolbar:false{
			chart "Desempeño" y_range:[0,1.0] y_tick_line_visible:false type:histogram background:#black color:#white label_font:font("Arial",20,#plain) legend_font:font("Arial",20,#plain) title_font:font("Arial",30,#plain) 	tick_font:font("Arial",20,#plain)
			series_label_position: xaxis tick_line_color:#white axes:#white x_tick_values_visible:false x_serie:[0,1]  
			{
				datalist legend:["Acceso a mobilidad","Acceso a educación","Diversidad","Relación habitación/empleo","Densidad", "Acceso a salud","Acceso a cultura"] 
				style: bar
				color:[#mistyrose,rgb (159, 225, 165,255),#pink,#hotpink,#gamaorange,rgb (106, 129, 204,255),rgb (221, 224, 84,255)]
				value:[transport_accessibility,education_accessibility,diversity,hab_emp_ratio,density,health_accessibility,culture_accessibility];
			}
		}
	}
}
experiment Radar type:gui{
	parameter "case study" var:case_study <- "students";
	output{
		layout #split;
		display Simulation type:opengl background:#black draw_env:false {
			species block aspect:use_type;
			species cityscope_shape aspect:default;
			species hex_zone aspect:default;
		}
		display Movement type:opengl background:#black draw_env:false{
			species cityscope_shape aspect:default;
			species people aspect:mobility_accessibility;
		}
		display Overall type:java2D background:#black draw_env:false refresh:every(10#cycles) toolbar:false{
			chart "Desempeño" y_range:[0,2.0] y_tick_line_visible:false type:histogram background:#black color:#white label_font:font("Arial",20,#plain) legend_font:font("Arial",20,#plain) title_font:font("Arial",30,#plain) 	tick_font:font("Arial",20,#plain)
			series_label_position: xaxis tick_line_color:#white axes:#white x_tick_values_visible:false x_serie:[0,1]  
			{
				datalist legend:["Acceso a mobilidad","Diversidad","Relación habitación/empleo","Densidad"] 
				style: bar
				color:[#mistyrose,#pink,#hotpink,#gamaorange]
				value:[transport_accessibility,diversity,hab_emp_ratio,density];
			}
		}
		display Overall type: java2D
		{
			
			chart "Desempeño" type: radar x_serie_labels: ["Acceso a mobilidad","Acceso a educación","Diversidad","Relación habitación/empleo","Densidad", "Acceso a salud","Acceso a cultura"] series_label_position: xaxis
			{
				data "Escenario A" value: [inc+scenario_a[0],inc+scenario_a[1],inc+scenario_a[2],inc+scenario_a[3],inc+scenario_a[4],inc+scenario_a[5],inc+scenario_a[6]] color: # red;
				data "Escenario B" value: [inc+scenario_b[0],inc+scenario_b[1],inc+scenario_a[2],inc+scenario_a[3],inc+scenario_a[4],inc+scenario_a[5],inc+scenario_a[6]] color: # blue;
			}
			/*
			chart "data_non_cumulative_bar_chart" type: radar x_serie_labels: ["axeCos", "axeSin", "axeCosSin"] series_label_position: xaxis
			{
				data "Cycle" value: [1 + cos(cycle), 1 + sin(1 * cycle), 1 + cos(1 * cycle) * sin(cycle)] color: # yellow;
				data "2Cycle" value: [1 + cos(1 * cycle * 2), 1 + sin(1 * cycle * 2), 1 + cos(1 * cycle * 2) * sin(1 * cycle * 2)] color: # blue;
				data "5Cycle" value: [1 + cos(1 * cycle * 5), 1 + sin(1 * cycle * 5), 1 + cos(1 * cycle * 5) * sin(1 * cycle * 5)] color: # red;
			}*/

		}
		display Scenario_a type: java2D
		{
			
			chart "Desempeño" type: radar x_serie_labels: ["Acceso a mobilidad","Acceso a educación","Diversidad","Relación habitación/empleo","Densidad", "Acceso a salud","Acceso a cultura"] series_label_position: xaxis
			{
				data "Current scenario" value: [inc+transport_accessibility,inc+education_accessibility,inc+diversity,inc+hab_emp_ratio,inc+density,inc+health_accessibility,inc+culture_accessibility] color: # blue;
			}
			/*
			chart "data_non_cumulative_bar_chart" type: radar x_serie_labels: ["axeCos", "axeSin", "axeCosSin"] series_label_position: xaxis
			{
				data "Cycle" value: [1 + cos(cycle), 1 + sin(1 * cycle), 1 + cos(1 * cycle) * sin(cycle)] color: # yellow;
				data "2Cycle" value: [1 + cos(1 * cycle * 2), 1 + sin(1 * cycle * 2), 1 + cos(1 * cycle * 2) * sin(1 * cycle * 2)] color: # blue;
				data "5Cycle" value: [1 + cos(1 * cycle * 5), 1 + sin(1 * cycle * 5), 1 + cos(1 * cycle * 5) * sin(1 * cycle * 5)] color: # red;
			}*/

		}
	}
}

//
/*overlay size: { 5 #px, 50 #px } {
				draw "áéíóúabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.:0123456789([])" at: {0#px,0#px} color:rgb(0,0,0,0) font: font("Arial", 15, #plain);
				draw "áéíóúabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.:0123456789" at: {0#px,0#px} color:rgb(0,0,0,0) font: font("Arial", 25,#bold);
				draw "áéíóúabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.:0123456789" at: {0#px,0#px} color:rgb(0,0,0,0) font: font("Arial", 20,#bold);
				draw "Uso de suelo" color:#white at:{50,420} font: font("Arial", 20,#bold);
				loop i from:0 to:length(use_type_color.keys)-1{
					draw square(30) color:use_type_color.values[i] at:{50,520+100*i};
					draw use_type_color.keys[i]  color:#white at:{100,530+100*i} font: font("Arial", 15, #plain);
				}
				draw string(current_date) at:{30#px,30#px} color:#white font: font("Arial", 25,#bold);
				draw "Population: "+length(people) at:{30#px,50#px} color:#white font: font("Arial", 20,#bold);
				draw "Medio de transporte" color:#white at:{50,2000} font: font("Arial", 20,#bold);
				loop i from:0 to:length(mobility_colors.keys)-1{
					draw circle(30) color:mobility_colors.values[i] at:{50,2100+100*i} ;
					draw mobility_colors.keys[i] + " ("+mobility_count[mobility_colors.keys[i]] +")" at:{100,2130+100*i} font: font("Arial", 15, #plain) color:#white;
					//
				}
			}*/
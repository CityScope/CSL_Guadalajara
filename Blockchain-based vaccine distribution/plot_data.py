import matplotlib.pyplot as plt
import numpy as np
import csv

scenarios = 1

x 						= [[] for i in range(1,scenarios+1)]
physical_tokens 		= [[] for i in range(1,scenarios+1)]
virtual_tokens 			= [[] for i in range(1,scenarios+1)]
applied_vaccines		= [[] for i in range(1,scenarios+1)]
applied_virtual_tokens	= [[] for i in range(1,scenarios+1)]
priority_1_people		= [[] for i in range(1,scenarios+1)]
priority_2_vaccinated	= [[] for i in range(1,scenarios+1)]
number_applications 	= [[] for i in range(1,scenarios+1)]

def read_files():

	for i in range(scenarios):
		with open('Gama/output/results_scenario'+str(i+1)+'.csv') as csv_file:
			csv_reader = csv.reader(csv_file,delimiter=',')
			line_count = 0
			for row in csv_reader:
				x[i].append(int(row[1]))
				physical_tokens[i].append(int(row[2]))
				virtual_tokens[i].append(int(row[3]))
				applied_vaccines[i].append(int(row[4]))
				applied_virtual_tokens[i].append(int(row[5]))
				priority_1_people[i].append(int(row[6]))
				priority_2_vaccinated[i].append(int(row[7]))
				number_applications[i].append(int(row[8]))
			


def question1():
	#Pregunta 1
	plt.clf()
	current_x = x[0]
	print(physical_tokens[0])
	plt.plot(current_x,applied_vaccines[0], color = "green", label="Applied vaccines")
	plt.plot(current_x,priority_1_people[0],color = "blue", label="Priority 1 people")
	plt.plot(current_x,priority_2_vaccinated[0],color = "brown", label="Priority 2 vaccinated")
	plt.xlabel("Days")
	plt.ylabel("Number of cases")
	plt.title("Vaccination")
	
	plt.xticks(np.arange(0,len(current_x),4))
	#plt.yticks(np.arange(len(physical_tokens),0,4))
	plt.legend()
	plt.savefig("Gama/output/prueba/vaccination.png")

	plt.clf()
	current_x = x[0]
	print(physical_tokens[0])
	plt.plot(current_x,virtual_tokens[0], color = "orange", label="Remaining Virtual Tokens")
	plt.plot(current_x,applied_virtual_tokens[0], color = "blue", label="Applied Virtual Tokens")
	plt.plot(current_x,physical_tokens[0], color = "red", label="Remaining Physical Tokens")
	plt.plot(current_x, number_applications[0], color="green", label="Applied Physical Tokens")
	plt.xlabel("Days")
	plt.ylabel("Number of cases")
	plt.title("Token counter")
	
	plt.xticks(np.arange(0,len(current_x),4))
	#plt.yticks(np.arange(len(physical_tokens),0,4))
	plt.legend()
	plt.savefig("Gama/output/prueba/tokens.png")
	



if __name__ == '__main__':
	read_files()
	question1()
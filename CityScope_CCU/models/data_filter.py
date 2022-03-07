import matplotlib.pyplot as plt
import numpy as np
import csv
file_names = {1:"Migrantes14",2:"Personas14",3:"Viviendas14"}
data = {}
filtered = []
value_index = [1,2,3,4,5,6,7,8,9,12,13,44,45,46,47,48,49,
50,51,52,53,55,56,57,61,62,63,71,72,73,74,75,76,77,78,79];
mobility_mode = {'estudiantes':["caminando", "bicicleta", "metro", "trolebus", "metrobus", "camion", "escolar", "taxi normal", "taxi app", "motocicleta", "automovil", "otro"],
					'trabajadores':["caminando", "bicicleta", "metro", "trolebus", "metrobus", "camion", "transporte de personal", "taxi normal", "taxi app", "motocicleta", "automovil", "otro"]}
column_names = []

file_number = 2

def load_files():
	with open('../includes/csv/'+file_names[file_number]+'.csv') as csv_file:
		csv_reader = csv.reader(csv_file,delimiter=',')
		first = True
		for row in csv_reader:
			i = 0
			if(first):
				for column in row:
					data[column] = []
					column_names.append(column)
				first = False
			else:
				for value in row:
					data[column_names[i]].append(value)
					i = i+1	

load_files()
def get_people_by_mun(x):
	print("getting people from "+str(x))
	for i in range(len(data[column_names[1]])):
		if data[column_names[1]][i] == str(x):
			values = {}
			for index in value_index:
				values[index] = data[column_names[index-1]][i]
			filtered.append(values)
	return filtered

def get_non_commuters(population):
	result = []
	for person in population:
		#or person[61] == '30' or person[61] == '40' or person[61] == '60' or person[61] == '70' or person[61] == '80' or person[76] == '7':
		#Estudiantes que se trasladan: person[44] == '1' or person[47] == '1' or person[47] == '2' or person[47] == '3' or person[47] == '5'
		#Trabajadores que se desplazan: person[61] == '10' or person[76] == '1' or person[76] == '2' or person[76] == '3' or person[76] == '4' or person[76] == '5'
		if  person[44] == '1' and person[47] == '1':# or person[47] == '2':# or person[47] == '3':# or person[47] == '4' or person[47] == '5':
			result.append(person)
	count = {str(x):0 for x in mobility_mode['estudiantes']}
	for p in result:
		if p[48] == '01':
			count["caminando"] += 1
		if p[48] == '02':
			count["bicicleta"] += 1
		if p[48] == '03':
			count["metro"] += 1
		if p[48] == '04':
			count["trolebus"] += 1
		if p[48] == '05':
			count["metrobus"] += 1
		if p[48] == '06':
			count["camion"] += 1
		if p[48] == '07':
			count["escolar"] += 1
		if p[48] == '08':
			count["taxi normal"] += 1
		if p[48] == '09':
			count["taxi app"] += 1
		if p[48] == '10':
			count["motocicleta"] += 1
		if p[48] == '11':
			count["automovil"] += 1
		if p[48] == '12':
			count["otro"] += 1

	return count



people_from_zapopan = get_people_by_mun(120)
print("People from Zapopan: "+str(len(people_from_zapopan)))
workers_by_mobility_mode = get_non_commuters(people_from_zapopan)
print("Students mobility mode: "+str(workers_by_mobility_mode))

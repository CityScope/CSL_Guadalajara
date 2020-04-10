input_file = open("terrain_asc.asc")
output_file = open("python_output.asc",'w')
lines = input_file.readlines()
cell_size = 5
xllcorner = 0
yllcorner = 0
NODATA_value = -9999
xcor = []
ycor = []
zval = []
for element in lines:
	numbers = element.split(" ")
	xcor.append(int(float(numbers[0])))
	ycor.append(int(float(numbers[1])))
	zval.append(float(numbers[2]))
#max_xcor/cell_size = number of columns
#max_ycor/cell_size = number of rows
print ("len(xcor): "+str(len(xcor)))
print ("len(ycor): "+str(len(ycor)))
print ("len(zval): "+str(len(zval)))
n_rows = int(max(ycor)/cell_size)
n_columns = int(max(xcor)/cell_size)
print ("n_rows: ",n_rows)
print ("n_columns: ",n_columns)

#Fill output_matrix with NODATA_value
output_matrix = []
for row in range(0,n_rows):
	row_i = []
	for column in range(0,n_columns):
		row_i.append(NODATA_value)
	output_matrix.append(row_i)
print (len(output_matrix))
#Fill output_matrix with actual values
for i in range(0,len(xcor)):
	print ("current ycor:",ycor[i])
	output_matrix[int(ycor[i]/cell_size)-1][int(xcor[i]/cell_size)-1] = zval[i] #xcor->columns and ycor->rows

output_file.write("ncols\t"+str(n_columns)+"\n")
output_file.write("nrows\t"+str(n_rows)+"\n")
output_file.write("xllcorner\t"+str(xllcorner)+"\n")
output_file.write("yllcorner\t"+str(yllcorner)+"\n")
output_file.write("cellsize\t"+str(cell_size)+"\n")
output_file.write("NODATA_value\t"+str(NODATA_value)+"\n")

for i in range(0,len(output_matrix)):
	for j in range(0,len(output_matrix[0])):
		output_file.write(str(output_matrix[i][j])+" ")
	output_file.write("\n")
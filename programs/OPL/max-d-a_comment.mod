/*********************************************
 * OPL 12.10.0.0 Model
 * 
 * Version Date: 21 oct. 2021
 *********************************************/


//Data declarations
int n = ...;			// Number of observations 
int m = ...;			// Number of features
float C = ...;			// Penalization parameter
float C_intra = ...;
float C_inter = ...;
range N = 1..n;
range M = 1..m;
int y[N] = ...;			// Class of each observation
float x[N][M] = ...;		// Description of each observation
float a[N][N][M];		// Pre-processing array

//Decision variables
dvar float+ w[M];		// Weight of each feature
dvar float+ xi[N];		// Penalization of each observations
dvar float+ r;			// Least inter-class distance; greatest intra-class distance for Min models


/*********************************************
 * This function aims at simplify the program
 *********************************************/
//Pre-processing
execute {
	for(var i in N){
	  for(var j in N){
	    for(var k in M){
	      a[i][j][k] = (x[i][k] - x[j][k]) * (x[i][k] - x[j][k]); 
	      }
	    }
	}
}


//Objective function
maximize r - (1 / C) * (sum (i in N) xi[i]);


//Constraints
subject to {
	forall(i in N, j in N){
		if (y[i] == y[j]) {	// Constraints for the same class
			sum (k in M) a[i][j][k] * w[k] <= 1 + xi[i];
		} else {		// Constraints for different classes
			sum (k in M) a[i][j][k] * w[k] >= r;
		}
	}
}


main {
	var ofile = new IloOplOutputFile("./../../inter_process/tmp/tmp");	// Temporary output file

	/**************************************************************************************
	 * The same model with the almost same data, use Flow control in Cplex to achive that
	 * It could generate the same model by just changing the value of some parameters
	 **************************************************************************************/
	// Generate the first model
	thisOplModel.generate();	// Generate the initial model
	var produce = thisOplModel;	// Assign with all initial values
	var C_now = produce.C;		// Get the initial C value
	var i = 0;			// Iteration parameter of C
	cplex.tilim = 600;		// Set time limit of 10 minutes

	/*********************************************
	 * Set up 2 break conditions to save time
	 * 1. All the weights are assigned with 0
	 * 2. Time limit of 10 minutes reached
	 *********************************************/
	// Iteration of C
	while (i <= 10) {
		// Solve current problem
		i++;
		var time = new Date();		// Get the time before running linear progromming model
		start = time.getTime();
		if (cplex.solve()){
			var time = new Date();	// Get the time after running linear progromming model
			end = time.getTime();
			var count = 0;		// Count the number of non-zero weights
			ofile.write((i - 1) + ";-1;")		// Output C_intra and C_inter
			for(var k = 1; k <= thisOplModel.m; k++) {
				if (produce.w[k] > 0) {		// Output positif weight
					ofile.write(produce.w[k] + ";");
					count++;
				} else {			// Output negatif or 0 weight
					// Output negatif or 0 weight 
					// Due to the float precision, some weights may be a extremely small negatif value
					// In this case, write a "0" instead of the extremyly small negatif value
					ofile.write("0;");
				}
			}
			// Output running time of linear programming model and number of non-zero weights
			ofile.writeln(((end - start) / 1000) + ";" + count);
			if (count == 0) {
				break;				// Break while all weights 0
			}
		} else {
			var time = new Date();			// Get the time after running linear progromming model
			end = time.getTime();
			// OPL is not solved; output a running time (about 600) and a 0 (initial count value)
			ofile.writeln(((end - start) / 1000) + ";" + count);
			break;					// Break while reaching time limit
		}
		
		// Flow control part for the next iteration
		if (i <= 10) {
			var def = produce.modelDefinition;		// Definition of new model
			var data = produce.dataElements;		// Copy the old input data
			produce = new IloOplModel(def,cplex);		// Assemble to new model
	    		C_now = C_now * 2;				// Modify the C value
			data.C = C_now;
			produce.addDataSource(data);			// Add new values to the model
			produce.generate();				// Generate the new model
		}
	}
	
	
	/**************************************************************************************
	 * Comment all above and use the following code if iteration is achieved in bash
	 **************************************************************************************/
	/*
	thisOplModel.generate();	// Generate the initial model
	var produce = thisOplModel;	// Assign with all initial values
	cplex.tilim = 600;		// Set time limit of 10 minutes

	var time = new Date();		// Get the time before running linear progromming model
	start = time.getTime();
	var count = 0;			// Count the number of non-zero weights
	if (cplex.solve()){
		var time = new Date();	// Get the time after before running linear progromming model
		end = time.getTime();
		for(var k = 1; k <= thisOplModel.m; k++) {
			if (produce.w[k] > 0) {			// Output positif weight
				ofile.write(produce.w[k] + ";");
				count++;
			} else {
				// Output negatif or 0 weight 
				// Due to the float precision, some weights may be a extremely small negatif value
				// In this case, write a "0" instead of the extremyly small negatif value
				ofile.write("0;");
			}
		}
	} else {
		var time = new Date();	// Get the time after before running linear progromming model
		end = time.getTime();
	}

	// There are 2 possibilities to get a "count == 0" scenario
	// First, the OPL is solved while all the weights are 0; second, the OPL is not solved; 
	// in this second case, this ligne just contains a running time (about 10 minutes) and a 0 (initial count value)
	ofile.writeln(((end - start) / 1000) + ";" + count);
	*/

	ofile.close();
}


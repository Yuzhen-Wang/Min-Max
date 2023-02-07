/*********************************************
 * OPL 12.10.0.0 Model
 * 
 * Version Date: 21 oct. 2021
 *********************************************/


//Data declarations
int n = ...;
int m = ...;
float C = ...;
float C_intra = ...;
float C_inter = ...;
range N = 1..n;
range M = 1..m;
int y[N] = ...;
float x[N][M] = ...;
float a[N][N][M];

//Decision variables
dvar float+ w[M];
dvar float+ xi[N];
dvar float+ r;


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
maximize r;


//Constraints
subject to {
	sum (k in M) w[k] == 1;
	
	forall(i in N, j in N){
		if (y[i] != y[j]) {
			sum (k in M) a[i][j][k] * w[k] >= r;
		}
	}	
}



main {
	// Generate model
	thisOplModel.generate();
	var produce = thisOplModel;
	var ofile = new IloOplOutputFile("./../../inter_process/tmp/tmp.txt");
	cplex.tilim = 600;
	
	var time = new Date();
	start = time.getTime();
	if (cplex.solve()){
		var time = new Date();
		end = time.getTime();
		var count = 0;
		ofile.write("-1;-1;");
		var j = 0;
		while (j < produce.m) {
			j++;
			if (produce.w[j] > 0) {
				ofile.write(produce.w[j] + ";");
				count++;
			} else {
				ofile.write("0;");
			}
		}
		ofile.writeln(((end - start) / 1000) + ";" + count);		
	}
	
	ofile.close();
}


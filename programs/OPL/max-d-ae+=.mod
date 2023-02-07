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
maximize r - (1 / C) * ((sum (i in N) xi_intra[i]) + (sum (i in N) xi_inter[i]));


//Constraints
subject to {
	forall(i in N, j in N){
		if (y[i] == y[j]) {
			sum (k in M) a[i][j][k] * w[k] <= 1 + xi_intra[i] + xi_intra[j];
		} else {
			sum (k in M) a[i][j][k] * w[k] >= r - xi_inter[i] - xi_inter[j];
		}
	}
}


main {
	var ofile = new IloOplOutputFile("./../../inter_process/tmp/tmp");
	thisOplModel.generate();
	var produce = thisOplModel;
	var C_now = produce.C;
	var i = 0;
	cplex.tilim = 600;

	while (i <= 10) {
		i++;
		var time = new Date();
		start = time.getTime();
		if (cplex.solve()){
			var time = new Date();
			end = time.getTime();
			var count = 0;
			ofile.write((i - 1) + ";" + (i - 1) + ";")
			for(var k = 1; k <= thisOplModel.m; k++) {
				if (produce.w[k] > 0) {
					ofile.write(produce.w[k] + ";");
					count++;
				} else {
					ofile.write("0;");
				}
			}
			ofile.writeln(((end - start) / 1000) + ";" + count);
			if (count == 0) {
				break;
			}
		} else {
			var time = new Date();
			end = time.getTime();
			ofile.writeln(((end - start) / 1000) + ";" + count);
			break;
		}
		if (i <= 10) {
			var def = produce.modelDefinition;
			var data = produce.dataElements;
			produce = new IloOplModel(def,cplex);
	    		C_now = C_now * 2;
			data.C = C_now;
			produce.addDataSource(data);
			produce.generate();
		}
	}
	
	ofile.close();
}


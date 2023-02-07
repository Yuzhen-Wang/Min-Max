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
dvar float+ xi_intra[N][N];
dvar float+ xi_inter[N][N];
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
maximize r - (1 / C_intra) * (sum (i in N, j in N) xi_intra[i][j]) -  (1 / C_inter) * (sum (i in N, j in N) xi_inter[i][j]);


//Constraints
subject to {
	forall(i in N, j in N){
		if (y[i] == y[j]) {
			sum (k in M) a[i][j][k] * w[k] <= 1 + xi_intra[i][j];
		} else {
			sum (k in M) a[i][j][k] * w[k] >= r - xi_inter[i][j];
		}
	}
}


main {
	var ofile = new IloOplOutputFile("./../../inter_process/tmp/tmp");
	thisOplModel.generate();
	var produce = thisOplModel;
	var C_now_intra = produce.C_intra;
	var C_now_inter = produce.C_inter;
	var i_intra = 0;
	var i_inter = 0;
	var j = 0;

	while (i_intra <= 10) {
		i_intra++;
		while (i_inter <= 10) {
			i_inter++;
			var time = new Date();
			start = time.getTime();
			if (cplex.solve()){
				var time = new Date();
				end = time.getTime();
				var count = 0;
				ofile.write((i_intra - 1) + ";" + (i_inter - 1) + ";");
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
				if (count == 0) {
					break;
				}
				j = 0;
			} else {
				var time = new Date();
				end = time.getTime();
				ofile.writeln(((end - start) / 1000) + ";" + count);
			  	break;
			  	
			}
			
			if (i_inter <= 10) {
    				var def = produce.modelDefinition;
			    	var data = produce.dataElements;
				produce = new IloOplModel(def, cplex);
    				C_now_inter = C_now_inter * 2;
			    	data.C_inter = C_now_inter;
				produce.addDataSource(data);
				produce.generate();
			}
		}
		
		if (i_intra <= 10) {
			var def = produce.modelDefinition;
			var data = produce.dataElements;
			produce = new IloOplModel(def, cplex);
			C_now_intra = C_now_intra * 2;
			data.C_intra = C_now_intra;
			C_now_inter = 1;
			data.C_inter = C_now_inter;
			produce.addDataSource(data);
			produce.generate();
			i_inter = 0;
		}
	}

	ofile.close();
}


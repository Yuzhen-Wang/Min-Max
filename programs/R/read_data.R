read.data <- function(D, id.y) {
  # Generate folds and OPL input file of data set
  # D: data set
  # id.y: index of class of observations
  # return value: NA; but assign global variables in R environment 

  # Get the name of the data set
  name = deparse(substitute(D))
  # Create a directory for the data set 
  # Dir represents the directory used for test
  system(sprintf( "mkdir Dir/inter_process/pretreatment/%s", name))
  system(sprintf( "mkdir Dir/Min_Max/inter_process/OPL_data/%s", name))
  
  #### Generate and output the splitting folds ####
  folds = gen.folds(D)
  write.table(folds, file = sprintf("Dir/inter_process/pretreatment/%s/%s_folds", name, name), sep = ",", row.names = FALSE, col.names = FALSE)
  
  #### Output the classification of the data set ####
  y = as.numeric(D[, id.y])
  write.table(y, file = sprintf("Dir/inter_process/pretreatment/%s/%s_y", name, name), row.names = FALSE, col.names = FALSE)
  
  ##### Original data set ####
  # Output the original data set
  x = D[, -id.y]
  write.table(x, file = sprintf("Dir/inter_process/pretreatment/%s/%s_x_o", name, name), sep = ",", row.names = FALSE, col.names = FALSE)
  # Generate the directory of original data set
  D.dir = sprintf("Dir/inter_process/OPL_data/%s/O", name)
  system(sprintf( "mkdir %s", D.dir))
  # Generate OPL input data of original data set
  gen.opl.data(x, y, folds, D.dir)
  
  ##### Re-scaled data set: standardization ####
  # Output the re-scaled data set; Package BBmisc is required to re-scale the data set
  x.n = normalize(x, method = "standardize")
  write.table(x.n, file = sprintf("~/Min_Max/inter_process/pretreatment/%s/%s_x_n", name, name), sep = ",", row.names = FALSE, col.names = FALSE)
  # Generate the directory of re-scaled data set
  D.dir = sprintf("Dir/inter_process/OPL_data/%s/R", name)
  system(sprintf( "mkdir %s", D.dir))
  # Generate OPL input data of re-scaled data set
  gen.opl.data(x.n, y, folds, D.dir)
  
  ##### Assign global variables ####
  # Separation of "_" used to correspond names of variables in R environment and names of files
  assign(paste("x", name, "o", sep = "_"), x, envir = globalenv())
  assign(paste("x", name, "r", sep = "_"), x.n, envir = globalenv())
  assign(paste("y", name, sep = "_"), y, envir = globalenv())
  assign(paste("folds", name, sep = "_"), folds, envir = globalenv())
}



gen.folds <- function(D) {
  # Generate the folds for data set 
  # D: data set
  # return value: splitting of data set
  
  # Set the random seed to 0 to get a "stable" random splits
  set.seed(0)
  
  # This iteration generates a matrix of 10 * N(number of observations)
  # Each row represents an individual experiment 
  # Values are from 1-5; the fold that an observation belongs to
  folds = c()
  # Generate 10 times of random splits
  for (i in 1:10) {
    # Divide the observations into 5 splits
    folds.tmp = cut(seq(1,nrow(D)), breaks = 5, labels = FALSE)
    folds.tmp = sample(folds.tmp, nrow(D))
    folds = rbind(folds, t(folds.tmp))
  }
  
  # Return the generated splitting of data set
  return(folds)
}



gen.opl.data <- function(x, y, folds, D.dir) {
  # Generate OPL input file 
  # x: description of data set
  # y: class of data set
  # folds: 10*5 folds of data set
  # D.dir: output directory
  # return value: NA
  
  # Get the number of features of this data set
  m = ncol(x)
  
  # Iteration to generate OPL input file; e: experiment; f: fold
  for (e in 1:10) {
    for (f in 1:5) {
      #### Output directory of this fold ####
      output = sprintf("%s/%d_%d.dat", D.dir, e, f)
      
      
      #### Output basic information ####
      # Get the index of observations for testing set of this fold
      idxs = which(folds[e, ] == f, arr.ind = TRUE)
      # Get the information of training set
      x.tmp = x[-idxs, ]
      y.tmp = y[-idxs]
      
      # Output the number of observations of training set 
      n = nrow(x.tmp)
      cat(sprintf("n = %d;\n", n), file = output, append = FALSE)
      
      # Output the number of features of data set 
      cat(sprintf("m = %d;\n", m), file = output, append = TRUE)
      
      # Output the penalization parameters to output file
      # All penalization parameters are initialized at 1 by default 
      cat(sprintf("C = 1;\n"), file = output, append = TRUE)
      cat(sprintf("C_intra = 1;\n"), file = output, append = TRUE)
      cat(sprintf("C_inter = 1;\n"), file = output, append = TRUE)
      

      ##### Output the classification of training set ####
      cat(sprintf("y = [\n%s\n];\n", paste(y.tmp, collapse = ", ")), file = output, append = TRUE)
      
      
      #### Print the description of training set ####
      cat(sprintf("x = [\n%s\n];\n", 
                  paste(apply(x.tmp, 1, function(x) sprintf("[%s]", paste(x, collapse = ",\t"))), 
                        collapse = ",\n")),
          file = output, append = TRUE)
    }
  }
}

weighted.cross.validation <- function(w, x, y, folds) {
  # Weighted k-NN cross-validation
  # w: weight file
  # x, y, folds: description of data set
  # return value: formalized weighted error rate table
  
  n = nrow(w)   # Number of rows of weight file
  l = ncol(w)   # Number of column of weight file


  #### Calculate error rates ####
  # Error rate by 2 columns: on testing set && average of 4-folds cross-validation on training set
  er = t(apply(w, 1, function(w) {
    # weighted distance data set
    x.tmp = t(apply(x[], 1, function(x) unlist(x * sqrt(as.numeric(w[10:l])))))
    # First line: cross-validation on testing set; 
    # Second line: average results of 4-fold cross-validation on training set
    er = c(cross.validation(x.tmp, y, folds, k = 3, as.numeric(w[4]), as.numeric(w[5])), 
           cross.validation.4.folds(x.tmp, y, folds, k = 3, as.numeric(w[4]), as.numeric(w[5])))
    return(er)
  }))
  # Combine error rates with weight file 
  res = cbind(w[, 1:9], er)
  
  
  #### Select the rows - 3 strategies (FML) ####
  # Create a matrix of 3 columns for "First", "Middle" and "Last" strategies respectively
  slt = matrix(0, nrow = nrow(res), ncol = 3)
  # List of models tested
  model.list = levels(as.factor(w$Model))
  for (model in model.list) {
    for (e in 1:10) {   # e: experiment
      for (f in 1:5) {  # f: fold
        # Same model, serial of experiment and folds
        idx = which((w$Model == model) & (w$Exp == e) & (w$Fold == f))
        
        # First strategy
        if (length(idx) > 0) {    # Check if this set is not empty
          # All the index with the same best value
          idx.min = idx[which(er[idx, 2] == min(er[idx, 2]))]
          slt[idx.min[1], 1] = 1                  # First strategy
          slt[idx.min[length(idx.min)], 3] = 1    # Last strategy
          # 2 scenarios should be done separately for middle strategy
          # Models with 1 or no parameter; 2 parameters ("AE" type)
          if (!endsWith(w$Model[idx.min[1]], "AE")) {
            # First case, just find the middle directly within all the best ones
            idx.min = idx.min[(length(idx.min)+1) %/% 2]
            slt[idx.min, 2] = 1
          } else {
            # For the second case, at first, find the middle of C_intra
            ca = w$C_A[idx.min]
            idx.a = levels(factor(ca))[(nlevels(factor(ca))+1) %/% 2]
            # Then, find the middle of C_inter within the "best" C_intra
            idx.e = which(w$C_A[idx.min] == idx.a)
            idx.min = idx.min[(length(idx.e)+1) %/% 2]
            slt[idx.min, 2] = 1
          }
        }
      }
    }
  }
  # Combine the selected matrix
  res = cbind(res, slt, w$W_1)
  
  
  #### Rename the columns ####
  res = as.data.frame(res)
  colnames(res) <- c("Data_Set", "Type", "Model", "Exp", "Fold", "C_A", "C_E", "Time", "Rank", 
                     "Error_Rate", "Error_Rate_4", "Selected_F", "Selected_M", "Selected_L", "Weights")
  
  
  #### Compress all the weights to one column separated by "," ####
  for (i in 10:ncol(w)) {
    res$Weights = paste(res$Weights, sep = ",", res[,i])
  }

  
  # Return the error rate file
  return(res)
}




cross.validation <- function(x, y, folds, k, e, f) {
  # Normal k-NN with cross validation
  # x, y, folds: description of data set
  # k: parameter k of K-NN algorithm
  # e: experiment of folds
  # f: testing fold in the experiment 
  # return value: error rate by k-NN
  
  # Index of training set
  tr.idxs = which(folds[e, ] != f)
  # Index of testing set
  ts.idxs = which(folds[e, ] == f)
  # Assigning training and testing sets
  x.tr = x[tr.idxs, ]
  x.ts = x[ts.idxs, ]
  y.tr = y[tr.idxs]
  y.ts = y[ts.idxs]
  # predicting results for testing set
  y.pr = knn(x.tr, x.ts, y.tr, k = k)
  #count the error number and calculate error rate
  error = error.count(y.pr, y.ts)
  error.rate = error / length(ts.idxs)
  
  # Return error rate
  return(error.rate)
}




cross.validation.4.folds <- function(x, y, folds, k, e, f) {
  # 4-folds cross validation while having parameter C
  # x, y, folds: description of data set
  # k: parameter k of K-NN algorithm
  # e: experiment of folds
  # f: folds to be used in this experiment 
  # return value: average of 4-folds cross-validation 
  
  er = c()
  for (t in 1:5) {
    if (t != f) {
      # Index of training set: not ignored and not the testing set
      tr.idxs = which(((folds[e, ] != t) & (folds[e, ] != f)), arr.ind = TRUE)
      # Index of testing set: decide by iteration t
      ts.idxs = which(folds[e, ] == t, arr.ind = TRUE)
      # assigning training and testing sets
      x.tr = x[tr.idxs, ]
      x.ts = x[ts.idxs, ]
      y.tr = y[tr.idxs]
      y.ts = y[ts.idxs]
      # predicting results
      y.pr = knn(x.tr, x.ts, y.tr, k = k)
      #count the error number and calculate error rate
      error = error.count(y.pr, y.ts)
      er = append(er, error / length(ts.idxs))
    }
  }
  
  # Calculate the average of the 4 error rates
  return(mean(er))
}




error.count <- function(res, ans) {
  # Count the number of differences
  # return value: number of different elements
  len = length(res)
  count = 0
  for (i in 1:len) {
    if (res[i] != ans[i]) {
      count = count + 1
    }
  }
  return(count)
}

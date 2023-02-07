pretreat.weight <- function(w) {
  # Formalize the weight file
  # weight: untreated weight table
  # return value: formalized weight table
  
  #### Swap the "Time" and "Rank" column before "Weights" ####
  w = w[, c(1:7, ncol(w)-1, ncol(w), 8:(ncol(w)-2))]  
  
  
  #### Discard the un-meaningful rows ####
  # There are 2 possibilities to get a "Rank==0" scenario
  # First, the OPL is solved while all the weights are 0; second, the OPL is not solved
  # In this second case, the rows are not filled completely (weights data were placed with "NA")
  # Search the rows with "NA" on weights and discard them
  idx = which(is.na(w[, 10]))
  w = w[-idx, ]
  
  
  #### Rename the name of columns ####
  tmp = c()
  # Name the weights as "W_1, W_2, ..."
  for (i in 8:(ncol(w)-2)) {
    tmp = c(tmp, paste("W", sep = "_", as.character(i-7)))
  }
  col.names = c("Data_Set", "Type", "Model", "Exp", "Fold", "C_A", "C_E", "Time", "Rank", tmp)
  colnames(w) <- col.names
  
  
  #### Rename the column of models ####
  # List all the tested models
  model.list = levels(as.factor(w$Model))
  # Transform the name to string type
  w$Model = as.character(w$Model)
  
  # Iteration of models
  for (model in model.list) {
    # Get index of model
    idx = which(w$Model == model)
    # Rename models by their official names
    ord.model = match(model, model.names$opl.name)             # Get the index in model function table
    model.name = as.character(model.names$off.name[ord.model]) # Get the official name of models
    w$Model[idx] = model.name                                  # Assign the official name of models
    
    #### Select AE to A=E ####
    # Since model "A=E" is a special scenario for model "AE"
    # Sometimes, models "A=E" are not tested and the results are expanded by "AE"
    # In this case, un-comment the following part
    #if (endsWith(model.name, "AE")) {                          # Check if a model is of "AE" type
    #  idx = idx[which(w$C_A[idx]==w$C_E[idx])]                 # Get the index of this model
    #  copy = w[idx,]                                           # Copy all the results to a temporary table
    #  copy$Model = str_replace_all(copy$Model, "AE", "A=E")    # Replace the model names as "A=E" type
    #  w = rbind(w, copy)                                       # Combine the results table
    #}
  }
  
  
  # Return the formal weights file
  return(w)
}



#### Model names function ####
model.names = t(rbind(c("min-d-0","min-d-a","min-d-e","min-d-a=e","min-d-ae=","min-d-ae",
                        "min-d-a+","min-d-e+","min-d-a=e+","min-d-ae+=","min-d-ae+",
                        "min-d-am","min-d-em","min-d-a=em","min-d-ae=m","min-d-aem",
                        "max-d-0","max-d-a","max-d-e","max-d-a=e","max-d-ae=","max-d-ae",
                        "max-d-a+","max-d-e+","max-d-a=e+","max-d-ae+=","max-d-ae+",
                        "max-d-am","max-d-em","max-d-a=em","max-d-ae=m","max-d-aem",
                        "min-w-0","min-w-a","min-w-a+","min-w-am","max-w-0","max-w-e","max-w-e+","max-w-em"), 
                      c("Min-d-0","Min-d-i^A","Min-d-i^E","Min-d-i^Æ","Min-d-i^A=E","Min-d-i^AE",
                        "Min-d-i+j^A","Min-d-i+j^E","Min-d-i+j^Æ","Min-d-i+j^A=E","Min-d-i+j^AE",
                        "Min-d-i,j^A","Min-d-i,j^E","Min-d-i,j^Æ","Min-d-i,j^A=E","Min-d-i,j^AE",
                        "Max-d-0","Max-d-i^A","Max-d-i^E","Max-d-i^Æ","Max-d-i^A=E","Max-d-i^AE",
                        "Max-d-i+j^A","Max-d-i+j^E","Max-d-i+j^Æ","Max-d-i+j^A=E","Max-d-i+j^AE",
                        "Max-d-i,j^A","Max-d-i,j^E","Max-d-i,j^Æ","Max-d-i,j^A=E","Max-d-i,j^AE",
                        "Min-w-0","Min-w-i^A","Min-w-i+j^A","Min-w-i,j^A","Max-w-0","Max-w-i^E","Max-w-i+j^E","Max-w-i,j^E")))
colnames(model.names) = c("opl.name", "off.name")
# model.names #
#     OPL names   official names
#	1  	min-d-0	    Min-d-0
#	2  	min-d-a	    Min-d-i^A
#	3  	min-d-e	    Min-d-i^E
#	4	  min-d-a=e  	Min-d-i^Æ
#	5  	min-d-ae=	  Min-d-i^A=E
#	6	  min-d-ae	  Min-d-i^AE
#	7  	min-d-a+	  Min-d-i+j^A
#	8  	min-d-e+	  Min-d-i+j^E
#	9	  min-d-a=e+	Min-d-i+j^Æ
#	10	min-d-ae+=	Min-d-i+j^A=E
#	11	min-d-ae+	  Min-d-i+j^AE
#	12	min-d-am	  Min-d-i,j^A
#	13	min-d-em  	Min-d-i,j^E
#	14	min-d-a=em	Min-d-i,j^Æ
#	15	min-d-ae=m	Min-d-i,j^A=E
#	16	min-d-aem	  Min-d-i,j^AE
#	17	max-d-0	    Max-d-0
#	18	max-d-a	    Max-d-i^A
#	19	max-d-e    	Max-d-i^E
#	20	max-d-a=e  	Max-d-i^Æ
#	21	max-d-ae=	  Max-d-i^A=E
#	22	max-d-ae  	Max-d-i^AE
#	23	max-d-a+  	Max-d-i+j^A
#	24	max-d-e+  	Max-d-i+j^E
#	25	max-d-a=e+	Max-d-i+j^Æ
#	26	max-d-ae+=	Max-d-i+j^A=E
#	27	max-d-ae+  	Max-d-i+j^AE
#	28	max-d-am	  Max-d-i,j^A
#	29	max-d-em	  Max-d-i,j^E
#	30	max-d-a=em	Max-d-i,j^Æ
#	31	max-d-ae=m	Max-d-i,j^A=E
#	32	max-d-aem  	Max-d-i,j^AE
#	33	min-w-0  	  Min-w-0
#	34	min-w-a    	Min-w-i^A
#	35	min-w-a+  	Min-w-i+j^A
#	36	min-w-am	  Min-w-i,j^A
#	37	max-w-0    	Max-w-0
#	38	max-w-e	    Max-w-i^E
#	39	max-w-e+	  Max-w-i+j^E
#	40	max-w-em	  Max-w-i,j^E

#!/bin/bash

# Temporary output file for Cplex OPL program
res_tmp=./inter_process/tmp/tmp
# Direction of Cplex OPL running environment
opl_run=~/cplex/opl/bin/x86-64_linux/oplrun

# Folder of data set
# Change here to test for some specific data sets
for ds in ./inter_process/OPL_data/*
do
	# Get the data name
	data_name=$(basename "$ds")
	# Types of data set: O/R for original/re-scaled data set 
	# Change here to test for some specific types
	for tp in ./inter_process/OPL_data/$data_name/*
	do
		# Get the type of data set
		type=$(basename "$tp")
		# Creat the corresponding result file
		touch ./inter_process/results/w\_$data_name\_$type
		res=./inter_process/results/w\_$data_name\_$type
		# Iteration of folds 
		# Change here to test for some specific folds 
		for folds in ./inter_process/OPL_data/$data_name/$type/*
		do
			tmp=$(basename "$folds" .dat)
			# Get the number of experiment
			exp=$(echo "$tmp" | cut -d '_' -f 1)
			# Get the number of fold of the experiment
			fold=$(echo "$tmp" | cut -d '_' -f 2)
			# Iteration of models 
			# Change here to test for some specific models 
			for model in ./programs/OPL/*.mod
			do
				# Get the name of model
				model_name=$(basename $model .mod)
				# Run Cplex OPL program
				$opl_run $model $folds
				# Copy the temporary result to the final result file with more information
				while read ligne 
				do 
					echo "$data_name;$type;$model_name;$exp;$fold;$ligne" >> $res
				done < $res_tmp
			done 
		done
	done
done



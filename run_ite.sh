#!/bin/bash

# Temporary output file for Cplex OPL program
res_tmp=./inter_process/tmp/tmp
# Temporary OPL data input file 
data=./inter_process/tmp/tmp.dat
# Path of Cplex OPL running environment
opl_run=~/cplex/opl/bin/x86-64_linux/oplrun
# Define value of C to modify the Cplex OPL input file
declare -A tab_C=( ['0']="1" ['1']="2" ['2']="4" ['3']="8" ['4']="16" ['5']="32" 
		   ['6']="64"  ['7']="128" ['8']="256" ['9']="512" ['10']="1024" )

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
				
				# Models without penalization parameter C; no need for iteration
				if [ $model_name == "min-d-0" ] || [ $model_name == "max-d-0" ] || [ $model_name == "min-w-0" ] || [ $model_name == "max-w-0" ]
				then 
					# Run Cplex OPL program
					$opl_run $model $folds
					# Copy the temporary result to the final result file with more information
					while read ligne 
					do 
						echo "$data_name;$type;$model_name;$exp;$fold;-1;-1;$ligne" >> $res
					done < $res_tmp
				
				# Models with 2 penalization parameters C; need for 2 iterations in bash
				elif [ $model_name == "min-d-ae" ] || [ $model_name == "max-d-ae" ] || [ $model_name == "min-d-ae+" ] || [ $model_name == "max-d-ae+" ] || [ $model_name == "min-d-aem" ] || [ $model_name == "max-d-aem" ]
				then
					for C_A in $(seq 0 10)			# Iteration of C_intra
					do
						for C_E in $(seq 0 10)		# Iteration of C_inter
						do
							cp $folds $data		# Copy original data to temporary OPL input file
							sed -i "s/C_intra = 1;/C_intra = ${tab_C[$C_A]};/g" $data	# Modify the value of C_intra 
							sed -i "s/C_inter = 1;/C_inter = ${tab_C[$C_E]};/g" $data	# Modify the value of C_inter 
							$opl_run $model $data	# Run Cplex OPL program
							while read ligne 	# Copy the temporary result to the final result file with more information
							do
								echo "$data_name;$type;$model_name;$p;$q;$C_A;$C_E;$ligne" >> $res
							done < $res_tmp
							rank=$(tail -c 3 $res_tmp)	# Check if stop criteria achieves; if one line ends up with a ";0"
							if [ $rank == ";0" ]		# That means either it gots an all 0 weights; either ends up without solving the linear model
							then
								break
							fi
					done
				done
				
				# Models with 1 penalization parameter C; need for 1 iteration in bash
				else
					for C in $(seq 0 10)			# Iteration of parameter C
					do
						cp $data
						sed -i "s/C = 1;/C = ${tab_C[$C]};/g" $data		# Modify the value of C
						$opl_run $model $data		# Run Cplex OPL program
						while read ligne		# Copy the temporary result to the final result file with more information
						do
							# Seperation of model with parameters on intra or inter-class distance
							# This is used to uniform the format of weight output file 
							if [ $model_name == "min-d-a" ] || [ $model_name == "max-d-a" ] || [ $model_name == "min-d-a+" ] || [ $model_name == "max-d-a+" ] || [ $model_name == "min-d-am" ] || [ $model_name == "max-d-am" ] || [ $model_name == "min-w-a" ] || [ $model_name == "min-w-a+" ] || [ $model_name == "min-w-am" ] 
							then echo "$data_name;$type;$model_name;$p;$q;$C;-1;$ligne" >> $res 
							elif [ $model_name == "min-d-e" ] || [ $model_name == "max-d-e" ] || [ $model_name == "min-d-e+" ] || [ $model_name == "max-d-e+" ] || [ $model_name == "min-d-em" ] || [ $model_name == "max-d-em" ] || [ $model_name == "min-w-e" ] || [ $model_name == "min-w-e+" ] || [ $model_name == "min-w-em" ] 
							then echo "$data_name;$type;$model_name;$p;$q;-1;$C;$ligne" >> $res 
							else echo "$data_name;$type;$model_name;$p;$q;$C;$C;$ligne" >> $res 
							fi
						done < $res_tmp
						rank=$(tail -c 3 $res_tmp)	# Check if stop criteria achieves
						if [ $rank == ";0" ]
						then
							break
						fi
					done
				fi
			done 
		done
	done
done









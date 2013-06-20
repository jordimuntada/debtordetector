#!/usr/bin/env ruby
# encoding: UTF-8
Dir["../lib/*.rb"].each {|file| require file }

# define an array to hold the Customer records
set = Array.new
atts = Array.new
trainingset = Array.new
testset = Array.new

#filename = 'moros_deprova.csv'
filename = ARGV[0]
filenameAtt = ARGV[1]
ptraining = ARGV[2].to_i
ptest = ARGV[3].to_i



puts "Apply Decision Tree [d] or KNN [k] on the training set? "
STDOUT.flush
method=STDIN.gets # store '\n' at the end of the string 

# Once we've got the option which indicated what method to be applied, we proceed.
case method[0].to_s
	when "d"
		puts "Way of execution? [C]urrent - [V]alidation Test - [E]rror Estimation"
		STDOUT.flush
		way_of_execution=STDIN.gets
		
		Dir["../lib/decisiontree/*.rb"].each {|file| require file }

		if ARGV[4] != nil
			levels_discretization = ARGV[4].to_i
		else
			levels_discretization = DEFAULT_LEVELS_CONST
		end
		if levels_discretization < 2 or levels_discretization > 4
			# the number of levels of discretization is too small or too great so the default configuration (4 levels) will be applied on
			puts "The amount of levels of discretization is too small or too great so the default configuration(4 levels) will be applied on."
			levels_discretization = DEFAULT_LEVELS_CONST
		end
		# we get all information required
		atts,information_classification = getAttributes(levels_discretization, filenameAtt)
		set  = getInfo(atts, filename) # we get all the clients from the file .csv and we store them into "customers"	
		puts "quantitat = "+set.count.to_s

		proportion_training = (set.count * ptraining) / PERCENTAGE_CONST # proportion number of training set calculated
		proportion_test = set.count - proportion_training # proportion number of test set calculated

		trainingset, testset = getSets(set, proportion_training, proportion_test) # Now we've got training set and test set ready
		
		# Instantiate the tree, and train it based on the data (set default to '1')
		trainingset_ready = Array.new
		trainingset_ready = discretize(trainingset, atts, levels_discretization) # Now it is time to make the values (many floats) discrete

		# We make all values in test set become discretized
		testset_ready = Array.new
		testset_ready = discretize(testset, atts, levels_discretization) # levels_discretization -> means the amount of levels of discretization [2, 3, 4]
		case way_of_execution[0].to_s
			when "C"
				# Then, build the tree with the examples and attributes:
				t = DecisionTree.new("C", trainingset_ready, atts, information_classification, 0)
				t.testing(testset_ready)
				t.predict(atts, levels_discretization)
			when "V"
				# Then, build the tree with the examples and attributes:
				best_tree = several_tests("V", trainingset_ready, testset_ready, atts, information_classification)
				best_tree.predict(atts, levels_discretization)
			when "E"
				# Then, build the tree with the examples and attributes:
				t = DecisionTree.new("E", trainingset_ready, atts, information_classification, 0)
				t.testing(testset_ready)
				t.predict(atts, levels_discretization)
			else
				puts "Wrong way of execution. It doesn't exist."
		end
		###################################
		### END OF DECISION TREE OPTION
		###################################
	when "k"
		Dir["../lib/knn/*.rb"].each {|file| require file }
		
		puts "Way of execution? [C]urrent - [D]istance Weighted - [A]ttribute Weighted"
		STDOUT.flush
		way_of_execution=STDIN.gets
		
		if ARGV[4] != nil
			number_neighbours = ARGV[4].to_i
		else
			number_neighbours = DEFAULT_NUMBER_NEIGHBOURS_CONST
		end
		if number_neighbours < 2
			# the number of levels of discretization is too small or too great so the default configuration (4 levels) will be applied on
			puts "The number of neighbours selected is too small or too great so the default configuration(4 levels) will be applied on."
			number_neighbours = DEFAULT_NUMBER_NEIGHBOURS_CONST
		end
		# we get all information required
		atts,information_classification = getAttributes_for_knn(filenameAtt)
		set  = getInfo_for_knn(atts, filename) # we get all the clients from the file .csv and we store them into "customers"	
	  
    #let's get max and min values from attributes
    atts = find_mins_and_maxes(set, atts)
    set = normalize( set, atts )
    
    proportion_training = (set.count * ptraining) / PERCENTAGE_CONST # proportion number of training set calculated
  	proportion_test = set.count - proportion_training # proportion number of test set calculated
    
    mixing = 0
File.open('test_vehicle_millora1.csv', 'w') do |f2|
    while mixing < 500
      puts "We are at mixing "+mixing.to_s
      #set = my_scramble(set) # let's scramble all the set'
      set_mixed = []
      set_mixed = set.shuffle
      puts "quantitat = "+set_mixed.count.to_s
      
      trainingset_aux = Array.new
      accuracy = Array.new
      partitions = []
      
  		partitions = getSets_for_knn(set_mixed, proportion_training, proportion_test) # Now we've got training set and test set ready

      combination = 0
      while combination < CROSS_VALIDATION_PARTITIONS_CONST
        
        trainingset = []
        testset = []
        trainingset_aux = partitions
        testset = trainingset_aux [combination]
        trainingset_aux.delete_at(combination)

        trainingset_aux.each do |train|
		      trainingset.concat(train)
	      end

    		case way_of_execution[0].to_s
        when "C"
            knn = KNN.new("C", trainingset, testset, atts, number_neighbours)
            puts "We are at combination "+ combination.to_s + " - # examples = " + trainingset.count.to_s
            accuracy[combination] = knn.testing
    				#knn.predict(atts)
    			when "D"
    				knn = KNN.new("D", trainingset, testset, atts, number_neighbours)
    				knn.testing
    				#knn.predict(atts)
    			when "A"
    				knn = KNN.new("A", trainingset, testset, atts, number_neighbours)
    				knn.testing
    			else
    				puts "Wrong way of execution. It doesn't exist."
    		end
        trainingset_aux.insert(combination, testset)
        combination += 1
      end

        begin
          accuracy_sum = 0
          accuracy_sum = (accuracy.inject{|sum,x| sum + x }).to_f/(accuracy.size).to_f
          puts "|| ---> mixing = "+mixing.to_s+" ACCURACY AVG = "+accuracy_sum.to_s+" <---"
        rescue
          puts "Alternative way:"
          puts "Array = "+accuracy.to_s
          accuracy_sum = 0
          accuracy.each do |a|
            accuracy_sum = accuracy_sum + a
          end
          accuracy_sum = accuracy_sum.to_f / accuracy.size.to_f
          puts "---> mixing = "+mixing.to_s+" ACCURACY AVG = "+accuracy_sum.to_s+" <---"
        end
f2.puts mixing.to_s+";"+accuracy_sum.to_s

      mixing += 1
    end
end
		
		######################################
		### END OF K NEAREST NEIGHBOUR OPTION
		######################################
	else
		puts "Option introduced is wrong!"
end
puts "-----------------------"
puts "Hello world!"

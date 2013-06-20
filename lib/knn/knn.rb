class KNN
	def initialize(option, train_data, test_data, atts, k_number_of_neighbours, options={})
		@option = option
		@attributes = atts
    @train_data = train_data
    @test_data = test_data
		@k = k_number_of_neighbours
		@distance_measure = options[:distance_measure] || :euclidean_distance
	end

  	# tells what classification is predicted for each example in the testset
	def testing
		test = @test_data
    right_counter = 0
		wrong_counter = 0
		test.each do |t|
			class_predicted = classify(t)
      # Screen output in order to detect predictions and assignings
#      puts "--> "+t.to_s+" classification predicted = "+ class_predicted.to_s + " --- classification assigned = "+ t.classification.to_s
			# we keep up a control of right and wrong classification via counting
			if t.classification == class_predicted
				right_counter += 1
			else
				wrong_counter += 1
			end
		end
#		puts "right_counter = "+right_counter.to_s
#		puts "wrong_counter = "+wrong_counter.to_s
		##############################
		# ACCURACY CALCULATION #######
		##############################
		accuracy = right_counter.to_f / test.size.to_f
#		puts "-----------> ACCURACY == "+accuracy.to_s
		
		##############################
		# ERROR CALCULATION ##########
		##############################
		error = wrong_counter.to_f / test.size.to_f
#		puts "-----------> ERROR == "+error.to_s
    
    return accuracy
	end

	# this method returns the distance according to all the attributes of the same FORMAT as the parameter INDICATOR says
	def get_distance(indicator, row_from_training, example_to_classify)
    atts = @attributes
		dist = 0
		case indicator
			when CONTINUOUS_CONST
				atts.each do |a|
					if a.format == CONTINUOUS_CONST
              dist += ((row_from_training.attributes[a.name].to_f - example_to_classify.attributes[a.name].to_f)**MINKOWSKI_DISTANCE_CONST)**(1/MINKOWSKI_DISTANCE_CONST)
					end
				end # end loop atts.each

			when NOMINAL_CONST
				# method based on simple matching method
				counterR = 0
				counterQ = 0
				atts.each do |a|
					if a.format == NOMINAL_CONST
						if row_from_training.attributes[a.name] == example_to_classify.attributes[a.name]
							counterQ += 1
						end
						counterR += 1
					end
				end # end loop atts.each
				dist = (counterR - counterQ) / counterR if counterR > 0
				dist = 0 if counterR == 0
			
			when BINARY_CONST
				# SOKAL-MICHENER similarity implemented
				counterN = 0 # It counts all binary attributes
				counterA = 0 # It counts the attributes alike and equal 1
				counterD = 0 # It counts the attributes alike and equal 0
				atts.each do |a|
					# 1.- We get counterA value
					if a.format == BINARY_CONST
						if row_from_training.attributes[a.name] == 1 and example_to_classify.attributes[a.name] == 1
							counterA += 1
						end
						counterN += 1
					end
					# 2.- We get counterD value
					if a.format == BINARY_CONST
						if row_from_training.attributes[a.name] == 0 and example_to_classify.attributes[a.name] == 0
							counterD += 1
						end
						counterN += 1
					end
					# 3.- We get b value (for Jaccard similarity)
					# 4.- We get c value (for Jaccard similarity)
					
				end # end loop atts.each
				dist = (counterA + counterD) / counterN if counterN > 0
				dist = 0 if counterN == 0
			else
				#puts "There's a format indicated and it doesn't exist"
				puts "ERROR: NOT continuous, NOT nominal, NOT binary, What is this?"
		end
		return dist
	end
	
	# it receives one example from the training dataset and the example we want to classify
	# it calculates the right distance according to the values of attributes
	def calculate_distance_by_attributes(t, e)
    option = @option
		s1 = get_distance(CONTINUOUS_CONST, t, e)
		s2 = get_distance(NOMINAL_CONST, t, e)
		s3 = get_distance(BINARY_CONST, t, e)
		sum = s1 + s2 + s3
    # we may gauge the MINKOWSKI_CONSTANT-ROOT on the total sum
    # sum = sum**(1/MINKOWSKI_CONSTANT)
		if option == "C"
			return sum
		else
			if option == "D"
				return (( 1 - sum.to_f ) * sum.to_f) # As we've got all data normalized, we multiply by (1 - distance) instead of (1/distance)
			end
		end
	end
	
	def find_distances(ex)
    train = @train_data
    atts = @attributes
		distances = []
		sum = 0
		i = 0
		while i < train.count
			dist = calculate_distance_by_attributes(train[i], ex)
			distances << dist
			i+=1
		end # end while
		return distances
	end
	
	def pair_up(distances)
    train = @train_data
		pairs = []
		
		distances.each_with_index do |d, i|
			pairs << [d, train[i].classification]
		end
		#puts "paris = "+pairs.to_s
		pairs = pairs.sort_by { |p| p.first }
		return pairs
	end
	
	def gather_votes(votes, pairs)
    k = @k
		votes = (0...k).each.inject([]) do |votes, neighbour|
			votes << pairs[0].last
		end
		return votes
	end
	
	 def classify(example)
	 	# First. We find out the distances
		distances = find_distances(example)
		# Second. We pair up each distance with its label/classification
		pairs = pair_up(distances)
		# Third. We gather the K nearest neighbours
		votes = gather_votes(votes, pairs)
		freq = votes.inject(Hash.new(0)) { |h,v| h[v] += 1; h }
		# Fifth. We get the most common classification in the K Nearest Neighbours
		label = votes.sort_by { |v| freq[v] }.last

		return label
	end
	
	# it asks the user for a new example and classifies it.
	def predict(attributes)
		values_in_order = {}
		attributes.each do |att|
			puts "Value for "+att.name+" : "
			STDOUT.flush
			value = STDIN.gets # store '\n' at the end of the string
			value[-1] = ""
			values_in_order[att.name] = value
		end
		toPredict = Example.new(values_in_order, nil)
		puts "Let's classify the example you recently provided."
		prediction = self.classify(toPredict)
		p "predicting..."
		puts "The example you provided is classified as " + prediction.to_s
	end
end

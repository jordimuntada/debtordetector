# encoding: utf-8
class DecisionTree
	# provided a set of examples and attributes, we build the tree
	def initialize(opt, set, testset, attributes, info_classif, constraint) # 'constraint' is only useful when opt == "V"
		@information_of_classification = info_classif
    @testset = testset
		@numerous_classification = most_popular_classification(set)[0] # the most numerous classification in dataset is stored
		if opt == "C"
			@r = DecisionTree.build_decision_tree(set, attributes, LEVEL_OF_START_CONST, info_classif)
		else
			if opt == "V"
				@constraint = constraint
				@r = DecisionTree.build_decision_tree_under_constraint(set, attributes, LEVEL_OF_START_CONST, constraint, info_classif)
			else
				if opt == "E"
					@r = DecisionTree.build_decision_tree_under_error_estimation(set, attributes, LEVEL_OF_START_CONST, info_classif)
				end
			end
		end
	end

	# represents a decision node - it splits based on an attribute
	class DecisionTreeInternalNode
		# child_map should be a mapping of class=>subtree, both types being string
		# frequencies will store ratios for each possible enumeration of the ratio
		def initialize(attribute, level, child_map = {})
			@attribute = attribute
			@level = level
			@child_map = child_map
			@frequencies = {}
		end
		
		def leaf?
		    false
		end
		
		# finds the most common class in the attribute encountered when
		# building the tree, used for new examples with missing attributes
		# returns [name, freq]
		def most_common_attribute
		    @frequencies.sort {|f1, f2| f1[1] <=> f2[1]}[-1]
		end

		def add_child(path_val, frequency, child)
			@child_map[path_val] = child
			@frequencies[path_val] = frequency
		end

		attr_reader :attribute, :child_map, :level
	end

	# represents a leaf, a point at which we've classified the new example
	# as best we can.
	class DecisionTreeLeaf
		def initialize(classification, level)
		    @classification = classification
		    @level = level
		end
		def leaf?
		    true
		end
		attr_accessor :classification, :level
	end # end DTLeaf

   # this method builds a decision tree but following up a constraint which is the level. It builds a tree to the level indicated by the parameter.
def self.build_decision_tree_under_constraint(set, attributes, level, restriction, info_classif)
	# if all examples are the same, this can be a classification leaf
        if one_classification?(set)
		return DecisionTreeLeaf.new(set[0].classification, level)
        end

        # in the event that we have nothing further to split on, but have a mixed
        # group, guess that most examples will follow majority.
        if attributes.empty?
        	#puts "most popular --> "+most_popular_classification(set)[0].to_s
		# return DecisionTreeLeaf.new(most_popular_classification(set))
		return DecisionTreeLeaf.new(most_popular_classification(set)[0], level) # we just need to pass the classification parameter which resides in position "[0]"
        end
	# split on the best attribute
        best_att = best_attribute(set, attributes, info_classif)
        root = DecisionTreeInternalNode.new(best_att, level)
        
        if restriction != 0
		if level.to_i < restriction.to_i
			# divide the examples into groups according to their value for this attribute
			set.group_by {|s| s.attributes[best_att.name]}.each do |val, sub_set|
				# get ratio for each pathway so we can handle missing fields in new examples
				p = sub_set.size.to_f/set.size
			    if sub_set.empty?
				# add to root's map a leaf most common classification of current examples
				# puts "most popular --> "+most_popular_classification(set).to_s
				root.add_child(val, p, DecisionTreeLeaf.new(most_popular_classification(set)[0]), level + 1) # previously [0] was erased
			    else
				# we have more splitting to do
				attributes2 = Array.new(attributes)
				attributes2 = attributes2 - [best_att]
				root.add_child(val, p, build_decision_tree_under_constraint(sub_set, attributes2, level + 1, restriction, info_classif))
			    end
			    
			end # end iteration over groups of examples
		else
			return DecisionTreeLeaf.new(most_popular_classification(set)[0], level)
		end
	else
		# divide the examples into groups according to their value for this attribute
		set.group_by {|s| s.attributes[best_att.name]}.each do |val, sub_set|
			# get ratio for each pathway so we can handle missing fields in new examples
			p = sub_set.size.to_f/set.size
		    if sub_set.empty?
			# add to root's map a leaf most common classification of current examples
			# puts "most popular --> "+most_popular_classification(set).to_s
			root.add_child(val, p, DecisionTreeLeaf.new(most_popular_classification(set)[0]), level + 1) # previously [0] was erased
		    else
			# we have more splitting to do
			attributes2 = Array.new(attributes)
			attributes2 = attributes2 - [best_att]
			root.add_child(val, p, build_decision_tree(sub_set, attributes2, level + 1, info_classif))
		    end
		    
		end # end iteration over groups of examples
	end
        return root
end # end build_tree

def self.build_decision_tree_under_error_estimation(set, attributes, level, info_classif)
	# if all examples are the same, this can be a classification leaf
        if one_classification?(set)
		return DecisionTreeLeaf.new(set[0].classification, level)
        end
        # in the event that we have nothing further to split on, but have a mixed
        # group, guess that most examples will follow majority.
        if attributes.empty?
        	#puts "most popular --> "+most_popular_classification(set)[0].to_s
		# return DecisionTreeLeaf.new(most_popular_classification(set))
		return DecisionTreeLeaf.new(most_popular_classification(set)[0], level) # we just need to pass the classification parameter which resides in position "[0]"
        end
	# split on the best attribute
        best_att = best_attribute(set, attributes, info_classif)
        root = DecisionTreeInternalNode.new(best_att, level)

        # variables needed for Error Estimation
        number_of_examples_in_set = set.count
        majority_class_in_set = most_popular_classification(set)[0]
	number_of_examples_in_set_belong_to_majority_class = set.find_all {|e| e.classification == majority_class_in_set }.size
	number_of_classes = info_classif.vals.count
	node_error_estimation = ( ( number_of_examples_in_set - number_of_examples_in_set_belong_to_majority_class + number_of_classes - 1 ).to_f / ( number_of_examples_in_set + number_of_classes ).to_f )
	
	#puts "number_of_examples_in_set = "+number_of_examples_in_set.to_s
	#puts "majority_class_in_set = "+majority_class_in_set.to_s
	#puts "number_of_examples_in_set_belong_to_majority_class = "+number_of_examples_in_set_belong_to_majority_class.to_s
	#puts "number_of_classes = "+number_of_classes.to_s
	#puts "node_error_estimation = "+ node_error_estimation.to_s
        
	freq = entropy_for_error_estimation(set, info_classif) # we just need p
        
  bu_error = backed_up_error(set, freq, info_classif, number_of_examples_in_set, majority_class_in_set, number_of_examples_in_set_belong_to_majority_class, number_of_classes)
        
	if node_error_estimation < bu_error
		# PROBLEM: From the beginning, the node_error_estimation is smaller than the BackedUpError (bu_error)
		puts "LET'S PRUNE"
		return DecisionTreeLeaf.new(most_popular_classification(set)[0], level)
	else
		# divide the examples into groups according to their value for this attribute
		set.group_by {|s| s.attributes[best_att.name]}.each do |val, sub_set|
			# get ratio for each pathway so we can handle missing fields in new examples
			p = sub_set.size.to_f/set.size
		    if sub_set.empty?
		        # add to root's map a leaf most common classification of current examples
		        # puts "most popular --> "+most_popular_classification(set).to_s
		        root.add_child(val, p, DecisionTreeLeaf.new(most_popular_classification(set)[0]), level + 1) # previously [0] was erased
		    else
		        # we have more splitting to do
		        attributes2 = Array.new(attributes)
		        attributes2 = attributes2 - [best_att]
		        root.add_child(val, p, build_decision_tree(sub_set, attributes2, level + 1, info_classif))
		    end
		    
		end # end iteration over groups of examples	
	end
        return root
end # end build_tree

    # to build the tree, we need to have:
    # -a list of attributes(those that haven't split yet) with their possible values
    # -a list of examples that would still be eligible to be classified at this point,
    # with their values for all of their attributes
    # returns a subtree that classifies the examples according to the given attributes.
# It builds up a tree with no restrictions
def self.build_decision_tree(set, attributes, level, info_classif)
	# if all examples are the same, this can be a classification leaf
        if one_classification?(set)
		return DecisionTreeLeaf.new(set[0].classification, level)
        end
        # in the event that we have nothing further to split on, but have a mixed
        # group, guess that most examples will follow majority.
        if attributes.empty?
        	#puts "most popular --> "+most_popular_classification(set)[0].to_s
		# return DecisionTreeLeaf.new(most_popular_classification(set))
		return DecisionTreeLeaf.new(most_popular_classification(set)[0], level) # we just need to pass the classification parameter which resides in position "[0]"
        end
	# split on the best attribute
        best_att = best_attribute(set, attributes, info_classif)
        root = DecisionTreeInternalNode.new(best_att, level)

        # divide the examples into groups according to their value for this attribute
        set.group_by {|s| s.attributes[best_att.name]}.each do |val, sub_set|
		# get ratio for each pathway so we can handle missing fields in new examples
		p = sub_set.size.to_f/set.size
            if sub_set.empty?
                # add to root's map a leaf most common classification of current examples
                # puts "most popular --> "+most_popular_classification(set).to_s
                root.add_child(val, p, DecisionTreeLeaf.new(most_popular_classification(set)[0]), level + 1) # previously [0] was erased
            else
                # we have more splitting to do
                attributes2 = Array.new(attributes)
                attributes2 = attributes2 - [best_att]
                root.add_child(val, p, build_decision_tree(sub_set, attributes2, level + 1, info_classif))
            end
            
        end # end iteration over groups of examples
        return root
end # end build_tree

# outputs the tree, with indentation indicating a new level
# label is the label preceeding this node, if there is one
def print_tree(root = @r, indent = 0, label = nil)
# puts "==========================================================================================="
# puts "root -> "+root.to_s+" | indent -> "+indent.to_s+ " | label -> "+label.to_s
# puts "==========================================================================================="
	File.open("tree.txt", "a") do |f|
		# if leaf, we can just output this node and return
		if root.leaf?
		    print "\t" * indent+" --> {"+indent.to_s+"} leaf:"
		    f.print "\t" * indent+" --> {"+indent.to_s+"} leaf:"
		    if label
			    print label + ":"
			    f.print label + ":"
		  	# when we get to a leaf whose tree level is as large as the number of attributes being processed,
		  	# then it shows all the attributes
		    	puts root.classification.to_s+" && level="+root.level.to_s
		    	f.puts root.classification.to_s
		    end
		# otherwise, simulate an inorder traversal
		else
		    m = root.child_map
		    n = 0
		    # print each child
		    m.each do |child_label, child|
			# in the middle of the children, output this node
			if n == m.size/2
			    f.print "\t" * indent+" --> {"+indent.to_s+"}"
			    print "\t" * indent+" --> {"+indent.to_s+"}"
			    if label
				print label + ":"
				f.print label + ":"
			    end
			    puts root.attribute.name + " && level="+root.level.to_s
			    f.puts root.attribute.name
			end
			print_tree(child, indent + 1, child_label)
			n += 1
		    end # end iteration over children
		end # end internal node else
	end # end of file writing
end # end print_Tree
    
	# classification algorithm - descends tree using values in the new example
	# to find a classification node. If an attribute is missing a value,
	# guesses what it might be based on most popular value for this attribute
	# in training set.
	def classify(example)
    
		current = @r
		nc = @numerous_classification
		search_attribute = nil
		count = 0
		while !current.leaf?
			search_attribute = current.attribute.name
			example_class = example.attributes[search_attribute]
			if !example_class
			# if it does not find its corresponding attribute in the tree, then it assigns the most common attribute to the example class
				example_class = current.most_common_attribute
			end
			current = current.child_map[example_class]
			puts "==> Exemple a classificar i no té branca escaient per tal de decidir --> "+example.classification.to_s+ "||| numerous classification == "+nc if !current
			return nc if !current #we return the most numerous classification in the trainingset
			#return 0 if !current # It may be "NO" instead of "0"
		end
		return current.classification
	end # end classify

    # returns decisions made by the tree in order of importance, and in case
    # of same level, from "left to right"
    def get_decisions(root = @r)
        d = []
        if !root.leaf?
            d << root.attribute
            root.child_map.values.each do |child|
                d += get_decisions(child)
            end
        end
        return d
    end#end get_decisions
    
    # tells what classification is predicted for each example in the testset
	def testing
    test = @testset
		i_o_c = @information_of_classification

		right_counter = 0
		wrong_counter = 0
		test.each do |t|
			class_predicted = self.classify(t) # it returns a classification by predicting
			# Because confusion_matrix is a hash structure, we can access the content by string indexes
      #puts "t.classification = "+t.classification.upcase.to_s+" - class_predicted = "+class_predicted.upcase.to_s
			# we keep up a control of right and wrong classification via counting
			if t.classification == class_predicted
				# this section is used to fill the diagonal of the confusion matrix by counters 
				right_counter += 1
			else
				wrong_counter += 1
			end
		end
    puts "right_counter = "+right_counter.to_s
		puts "wrong_counter = "+wrong_counter.to_s
		#######################################################
		# ACCURACY CALCULATION ################################
		#######################################################
		accuracy = right_counter.to_f / test.size.to_f
		puts "---> ACCURACY = "+accuracy.to_s
		
		####################################################
		# ERROR CALCULATION ################################
		####################################################
		error = wrong_counter.to_f / test.size.to_f
		puts "---> ERROR = "+error.to_s
		return accuracy
	end
	
	# It asks the user for a new example and classifies it.
	def predict(attributes, levels)
		values_in_order = {}
		attributes.each do |att|
			puts "Value for "+att.name+" : "
			STDOUT.flush
			value = STDIN.gets # store '\n' at the end of the string
			value[-1] = ""
			values_in_order[att.name] = value
		end
		toPredict = Example.new(values_in_order, nil)
		toPredictDiscrete = discretize(toPredict, atts, levels)
		puts "Let's classify the example you recently provided."
		prediction = self.classify(toPredictDiscrete)
		p "predicting..."
		puts "The example you provided is classified as " + prediction.to_s
	end	
end

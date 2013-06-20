def initMax (att)
	att.max = MAX_DISCRETE_CONST
	return att
end

def initMin (att)
	att.min = MIN_DISCRETE_CONST
	return att
end

def getMax(set, atts)
	atts.each do |a|
		if a.type == "continuous"
			a = initMax(a)
			i = 0
			while i < set.count
				# Next 2 lines are just applied in getMax because after its executation, set will be modified
				## set[i].attributes[a.name][0]='' if set[i].attributes[a.name].include? ','
				##puts "set[i].attributes["+a.name.to_s+"] ---> "+set[i].attributes[a.name].to_s
				set[i].attributes[a.name][0]='' if set[i].attributes[a.name][0]=='"'
				## set[i].attributes[a.name][-1]='' if set[i].attributes[a.name].include? ','
				set[i].attributes[a.name][-1]='' if set[i].attributes[a.name][-1]=='"' # it should be -1
				#puts "set[i].attributes[a.name] == " + set[i].attributes[a.name].to_s
				a.max = set[i].attributes[a.name] if a.max.to_f < set[i].attributes[a.name].to_f
				i+=1
			end
		end
	end
	return atts
end

def getMin(set, atts)
	atts.each do |a|
		if a.type == "continuous"
			a = initMin(a)
			i = 0
			while i < set.count
				#set[i].attributes[a.name][0]='' if set[i].attributes[a.name].include? ','
				#set[i].attributes[a.name][-1]='' if set[i].attributes[a.name].include? ','
				a.min = set[i].attributes[a.name] if a.min.to_f > set[i].attributes[a.name].to_f
				i+=1
			end
		end
	end
	return atts
end

def find_mins_and_maxes(set, atts)
	atts = getMax(set,atts)
	atts = getMin(set,atts)
	return atts
end

# this method just normalize the continuous attributes in the set
def normalize(set, attributes)
		new_set = []
		i = 0
		while i < set.count
			example_aux = set[i]
			attributes.each do |a|
				# only if the attribute is continuous
				if a.type == "continuous"
          #puts "example_aux.attributes[a.name] = "+((set[i].attributes[a.name]).to_f / (a.max.to_f - a.min.to_f).to_f).to_s
          example_aux.attributes[a.name] = (set[i].attributes[a.name]).to_f / (a.max.to_f - a.min.to_f).to_f # normalization: (attribute.value)/(attribute max - attribute.min)
        end
			end
			new_set << example_aux
			i += 1
		end
		return new_set
	end

def getAttributes_for_knn(filename)
	# handle attributes
	attributes = []
	File.open(filename, 'r').each_line do |line|
		atts = line.chomp.split(';').map{|s| s.strip}
		name = atts.shift.upcase
		type = atts.shift
		i=0
		while i<atts.count 
			atts[i]=atts[i].upcase
			i += 1
		end
		if type == "categorical"
			if atts.count == 2
				treatment = "binary"
			else
				if atts.count > 2
					treatment = "nominal"
				else
					puts "A categorical attriutes can not have under 2 different values"
				end
			end
		else
			if type == "continuous"
				treatment = "continuous"
			else
				puts "There can not be over two kind of attributes: categorical and continuous"
			end
		end
		attributes << Attribute.new(name, type, atts, treatment)
	end
	att_aux = attributes.pop
	info_classification = Classification.new(att_aux.name, att_aux.type, att_aux.vals)
	return attributes,info_classification
end

def getInfo_for_knn(attributes, fileset)
	# handle examples, values should be in same order as attributes
	set = []
	aux = 0
	#File.open(@fileset, 'r').each_line do |line|
	###file = File.new(@fileset, 'r').each_line do |line|
	file = File.new(fileset, 'r')
	file.each_line do |line|
		if aux == 0
			basura = line.chomp.split(';').map{|s| s.strip}
			aux = 1
		else
			map = {}
			atts = line.chomp.split(';').map{|s| s.strip}
			classification = atts.pop
			# if the number of attributes read from Info File ranges from 0 to amount of attributes in Atts File then
			# the example just read is put in the overall set 
			if atts.count > 0 and atts.count < (attributes.count + 1)
				attributes.each do |attr|
					map[attr.name] = atts.shift
				end
				set << Example.new(map, classification)
			end
		end
		#break if file.lineno > 20 #to limit the number of row readings
	end
	return set
end

def my_scramble(vector)
	new_vector = []
	front_index = 0
	back_index = vector.length-1

	while front_index <= back_index
	  new_vector << vector[front_index]
	  front_index += 1
	  if front_index <= back_index
	  	new_vector << vector[back_index]
	  	back_index -= 1
	  end
	end
	return new_vector
end

def getSets_for_knn(examples, proportion_training, proportion_test)
	trainingset = Array.new
	training_final = Array.new
	testset = Array.new
	test_final = Array.new
	part = Array.new
	partitions = Array.new

	total_examples = examples.size # first we need all the amount of examples counted
	
	# we calculate a concrete partition by CROSS_VALIDATION_PARTITIONS_CONST
	number_partition = total_examples / CROSS_VALIDATION_PARTITIONS_CONST
	count = 0
	while count < CROSS_VALIDATION_PARTITIONS_CONST
		part = []
		acumulador = 0
		while acumulador < number_partition
			part << examples.pop
			acumulador += 1
		end
		partitions << part
		count += 1
	end
  partitions = partitions.shuffle
	#partitions=my_scramble(partitions)

	return partitions
#return training_final, test_final
end

def getSets_for_knn_by_proportions(examples, proportion_training, proportion_test)
  trainingset = Array.new
	training_final = Array.new
	testset = Array.new
	test_final = Array.new
	part = Array.new
	partitions = Array.new

	total_examples = examples.size # first we need all the amount of examples counted
	
	# we calculate a concrete partition by CROSS_VALIDATION_PARTITIONS_CONST
	number_partition = total_examples / CROSS_VALIDATION_PARTITIONS_CONST
	count = 0
	while count < CROSS_VALIDATION_PARTITIONS_CONST
		part = []
		acumulador = 0
		while acumulador < number_partition
			part << examples.pop
			acumulador += 1
		end
		partitions << part
		count += 1
	end
	partitions = partitions.shuffle
	
	count = 0
	initial_border = total_examples - proportion_test
	while initial_border < total_examples
		testset << partitions.pop
		initial_border += number_partition
	end
	trainingset = partitions
	
	testset.each do |test|
		test_final.concat(test)
	end
	trainingset.each do |train|
		training_final.concat(train)
	end
	
	return training_final, test_final
end

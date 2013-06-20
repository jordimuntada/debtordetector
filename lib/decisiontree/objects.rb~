# represents information of the classification
# has a title and a list of possible values.
class Classification
	attr_reader :name, :vals, :type#, :max, :min
	attr_accessor :max, :min
	def initialize(name, type, vals)
		@name = name
		@type = type
		@vals = vals
		@max = MAX_DISCRETE_CONST # in "constants.rb"
		@min = MIN_DISCRETE_CONST # in "constants.rb"
	end
end # end class Classification

# represents an attribute to classify on
# has a title and a list of possible values.
class Attribute
	attr_reader :name, :vals, :type#, :max, :min
	attr_accessor :max, :min
	def initialize(name, type, vals)
		@name = name
		@type = type
		@vals = vals
		@max = MAX_DISCRETE_CONST # in "constants.rb"
		@min = MIN_DISCRETE_CONST # in "constants.rb"
	end
end # end class Attribute

# represents an example, currently used for both training and to hold new info
# classification isn't used if not known
class Example
	attr_reader :attributes, :classification
	# attributes is a map of attr_name => class
	# classification is what the decision should be for the example
	def initialize(attributes, classification = nil)
		@attributes = attributes
		@classification = classification
	end
end # end of class Example

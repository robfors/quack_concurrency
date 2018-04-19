module QuackConcurrency
  class ConcurrencyTool
    
    def setup_duck_types(supplied_classes)
      resultant_classes = {}
      required_classes = [:condition_variable, :mutex]
      required_classes = required_classes.map { |name| Name.new(name.to_s) }
      if supplied_classes
        raise ArgumentError, "'supplied_classes' must be Hash" unless supplied_classes.is_a?(Hash)
        supplied_classes = supplied_classes.map { |k, v| [Name.new(k.to_s), v] }.to_h
        required_classes.each do |class_name|
          unless supplied_classes[class_name]
            raise ArgumentError, "missing duck type: #{class_name.camel_case(:upper)}"
          end
          resultant_classes[class_name.snake_case.to_sym] = supplied_classes[class_name]
        end
      else
        required_classes.each do |class_name|
          resultant_classes[class_name.snake_case.to_sym] = Object.const_get(class_name.camel_case(:upper))
        end
      end
      resultant_classes
    end
    
  end
end

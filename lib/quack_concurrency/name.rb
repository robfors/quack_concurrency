module QuackConcurrency
  class Name < String
    
    def initialize(*args)
      super
      # set all names to a default case
      # if we create two of the same name with different cases they will now be equal
      replace(snake_case)
    end
    
    def camel_case(first_letter = :upper)
      case first_letter
      when :upper
        self.split('_').collect(&:capitalize).join
      when :lower
        self.camelcase(:upper)[0].downcase + self.camelcase(:upper)[1..-1]
      else
        raise ArgumentError, 'invalid option, use either :upper or :lower'
      end
    end
    
    def snake_case
      self.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("- ", "_").
      downcase
    end
    
  end
end

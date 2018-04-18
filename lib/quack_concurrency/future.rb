module QuackConcurrency
  class Future
    
    def initialize(duck_types: {})
      condition_variable_class = duck_types[:condition_variable] || ConditionVariable
      mutex_class = duck_types[:mutex] || Mutex
      @condition_variable = condition_variable_class.new
      @mutex = mutex_class.new
      @value = nil
      @value_set = false
      @complete = false
    end
    
    def set(new_value = nil)
      @mutex.synchronize do
        raise Complete if @complete
        @value_set = true
        @complete = true
        @value = new_value
        @condition_variable.broadcast
      end
      nil
    end
    
    def get
      @mutex.synchronize do
        @condition_variable.wait(@mutex) unless complete?
        raise 'internal error, invalid state' unless complete?
        raise Canceled unless @value_set
        @value
      end
    end
    
    def cancel
      @mutex.synchronize do
        raise Complete if @complete
        @complete = true
        @condition_variable.broadcast
      end
      nil
    end
    
    def complete?
      @complete
    end
    
  end
end

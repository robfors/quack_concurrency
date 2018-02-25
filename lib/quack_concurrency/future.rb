# Author: Rob Fors
# Revision Date: 20180102

module QuackConcurrency
  class Future
    
    class Canceled < StandardError
    end
    
    def initialize(duck_types: {})
      mutex_class = duck_types[:mutex] || Mutex
      condition_variable_class = duck_types[:condition_variable] || ::ConditionVariable
      @mutex = mutex_class.new
      @condition_variable = condition_variable_class.new
      @value = nil
      @value_set = false
      @complete = false
    end
    
    def set(new_value = nil)
      @mutex.synchronize do
        raise if @complete
        @value_set = true
        @complete = true
        @value = new_value
        @condition_variable.broadcast
      end
    end
    
    def get
      @mutex.synchronize do
        @condition_variable.wait(@mutex) unless complete?
        raise 'should not get here' unless complete?
        raise Canceled unless @value_set
        @value
      end
    end
    
    def cancel
      @mutex.synchronize do
        raise if @complete
        @complete = true
      end
    end
    
    def complete?
      @complete
    end
    
  end
end

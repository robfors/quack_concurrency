# Author: Rob Fors
# Revision Date: 20180102

module QuackConcurrency
  class Waiter
  
    def initialize(duck_types: {})
      queue_class = duck_types[:queue] || Queue
      @queue = queue_class.new
    end
    
    def resume(value = nil)
      @queue << value
    end
    
    def wait
      @queue.pop
    end
    
  end
end

module QuackConcurrency
  class Waiter
  
    def initialize(duck_types: {})
      @queue = Queue.new(duck_types: duck_types)
    end
    
    def resume(value = nil)
      @queue << value
    end
    
    def wait
      @queue.pop
    end
    
  end
end

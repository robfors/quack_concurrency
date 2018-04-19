module QuackConcurrency
  class Waiter < ConcurrencyTool
  
    def initialize(duck_types: nil)
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

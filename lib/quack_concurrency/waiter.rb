module QuackConcurrency
  class Waiter < ConcurrencyTool
  
    # Creates a new {Waiter} concurrency tool.
    # @param duck_types [Hash] hash of core Ruby classes to overload.
    #   If a +Hash+ is given, the keys +:condition_variable+ and +:mutex+ must be present.
    # @return [Waiter]
    def initialize(duck_types: nil)
      @queue = Queue.new(duck_types: duck_types)
    end
    
    # Resumes next waiting thread.
    # @param value value to pass to waiting thread
    # @return [void]
    def resume(value = nil)
      @queue << value
      nil
    end
    
    # Waits for another thread to resume the calling thread.
    # @note Will block until resumed.
    # @return value passed from resuming thread
    def wait
      @queue.pop
    end
    
  end
end

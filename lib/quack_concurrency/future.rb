module QuackConcurrency
  class Future < ConcurrencyTool
    
    # Creates a new +Future+ concurrency tool.
    # @param duck_types [Hash] hash of core Ruby classes to overload.
    #   If a +Hash+ is given, the keys +:condition_variable+ and +:mutex+ must be present.
    # @return [Future]
    def initialize(duck_types: nil)
      classes = setup_duck_types(duck_types)
      @condition_variable = classes[:condition_variable].new
      @mutex = classes[:mutex].new
      @value = nil
      @value_set = false
      @complete = false
    end
    
    # Cancels the future.
    # @raise [Complete] if the future is already completed
    # @return [void] value of the future
    def cancel
      @mutex.synchronize do
        raise Complete if @complete
        @complete = true
        @condition_variable.broadcast
      end
      nil
    end
    
    # Checks if future has a value or is canceled.
    # @return [Boolean]
    def complete?
      @complete
    end
    
    # Gets the value of the future.
    # @note This method will block until the future has completed.
    # @raise [Canceled] if the future is canceled
    # @return value of the future
    def get
      @mutex.synchronize do
        @condition_variable.wait(@mutex) unless complete?
        raise 'internal error, invalid state' unless complete?
        raise Canceled unless @value_set
        @value
      end
    end
    
    # Sets the value of the future.
    # @raise [Complete] if the future has already completed
    # @param new_value value to assign to future
    # @return [void]
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
    
  end
end

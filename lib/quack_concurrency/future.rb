module QuackConcurrency
  class Future
    
    # Creates a new {Future} concurrency tool.
    # @return [Future]
    def initialize
      @waiter = Waiter.new
      @mutex = ::Mutex.new
      @value = nil
      @complete = false
      @exception = false
    end
    
    # Cancels the {Future}.
    # Calling {#get} will result in Canceled being raised.
    # Same as `raise(Canceled.new)`.
    # @raise [Complete] if the {Future} was already completed
    # @param exception [Exception] custom `Exception` to set
    # @return [void]
    def cancel(exception = nil)
      exception ||= Canceled.new
      self.raise(exception)
      nil
    end
    
    # Checks if {Future} has a value or was canceled.
    # @return [Boolean]
    def complete?
      @complete
    end
    
    # Gets the value of the {Future}.
    # @note This method will block until the future has completed.
    # @raise [Canceled] if the {Future} is canceled
    # @raise [Exception] if the {Future} was canceled with a given exception
    # @return [Object] value of the {Future}
    def get
      @waiter.wait
      Kernel.raise(@exception) if @exception
      @value
    end
    
    # Cancels the {Future} with a custom `Exception`.
    # @raise [Complete] if the future has already completed
    # @param exception [Exception]
    # @return [void]
    def raise(exception = nil)
      exception = case
      when exception == nil then StandardError.new
      when exception.is_a?(Exception) then exception
      when exception <= Exception then exception.new
      else
        Kernel.raise(ArgumentError, "'exception' must be nil or an instance of or descendant of Exception")
      end
      @mutex.synchronize do
        Kernel.raise(Complete) if @complete
        @complete = true
        @exception = exception
        @waiter.resume_all_forever
      end
      nil
    end
    
    # Sets the value of the {Future}.
    # @raise [Complete] if the {Future} has already completed
    # @param new_value [nil,Object] value to assign to future
    # @return [void]
    def set(new_value = nil)
      @mutex.synchronize do
        Kernel.raise(Complete) if @complete
        @complete = true
        @value = new_value
        @waiter.resume_all_forever
      end
      nil
    end
    
  end
end

module QuackConcurrency

  # Used to send a value or error from one thread to another without the need for coordination.
  class Future

    # Creates a new {Future} concurrency tool.
    # @return [Future]
    def initialize
      @complete = false
      @exception = false
      @mutex = ::Mutex.new
      @value = nil
      @waiter = Waiter.new
    end

    # Cancels it.
    # If no +exception+ is specified, a {Canceled} error will be set.
    # @raise [Complete] if the {Future} has already completed
    # @param exception [Exception] custom exception to set (see {#raise})
    # @return [void]
    def cancel(exception = nil)
      exception ||= Canceled.new
      self.raise(exception)
      nil
    end

    # Checks if it has a value or error set.
    # @return [Boolean]
    def complete?
      @complete
    end

    # Gets it's value.
    # @note This method will block until the future has completed
    # @raise [Canceled] if it is canceled
    # @raise [Exception] if specific error was set
    # @return [Object] it's value
    def get
      @waiter.wait
      Kernel.raise(@exception) if @exception
      @value
    end

    # Sets it to an error.
    # @raise [Complete] if the it has already completed
    # @param exception [nil,Object] +Exception+ class or instance to set, otherwise a +StandardError+ will be set
    # @return [void]
    def raise(exception = nil)
      exception = case
      when exception == nil then StandardError.new
      when exception.is_a?(Exception) then exception
      when Exception >= exception then exception.new
      else
        Kernel.raise(TypeError, "'exception' must be nil or an instance of or descendant of Exception")
      end
      @mutex.synchronize do
        Kernel.raise(Complete) if @complete
        @complete = true
        @exception = exception
        @waiter.resume_all_indefinitely
      end
      nil
    end

    # Sets it to a value.
    # @raise [Complete] if it has already completed
    # @param new_value [nil,Object] value to assign to future
    # @return [void]
    def set(new_value = nil)
      @mutex.synchronize do
        Kernel.raise(Complete) if @complete
        @complete = true
        @value = new_value
        @waiter.resume_all_indefinitely
      end
      nil
    end

  end
end

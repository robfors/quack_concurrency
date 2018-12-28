module QuackConcurrency

  # {Waiter} is similar to {ConditionVariable}.
  #
  # A few differences include:
  # * the ability to force any future request to {#wait} to return immediately
  # * every call to {#wait} can only be resumed via the {Waiter}
  #   (not with +Thread#run+, +Thread#wakeup+, etc.)
  # * {#wait} does not accept a mutex
  # * some methods have been renamed to be more intuitive
  # @api private
  class Waiter

    # Creates a new {Waiter} concurrency tool.
    # @return [Waiter]
    def initialize
      @condition_variable = SafeConditionVariable.new
      @resume_all_indefinitely = false
      @mutex = ::Mutex.new
    end

    # Checks if any threads are waiting on it.
    # @return [Boolean]
    def any_waiting_threads?
      @condition_variable.any_waiting_threads?
    end

    # Resumes all threads waiting on it.
    # @return [void]
    def resume_all
      @condition_variable.broadcast
    end

    # Resumes all threads waiting on it and will cause
    #   any future calls to {#wait} to return immediately. 
    # @return [void]
    def resume_all_indefinitely
      @mutex.synchronize do
        @resume_all_indefinitely = true
        resume_all
      end
    end

    # Resumes next thread waiting on it if one exists.
    # @return [void]
    def resume_next
      @condition_variable.signal
    end

    # Puts this thread to sleep until another thread resumes it via this {Waiter}.
    # @note Will block until resumed.
    # @return [void]
    def wait
      @mutex.synchronize do
        return if @resume_all_indefinitely
        @condition_variable.wait(@mutex)
      end
    end

    # Returns the number of threads waiting on it.
    # @return [Integer]
    def waiting_threads_count
      @condition_variable.waiting_threads_count
    end

  end
end

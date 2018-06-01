module QuackConcurrency
  
  # @api private
  class Waiter
  
    # Creates a new {Waiter} concurrency tool.
    # @return [Waiter]
    def initialize
      @condition_variable = UninterruptibleConditionVariable.new
      @resume_all_forever = false
      @mutex = ::Mutex.new
    end
    
    def any_waiting_threads?
      @condition_variable.any_waiting_threads?
    end
    
    # Resumes all current and future waiting Thread.
    # @return [void]
    def resume_all
      @condition_variable.broadcast
      nil
    end
    
    # Resumes all current and future waiting Thread.
    # @return [void]
    def resume_all_forever
      @mutex.synchronize do
        @resume_all_forever = true
        resume_all
      end
      nil
    end
    
    # Resumes next waiting Thread if one exists.
    # @return [void]
    def resume_one
      @condition_variable.signal
      nil
    end
    
    # Waits for another Thread to resume the calling Thread.
    # @note Will block until resumed.
    # @return [void]
    def wait
      @mutex.synchronize do
        return if @resume_all_forever
        @condition_variable.wait(@mutex)
      end
      nil
    end
    
    def waiting_threads_count
      @condition_variable.waiting_threads_count
    end
    
  end
end

module QuackConcurrency

  # Unlike `::ConditionVariable` {UninterruptibleConditionVariable} will
  # safely sleep a `Thread`s. Any calls to `Thread#run` directly, will be ignored.
  class UninterruptibleConditionVariable
  
    def initialize
      @waiting_threads_sleepers = []
      @mutex = ::Mutex.new
    end
    
    def any_waiting_threads?
      waiting_threads_count >= 1
    end
    
    def broadcast
      @mutex.synchronize do
        signal_next until @waiting_threads_sleepers.empty?
      end
      self
    end
    
    def signal
      @mutex.synchronize do
        signal_next if @waiting_threads_sleepers.any?
      end
      self
    end
    
    def wait(mutex = nil, timeout = nil)
      validate_mutex(mutex)
      if timeout != nil && !timeout.is_a?(Numeric)
        raise ArgumentError, "'timeout' argument must be nil or a Numeric"
      end
      sleeper = UninterruptibleSleeper.for_current
      @mutex.synchronize { @waiting_threads_sleepers.push(sleeper) }
      if mutex
        if mutex.respond_to?(:unlock!)
          mutex.unlock! { sleep(sleeper, timeout) }
        else
          mutex.unlock
          sleep(sleeper, timeout)
          mutex.lock
        end
      else
        sleep(sleeper, timeout)
      end
      @mutex.synchronize { @waiting_threads_sleepers.delete(sleeper) }
      self
    end
    
    def waiting_threads_count
      @waiting_threads_sleepers.length
    end
    
    private
    
    # @api private
    def signal_next
      next_waiting_thread_sleeper = @waiting_threads_sleepers.shift
      next_waiting_thread_sleeper.run_thread if next_waiting_thread_sleeper
      nil
    end
    
    # @api private
    def sleep(sleeper, duration)
      if duration == nil || duration == Float::INFINITY
        sleeper.stop_thread
      else
        sleeper.sleep_thread(timeout)
      end
      nil
    end
    
    def validate_mutex(mutex)
      return if mutex == nil
      return if mutex.respond_to?(:lock) && (mutex.respond_to?(:unlock) || mutex.respond_to?(:unlock!))
      raise ArgumentError, "'mutex' must respond to 'lock' and ('unlock' or'unlock!')"
    end
    
  end
end

module QuackConcurrency

  # {ConditionVariable} is similar to +::ConditionVariable+.
  #
  # A a few differences include:
  # * {#wait} supports passing a {ReentrantMutex} and {Mutex}
  # * methods have been added to get information on waiting threads
  class ConditionVariable

    # Creates a new {ConditionVariable} concurrency tool.
    # @return [ConditionVariable]
    def initialize
      @mutex = ::Mutex.new
      @waitables = []
      @waitables_to_resume = []
    end

    # Checks if any threads are waiting on it.
    # @return [Boolean]
    def any_waiting_threads?
      waiting_threads_count >= 1
    end

    # Resumes all threads waiting on it.
    # @return [self]
    def broadcast
      @mutex.synchronize do
        signal_next until @waitables_to_resume.empty?
      end
      self
    end

    # Returns the {Waitable} representing the next thread to be woken.
    # It will return the thread that made the earliest call to {#wait}.
    # @api private
    # @return [Waitable]
    def next_waitable_to_wake
      @mutex.synchronize { @waitables.first }
    end

    # Resumes next thread waiting on it if one exists.
    # @return [self]
    def signal
      @mutex.synchronize do
        signal_next if @waitables_to_resume.any?
      end
      self
    end

    # Puts this thread to sleep until another thread resumes it.
    # Threads will be woken in the chronological order that this was called.
    # @note Will block until resumed
    # @param mutex [Mutex] mutex to be unlocked while this thread is sleeping
    # @param timeout [nil,Numeric] maximum time to sleep in seconds, +nil+ for forever
    # @raise [TypeError] if +timeout+ is not +nil+ or +Numeric+
    # @raise [ArgumentError] if +timeout+ is negative
    # @raise [Exception] any exception raised by +::ConditionVariable#wait+ (eg. interrupts, +ThreadError+)
    # @return [self]
    def wait(mutex, timeout = nil)
      validate_mutex(mutex)
      validate_timeout(timeout)
      waitable = waitable_for_current_thread
      @mutex.synchronize do
        @waitables.push(waitable)
        @waitables_to_resume.push(waitable)
      end
      waitable.wait(mutex, timeout)
      self
    end

    # Remove a {Waitable} whose thread has been woken.
    # @api private
    # @return [void]
    def waitable_woken(waitable)
      @mutex.synchronize { @waitables.delete(waitable) }
    end

    # Returns the number of threads currently waiting on it.
    # @return [Integer]
    def waiting_threads_count
      @waitables.length
    end

    private

    # Wakes up the next waiting thread.
    # Will try again if the thread has already been woken.
    # @api private
    # @return [void]
    def signal_next
      loop do
        next_waitable = @waitables_to_resume.shift
        if next_waitable
          resume_successful = next_waitable.resume
          break if resume_successful
        end
      end
      nil
    end

    # Validates that an object behaves like a +::Mutex+
    # Must be able to lock and unlock +mutex+.
    # @api private
    # @param mutex [Mutex] mutex to be validated
    # @raise [TypeError] if +mutex+ does not behave like a +::Mutex+
    # @return [void]
    def validate_mutex(mutex)
      return if mutex.respond_to?(:lock) && mutex.respond_to?(:unlock)
      return if mutex.respond_to?(:unlock!)
      raise TypeError, "'mutex' must respond to ('lock' and 'unlock') or 'unlock!'"
    end

    # Validates a timeout value
    # @api private
    # @param timeout [nil,Numeric]
    # @raise [TypeError] if +timeout+ is not +nil+ or +Numeric+
    # @raise [ArgumentError] if +timeout+ is negative
    # @return [void]
    def validate_timeout(timeout)
      unless timeout == nil
        raise TypeError, "'timeout' must be nil or a Numeric" unless timeout.is_a?(Numeric)
        raise ArgumentError, "'timeout' must not be negative" if timeout.negative?
      end
    end

    # Returns a waitable to represent the current thread.
    # @api private
    # @return [Waitable]
    def waitable_for_current_thread
      Waitable.new(self)
    end

  end
end

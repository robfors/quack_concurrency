module QuackConcurrency

  # A {Sleeper} can be used to preemptively wake a thread that will be put to sleep in the future.
  #
  # A thread can only be put to sleep and woken once for each {Sleeper}.
  class Sleeper

    # Creates a new {Sleeper} concurrency tool.
    # @return [Sleeper]
    def initialize
      @state = :initial
      @mutex = ::Mutex.new
      @condition_variable = ::ConditionVariable.new
      @sleep_called = false
      @wake_called = false
    end

    # Puts this thread to sleep.
    # Will be skipped if {#wake} has already been called.
    # If called without a timeout it will sleep forever.
    # It can only be called once.
    # @param timeout [nil,Numeric] maximum time to sleep in seconds, +nil+ for forever
    # @raise [TypeError] if +timeout+ is not +nil+ or +Numeric+
    # @raise [ArgumentError] if +timeout+ is negative
    # @raise [RuntimeError] if already called once
    # @raise [Exception] any exception raised by +ConditionVariable#wait+ (eg. interrupts, +ThreadError+)
    # @return [Float] duration of time the thread was asleep in seconds
    def sleep(timeout = nil)
      timeout = process_timeout(timeout)
      enforce_sleep_call_limit
      @mutex.synchronize do
        timer do
          @condition_variable.wait(@mutex, timeout) unless @wake_called
        end
      end
    end

    # Wake it's sleeping thread, if one exists.
    # It can only be called once.
    # @raise [RuntimeError] if already called once
    # @return [void]
    def wake
      @mutex.synchronize do
        enforce_wake_call_limit
        @condition_variable.signal
      end
      nil
    end

    private

    # Ensure {#sleep} is not called more than once.
    # Call this every time {#sleep} is called.
    # @api private
    # @raise [RuntimeError] if called more than once
    # @return [void]
    def enforce_sleep_call_limit
      raise RuntimeError, '#sleep has already been called once' if @sleep_called
      @sleep_called = true
    end

    # Ensure {#wake} is not called more than once.
    # Call this every time {#wake} is called.
    # @api private
    # @raise [RuntimeError] if called more than once
    # @return [void]
    def enforce_wake_call_limit
      raise RuntimeError, '#wake has already been called once' if @wake_called
      @wake_called = true
    end

    # Calculate time elapsed when running a block.
    # @api private
    # @yield called while running timer
    # @yieldparam start_time [Time]
    # @raise [Exception] any exception raised in block
    # @return [Float] time elapsed while running block
    def timer(&block)
      start_time = Time.now
      yield(start_time)
      time_elapsed = Time.now - start_time
    end

    # Validates a timeout value, converting to a acceptable value if necessary
    # @api private
    # @param timeout [nil,Numeric]
    # @raise [TypeError] if +timeout+ is not +nil+ or +Numeric+
    # @raise [ArgumentError] if +timeout+ is negative
    # @return [nil,Numeric]
    def process_timeout(timeout)
      unless timeout == nil
        raise TypeError, "'timeout' must be nil or a Numeric" unless timeout.is_a?(Numeric)
        raise ArgumentError, "'timeout' must not be negative" if timeout.negative?
      end
      timeout = nil if timeout == Float::INFINITY
      timeout
    end

  end
end

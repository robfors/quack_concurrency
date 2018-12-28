module QuackConcurrency

  # A {SafeSleeper} can be used to safely sleep a thread or preemptively wake it.
  #
  # Unlike simply calling +Thread#sleep+, {#sleep} will ensure that only
  # calling {#wake} on this {SafeSleeper} will wake the thread.
  # Any call to +Thread#run+ directly, will be ignored.
  # Threads are still be resumed if +Thread#raise+ is called which may cause
  # problems so it should never be used.
  # A thread can only be put to sleep and woken once for each {SafeSleeper}.
  class SafeSleeper < Sleeper

    # Creates a new {SafeSleeper} concurrency tool.
    # @return [SafeSleeper]
    def initialize
      super
      @state = :initial
    end

    # @see SafeSleeper#sleep
    def sleep(timeout = nil)
      timer do |start_time|
        deadline = wake_deadline(start_time, timeout)
        enforce_sleep_call_limit
        @mutex.synchronize do
          break if @state == :complete
          @state == :sleep
          wait(deadline)
        ensure
          @state = :complete
        end
      end
    end

    # @see SafeSleeper#wake
    def wake
      @mutex.synchronize do
        enforce_wake_call_limit
        @state = :complete
        @condition_variable.signal
      end
      nil
    end

    private

    # Put this thread to sleep and wait for it to be woken.
    # Will wake if {#wake} is called.
    # If called with a +deadline+ it will wake when +deadline+ is reached.
    # @api private
    # @param deadline [nil,Time] maximum time to sleep, +nil+ for forever
    # @raise [Exception] any exception raised by +ConditionVariable#wait+ (eg. interrupts, +ThreadError+)
    # @return [void]
    def wait(deadline)
      loop do
        if deadline
          remaining = deadline - Time.now
          @condition_variable.wait(@mutex, remaining) if remaining > 0
        else
          @condition_variable.wait(@mutex)
        end
        break if @state == :complete
        break if deadline && Time.now >= deadline
      end
    end

    # Calculate the desired time to wake up.
    # @api private
    # @param start_time [nil,Time] time when the thread is put to sleep
    # @param timeout [Numeric] desired time to sleep in seconds, +nil+ for forever
    # @raise [TypeError] if +start_time+ is not +nil+ or a +Numeric+
    # @raise [ArgumentError] if +start_time+ is negative
    # @return [Time]
    def wake_deadline(start_time, timeout)
      timeout = process_timeout(timeout)
      deadline = start_time + timeout if timeout
    end

  end
end

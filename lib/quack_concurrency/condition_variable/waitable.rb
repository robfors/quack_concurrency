module QuackConcurrency
  class ConditionVariable

    # Used to put threads to sleep and wake them back up in order.
    # A given mutex will be unlocked while the thread sleeps.
    # When waking a thread it will ensure the mutex is relocked before wakng the next thread.
    # Threads will be woken in the chronological order that {#wait} was called.
    class Waitable

      # Creates a new {Waitable}.
      # @return [ConditionVariable]
      def initialize(condition_variable)
        @condition_variable = condition_variable
        @complete_condition_variable = ::ConditionVariable.new
        @mutex = ::Mutex.new
        @sleeper = Sleeper.new
        @state = :inital
      end

      # Request the sleeping thread to wake.
      # It will return +false+ if the thread was already woken,
      #   possibly due to an interrupt or calling +Thread#run+, etc.
      # @return [Boolean] if the thread was successfully woken during this call
      def resume
        @mutex.synchronize do
          if @state == :complete
            false
          else
            @sleeper.wake
            true
          end
        end
      end

      # Puts this thread to sleep until {#resume} is called.
      # Unlocks +mutex+ while sleeping
      # It will ensure that previous sleeping threads have resumed before mutex is relocked.
      # @note Will block until resumed
      # @param mutex [Mutex] mutex to be unlocked while this thread is sleeping
      # @param timeout [nil,Numeric] maximum time to sleep in seconds, nil for forever
      # @raise [TypeError] if +timeout+ is not +nil+ or +Numeric+
      # @raise [ArgumentError] if +timeout+ is negative
      # @raise [Exception] any exception raised by +::ConditionVariable#wait+ (eg. interrupts, +ThreadError+)
      # @return [self]
      def wait(mutex, timeout)
        # ideally we would would check if this thread can sleep (ie. is not the last thread alive)
        #   before we unlock the mutex, however I am not sure that it can be implemented
        if mutex.respond_to?(:unlock!)
          mutex.unlock! { sleep(timeout) }
        else
          mutex_unlock(mutex) { sleep(timeout) }
        end
      ensure
        @mutex.synchronize do
          @condition_variable.waitable_woken(self)
          @state = :complete
          @complete_condition_variable.broadcast
        end
      end

      # Wait until thread has woken and relocked the mutex.
      # Will block until thread has resumed.
      # Will not block if {#resume} has already been called.
      # @api private
      # @return [void]
      def wait_until_resumed
        @mutex.synchronize do
          @complete_condition_variable.wait(@mutex) unless @state == :complete
        end
      end

      private

      # Temporarily unlocks a mutex while a block is run.
      # If an error is raised in the block, +mutex+ will try to be immediately relocked
      #   before passing the error up. If unsuccessful, a +ThreadError+ will be raised to
      #   imitate the core's behavior.
      # @api private
      # @raise [ThreadError] if relock unsuccessful after an error
      # @return [void]
      def mutex_unlock(mutex, &block)
        mutex.unlock
        yield
        mutex.lock
      rescue Exception
        unless mutex.try_lock
          raise ThreadError, "Attempt to lock a mutex which is locked by another thread"
        end
        raise
      end

      # Puts this thread to sleep.
      # It will ensure that previous sleeping threads have resumed before returning.
      # @api private
      # @param timeout [nil, Numeric] time to sleep in seconds, nil for forever
      # @return [void]
      def sleep(timeout)
        @sleeper.sleep(timeout)
        loop do
          next_waitable = @condition_variable.next_waitable_to_wake
          break if next_waitable == self
          next_waitable.wait_until_resumed
        end
      end

    end
  end
end

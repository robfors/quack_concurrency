module QuackConcurrency

  # {Mutex} is similar to +::Mutex+.
  #
  # A few differences include:
  # * {#lock} supports passing a block and behaves like +::Mutex#synchronize+
  # * {#unlock} supports passing a block
  class Mutex

    # Creates a new {Mutex} concurrency tool.
    # @return [Mutex]
    def initialize
      @condition_variable = SafeConditionVariable.new
      @mutex = ::Mutex.new
      @owner = nil
    end

    # @raise [ThreadError] if current thread is already locking it
    #@overload lock
    #  Obtains the lock or sleeps the current thread until it is available.
    #  @return [void]
    #@overload lock(&block)
    #  Obtains the lock, runs the block, then releases the lock when the block completes.
    #  @raise [Exception] any exception raised in block
    #  @yield block to run while holding the lock
    #  @return [Object] result of the block
    def lock(&block)
      raise ThreadError, 'Attempt to lock a mutex which is already locked by this thread' if owned?
      if block_given?
        lock
        begin
          yield
        ensure
          unlock
        end
      else
        @mutex.synchronize do
          @condition_variable.wait(@mutex) if locked?
          @owner = caller
        end
        nil
      end
    end

    # Checks if it is locked by a thread.
    # @return [Boolean]
    def locked?
      !!@owner
    end

    # Checks if it is locked by another thread.
    # @return [Boolean]
    def locked_out?
      # don't need a mutex because we know #owned? can't change during the call 
      locked? && !owned?
    end

    # Checks if it is locked by current thread.
    # @return [Boolean]
    def owned?
      @owner == caller
    end

    # Returns the thread locking it if one exists.
    # @return [nil,Thread] the locking +Thread+ if one exists, otherwise +nil+
    def owner
      @owner
    end

    # Releases the lock and puts this thread to sleep.
    # @param timeout [nil, Numeric] time to sleep in seconds or +nil+ to sleep forever
    # @raise [TypeError] if +timeout+ is not +nil+ or +Numeric+
    # @raise [ArgumentError] if +timeout+ is not positive
    # @return [Integer] elapsed time sleeping
    def sleep(timeout = nil)
      validate_timeout(timeout)
      unlock do
        if timeout == nil || timeout == Float::INFINITY
          elapsed_time = (timer { Thread.stop }).round
        else
          elapsed_time = Kernel.sleep(timeout)
        end
      end
    end

    # Obtains the lock or blocks until the lock is available.
    # @raise [ThreadError] if block not given
    # @raise [ThreadError] if current thread is already locking it
    # @raise [Exception] any exception raised in block
    # @return [Object] value return from block
    def synchronize(&block)
      raise ThreadError, 'must be called with a block' unless block_given?
      lock(&block)
    end

    # Attempts to obtain the lock and return immediately.
    # @raise [ThreadError] if current thread is already locking it
    # @return [Boolean] returns if the lock was granted
    def try_lock
      raise ThreadError, 'Attempt to lock a mutex which is already locked by this thread' if owned?
      @mutex.synchronize do
        if locked?
          false
        else
          @owner = caller
          true
        end
      end
    end

    # @raise [ThreadError] if current thread is not locking it
    #@overload unlock
    #  Releases the lock
    #  @return [void]
    #@overload unlock(&block)
    #  Releases the lock, runs the block, then reacquires the lock when available,
    #    blocking if necessary.
    #  @raise [Exception] any exception raised in block
    #  @yield block to run while releasing the lock
    #  @return [Object] result of the block
    def unlock(&block)
      if block_given?
        temporarily_release(&block)
      else
        @mutex.synchronize do
          ensure_can_unlock
          if @condition_variable.any_waiting_threads?
            @condition_variable.signal
            
            # we do this to avoid a bug
            # consider this problem, imagine we have three threads:
            #   * A: this thread
            #   * B: has previously called #lock and is waiting on the @condition_variable
            #   * C: enters #lock after A has released the lock but before B has reacquired it
            #   is this scenario the threads may end up executing not in the chronological order
            #     that they entered #lock
            @owner = true
          else
            @owner = nil
          end
        end
        nil
      end
    end

    # Returns the number of threads currently waiting on it.
    # @return [Integer]
    def waiting_threads_count
      @condition_variable.waiting_threads_count
    end

    private

    # Returns the current thread.
    # @return [Thread]
    def caller
      Thread.current
    end

    # Ensure it can be unlocked
    # @raise [ThreadError] if it is not locked by the calling thread
    def ensure_can_unlock
      raise ThreadError, 'Attempt to unlock a ReentrantMutex which is not locked' unless locked?
      raise ThreadError, 'Attempt to unlock a ReentrantMutex which is locked by another thread' unless owned?
    end

    # Try to immediately lock it.
    # @api private
    # @raise [ThreadError] if another thread is locking it
    # @return [void]
    def lock_immediately
      unless try_lock
        raise ThreadError, 'Attempt to lock a mutex which is locked by another thread'
      end
    end

    # Temporarily unlocks it while a block is run.
    # If an error is raised in the block the it will try to be immediately relocked
    #   before passing the error up. If unsuccessful, a +ThreadError+ will be raised to
    #   imitate the core's behavior.
    # @api private
    # @raise [ThreadError] if relock unsuccessful after an error
    # @raise [ArgumentError] if no block given
    # @return [void]
    def temporarily_release(&block)
      raise ArgumentError, 'no block given' unless block_given?
      unlock
      begin
        return_value = yield
        lock
      rescue Exception
        lock_immediately
        raise
      end
      return_value
    end

    # Calculate time elapsed when running block.
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

    # Validates a timeout value
    # @api private
    # @raise [TypeError] if {timeout} is not +nil+ or +Numeric+
    # @raise [ArgumentError] if {timeout} is not positive
    # @return [void]
    def validate_timeout(timeout)
      unless timeout == nil
        raise TypeError, "'timeout' must be nil or a Numeric" unless timeout.is_a?(Numeric)
        raise ArgumentError, "'timeout' must not be negative" if timeout.negative?
      end
    end

  end
end

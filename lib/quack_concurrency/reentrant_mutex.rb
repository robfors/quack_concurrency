# based off https://en.wikipedia.org/wiki/Reentrant_mutex


module QuackConcurrency

  # {ReentrantMutex}s are similar to {Mutex}s with with the key distinction being
  # that a thread can call lock on a {Mutex} that it has already locked.
  class ReentrantMutex < Mutex

    # Creates a new {ReentrantMutex} concurrency tool.
    # @return [ReentrantMutex]
    def initialize
      super
      @lock_depth = 0
    end

    #@overload lock
    #  Obtains a lock, blocking until available.
    #  It will acquire a lock even if one is already held.
    #  @return [void]
    #@overload lock(&block)
    #  Obtains a lock, runs the block, then releases a lock.
    #  It will block until a lock is available.
    #  It will acquire a lock even if one is already held.
    #  @raise [ThreadError] if not locked by the calling thread when unlocking
    #  @raise [ThreadError] if not holding the same lock count when unlocking
    #  @raise [Exception] any exception raised in block
    #  @yield block to run with the lock
    #  @return [Object] result of the block
    def lock(&block)
      if block_given?  
        lock
        start_depth = @lock_depth
        begin
          yield
        ensure
          ensure_can_unlock
          unless @lock_depth == start_depth
            raise ThreadError, 'Attempt to unlock a ReentrantMutex whose lock depth has been changed since locking it'
          end
          unlock
        end
      else
        super unless owned?
        @lock_depth += 1
        nil
      end
    end

    # @see Mutex#sleep
    def sleep(timeout = nil)
      ensure_can_unlock
      base_depth do
        super(timeout)
      end
    end

    # Attempts to obtain the lock and returns immediately.
    # @return [Boolean] returns if the lock was granted
    def try_lock
      if owned? || super
        @lock_depth += 1
        true
      else
        false
      end
    end

    #@overload unlock
    #  Releases a lock.
    #  @return [void]
    #@overload unlock(&block)
    #  Releases a lock, runs the block, then reacquires the lock when available,
    #    blocking if necessary.
    #  @raise [Exception] any exception raised in block
    #  @raise [ThreadError] if relock unsuccessful after an error
    #  @yield block to run while releasing the lock
    #  @return [Object] result of the block
    # @raise [ThreadError] if it is not locked by this thread
    def unlock(&block)
      ensure_can_unlock
      if block_given?
        temporarily_release(&block)
      else
        @lock_depth -= 1
        super if @lock_depth == 0
        nil
      end
    end

    # Releases all lock, runs the block, then reacquires the same lock count when available,
    #   blocking if necessary.
    # @raise [ArgumentError] if no block given
    # @raise [ThreadError] if this thread does not hold any locks
    # @raise [Exception] any exception raised in block
    # @yield block to run while locks have been released
    # @return [Object] result of the block
    def unlock!(&block)
      ensure_can_unlock
      base_depth do
        temporarily_release(&block)
      end
    end

    private

    # Releases all but one lock, runs the block, then reacquires the released lock count when available,
    #   blocking if necessary.
    # @api private
    # @raise [Exception] any exception raised in block
    # @return [Object] result of the block
    def base_depth(&block)
      start_depth = @lock_depth
      @lock_depth = 1
      return_value = yield
      @lock_depth = start_depth
      return_value
    end

    # Ensure it can be unlocked
    # @raise [ThreadError] if it is not locked by this thread
    # @return [void]
    def ensure_can_unlock
      raise ThreadError, 'Attempt to unlock a ReentrantMutex which is not locked' unless locked?
      raise ThreadError, 'Attempt to unlock a ReentrantMutex which is locked by another thread' unless owned?
    end

  end
end

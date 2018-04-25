# based off https://en.wikipedia.org/wiki/Reentrant_mutex


module QuackConcurrency
  class ReentrantMutex < ConcurrencyTool
  
    # Creates a new {ReentrantMutex} concurrency tool.
    # @param duck_types [Hash] hash of core Ruby classes to overload.
    #   If a +Hash+ is given, the keys +:condition_variable+ and +:mutex+ must be present.
    # @return [ReentrantMutex]
    def initialize(duck_types: nil)
      classes = setup_duck_types(duck_types)
      @condition_variable = classes[:condition_variable].new
      @mutex = classes[:mutex].new
      @owner = nil
      @lock_depth = 0
    end
    
    # Locks this {ReentrantMutex}. Will block until available.
    # @return [void]
    def lock
      @mutex.synchronize do
        @condition_variable.wait(@mutex) if @owner && @owner != caller
        raise 'internal error, invalid state' if @owner && @owner != caller 
        @owner = caller
        @lock_depth += 1
      end
      nil
    end
    
    # Checks if this {ReentrantMutex} is locked by some thread.
    # @return [Boolean]
    def locked?
      !!@owner
    end
    
    # Checks if this {ReentrantMutex} is locked by a thread other than the caller.
    # @return [Boolean]
    def locked_out?
      @mutex.synchronize { locked? && @owner != caller }
    end
    
    # Checks if this {ReentrantMutex} is locked by the calling thread.
    # @return [Boolean]
    def owned?
      @owner == caller
    end
    
    # Releases the lock and sleeps.
    # When the calling thread is next woken up, it will attempt to reacquire the lock.
    # @param timeout [Integer] seconds to sleep, +nil+ will sleep forever
    # @raise [Error] if this {ReentrantMutex} wasn't locked by the calling thread.
    # @return [void]
    def sleep(timeout = nil)
      unlock
      # i would rather not need to get a ducktype for sleep so we will just take
      #   advantage of Mutex's sleep method that must take it into account already
      @mutex.synchronize do
        @mutex.sleep(timeout)
      end
      nil
    ensure
      lock unless owned?
    end
    
    # Obtains a lock, runs the block, and releases the lock when the block completes.
    # @return return value from yielded block
    def synchronize
      lock
      start_depth = @lock_depth
      start_owner = @owner
      result = yield
      result
    ensure
      unless @lock_depth == start_depth && @owner == start_owner
        raise Error, 'could not unlock reentrant mutex as its state has been modified'
      end
      unlock
    end
    
    # Attempts to obtain the lock and returns immediately.
    # @return [Boolean] returns if the lock was granted
    def try_lock
      @mutex.synchronize do
        return false if @owner && @owner != caller
        @owner = caller
        @lock_depth += 1
        true
      end
    end
    
    # Releases the lock.
    # @raise [Error] if {ReentrantMutex} wasn't locked by the calling thread
    # @return [void]
    def unlock
      @mutex.synchronize do
        raise Error, 'can not unlock reentrant mutex, it is not locked' if @lock_depth == 0
        raise Error, 'can not unlock reentrant mutex, caller is not the owner' unless @owner == caller
        @lock_depth -= 1
        if @lock_depth == 0
          @owner = nil
          @condition_variable.signal
        end
      end
      nil
    end
    
    private
    
    def caller
      Thread.current
    end
    
  end
end
  

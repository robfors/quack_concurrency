# based off https://en.wikipedia.org/wiki/Reentrant_mutex


module QuackConcurrency
  class ReentrantMutex < Mutex
  
    # Creates a new {ReentrantMutex} concurrency tool.
    # @return [ReentrantMutex]
    def initialize
      super
      @lock_depth = 0
    end
    
    #@overload lock
    #  Obtains the lock or sleeps the current `Thread` until it is available.
    #  @return [void]
    #@overload lock(&block)
    #  Obtains the lock, runs the block, then releases the lock when the block completes.
    #  @yield block to run with the lock
    #  @return [Object] result of the block
    def lock(&block)
      if block_given?  
        lock
        start_depth = @lock_depth
        start_owner = owner
        begin
          yield
        ensure
          unless @lock_depth == start_depth && owner == start_owner
            raise Error, 'could not unlock reentrant mutex as its state has been modified'
          end
          unlock
        end
      else
        super unless owned?
        @lock_depth += 1
        nil
      end
    end
    
    # Checks if this {ReentrantMutex} is locked by a Thread other than the caller.
    # @return [Boolean]
    def locked_out?
      # don't need a mutex because we know #owned? can't change during the call 
      locked? && !owned?
    end
    
    # Releases the lock and sleeps.
    # When the calling Thread is next woken up, it will attempt to reacquire the lock.
    # @param timeout [Integer] seconds to sleep, `nil` will sleep forever
    # @raise [Error] if this {ReentrantMutex} wasn't locked by the calling Thread
    # @return [void]
    def sleep(timeout = nil)
      raise Error, 'can not unlock reentrant mutex, it is not locked' unless locked?
      raise Error, 'can not unlock reentrant mutex, caller is not the owner' unless owned?
      base_depth do
        super(timeout)
      end
    end
    
    # Obtains a lock, runs the block, and releases the lock when the block completes.
    # @return [Object] value from yielded block
    def synchronize(&block)
      lock(&block)
    end
    
    alias parent_try_lock try_lock
    private :parent_try_lock
    # Attempts to obtain the lock and returns immediately.
    # @return [Boolean] returns if the lock was granted
    def try_lock
      if owned?
        @lock_depth += 1
        true
      else
        lock_successful = parent_try_lock
        if lock_successful
          @lock_depth += 1
          true
        else
          false
        end
      end
    end
    
    # Releases the lock.
    # @raise [Error] if {ReentrantMutex} wasn't locked by the calling Thread
    # @return [void]
    def unlock(&block)
      raise Error, 'can not unlock reentrant mutex, it is not locked' unless locked?
      raise Error, 'can not unlock reentrant mutex, caller is not the owner' unless owned?
      if block_given?
        unlock
        begin
          yield
        ensure
          lock
        end
      else
        @lock_depth -= 1
        super if @lock_depth == 0
        nil
      end
    end
    
    # Releases the lock.
    # @raise [Error] if {ReentrantMutex} wasn't locked by the calling Thread
    # @return [void]
    def unlock!(&block)
      raise Error, 'can not unlock reentrant mutex, it is not locked' unless locked?
      raise Error, 'can not unlock reentrant mutex, caller is not the owner' unless owned?
      if block_given?
        base_depth do
          unlock
          begin
            yield
          ensure
            lock
          end
        end
      else
        @lock_depth = 0
        super
        nil
      end
    end
    
    private
    
    # @api private
    def base_depth(&block)
      start_depth = @lock_depth
      @lock_depth = 1
      yield
    ensure
      @lock_depth = start_depth
    end
    
  end
end
  

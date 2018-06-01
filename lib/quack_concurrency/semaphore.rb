# not ready yet

module QuackConcurrency
  class Semaphore
  
    # Gets total permit count
    # @return [Integer]
    attr_reader :permit_count
    
    # Creates a new {Semaphore} concurrency tool.
    # @return [Semaphore]
    def initialize(permit_count = 1)
      raise 'not ready yet'
      @condition_variable = UninterruptibleConditionVariable.new
      verify_permit_count(permit_count)
      @permit_count = permit_count
      @permits_used = 0
      @mutex = ::ReentrantMutex.new
    end
    
    # Check if a permit is available to be released.
    # @return [Boolean]
    def permit_available?
      permits_available >= 1
    end
    
    # Counts number of permits available to be released.
    # @return [Integer]
    def permits_available
      @mutex.synchronize do
        raw_permits_available = @permit_count - @permits_used
        raw_permits_available.positive? ? raw_permits_available : 0
      end
    end
    
    # Returns a permit so it can be released again in the future.
    # @return [void]
    def reacquire
      @mutex.synchronize do
        raise Error, 'can not reacquire a permit, no permits released right now' if @permits_used == 0
        @permits_used -= 1
        @condition_variable.signal if permit_available?
      end
      nil
    end
    
    # Releases a permit.
    # @note Will block until a permit is available.
    # @return [void]
    def release
      @mutex.synchronize do
        @condition_variable.wait(@mutex) unless permit_available?
        raise 'internal error, invalid state' unless permit_available?
        @permits_used += 1
      end
      nil
    end
    
    # Changes the permit count after {Semaphore} has been created.
    # @raise [Error] if total permit count is reduced and not enough permits are available to remove
    # @return [void]
    def set_permit_count(new_permit_count)
      verify_permit_count(new_permit_count)
      @mutex.synchronize do
        remove_permits = @permit_count - new_permit_count
        if remove_permits.positive? && remove_permits > permits_available
          raise Error, 'can not set new permit count, not enough permits available to remove right now'
        end
        set_permit_count!(new_permit_count)
      end
      nil
    end
    
    # Changes the permit count after {Semaphore} has been created.
    # If total permit count is reduced and not enough permits are available to remove,
    # it will change the count anyway but some permits will need to be reacquired
    # before any can be released.
    # @return [void]
    def set_permit_count!(new_permit_count)
      verify_permit_count(new_permit_count)
      @mutex.synchronize do
        new_permits = new_permit_count - @permit_count
        if new_permits.positive?
          new_permits.times { add_permit }
        else
          remove_permits = -new_permits
          remove_permits.times { remove_permit! }
        end
      end
      nil
    end
    
    # Releases a permit, runs the block, and reacquires the permit when the block completes.
    # @return return value from yielded block
    def synchronize
      release
      begin
        yield
      ensure
        reacquire
      end
    end
    
    # Attempts to release a permit and returns immediately.
    # @return [Boolean] returns if the permit was released
    def try_release
      @mutex.synchronize do
        if permit_available?
          release
          true
        else
          false
        end
      end
    end
    
    private
    
    def add_permit
      @permit_count += 1
      @condition_variable.signal if permit_available?
      nil
    end
    
    def remove_permit!
      @permit_count -= 1
      raise 'internal error, invalid state' if @permit_count < 0
      nil
    end
    
    def verify_permit_count(permit_count)
      unless permit_count.is_a?(Integer) && permit_count >= 0
        raise ArgumentError, "'permit_count' must be a non negative Integer"
      end
    end
    
  end
end
  

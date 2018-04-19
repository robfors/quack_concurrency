module QuackConcurrency
  class Semaphore < ConcurrencyTool
  
    attr_reader :permit_count
    
    def initialize(permit_count = 1, duck_types: nil)
      classes = setup_duck_types(duck_types)
      @condition_variable = classes[:condition_variable].new
      verify_permit_count(permit_count)
      @permit_count = permit_count
      @permits_used = 0
      @mutex = ReentrantMutex.new(duck_types: duck_types)
    end
    
    def permit_available?
      permits_available >= 1
    end
    
    def permits_available
      @mutex.synchronize do
        raw_permits_available = @permit_count - @permits_used
        raw_permits_available.positive? ? raw_permits_available : 0
      end
    end
    
    def reacquire
      @mutex.synchronize do
        raise Error, 'can not reacquire a permit, no permits released right now' if @permits_used == 0
        @permits_used -= 1
        @condition_variable.signal if permit_available?
      end
      nil
    end
    
    def release
      @mutex.synchronize do
        @condition_variable.wait(@mutex) unless permit_available?
        raise 'internal error, invalid state' unless permit_available?
        @permits_used += 1
      end
      nil
    end
    
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
    
    def synchronize
      release
      begin
        yield
      ensure
        reacquire
      end
    end
    
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
  

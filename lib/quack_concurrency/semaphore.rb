# Author: Rob Fors
# Revision Date: 20180102

module QuackConcurrency
  class Semaphore
  
    attr_reader :permit_count
    
    def initialize(permit_count = 1, duck_types: {})
      condition_variable_class = duck_types[:condition_variable] || ConditionVariable
      raise 'Error: permit_count invalid' if permit_count < 1
      @permit_count = permit_count
      @permits_used = 0
      @mutex = ReentrantMutex.new(duck_types: duck_types)
      @condition_variable = condition_variable_class.new
    end
    
    def acquire
      @mutex.synchronize do
        @condition_variable.wait(@mutex) unless permit_available?
        @permits_used += 1
      end
      nil
    end
    
    def set_permit_count(new_permit_count)
      @mutex.synchronize do
        remove_permits = @permit_count - new_permit_count
        if remove_permits.positive? && remove_permits > permits_available
          raise 'Error: can not remove enough permits right not'
        end
        set_permit_count!(new_permit_count)
      end
      nil
    end
    
    def set_permit_count!(new_permit_count)
      raise 'Error: permit_count invalid' if new_permit_count < 1
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
    
    def release
      @mutex.synchronize do
        raise 'No pemit to release.' if @permits_used == 0
        @permits_used -= 1
        @condition_variable.signal if permit_available?
      end
      nil
    end
    
    # how to handle if yield raises an error but has temporarily released its permit?
    #def synchronize
    #  acquire
    #  begin
    #    yield
    #  ensure
    #    release
    #  end
    #end
    
    def permits_available
      @mutex.synchronize { @permit_count - @permits_used }
    end
    
    def permit_available?
      @mutex.synchronize { permits_available >= 1 }
    end
    
    private
    
    def add_permit
      @permit_count += 1
      @condition_variable.signal
    end
    
    def remove_permit!
      @permit_count -= 1
    end
    
  end
end
  

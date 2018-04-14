# based off https://en.wikipedia.org/wiki/Reentrant_mutex

module QuackConcurrency
  class ReentrantMutex
  
    def initialize(duck_types: {})
      condition_variable_class = duck_types[:condition_variable] || ConditionVariable
      @kernel_module = duck_types[:kernel] || Kernel
      mutex_class = duck_types[:mutex] || Mutex
      @condition_variable = condition_variable_class.new
      @mutex = mutex_class.new
      @owner = nil
      @lock_depth = 0
    end
    
    def lock
      @mutex.synchronize do
        @condition_variable.wait(@mutex) if @owner && @owner != caller
        @owner = caller
        @lock_depth += 1
      end
      nil
    end
    
    def locked?
      !!@owner
    end
    
    def locked_out?
      @mutex.synchronize { locked? && @owner != caller }
    end
    
    def owned?
      @owner == caller
    end
    
    def sleep(timeout = nil)
      unlock
      if timeout
        @kernel_module.sleep(timeout)
      else
        @kernel_module.sleep
      end
      lock
    end
    
    def synchronize
      lock
      start_depth = @lock_depth
      start_owner = @owner
      result = yield
      result
    ensure
      unless @lock_depth == start_depth && @owner == start_owner
        raise 'could not unlock mutex as its state has been modified'
      end
      unlock
    end
    
    def try_lock
      @mutex.synchronize do
        if @owner && @owner != caller
          return false
        else
          @owner = caller
          @lock_depth += 1
        end
      end
      true
    end
    
    def unlock
      @mutex.synchronize do
        raise "not locked" if @lock_depth == 0
        raise "not the owner" unless @owner == caller
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
  

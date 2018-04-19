# based off https://en.wikipedia.org/wiki/Reentrant_mutex

module QuackConcurrency
  class ReentrantMutex < ConcurrencyTool
  
    def initialize(duck_types: nil)
      classes = setup_duck_types(duck_types)
      @condition_variable = classes[:condition_variable].new
      @mutex = classes[:mutex].new
      @owner = nil
      @lock_depth = 0
    end
    
    def lock
      @mutex.synchronize do
        @condition_variable.wait(@mutex) if @owner && @owner != caller
        raise 'internal error, invalid state' if @owner && @owner != caller 
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
    
    def sleep(*args)
      unlock
      # i would rather not need to get a ducktype for sleep so we will just take
      #   advantage of Mutex's sleep method that must take it into account already
      @mutex.synchronize do
        @mutex.sleep(*args)
      end
      nil
    ensure
      lock unless owned?
    end
    
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
    
    def try_lock
      @mutex.synchronize do
        return false if @owner && @owner != caller
        @owner = caller
        @lock_depth += 1
        true
      end
    end
    
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
  

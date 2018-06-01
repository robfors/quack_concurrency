module QuackConcurrency
  
  # @note duck type for `::Thread::Mutex`
  class Mutex
  
    # Creates a new {Mutex} concurrency tool.
    # @return [Mutex]
    def initialize
      @mutex = ::Mutex.new
      @condition_variable = UninterruptibleConditionVariable.new
      @owner = nil
    end
    
    # @raise [ThreadError] if current `Thread` is already locking it
    #@overload lock
    #  Obtains the lock or sleeps the current `Thread` until it is available.
    #  @return [void]
    #@overload lock(&block)
    #  Obtains the lock, runs the block, then releases the lock when the block completes.
    #  @yield block to run with the lock
    #  @return [Object] result of the block
    def lock(&block)
      raise ThreadError, 'this Thread is already locking this Mutex' if owned?
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
    
    def locked?
      !!@owner
    end
    
    def owned?
      @owner == caller
    end
    
    def owner
      @owner
    end
    
    def sleep(timeout = nil)
      if timeout != nil && !timeout.is_a?(Numeric)
        raise ArgumentError, "'timeout' argument must be nil or a Numeric"
      end
      unlock do
        if timeout
          elapsed_time = Kernel.sleep(timeout)
        else
          elapsed_time = Kernel.sleep
        end
      end
    end
    
    def synchronize(&block)
      lock(&block)
    end
    
    # Attempts to obtain the lock and returns immediately.
    # @return [Boolean] returns if the lock was granted
    def try_lock
      raise ThreadError, 'this Thread is already locking this Mutex' if owned?
      @mutex.synchronize do
        if locked?
          false
        else
          @owner = caller
          true
        end
      end
    end
    
    def unlock(&block)
      if block_given?
        unlock
        begin
          yield
        ensure
          lock
        end
      else
        @mutex.synchronize do
          raise ThreadError, 'Mutex is not locked' unless locked?
          raise ThreadError, 'current Thread is not locking the Mutex' unless owned?
          if @condition_variable.any_waiting_threads?
            @condition_variable.signal
            
            # we do this to avoid a bug
            # consider what would happen if we set this to nil and then a thread called #lock
            #   before the resuming thread was able to set itself at the owner in #lock
            @owner = true
          else
            @owner = nil
          end
        end
        nil
      end
    end
    
    def waiting_threads_count
      @condition_variable.waiting_threads_count
    end
    
    private
    
    def caller
      Thread.current
    end
    
  end
end

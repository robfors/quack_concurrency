module QuackConcurrency

  # An {UninterruptibleSleeper} can be used to safely sleep a `Thread`.
  # Unlike simply calling `Thread#sleep`, {#stop_thread} will ensure that only
  # calling {#run_thread} on this {UninterruptibleSleeper} will wake the `Thread`.
  # Any call to `Thread#run` directly, will be ignored.
  # `Thread`s can still be resumed if `Thread#raise` is called.
  # A `ThreadError` will be raised if a the last running `Thread` is stopped.
  class UninterruptibleSleeper
    
    def self.for_current
      new(Thread.current)
    end
    
    def initialize(thread)
      raise ArgumentError, "'thread' must be a Thread" unless thread.is_a?(Thread)
      @thread = thread
      @state = :running
      @mutex = ::Mutex.new
      @stop_called = false
      @run_called = false
    end
    
    def run_thread
      @mutex.synchronize do
        raise '#run_thread has already been called once' if @run_called
        @run_called = true
        return if @state == :running
        Thread.pass until @state = :running || @thread.status == 'sleep'
        @state = :running
        @thread.run
      end
      nil
    end
    
    def sleep_thread(duration)
      start_time = Time.now
      stop_thread(timeout: duration)
      time_elapsed = Time.now - start_time
    end
    
    def stop_thread(timeout: nil)
      raise 'can only stop current Thread' unless Thread.current == @thread
      raise "'timeout' argument must be nil or a Numeric" if timeout != nil && !timeout.is_a?(Numeric)
      raise '#stop_thread has already been called once' if @stop_called
      @stop_called = true
      target_end_time = Time.now + timeout if timeout
      @mutex.synchronize do
        return if @run_called
        @state = :sleeping
        @mutex.unlock
        loop do
          if timeout
            time_left = target_end_time - Time.now
            Kernel.sleep(time_left) if time_left > 0
          else
            Thread.stop # may raise ThreadError if this is last running Thread
          end
          break if @state == :running || Time.now >= target_time
        end
      ensure
        @state = :running
        
        # we relock the mutex to ensure #run_thread has finshed before #stop_thread
        # if Thread#run is called by another part of the code at the same time as
        #   #run_thread is being called, we dont want the call to #run_thread
        #   to call Thread#run on a Thread has already resumed and stopped again
        @mutex.lock
      end
      nil
    end
    
    private
    
    # @api private
    def current?
      Thread.current == @thread
    end
    
  end
end

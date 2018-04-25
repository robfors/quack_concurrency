module QuackConcurrency
  
  # @note duck type for +::Thread::Queue+
  class Queue < ConcurrencyTool
  
    # Creates a new {Queue} concurrency tool.
    # @param duck_types [Hash] hash of core Ruby classes to overload.
    #   If a +Hash+ is given, the keys +:condition_variable+ and +:mutex+ must be present.
    # @return [Queue]
    def initialize(duck_types: nil)
      classes = setup_duck_types(duck_types)
      @condition_variable = classes[:condition_variable].new
      @mutex = classes[:mutex].new
      @queue = []
      @waiting_count = 0
      @closed = false
    end
    
    # Removes all objects from the queue.
    # @return [self]
    def clear
      @mutex.synchronize { @queue = [] }
      self
    end
    
    # Closes the queue. A closed queue cannot be re-opened.
    # After the call to close completes, the following are true:
    # * {#closed?} will return +true+.
    # * {#close} will be ignored.
    # * {#push} will raise an exception.
    # * until empty, calling {#pop} will return an object from the queue as usual.
    # @return [self]
    def close
      @mutex.synchronize do
        return if closed?
        @closed = true
        @condition_variable.broadcast
      end
      self
    end
    
    # Checks if queue is closed.
    # @return [Boolean]
    def closed?
      @closed
    end
    
    # Checks if queue is empty.
    # @return [Boolean]
    def empty?
      @queue.empty?
    end
    
    # Returns the length of the queue.
    # @return [Integer]
    def length
      @queue.length
    end
    alias_method :size, :length
    
    # Returns the number of threads waiting on the queue.
    # @return [Integer]
    def num_waiting
      @waiting_count
    end
    
    # Retrieves item from the queue.
    # @note If the queue is empty, it will block until an item is available.
    def pop
      @mutex.synchronize do
        if @waiting_count >= length
          return if closed?
          @waiting_count += 1
          @condition_variable.wait(@mutex)
          @waiting_count -= 1
          return if closed?
        end
        @queue.shift
      end
    end
    alias_method :deq, :pop
    alias_method :shift, :pop
    
    # Pushes the given object to the queue.
    # @return [self]
    def push(item = nil)
      @mutex.synchronize do
        raise ClosedQueueError if closed?
        @queue.push(item)
        @condition_variable.signal
      end
      self
    end
    alias_method :<<, :push
    alias_method :enq, :push
    
  end
end

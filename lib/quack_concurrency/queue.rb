module QuackConcurrency
  class Queue < ConcurrencyTool
  
    def initialize(duck_types: nil)
      classes = setup_duck_types(duck_types)
      @condition_variable = classes[:condition_variable].new
      @mutex = classes[:mutex].new
      @queue = []
      @waiting_count = 0
      @closed = false
    end
    
    def clear
      @mutex.synchronize { @queue = [] }
      self
    end
    
    def close
      @mutex.synchronize do
        return if closed?
        @closed = true
        @condition_variable.broadcast
      end
      self
    end
    
    def closed?
      @closed
    end
    
    def empty?
      @queue.empty?
    end
    
    def length
      @queue.length
    end
    alias_method :size, :length
    
    def num_waiting
      @waiting_count
    end
    
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

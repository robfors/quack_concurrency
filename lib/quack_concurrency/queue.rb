module QuackConcurrency

  # This is a duck type for +::Thread::Queue+.
  # It is intended to be a drop in replacement for it's core counterpart.
  # Valuable if +::Thread::Queue+ has not been implemented.
  class Queue

    # Creates a new {Queue} concurrency tool.
    # @return [Queue]
    def initialize
      @closed = false
      @items = []
      @mutex = ::Mutex.new
      @pop_mutex = Mutex.new
      @waiter = Waiter.new
    end

    # Removes all objects from it.
    # @return [self]
    def clear
      @mutex.synchronize { @items.clear }
      self
    end

    # Closes it.
    # Once closed, it cannot be re-opened.
    # After the call to close completes, the following are true:
    # * {#closed?} will return +true+.
    # * {#close} will be ignored.
    # * {#push} will raise an exception.
    # * until empty, calling {#pop} will return an object from it as usual.
    # @return [self]
    def close
      @mutex.synchronize do
        return if closed?
        @closed = true
        @waiter.resume_all
      end
      self
    end

    # Checks if it is closed.
    # @return [Boolean]
    def closed?
      @closed
    end

    # Checks if it is empty.
    # @return [Boolean]
    def empty?
      @items.empty?
    end

    # Returns the length of it.
    # @return [Integer]
    def length
      @items.length
    end
    alias_method :size, :length

    # Returns the number of threads waiting on it.
    # @return [Integer]
    def num_waiting
      @pop_mutex.waiting_threads_count + @waiter.waiting_threads_count
    end

    # Retrieves an item from it.
    # @note If it is empty, the method will block until an item is available.
    # If +non_block+ is +true+, a +ThreadError+ will be raised.
    # @raise [ThreadError] if it is empty and +non_block+ is +true+
    # @param non_block [Boolean]
    # @return [Object]
    def pop(non_block = false)
      @pop_mutex.lock do
        @mutex.synchronize do
          if empty?
            return if closed?
            raise ThreadError if non_block
            @mutex.unlock
            @waiter.wait
            @mutex.lock
            return if closed?
          end
          @items.shift
        end
      end
    end
    alias_method :deq, :pop
    alias_method :shift, :pop

    # Pushes the given object to it.
    # @param item [Object]
    # @return [self]
    def push(item = nil)
      @mutex.synchronize do
        raise ClosedQueueError if closed?
        @items.push(item)
        @waiter.resume_next
      end
      self
    end
    alias_method :<<, :push
    alias_method :enq, :push

  end
end

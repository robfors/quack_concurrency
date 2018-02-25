# Author: Rob Fors
# Revision Date: 20180102

module QuackConcurrency
  class ConditionVariable
  
    def initialize(duck_types: {})
      mutex_class = duck_types[:mutex] || Mutex
      queue_class = duck_types[:queue] || Queue
      @mutex = mutex_class.new
      @queue = queue_class.new
    end
    
    def signal
      @mutex.synchronize do
        @queue.push(nil) unless @queue.num_waiting == 0
      end
    end
    
    def broadcast
      @mutex.synchronize do
        @queue.push(nil) until @queue.num_waiting == 0
      end
    end
    
    def wait(mutex)
      mutex.unlock
      @queue.pop
      mutex.lock
      nil
    end
    
  end
end

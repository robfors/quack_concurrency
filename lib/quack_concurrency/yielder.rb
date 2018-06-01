# not ready yet

module Threadesque
  class SafeYielder
    
    def self.for_current
      new(Thread.current)
    end
    
    def initialize(thread)
      raise 'not ready yet'
      @thread = thread
      @state = :running
    end
    
    def resume
      raise 'Thread is not sleeping' unless @state == :sleeping
      :wait until @thread.status == 'sleep'
      @state = :running
      @thread.run
      nil
    end
    
    def yield
      raise 'can only stop current Thread' unless Thread.current == @thread
      @state = :sleeping
      loop do
        Thread.stop
        redo if @state == :sleeping
      end
      nil
    end
    
  end
end

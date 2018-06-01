require 'quack_concurrency'

RSpec.describe QuackConcurrency::Queue do
  
  describe "#push" do
  
    context "when called many times when queue is not closed" do
      it "should not raise error" do
        queue = QuackConcurrency::Queue.new
        expect{ queue.push(1) }.not_to raise_error
        expect{ queue.push(2) }.not_to raise_error
      end
    end
    
  end
  
  describe "#pop" do
  
    context "when #pop is called with non_block set to true" do
      it "should raise Error" do
        queue = QuackConcurrency::Queue.new
        expect{ queue.pop(true) }.to raise_error(ThreadError)
      end
    end
    
  end
  
  describe "#close, #push" do

    context "when called when queue is closed" do
      it "should raise ClosedQueueError" do
        queue = QuackConcurrency::Queue.new
        queue.close
        expect{ queue.push(1) }.to raise_error(ClosedQueueError)
      end
    end
    
  end
  
  describe "#pop, #close" do
  
    context "when #pop is called after #close on empty queue" do
      it "should reutrn nil" do
        queue = QuackConcurrency::Queue.new
        queue.close
        expect(queue.pop).to eql nil
      end
    end
    
  end
  
  describe "#pop, #close" do
  
    context "when #pop is called before #close on empty queue" do
      it "should wait for #close then reutrn nil" do
        queue = QuackConcurrency::Queue.new
        thread = Thread.new do
          sleep 1
          queue.close
        end
        start_time = Time.now
        expect(queue.pop).to eql nil
        end_time = Time.now
        duration = end_time - start_time
        thread.join
        expect(duration).to be > 0.5
      end
    end
    
  end
  
  describe "#pop, #push, #close" do
  
    context "when #pop is called after #close on queue with one item" do
      it "should reutrn item" do
        queue = QuackConcurrency::Queue.new
        queue.push(1)
        queue.close
        expect(queue.pop).to eql 1
      end
    end
    
  end
  
  describe "#pop, #push" do
  
    context "when #pop is called before #push" do
      it "should wait until #push is called" do
        $test = []
        queue = QuackConcurrency::Queue.new
        thread = Thread.new do
          queue.pop
          $test << 1
          sleep 1
          queue.push
        end
        sleep 1
        queue.push
        queue.pop
        $test << 2
        thread.join
        expect($test).to eql [1, 2]
      end
    end
  
  end
  
  describe "#pop, #push, #clear" do
  
    context "when #pop is called after #push but before #clear" do
      it "should wait until #push is called again" do
        queue = QuackConcurrency::Queue.new
        queue.push(1)
        queue.clear
        thread = Thread.new do
          sleep 1
          queue.push(2)
        end
        start_time = Time.now
        expect(queue.pop).to eql 2
        end_time = Time.now
        duration = end_time - start_time
        thread.join
        expect(duration).to be > 0.5
      end
    end
  
  end
  
end

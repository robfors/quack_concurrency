require 'quack_concurrency'

RSpec.describe QuackConcurrency::Queue do
  
  describe "pop" do
  
    context "when called when queue empty" do
      it "should wait" do
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
    
    context "when called when queue not empty" do
      it "should immediately return" do
        $test = []
        queue = QuackConcurrency::Queue.new
        queue.push
        thread = Thread.new do
          queue.pop
          $test << 1
        end
        sleep 1
        $test << 2
        thread.join
        expect($test).to eql [1, 2]
      end
    end
    
    context "when called" do
      it "should return value of the push" do
        queue = QuackConcurrency::Queue.new
        queue.push 1
        expect(queue.pop).to eql 1
      end
    end
    
  end
end

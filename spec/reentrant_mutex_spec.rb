require 'quack_concurrency'

RSpec.describe QuackConcurrency::ReentrantMutex do
  
  describe "lock" do
  
    context "when called for first time" do
      it "should not raise error" do
        mutex = QuackConcurrency::ReentrantMutex.new
        expect { mutex.lock }.not_to raise_error
      end
    end
    
    context "when called the second time" do
      it "should not raise error" do
        mutex = QuackConcurrency::ReentrantMutex.new
        mutex.lock
        expect { mutex.lock }.not_to raise_error
      end
    end
    
    context "when called on non owning thread" do
      it "should wait" do
        $test = []
        mutex = QuackConcurrency::ReentrantMutex.new
        thread = Thread.new do
          sleep 1
          mutex.lock
          $test << 2
        end
        mutex.lock
        sleep 2
        $test << 1
        mutex.unlock
        thread.join
        expect($test).to eql [1, 2]
      end
    end
    
  end
  
  describe "unlock" do
  
    context "when called after one lock" do
      it "should not raise error" do
        mutex = QuackConcurrency::ReentrantMutex.new
        mutex.lock
        expect { mutex.unlock }.not_to raise_error
      end
    end
    
    context "when called after two locks" do
      it "should not raise error" do
        mutex = QuackConcurrency::ReentrantMutex.new
        mutex.lock
        mutex.lock
        expect { mutex.unlock }.not_to raise_error
      end
    end
    
    context "when called twice after only one lock" do
      it "should raise error" do
        mutex = QuackConcurrency::ReentrantMutex.new
        mutex.lock
        mutex.unlock
        expect { mutex.unlock }.to raise_error(QuackConcurrency::ReentrantMutex::Error)
      end
    end
    
  end
end

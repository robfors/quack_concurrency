require 'quack_concurrency'

RSpec.describe QuackConcurrency::ReentrantMutex do
  
  describe "#lock" do
  
    context "when called for first time" do
      it "should not raise error" do
        mutex = QuackConcurrency::ReentrantMutex.new
        expect { mutex.lock }.not_to raise_error
      end
    end
    
    context "when called a second time" do
      it "should not raise error" do
        mutex = QuackConcurrency::ReentrantMutex.new
        mutex.lock
        expect { mutex.lock }.not_to raise_error
      end
    end
    
  end
  
  describe "#lock, #unlock" do
    
    context "when #lock called on non owning thread" do
      it "should wait for #unlock" do
        mutex = QuackConcurrency::ReentrantMutex.new
        thread = Thread.new do
          mutex.lock
          sleep 2
          mutex.unlock
        end
        sleep 1
        start_time = Time.now
        mutex.lock
        end_time = Time.now
        duration = end_time - start_time
        thread.join
        expect(duration).to be > 0.5
      end
    end
    
    context "when #unlock called after one #lock" do
      it "should not raise error" do
        mutex = QuackConcurrency::ReentrantMutex.new
        mutex.lock
        expect { mutex.unlock }.not_to raise_error
      end
    end
    
    context "when #unlock called after two #locks" do
      it "should not raise error" do
        mutex = QuackConcurrency::ReentrantMutex.new
        mutex.lock
        mutex.lock
        expect { mutex.unlock }.not_to raise_error
      end
    end
    
    context "when #unlock called twice after only one #lock" do
      it "should raise error" do
        mutex = QuackConcurrency::ReentrantMutex.new
        mutex.lock
        mutex.unlock
        expect { mutex.unlock }.to raise_error(QuackConcurrency::ReentrantMutex::Error)
      end
    end
    
  end
  
  describe "#lock, #try_lock" do
    
    context "when #try_lock called" do
      it "should reutrn true" do
        mutex = QuackConcurrency::ReentrantMutex.new
        expect(mutex.try_lock).to eql true
      end
    end
    
    context "when #try_lock called after #lock called from other Thread" do
      it "should reutrn false" do
        mutex = QuackConcurrency::ReentrantMutex.new
        thread = Thread.new { mutex.lock }
        sleep 1
        expect(mutex.try_lock).to eql false
      end
    end
    
  end
  
  describe "#lock, #try_lock, #unlock" do
    
    context "when #lock called after #try_lock called from other Thread" do
      it "should wait for #unlock" do
        mutex = QuackConcurrency::ReentrantMutex.new
        thread = Thread.new do
          mutex.try_lock
          sleep 2
          mutex.unlock
        end
        sleep 1
        start_time = Time.now
        mutex.lock
        end_time = Time.now
        duration = end_time - start_time
        thread.join
        expect(duration).to be > 0.5
      end
    end
    
  end
  
  describe "#synchronize" do
    
    context "when #synchronize called" do
      it "should return last value from block" do
        mutex = QuackConcurrency::ReentrantMutex.new
        value = mutex.synchronize do
          1
        end
        expect(value).to eql 1
      end
    end
    
  end
  
  describe "#sleep" do
    
    context "when #sleep called with time argument" do
      it "should wait for that time" do
        mutex = QuackConcurrency::ReentrantMutex.new
        start_time = Time.now
        #require 'pry'
        #binding.pry
        mutex.synchronize do
          mutex.sleep(1)
        end
        end_time = Time.now
        duration = end_time - start_time
        expect(duration).to be > 0.5
      end
    end
    
    context "when #sleep called with no time argument" do
      it "should wait until Thread is resumed" do
        mutex = QuackConcurrency::ReentrantMutex.new
        start_time = nil
        end_time = nil
        thread = Thread.new do
          start_time = Time.now
          mutex.synchronize do
            mutex.sleep
          end
          end_time = Time.now
        end
        sleep 1
        thread.run
        thread.join
        duration = end_time - start_time
        expect(duration).to be > 0.5
      end
    end
    
  end
  
end

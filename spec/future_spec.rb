require 'quack_concurrency'

RSpec.describe QuackConcurrency::Future do
  
  describe "#set" do
  
    context "when called" do
      it "should not raise error" do
        future = QuackConcurrency::Future.new
        expect{ future.set(1) }.not_to raise_error
      end
    end
    
    context "when called a second time" do
      it "should raise QuackConcurrency::Future::Complete" do
        future = QuackConcurrency::Future.new
        future.set(1)
        expect{ future.set(2) }.to raise_error(QuackConcurrency::Future::Complete)
      end
    end
    
  end
  
  describe "#cancel" do
  
    context "when called" do
      it "should not raise error" do
        future = QuackConcurrency::Future.new
        expect{ future.cancel }.not_to raise_error
      end
    end
    
    context "when called a second time" do
      it "should raise QuackConcurrency::Future::Complete" do
        future = QuackConcurrency::Future.new
        future.cancel
        expect{ future.cancel }.to raise_error(QuackConcurrency::Future::Complete)
      end
    end
    
  end
  
  describe "#set, #get" do
  
    context "when #get called after #set" do
      it "should return value from #set argument" do
        future = QuackConcurrency::Future.new
        future.set(1)
        expect(future.get).to eql 1
      end
    end
    
    context "when #get called a second time" do
      it "should return value from #set argument" do
        future = QuackConcurrency::Future.new
        future.set(1)
        future.get
        expect(future.get).to eql 1
      end
    end
    
    context "when #get called before #set" do
      it "should wait and return value from #set argument after #set is called" do
        future = QuackConcurrency::Future.new
        thread = Thread.new do
          sleep 1
          future.set(1)
        end
        start_time = Time.now
        expect(future.get).to eql 1
        end_time = Time.now
        duration = end_time - start_time
        thread.join
        expect(duration).to be > 0.5
      end
    end
    
  end
  
  describe "#set, #cancel" do
  
    context "when #set called after #cancel" do
      it "should raise QuackConcurrency::Future::Complete" do
        future = QuackConcurrency::Future.new
        future.cancel
        expect{ future.set(1) }.to raise_error(QuackConcurrency::Future::Complete)
      end
    end
    
    context "when #cancel called after #set" do
      it "should raise QuackConcurrency::Future::Complete" do
        future = QuackConcurrency::Future.new
        future.set(1)
        expect{ future.cancel }.to raise_error(QuackConcurrency::Future::Complete)
      end
    end
    
  end
  
  describe "#get, #cancel" do
  
    context "when #get called after #cancel" do
      it "should raise QuackConcurrency::Future::Canceled" do
        future = QuackConcurrency::Future.new
        future.cancel
        expect{ future.get }.to raise_error(QuackConcurrency::Future::Canceled)
      end
    end
    
  end

  describe "#raise" do
  
    context "when called with nil" do
      it "should set the error to raise StandardError" do
        future = QuackConcurrency::Future.new
        expect{ future.raise }.not_to raise_error
        expect{ future.get }.to raise_error(StandardError)
      end
    end

    context "when called with an error instance" do
      it "should set the error to that instance" do
        future = QuackConcurrency::Future.new
        e = TypeError.new
        expect{ future.raise(e) }.not_to raise_error
        expect{ future.get }.to raise_error(e)
      end
    end

    context "when called with an error class" do
      it "should set the error to an instance of that class" do
        future = QuackConcurrency::Future.new
        expect{ future.raise(TypeError) }.not_to raise_error
        expect{ future.get }.to raise_error(TypeError)
      end
    end

    context "when called with an invalid argument" do
      it "should raise ArgumentError" do
        future = QuackConcurrency::Future.new
        expect{ future.raise("error") }.to raise_error(ArgumentError)
      end
    end
    
  end
  
end

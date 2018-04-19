require 'quack_concurrency'

RSpec.describe QuackConcurrency::Future do
  
  describe "::new" do
  
    context "when called without a 'duck_types' argument" do
      it "should create a new QuackConcurrency::Future" do
        future = QuackConcurrency::Future.new
        expect(future).to be_a(QuackConcurrency::Future)
      end
    end
    
    context "when called with 'condition_variable' and 'mutex' duck types" do
      it "should create a new QuackConcurrency::Future" do
        duck_types = {condition_variable: Class.new, mutex: Class.new}
        future = QuackConcurrency::Future.new(duck_types: duck_types)
        expect(future).to be_a(QuackConcurrency::Future)
      end
    end
    
    context "when called with only 'condition_variable' duck type" do
      it "should raise ArgumentError" do
        duck_types = {condition_variable: Class.new}
        expect{ QuackConcurrency::Future.new(duck_types: duck_types) }.to raise_error(ArgumentError)
      end
    end
    
    context "when called with only 'mutex' duck type" do
      it "should raise ArgumentError" do
        duck_types = {mutex: Class.new}
        expect{ QuackConcurrency::Future.new(duck_types: duck_types) }.to raise_error(ArgumentError)
      end
    end
    
  end
  
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
          future.set 1
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
  
end

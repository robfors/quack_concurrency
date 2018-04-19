require 'quack_concurrency'

RSpec.describe QuackConcurrency::Semaphore do
  
  describe "::new" do
  
    context "when called without a 'duck_types' argument" do
      it "should create a new QuackConcurrency::Semaphore" do
        semaphore = QuackConcurrency::Semaphore.new
        expect(semaphore).to be_a(QuackConcurrency::Semaphore)
      end
    end
    
    context "when called with 'condition_variable' and 'mutex' duck types" do
      it "should create a new QuackConcurrency::Semaphore" do
        duck_types = {condition_variable: Class.new, mutex: Class.new}
        semaphore = QuackConcurrency::Semaphore.new(duck_types: duck_types)
        expect(semaphore).to be_a(QuackConcurrency::Semaphore)
      end
    end
    
    context "when called with only 'condition_variable' duck type" do
      it "should raise ArgumentError" do
        duck_types = {condition_variable: Class.new}
        expect{ QuackConcurrency::Semaphore.new(duck_types: duck_types) }.to raise_error(ArgumentError)
      end
    end
    
    context "when called with only 'mutex' duck type" do
      it "should raise ArgumentError" do
        duck_types = {mutex: Class.new}
        expect{ QuackConcurrency::Semaphore.new(duck_types: duck_types) }.to raise_error(ArgumentError)
      end
    end
    
  end
  
  describe "#release" do
  
    context "when called for the first time with many permits available" do
      it "should not raise error" do
        semaphore = QuackConcurrency::Semaphore.new(2)
        
        expect{ semaphore.release }.not_to raise_error
      end
    end
    
    context "when called a second time with one permit available" do
      it "should not raise error" do
        semaphore = QuackConcurrency::Semaphore.new(2)
        semaphore.release
        expect{ semaphore.release }.not_to raise_error
      end
    end
  
  end
  
  describe "#release, #reacquire" do
    
    context "when #release called with no permits available" do
      it "should wait until #reacquire is called" do
        semaphore = QuackConcurrency::Semaphore.new(2)
        semaphore.release
        semaphore.release
        thread = Thread.new do
          sleep 1
          semaphore.reacquire
        end
        start_time = Time.now
        semaphore.release
        end_time = Time.now
        duration = end_time - start_time
        thread.join
        expect(duration).to be > 0.5
      end
    end
    
    context "when #reacquire called when all permits are available" do
      it "should raise QuackConcurrency::Semaphore::Error" do
        semaphore = QuackConcurrency::Semaphore.new(2)
        expect{ semaphore.reacquire }.to raise_error(QuackConcurrency::Semaphore::Error)
      end
    end
    
  end
  
  describe "#release, #reacquire, #permit_available?, #permits_available" do
  
    context "#permit_available? and #permits_available" do
      it "should work as expected" do
        semaphore = QuackConcurrency::Semaphore.new(2)
        expect(semaphore.permit_available?).to eql true
        expect(semaphore.permits_available).to eql 2
        semaphore.release
        expect(semaphore.permit_available?).to eql true
        expect(semaphore.permits_available).to eql 1
        semaphore.release
        expect(semaphore.permit_available?).to eql false
        expect(semaphore.permits_available).to eql 0
        semaphore.reacquire
        expect(semaphore.permit_available?).to eql true
        expect(semaphore.permits_available).to eql 1
        semaphore.reacquire
        expect(semaphore.permit_available?).to eql true
        expect(semaphore.permits_available).to eql 2
      end
    end
    
  end
  
  describe "#set_permit_count, #permits_available" do
  
    context "when #set_permit_count is called with more permits then currently exist" do
      it "should add permits" do
        semaphore = QuackConcurrency::Semaphore.new(2)
        expect(semaphore.permits_available).to eql 2
        semaphore.set_permit_count(3)
        expect(semaphore.permits_available).to eql 3
      end
    end
    
    context "when #set_permit_count is called with less permits then currently exist" do
      it "should remove permits" do
        semaphore = QuackConcurrency::Semaphore.new(2)
        expect(semaphore.permits_available).to eql 2
        semaphore.set_permit_count(1)
        expect(semaphore.permits_available).to eql 1
      end
    end
  
  end
  
  describe "#set_permit_count, #permits_available, #release" do
    
    context "when #set_permit_count is called with less permits then currently available" do
      it "should raise QuackConcurrency::Semaphore::Error" do
        semaphore = QuackConcurrency::Semaphore.new(2)
        expect(semaphore.permits_available).to eql 2
        semaphore.release
        semaphore.release
        expect{ semaphore.set_permit_count(1) }.to raise_error(QuackConcurrency::Semaphore::Error)
      end
    end
    
  end
  
  describe "#set_permit_count, #release" do
  
    context "when #set_permit_count is called with more permits when one thread is waiting on #release" do
      it "should resume the thread" do
        semaphore = QuackConcurrency::Semaphore.new(2)
        semaphore.release
        semaphore.release
        thread = Thread.new do
          sleep 1
          semaphore.set_permit_count(3)
        end
        start_time = Time.now
        semaphore.release
        end_time = Time.now
        duration = end_time - start_time
        thread.join
        expect(duration).to be > 0.5
      end
    end
    
  end
  
  describe "#set_permit_count!, #permits_available" do
  
    context "when #set_permit_count! is called with more permits then currently exist" do
      it "should add permits" do
        semaphore = QuackConcurrency::Semaphore.new(2)
        expect(semaphore.permits_available).to eql 2
        semaphore.set_permit_count!(3)
        expect(semaphore.permits_available).to eql 3
      end
    end
    
    context "when #set_permit_count! is called with less permits then currently exist" do
      it "should remove permits" do
        semaphore = QuackConcurrency::Semaphore.new(2)
        expect(semaphore.permits_available).to eql 2
        semaphore.set_permit_count!(1)
        expect(semaphore.permits_available).to eql 1
      end
    end
  
  end
  
  describe "#set_permit_count!, #permits_available, #release, #reacquire" do
    
    context "when #set_permit_count! is called with less permits then currently available" do
      it "should force new permit count" do
        semaphore = QuackConcurrency::Semaphore.new(2)
        expect(semaphore.permits_available).to eql 2
        semaphore.release
        semaphore.release
        semaphore.set_permit_count!(1)
        expect(semaphore.permit_available?).to eql false
        semaphore.reacquire
        expect(semaphore.permit_available?).to eql false
        semaphore.reacquire
        expect(semaphore.permit_available?).to eql true
      end
    end
    
  end
  
  describe "#set_permit_count!, #release" do
  
    context "when #set_permit_count! is called with more permits when one thread is waiting on #release" do
      it "should resume the thread" do
        semaphore = QuackConcurrency::Semaphore.new(2)
        semaphore.release
        semaphore.release
        thread = Thread.new do
          sleep 1
          semaphore.set_permit_count(3)
        end
        start_time = Time.now
        semaphore.release
        end_time = Time.now
        duration = end_time - start_time
        thread.join
        expect(duration).to be > 0.5
      end
    end
    
  end
  
  describe "#set_permit_count!, #release, #permit_available?" do
  
    context "when semaphore has no permits available, them #set_permit_count! is called to remove 2 permits, then called again to add 1 permit" do
      it "should not have any permits available" do
        semaphore = QuackConcurrency::Semaphore.new(3)
        semaphore.release
        semaphore.release
        expect(semaphore.permit_available?).to eql true
        semaphore.set_permit_count!(1)
        expect(semaphore.permit_available?).to eql false
        semaphore.set_permit_count!(2)
        expect(semaphore.permit_available?).to eql false
      end
    end
    
  end
  
  describe "#set_permit_count!, #release, #reacquire" do
  
    context "when semaphore has no permits available, them #set_permit_count! is called to remove 2 permits, then a thread starts waiting for #release, then #set_permit_count! is called again to add 1 permit" do
      it "thread should wait for #reacquire to be called" do
        semaphore = QuackConcurrency::Semaphore.new(3)
        semaphore.release
        semaphore.release
        semaphore.release
        semaphore.set_permit_count!(1)
        thread = Thread.new do
          sleep 1
          semaphore.set_permit_count!(2)
          sleep 1
          semaphore.reacquire
          sleep 1
          semaphore.reacquire
        end
        start_time = Time.now
        semaphore.release
        end_time = Time.now
        duration = end_time - start_time
        thread.join
        expect(duration).to be_between(2.5, 3.5)
      end
    end
    
  end

end

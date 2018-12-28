require 'quack_concurrency'

describe QuackConcurrency::Future do

  describe "::new" do

    context "when called with no arguments" do
      it "should return a Mutex" do
        mutex = QuackConcurrency::Mutex.new
        expect(mutex).to be_a(QuackConcurrency::Mutex)
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
      it "should raise Future::Complete" do
        future = QuackConcurrency::Future.new
        future.cancel
        expect{ future.cancel }.to raise_error(QuackConcurrency::Future::Complete)
      end
    end

    context "when called" do
      it "should raise Future::Canceled when get called" do
        future = QuackConcurrency::Future.new
        future.cancel
        expect{ future.get }.to raise_error(QuackConcurrency::Future::Canceled)
      end
    end

  end

  describe "#complete?" do

    context "when called when no value or error has been set" do
      it "should return false" do
        future = QuackConcurrency::Future.new
        expect(future.complete?).to be false
      end
    end

    context "when called when a value has been set" do
      it "should return true" do
        future = QuackConcurrency::Future.new
        future.set(1)
        expect(future.complete?).to be true
      end
    end

    context "when called when a error has been set" do
      it "should return true" do
        future = QuackConcurrency::Future.new
        future.raise
        expect(future.complete?).to be true
      end
    end

  end

  describe "#get" do

    context "when called after #set" do
      it "should return value set" do
        future = QuackConcurrency::Future.new
        future.set(1)
        expect(future.get).to eql 1
      end
    end

    context "when called after #raise" do
      it "should raise error set" do
        future = QuackConcurrency::Future.new
        e = Class.new(StandardError)
        future.raise e
        expect{ future.get }.to raise_error(e)
      end
    end

    context "when called a second time" do
      it "should return value set again" do
        future = QuackConcurrency::Future.new
        future.set(1)
        future.get
        expect(future.get).to eql 1
      end
    end

    context "when called before #set is" do
      it "should wait and return value set after #set is called" do
        future = QuackConcurrency::Future.new
        value = nil
        thread = Thread.new { sleep 1; value = future.get }
        sleep 2
        expect(thread.alive?).to be true
        future.set(1)
        sleep 1
        expect(value).to be 1
      end
    end

    context "when called before #raise is" do
      it "should wait and raise error set after #raise is called" do
        future = QuackConcurrency::Future.new
        e_class = Class.new(StandardError)
        error = nil
        thread = Thread.new do
          sleep 1
          begin
            future.get
          rescue e_class => e
            error = e
          end          
        end
        sleep 2
        expect(thread.alive?).to be true
        future.raise(e_class)
        sleep 1
        expect(error).to be_a e_class
      end
    end

  end

  describe "#raise" do

    context "when called without an argument" do
      it "should set the error to a StandardError" do
        future = QuackConcurrency::Future.new
        future.raise
        expect{ future.get }.to raise_error(StandardError)
      end
    end

    context "when called with an error instance" do
      it "should set the error to that instance" do
        future = QuackConcurrency::Future.new
        e = TypeError.new
        future.raise(e)
        expect{ future.get }.to raise_error(e)
      end
    end

    context "when called with an error class" do
      it "should set the error to an instance of that class" do
        future = QuackConcurrency::Future.new
        e = Class.new(StandardError)
        future.raise(e)
        expect{ future.get }.to raise_error(e)
      end
    end

    context "when called with an invalid argument" do
      it "should raise TypeError" do
        future = QuackConcurrency::Future.new
        expect{ future.raise("error") }.to raise_error(TypeError)
      end
    end

    context "when called when value already set" do
      it "should raise Future::Complete" do
        future = QuackConcurrency::Future.new
        future.set(1)
        expect{ future.raise }.to raise_error(QuackConcurrency::Future::Complete)
      end
    end

    context "when called when error already set" do
      it "should raise Future::Complete" do
        future = QuackConcurrency::Future.new
        future.raise
        expect{ future.raise }.to raise_error(QuackConcurrency::Future::Complete)
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

    context "when called when value already set" do
      it "should raise QuackConcurrency::Future::Complete" do
        future = QuackConcurrency::Future.new
        future.set(1)
        expect{ future.set(2) }.to raise_error(QuackConcurrency::Future::Complete)
      end
    end

    context "when called when error already set" do
      it "should raise QuackConcurrency::Future::Complete" do
        future = QuackConcurrency::Future.new
        future.raise
        expect{ future.set(2) }.to raise_error(QuackConcurrency::Future::Complete)
      end
    end

  end

end

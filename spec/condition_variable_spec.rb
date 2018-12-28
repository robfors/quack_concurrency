require 'quack_concurrency'

describe QuackConcurrency::ConditionVariable do

  describe "::new" do
  
    context "when called with no arguments" do
      it "should return a ConditionVariable" do
        condition_variable = QuackConcurrency::ConditionVariable.new
        expect(condition_variable).to be_a(QuackConcurrency::ConditionVariable)
      end
    end

  end

  describe "#any_waiting_threads?" do

    context "when called with waiting threads" do
      it "should return true" do
        condition_variable = QuackConcurrency::ConditionVariable.new
        mutex = Mutex.new
        thread = Thread.new { mutex.synchronize { condition_variable.wait(mutex) } }
        sleep 1
        expect(condition_variable.any_waiting_threads?).to be true
        condition_variable.broadcast
        thread.join
      end
    end

    context "when called with no waiting threads" do
      it "should return false" do
        condition_variable = QuackConcurrency::ConditionVariable.new
        expect(condition_variable.any_waiting_threads?).to be false
      end
    end

  end

  describe "#broadcast" do

    context "when called with waiting threads" do
      it "should resume all threads currently waiting" do
        condition_variable = QuackConcurrency::ConditionVariable.new
        mutex = ::Mutex.new
        thread1 = Thread.new { mutex.synchronize { condition_variable.wait(mutex) } }
        thread2 = Thread.new { mutex.synchronize { condition_variable.wait(mutex) } }
        sleep 1
        condition_variable.broadcast
        sleep 1
        expect(thread1.alive?).to be false
        expect(thread2.alive?).to be false
      end
    end

    context "when called with no waiting threads" do
      it "should not raise an error" do
        condition_variable = QuackConcurrency::ConditionVariable.new
        expect{ condition_variable.broadcast }.not_to raise_error
      end
    end

  end

  describe "#signal" do

    context "when called with waiting threads" do
      it "should resume the next thread currently waiting" do
        condition_variable = QuackConcurrency::ConditionVariable.new
        mutex = Mutex.new
        values = []
        Thread.new { mutex.synchronize { condition_variable.wait(mutex); values << 1 } }
        Thread.new { sleep 1; mutex.synchronize { condition_variable.wait(mutex); values << 2 } }
        Thread.new { sleep 2; mutex.synchronize { condition_variable.wait(mutex); values << 3 } }
        sleep 3
        condition_variable.signal
        condition_variable.signal
        condition_variable.signal
        sleep 1
        expect(values).to eq [1, 2, 3]
      end
    end

    context "when called with no waiting threads" do
      it "should not raise an error" do
        condition_variable = QuackConcurrency::ConditionVariable.new
        expect{ condition_variable.signal }.not_to raise_error
      end
    end

  end

  describe "#wait" do

    context "when called without a timeout" do
      it "should block until #broadcast or #signal are called" do
        condition_variable = QuackConcurrency::ConditionVariable.new
        mutex = Mutex.new
        thread1 = Thread.new { mutex.synchronize { condition_variable.wait(mutex) } }
        thread2 = Thread.new { mutex.synchronize { condition_variable.wait(mutex) } }
        sleep 1
        expect(thread1.alive?).to be true
        expect(thread2.alive?).to be true
        condition_variable.broadcast
        sleep 1
        expect(thread1.alive?).to be false
        expect(thread2.alive?).to be false
      end
      context "and before Thread#run" do
        it "should return after Thread#run is called" do
          condition_variable = QuackConcurrency::ConditionVariable.new
          mutex = Mutex.new
          thread = Thread.new { mutex.synchronize { condition_variable.wait(mutex) } }
          sleep 1
          thread.run
          sleep 1
          expect(thread.alive?).to be false
        end
      end
    end

    context "when called with a timeout" do
      context "of nil" do
        it "should return only after #broadcast or #signal are called" do
          condition_variable = QuackConcurrency::ConditionVariable.new
          mutex = Mutex.new
          thread = Thread.new { mutex.synchronize { condition_variable.wait(mutex) } }
          sleep 1
          expect(thread.alive?).to be true
          condition_variable.broadcast
          sleep 1
          expect(thread.alive?).to be false
        end
      end
      context "of Float::INFINITY" do
        it "should return only after #broadcast or #signal are called" do
          condition_variable = QuackConcurrency::ConditionVariable.new
          mutex = Mutex.new
          thread = Thread.new { mutex.synchronize { condition_variable.wait(mutex) } }
          sleep 1
          expect(thread.alive?).to be true
          condition_variable.broadcast
          sleep 1
          expect(thread.alive?).to be false
        end
      end
      context "of non Numeric value" do
        it "should raise TypeError" do
          condition_variable = QuackConcurrency::ConditionVariable.new
          mutex = Mutex.new
          expect{ mutex.synchronize { condition_variable.wait(mutex, '1') } }.to raise_error(TypeError)
        end
      end
      context "of negative Numeric value" do
        it "should raise ArgumentError" do
          condition_variable = QuackConcurrency::ConditionVariable.new
          mutex = Mutex.new
          expect{ mutex.synchronize { condition_variable.wait(mutex, -1) } }.to raise_error(ArgumentError)
        end
      end
      context "of positive Integer" do
        it "should block until timeout reached" do
          condition_variable = QuackConcurrency::ConditionVariable.new
          mutex = Mutex.new
          thread = Thread.new { mutex.synchronize { condition_variable.wait(mutex, 2) } }
          sleep 1
          expect(thread.alive?).to be true
          sleep 2
          expect(thread.alive?).to be false
        end
      end
      context "and Thread#run is called before timeout is reached" do
        it "should return after Thread#run is called" do
          condition_variable = QuackConcurrency::ConditionVariable.new
          mutex = Mutex.new
          thread = Thread.new { mutex.synchronize { condition_variable.wait(mutex, 3) } }
          sleep 1
          thread.run
          sleep 1
          expect(thread.alive?).to be false
        end
      end
    end

  end

  describe "#waiting_threads_count" do

    context "when called" do
      it "should return a Integer" do
        condition_variable = QuackConcurrency::ConditionVariable.new
        expect(condition_variable.waiting_threads_count).to be_a(Integer)
      end
    end

    context "when called with no waiting threads" do
      it "should return 0" do
        condition_variable = QuackConcurrency::ConditionVariable.new
        expect(condition_variable.waiting_threads_count).to eq(0)
      end
    end

    context "when called with one waiting thread" do
      it "should return 1" do
        condition_variable = QuackConcurrency::ConditionVariable.new
        mutex = Mutex.new
        thread = Thread.new { mutex.synchronize { condition_variable.wait(mutex) } }
        sleep 1
        expect(condition_variable.waiting_threads_count).to eq(1)
        condition_variable.broadcast
        thread.join
      end
    end

  end

end

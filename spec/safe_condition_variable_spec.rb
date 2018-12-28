require 'quack_concurrency'

describe QuackConcurrency::SafeConditionVariable do

  it "should inherit ConditionVariable" do
    expect(described_class).to be < QuackConcurrency::ConditionVariable
  end

  describe "#signal" do

    context "when called with waiting threads" do
      it "should resume the next thread currently waiting" do
        condition_variable = QuackConcurrency::SafeConditionVariable.new
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

  end

  describe "#wait" do

    context "when called without a timeout" do
      it "should block until #broadcast or #signal are called" do
        condition_variable = QuackConcurrency::SafeConditionVariable.new
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
        it "should return only after #broadcast or #signal are called" do
          condition_variable = QuackConcurrency::SafeConditionVariable.new
          mutex = Mutex.new
          thread = Thread.new { mutex.synchronize { condition_variable.wait(mutex) } }
          sleep 1
          thread.run
          sleep 1
          expect(thread.alive?).to be true
          condition_variable.broadcast
          sleep 1
          expect(thread.alive?).to be false
        end
      end
    end

    context "when called with a timeout" do
      context "of nil" do
        it "should return only after #broadcast or #signal are called" do
          condition_variable = QuackConcurrency::SafeConditionVariable.new
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
          condition_variable = QuackConcurrency::SafeConditionVariable.new
          mutex = Mutex.new
          thread = Thread.new { mutex.synchronize { condition_variable.wait(mutex) } }
          sleep 1
          expect(thread.alive?).to be true
          condition_variable.broadcast
          sleep 1
          expect(thread.alive?).to be false
        end
      end
      context "of positive Integer" do
        it "should block until timeout reached" do
          condition_variable = QuackConcurrency::SafeConditionVariable.new
          mutex = Mutex.new
          thread = Thread.new { mutex.synchronize { condition_variable.wait(mutex, 2) } }
          sleep 1
          expect(thread.alive?).to be true
          sleep 2
          expect(thread.alive?).to be false
        end
      end
      context "and Thread#run is called before timeout is reached" do
        it "should return only after timeout is reached" do
          condition_variable = QuackConcurrency::SafeConditionVariable.new
          mutex = Mutex.new
          thread = Thread.new { mutex.synchronize { condition_variable.wait(mutex, 3) } }
          sleep 1
          thread.run
          sleep 1
          expect(thread.alive?).to be true
          sleep 2
          expect(thread.alive?).to be false
        end
      end
    end

  end

end

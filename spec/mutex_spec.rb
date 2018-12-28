require 'quack_concurrency'

describe QuackConcurrency::Mutex do

  describe "::new" do

    context "when called with no arguments" do
      it "should return a Mutex" do
        mutex = QuackConcurrency::Mutex.new
        expect(mutex).to be_a(QuackConcurrency::Mutex)
      end
    end

  end

  describe "#lock" do

    context "when called when Mutex is not locked" do
      it "should not raise error" do
        mutex = QuackConcurrency::Mutex.new
        expect { mutex.lock }.not_to raise_error
      end
    end

    context "when called when Mutex is locked by this thread" do
      it "should raise ThreadError" do
        mutex = QuackConcurrency::Mutex.new
        mutex.lock
        expect { mutex.lock }.to raise_error(ThreadError)
      end
    end

    context "when called when another thread is locking the Mutex" do
      it "should only return after the other thead has released the lock" do
        mutex = QuackConcurrency::Mutex.new
        Thread.new { mutex.lock { sleep 3 } }
        thread = Thread.new { sleep 1; mutex.lock }
        sleep 2
        expect(thread.alive?).to be true
        sleep 2
        expect(thread.alive?).to be false
      end
      context "and another thread waiting on the mutex" do
        it "should wake the threads in order of calling #lock" do
          mutex = QuackConcurrency::Mutex.new
          mutex.lock
          values = []
          thread1 = Thread.new { mutex.lock { values << 1 } }
          thread2 = Thread.new { sleep 1; mutex.lock { values << 2 } }
          thread3 = Thread.new { sleep 2; mutex.lock { values << 3 } }
          sleep 3
          mutex.unlock
          sleep 1
          expect(values).to eq [1, 2, 3]
        end
      end
    end

    context "when called with a block" do
      it "should run block and return it's value" do
        mutex = QuackConcurrency::Mutex.new
        expect(mutex.lock { :a }).to be :a
      end
      it "should pass up any error raised in the block" do
        mutex = QuackConcurrency::Mutex.new
        e = Class.new(StandardError)
        expect{ mutex.lock { raise e } }.to raise_error(e)
      end
      it "should hold lock while block is executed" do
        mutex = QuackConcurrency::Mutex.new
        hold_thread = Thread.new { mutex.lock { sleep 3 } }
        lock_thread = Thread.new { sleep 1; mutex.lock }
        sleep 2
        expect(lock_thread.alive?).to be true
        hold_thread.join
        lock_thread.join
      end
      it "should release the lock after the block has returned" do
        mutex = QuackConcurrency::Mutex.new
        Thread.new { mutex.lock { sleep 2 } }
        lock_thread = Thread.new { sleep 1; mutex.lock }
        sleep 3
        expect(lock_thread.alive?).to be false
      end
      context "that raises an error" do
        it "should release the lock after the block has returned" do
          mutex = QuackConcurrency::Mutex.new
          Thread.new do
            mutex.lock { sleep 2; raise } rescue nil
          end
          sleep 3
          expect(mutex.locked?).to be false
        end
      end
      context "that unlocks the mutex" do
        it "should raise ThreadError" do
          mutex = QuackConcurrency::Mutex.new
          expect{ mutex.lock { mutex.unlock } }.to raise_error(ThreadError)
        end
      end
    end

  end

  describe "#locked?" do

    context "when called when no threads hold the lock" do
      it "should return false" do
        mutex = QuackConcurrency::Mutex.new
        expect(mutex.locked?).to be false
      end
    end

    context "when called when a thread holds the lock" do
      it "should return true" do
        mutex = QuackConcurrency::Mutex.new
        thread = Thread.new { mutex.lock { sleep 2 } }
        sleep 1
        expect(mutex.locked?).to be true
        thread.join
      end
    end

  end

  describe "#locked_out?" do

    context "when called when mutex is locked by another thread" do
      it "should return true" do
        mutex = QuackConcurrency::Mutex.new
        thread = Thread.new { mutex.lock; sleep 2 }
        sleep 1
        expect(mutex.locked_out?).to be true
        thread.join
      end
    end

    context "when called when mutex is locked by this thread" do
      it "should return false" do
        mutex = QuackConcurrency::Mutex.new
        mutex.lock
        expect(mutex.locked_out?).to be false
      end
    end

    context "when called when mutex is not locked" do
      it "should return false" do
        mutex = QuackConcurrency::Mutex.new
        expect(mutex.locked_out?).to be false
      end
    end

  end

  describe "#owned?" do

    context "when called when no threads hold the lock" do
      it "should return false" do
        mutex = QuackConcurrency::Mutex.new
        expect(mutex.owned?).to be false
      end
    end

    context "when called when another thread holds the lock" do
      it "should return false" do
        mutex = QuackConcurrency::Mutex.new
        thread = Thread.new { mutex.lock { sleep 2 } }
        sleep 1
        expect(mutex.owned?).to be false
        thread.join
      end
    end

    context "when called when this thread holds the lock" do
      it "should return true" do
        mutex = QuackConcurrency::Mutex.new
        mutex.lock
        expect(mutex.owned?).to be true
      end
    end

  end

  describe "#owner" do

    context "when called when no threads hold the lock" do
      it "should return nil" do
        mutex = QuackConcurrency::Mutex.new
        expect(mutex.owner).to be nil
      end
    end

    context "when called when a thread holds the lock" do
      it "should return the Thread" do
        mutex = QuackConcurrency::Mutex.new
        thread = Thread.new { mutex.lock { sleep 2 } }
        sleep 1
        expect(mutex.owner).to be thread
        thread.join
      end
    end

  end

  describe "#sleep" do

    context "when called while not locking the Mutex" do
      it "should raise ThreadError" do
        mutex = QuackConcurrency::Mutex.new
        expect{ mutex.sleep }.to raise_error(ThreadError)
      end
    end

    context "when called" do
      it "should relock the Mutex after thread is woken" do
        mutex = QuackConcurrency::Mutex.new
        thread = Thread.new { mutex.lock { mutex.sleep; sleep 2 } }
        sleep 1
        thread.run
        sleep 1
        expect(mutex.locked?).to be true
        thread.join
      end
    end

    context "when called with no timeout" do
      it "should return only after Thread#run is called" do
        mutex = QuackConcurrency::Mutex.new
        thread = Thread.new { mutex.lock { mutex.sleep } }
        sleep 1
        expect(thread.alive?).to be true
        thread.run
        sleep 1
        expect(thread.alive?).to be false
      end
    end

    context "when called with a timeout" do
      it "should return timeout reached" do
        mutex = QuackConcurrency::Mutex.new
        thread = Thread.new { mutex.lock { mutex.sleep(1) } }
        sleep 2
        expect(thread.alive?).to be false
      end
    end

  end

  describe "#synchronize" do

    context "when called without a block" do
      it "should raise ThreadError" do
        mutex = QuackConcurrency::Mutex.new
        expect{ mutex.synchronize }.to raise_error(ThreadError)
      end
    end

    context "when called when another thread is locking the Mutex" do
      it "should only return after the other thead has released the lock" do
        mutex = QuackConcurrency::Mutex.new
        Thread.new { mutex.lock { sleep 3 } }
        thread = Thread.new { sleep 1; mutex.synchronize {} }
        sleep 2
        expect(thread.alive?).to be true
        sleep 2
        expect(thread.alive?).to be false
      end
    end

    context "when called with a block" do
      it "should run block and return it's value" do
        mutex = QuackConcurrency::Mutex.new
        expect(mutex.synchronize { :a }).to be :a
      end
      it "should hold lock while block is executed" do
        mutex = QuackConcurrency::Mutex.new
        hold_thread = Thread.new { mutex.synchronize { sleep 3 } }
        lock_thread = Thread.new { sleep 1; mutex.lock }
        sleep 2
        expect(lock_thread.alive?).to be true
        hold_thread.join
      end
      it "should release the lock after the block has returned" do
        mutex = QuackConcurrency::Mutex.new
        Thread.new { mutex.synchronize { sleep 2 } }
        lock_thread = Thread.new { sleep 1; mutex.lock }
        sleep 3
        expect(lock_thread.alive?).to be false
      end
      context "that raises an error" do
        it "should release the lock after the block has returned" do
          mutex = QuackConcurrency::Mutex.new
          Thread.new do
            mutex.synchronize { sleep 2; raise } rescue nil
          end
          lock_thread = Thread.new { sleep 1; mutex.lock }
          sleep 3
          expect(lock_thread.alive?).to be false
        end
      end
    end

  end

  describe "#try_lock" do

    context "when called when no threads locking the Mutex" do
      it "should reutrn true" do
        mutex = QuackConcurrency::Mutex.new
        expect(mutex.try_lock).to eql true
      end
    end
    context "when called when a thread is locking the Mutex" do
      it "should reutrn true" do
        mutex = QuackConcurrency::Mutex.new
        thread = Thread.new { mutex.lock; sleep 2 }
        sleep 1
        expect(mutex.try_lock).to eql false
        thread.join
      end
    end
    context "when called when this thread is locking the Mutex" do
      it "should raise ThreadError" do
        mutex = QuackConcurrency::Mutex.new
        mutex.lock
        expect{mutex.try_lock}.to raise_error(ThreadError)
      end
    end

  end

  describe "#unlock" do

    context "when called when locking the Mutex" do
      it "should release the lock" do
        mutex = QuackConcurrency::Mutex.new
        mutex.lock
        thread = Thread.new { mutex.lock }
        sleep 1
        expect(thread.alive?).to be true
        mutex.unlock
        sleep 1
        expect(thread.alive?).to be false
      end
    end

    context "when called when not locking the Mutex" do
      it "should raise ThreadError" do
        mutex = QuackConcurrency::Mutex.new
        expect { mutex.unlock }.to raise_error(ThreadError)
      end
    end

    context "when called with a block" do
      it "should run block and return it's value" do
        mutex = QuackConcurrency::Mutex.new
        mutex.lock
        expect(mutex.unlock { :a }).to be :a
      end
      it "should pass up any error raised in the block" do
        mutex = QuackConcurrency::Mutex.new
        e = Class.new(StandardError)
        mutex.lock
        expect{ mutex.unlock { raise e } }.to raise_error(e)
      end
      it "should release the lock while block is executed" do
        mutex = QuackConcurrency::Mutex.new
        thread = Thread.new do
          mutex.lock { mutex.unlock { sleep 2 } }
        end
        sleep 1
        expect(mutex.locked?).to be false
        thread.join
      end
      it "should reacquire the lock after the block has returned" do
        mutex = QuackConcurrency::Mutex.new
        thread = Thread.new do
          mutex.lock { mutex.unlock {}; sleep 2 }
        end
        sleep 1
        expect(mutex.locked?).to be true
        thread.join
      end
      context "that raises an error when no other thread is locking the Mutex" do
        it "should reacquire the lock after the block has returned" do
          mutex = QuackConcurrency::Mutex.new
          thread = Thread.new do
            mutex.lock do
              mutex.unlock { raise } rescue nil
              sleep 2
            end
          end
          sleep 1
          expect(mutex.locked?).to be true
          thread.join
        end
      end
      context "that raises an error when another thread is locking the Mutex" do
        it "should raise ThreadError after the block has returned" do
          mutex = QuackConcurrency::Mutex.new
          thread = Thread.new { sleep 1; mutex.lock; sleep 2 }
          mutex.lock
          expect{ mutex.unlock { sleep 2; raise } }.to raise_error(ThreadError)
          thread.join
        end
      end
    end

  end

  describe "#waiting_threads_count" do

    context "when called" do
      it "should return a Integer" do
        mutex = QuackConcurrency::Mutex.new
        expect(mutex.waiting_threads_count).to be_a(Integer)
      end
    end

    context "when called with no waiting threads" do
      it "should return 0" do
        mutex = QuackConcurrency::Mutex.new
        expect(mutex.waiting_threads_count).to eq(0)
      end
    end

    context "when called with one waiting thread" do
      it "should return 1" do
        mutex = QuackConcurrency::Mutex.new
        mutex.lock
        thread = Thread.new { mutex.lock }
        sleep 1
        expect(mutex.waiting_threads_count).to eq(1)
        mutex.unlock
        thread.join
      end
    end

  end

end

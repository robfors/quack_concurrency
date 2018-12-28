require 'quack_concurrency'

describe QuackConcurrency::ReentrantMutex do

  it "should inherit Mutex" do
    expect(described_class).to be < QuackConcurrency::Mutex
  end

  describe "::new" do

    context "when called with no arguments" do
      it "should return a ReentrantMutex" do
        mutex = QuackConcurrency::ReentrantMutex.new
        expect(mutex).to be_a(QuackConcurrency::ReentrantMutex)
      end
    end

  end

  describe "#lock" do

    context "when called when mutex is not locked" do
      it "should not raise error" do
        mutex = QuackConcurrency::ReentrantMutex.new
        expect { mutex.lock }.not_to raise_error
      end
    end

    context "when called when mutex is locked by this thread" do
      it "should not raise error" do
        mutex = QuackConcurrency::ReentrantMutex.new
        mutex.lock
        expect { mutex.lock }.not_to raise_error
      end
    end

    context "when called when mutex is locked by another thread" do
      it "should block until lock is available" do
        mutex = QuackConcurrency::ReentrantMutex.new
        thread = Thread.new { sleep 1; mutex.lock }
        mutex.lock
        sleep 2
        expect(thread.alive?).to be true
        mutex.unlock
        sleep 1
        expect(thread.alive?).to be false
      end
      context "and another thread waiting on the mutex" do
        it "should wake the threads in order of calling #lock" do
          mutex = QuackConcurrency::ReentrantMutex.new
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
        mutex = QuackConcurrency::ReentrantMutex.new
        expect(mutex.lock { :a }).to be :a
      end
      it "should pass up any error raised in the block" do
        mutex = QuackConcurrency::ReentrantMutex.new
        e = Class.new(StandardError)
        expect{ mutex.lock { raise e } }.to raise_error(e)
      end
      it "should hold lock while block is executed" do
        mutex = QuackConcurrency::ReentrantMutex.new
        hold_thread = Thread.new { mutex.lock { sleep 3 } }
        lock_thread = Thread.new { sleep 1; mutex.lock }
        sleep 2
        expect(lock_thread.alive?).to be true
        hold_thread.join
        lock_thread.join
      end
      it "should release the lock after the block has returned" do
        mutex = QuackConcurrency::ReentrantMutex.new
        Thread.new { mutex.lock { sleep 2 } }
        lock_thread = Thread.new { sleep 1; mutex.lock }
        sleep 3
        expect(lock_thread.alive?).to be false
      end
      context "that raises an error" do
        it "should release the lock after the block has returned" do
          mutex = QuackConcurrency::ReentrantMutex.new
          Thread.new do
            mutex.lock { sleep 2; raise } rescue nil
          end
          lock_thread = Thread.new { sleep 1; mutex.lock }
          sleep 3
          expect(lock_thread.alive?).to be false
        end
      end
      context "that locks the mutex" do
        it "should raise ThreadError" do
          mutex = QuackConcurrency::Mutex.new
          expect{ mutex.lock { mutex.lock } }.to raise_error(ThreadError)
        end
      end
      context "that unlocks the mutex" do
        it "should raise ThreadError" do
          mutex = QuackConcurrency::Mutex.new
          expect{ mutex.lock { mutex.unlock } }.to raise_error(ThreadError)
        end
      end
      context "that fully unlocks the mutex" do
        it "should raise ThreadError" do
          mutex = QuackConcurrency::Mutex.new
          mutex.lock
          expect{ mutex.lock { mutex.unlock; mutex.unlock } }.to raise_error(ThreadError)
        end
      end
    end

    context "when called twice when mutex is not locked" do
      it "should need to unlock twice before mutex is released" do
        mutex = QuackConcurrency::ReentrantMutex.new
        thread = Thread.new { sleep 1; mutex.lock }
        mutex.lock
        mutex.lock
        sleep 2
        expect(thread.alive?).to be true
        mutex.unlock
        sleep 1
        expect(thread.alive?).to be true
        mutex.unlock
        sleep 1
        expect(thread.alive?).to be false
      end
    end

  end

  describe "#sleep" do

    context "when called while not locking the mutex" do
      it "should raise ThreadError" do
        mutex = QuackConcurrency::ReentrantMutex.new
        expect{ mutex.sleep }.to raise_error(ThreadError)
      end
    end

    context "when called" do
      it "should relock the mutex after thread is woken" do
        mutex = QuackConcurrency::ReentrantMutex.new
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
        mutex = QuackConcurrency::ReentrantMutex.new
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
        mutex = QuackConcurrency::ReentrantMutex.new
        thread = Thread.new { mutex.lock { mutex.sleep(1) } }
        sleep 2
        expect(thread.alive?).to be false
      end
    end

    context "when called while holding two locks" do
      it "should acquire two locks after thread is woken" do
        mutex = QuackConcurrency::ReentrantMutex.new
        thread = Thread.new do
          mutex.lock
          mutex.lock
          mutex.sleep(2)
          sleep 2
          mutex.unlock
          sleep 2
          mutex.unlock
          sleep 2
        end
        sleep 1
        expect(mutex.locked?).to be false
        sleep 2
        expect(mutex.locked?).to be true
        sleep 2
        expect(mutex.locked?).to be true
        sleep 2
        expect(mutex.locked?).to be false
        thread.join
      end
    end

  end

  describe "#try_lock" do

    context "when called when mutex is not locked by any thread" do
      it "should reutrn true" do
        mutex = QuackConcurrency::ReentrantMutex.new
        expect(mutex.try_lock).to eql true
      end
    end

    context "when called when mutex is locked by another thread" do
      it "should reutrn false" do
        mutex = QuackConcurrency::ReentrantMutex.new
        thread = Thread.new { mutex.lock; sleep 2 }
        sleep 1
        expect(mutex.try_lock).to eql false
      end
    end

    context "when called when mutex is locked by this thread" do
      it "should reutrn true" do
        mutex = QuackConcurrency::ReentrantMutex.new
        mutex.lock
        expect(mutex.try_lock).to eql true
      end
    end

  end

  describe "#unlock" do

    context "when called when this thread does not hold a lock" do
      it "should raise ThreadError" do
        mutex = QuackConcurrency::ReentrantMutex.new
        expect { mutex.unlock }.to raise_error(ThreadError)
      end
      context "after locking and unlocking" do
        it "should raise ThreadError" do
          mutex = QuackConcurrency::ReentrantMutex.new
          mutex.lock
          mutex.lock
          mutex.unlock
          mutex.unlock
          expect { mutex.unlock }.to raise_error(ThreadError)
        end
      end
    end

    context "when called when this thread holds one lock" do
      context "and with a thread waiting on the mutex" do
        it "should wake the thread" do
          mutex = QuackConcurrency::ReentrantMutex.new
          mutex.lock
          thread = Thread.new { mutex.lock }
          sleep 1
          mutex.unlock
          sleep 1
          expect(thread.alive?).to eql false
          thread.join
        end
      end
      context "and with no thread waiting on the mutex" do
        it "should let another thread lock the mutex in the future" do
          mutex = QuackConcurrency::ReentrantMutex.new
          mutex.lock
          thread = Thread.new { sleep 1; mutex.lock }
          mutex.unlock
          sleep 2
          expect(thread.alive?).to eql false
        end
      end
    end

    context "when called when this thread holds two locks" do
      context "and with a thread waiting on the mutex" do
        it "should not wake the thread until a second unlock" do
          mutex = QuackConcurrency::ReentrantMutex.new
          mutex.lock
          mutex.lock
          thread = Thread.new { mutex.lock }
          sleep 1
          mutex.unlock
          sleep 1
          expect(thread.alive?).to eql true
          mutex.unlock
          sleep 1
          expect(thread.alive?).to eql false
          thread.join
        end
        context "and with no thread waiting on the mutex" do
          it "should not let another thread lock the mutex in the future" do
            mutex = QuackConcurrency::ReentrantMutex.new
            mutex.lock
            mutex.lock
            thread = Thread.new { sleep 1; mutex.lock }
            mutex.unlock
            sleep 2
            expect(thread.alive?).to eql true
            mutex.unlock
            thread.join
          end
        end
      end
    end

    context "when called with a block" do
      it "should run block and return it's value" do
        mutex = QuackConcurrency::ReentrantMutex.new
        mutex.lock
        expect(mutex.unlock { :a }).to be :a
      end
      it "should pass up any error raised in the block" do
        mutex = QuackConcurrency::ReentrantMutex.new
        e = Class.new(StandardError)
        mutex.lock
        expect{ mutex.unlock { raise e } }.to raise_error(e)
      end
      it "should release a lock while block is executed" do
        mutex = QuackConcurrency::ReentrantMutex.new
        thread = Thread.new do
          mutex.lock { mutex.unlock { sleep 2 } }
        end
        sleep 1
        expect(mutex.locked?).to be false
        thread.join
      end
      it "should reacquire the lock after the block has returned" do
        mutex = QuackConcurrency::ReentrantMutex.new
        thread = Thread.new do
          mutex.lock { mutex.unlock {}; sleep 2 }
        end
        sleep 1
        expect(mutex.locked?).to be true
        thread.join
      end
      context "that raises an error when no other thread is locking the mutex" do
        it "should reacquire the lock after the block has returned" do
          mutex = QuackConcurrency::ReentrantMutex.new
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
      context "that raises an error when another thread is locking the mutex" do
        it "should raise ThreadError after the block has returned" do
          mutex = QuackConcurrency::ReentrantMutex.new
          thread = Thread.new { sleep 1; mutex.lock; sleep 2 }
          mutex.lock
          expect{ mutex.unlock { sleep 2; raise } }.to raise_error(ThreadError)
          thread.join
        end
      end
    end

  end

  describe "#unlock!" do

    context "when called without a block" do
      it "should raise ArgumentError" do
        mutex = QuackConcurrency::ReentrantMutex.new
        mutex.lock
        expect{ mutex.unlock! }.to raise_error(ArgumentError)
      end
    end

    context "when called with a block" do
      it "should run block and return it's value" do
        mutex = QuackConcurrency::ReentrantMutex.new
        mutex.lock
        expect(mutex.unlock! { :a }).to be :a
      end
      it "should pass up any error raised in the block" do
        mutex = QuackConcurrency::ReentrantMutex.new
        e = Class.new(StandardError)
        mutex.lock
        expect{ mutex.unlock! { raise e } }.to raise_error(e)
      end
      it "should release a lock while block is executed" do
        mutex = QuackConcurrency::ReentrantMutex.new
        thread = Thread.new do
          mutex.lock { mutex.unlock! { sleep 2 } }
        end
        sleep 1
        expect(mutex.locked?).to be false
        thread.join
      end
      it "should reacquire the lock after the block has returned" do
        mutex = QuackConcurrency::ReentrantMutex.new
        thread = Thread.new do
          mutex.lock { mutex.unlock! {}; sleep 2 }
        end
        sleep 1
        expect(mutex.locked?).to be true
        thread.join
      end
      context "while holding two locks" do
        it "should acquire two locks after block reutrn" do
          mutex = QuackConcurrency::ReentrantMutex.new
          thread = Thread.new do
            mutex.lock
            mutex.lock
            mutex.unlock! { sleep 2 }
            sleep 2
            mutex.unlock
            sleep 2
            mutex.unlock
            sleep 2
          end
          sleep 1
          expect(mutex.locked?).to be false
          sleep 2
          expect(mutex.locked?).to be true
          sleep 2
          expect(mutex.locked?).to be true
          sleep 2
          expect(mutex.locked?).to be false
          thread.join
        end
      end
      context "that raises an error when no other thread is locking the mutex" do
        it "should reacquire the lock after the block has returned" do
          mutex = QuackConcurrency::ReentrantMutex.new
          thread = Thread.new do
            mutex.lock do
              mutex.unlock! { raise } rescue nil
              sleep 2
            end
          end
          sleep 1
          expect(mutex.locked?).to be true
          thread.join
        end
      end
      context "that raises an error when another thread is locking the mutex" do
        it "should raise ThreadError after the block has returned" do
          mutex = QuackConcurrency::ReentrantMutex.new
          thread = Thread.new { sleep 1; mutex.lock; sleep 2 }
          mutex.lock
          expect{ mutex.unlock! { sleep 2; raise } }.to raise_error(ThreadError)
          thread.join
        end
      end
    end

  end

end

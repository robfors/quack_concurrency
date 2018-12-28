require 'quack_concurrency'

describe QuackConcurrency::Waiter do

  # arbitrary amount of time we will wait for everything to settle
  def delay(units = 1)
    sleep units
  end

  describe "::new" do

    context "when called with no arguments" do
      waiter = nil
      it "should not raise error" do
        expect{ waiter = QuackConcurrency::Waiter.new }.not_to raise_error
      end
      it "should return a Waiter" do
        expect(waiter).to be_a(QuackConcurrency::Waiter)
      end
    end

  end

  describe "#any_waiting_threads?" do

    context "when called with waiting threads" do
      it "should return true" do
        waiter = QuackConcurrency::Waiter.new
        thread = Thread.new { waiter.wait }
        delay(1)
        expect(waiter.any_waiting_threads?).to be true
        waiter.resume_all
        thread.join
      end
    end

    context "when called with no waiting threads" do
      it "should return false" do
        waiter = QuackConcurrency::Waiter.new
        expect(waiter.any_waiting_threads?).to be false
      end
    end

  end

  describe "#resume_all" do

    context "when called" do
      it "should resume all threads currently waiting" do
        waiter = QuackConcurrency::Waiter.new
        thread1 = Thread.new { waiter.wait }
        thread2 = Thread.new { waiter.wait }
        delay(1)
        waiter.resume_all
        delay(1)
        expect(thread1.alive?).to be false
        expect(thread2.alive?).to be false
      end
      it "should not resume any future threads that call #wait" do
        waiter = QuackConcurrency::Waiter.new
        waiter.resume_all
        thread = Thread.new { waiter.wait }
        delay(1)
        expect(thread.alive?).to be true
        waiter.resume_all
        thread.join
      end
    end

  end

  describe "#resume_all_indefinitely" do

    context "when called" do
      it "should resume all threads currently waiting" do
        waiter = QuackConcurrency::Waiter.new
        thread1 = Thread.new { waiter.wait }
        thread2 = Thread.new { waiter.wait }
        delay(1)
        waiter.resume_all_indefinitely
        delay(1)
        expect(thread1.alive?).to be false
        expect(thread2.alive?).to be false
      end
      it "should resume all future threads that call #wait" do
        waiter = QuackConcurrency::Waiter.new
        waiter.resume_all_indefinitely
        thread1 = Thread.new { waiter.wait }
        thread2 = Thread.new { waiter.wait }
        delay(1)
        expect(thread1.alive?).to be false
        expect(thread2.alive?).to be false
      end
    end

  end

  describe "#resume_next" do

    context "when called" do
      it "should resume the next thread currently waiting" do
        waiter = QuackConcurrency::Waiter.new
        thread1 = Thread.new { waiter.wait }
        delay(1)
        thread2 = Thread.new { waiter.wait }
        delay(1)
        waiter.resume_next
        delay(1)
        expect(thread1.alive?).to be false
        expect(thread2.alive?).to be true
        waiter.resume_next
        delay(1)
        expect(thread2.alive?).to be false
      end
    end

  end

  describe "#wait" do

    context "when called" do
      it "should return only after one of the resume methods are called" do
        waiter = QuackConcurrency::Waiter.new
        thread1 = Thread.new { waiter.wait }
        thread2 = Thread.new { waiter.wait }
        delay(1)
        expect(thread1.alive?).to be true
        expect(thread2.alive?).to be true
        waiter.resume_all
        thread1.join
        thread2.join
      end
    end

    context "when called before Thread#run" do
      it "should return only after one of the resume methods are called" do
        waiter = QuackConcurrency::Waiter.new
        elapsed_time = nil
        thread = Thread.new { waiter.wait }
        delay(1)
        thread.run
        delay(1)
        expect(thread.alive?).to be true
        waiter.resume_all
        delay(1)
        expect(thread.alive?).to be false
      end
    end

  end

  describe "#waiting_threads_count" do

    context "when called" do
      it "should return a Integer" do
        waiter = QuackConcurrency::Waiter.new
        expect(waiter.waiting_threads_count).to be_a(Integer)
      end
    end

    context "when called with no waiting threads" do
      it "should return 0" do
        waiter = QuackConcurrency::Waiter.new
        expect(waiter.waiting_threads_count).to be 0
      end
    end

    context "when called with one waiting thread" do
      it "should return 1" do
        waiter = QuackConcurrency::Waiter.new
        thread = Thread.new { waiter.wait }
        delay(1)
        expect(waiter.waiting_threads_count).to be 1
        waiter.resume_next
        thread.join
      end
    end

  end

end

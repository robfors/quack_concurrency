require 'quack_concurrency'

describe QuackConcurrency::SafeSleeper do

  def timer(&block)
    start_time = Time.now
    yield(start_time)
    time_elapsed = Time.now - start_time
  end

  def delay(units = 1)
    sleep units
  end

  def expect_time(actual_time, expected_time)
    expect(actual_time).to be_between(expected_time - 0.5, expected_time + 0.5)
  end

  def sleep_test(sleep_duration: , timeout: false, wake_at: nil, sleep_at: 0)
    sleeper = QuackConcurrency::SafeSleeper.new
    elapsed_time = nil
    sleep_thread = Thread.new do
      delay(sleep_at)
      if timeout == false
        elapsed_time = timer { sleeper.sleep }
      else
        elapsed_time = timer { sleeper.sleep(timeout) }
      end
    end
    wake_thread = Thread.new do
      if wake_at
        delay(wake_at)
        sleeper.wake
      end
    end
    sleep_thread.join
    wake_thread.join
    expect_time(elapsed_time, sleep_duration) # test duration of sleep
  end

  describe "::new" do

    context "when called with no arguments" do
      sleeper = nil
      it "should not raise error" do
        expect{ sleeper = QuackConcurrency::SafeSleeper.new }.not_to raise_error
      end
      it "should return a SafeSleeper" do
        expect(sleeper).to be_a(QuackConcurrency::SafeSleeper)
      end
    end
  
  end

  describe "#wake" do

    context "when called" do
      it "should not raise error" do
        sleeper = QuackConcurrency::SafeSleeper.new
        expect{ sleeper.wake }.not_to raise_error
      end
      it "should wake a sleeping thread immediately if #sleep has already been called" do
        sleep_test(sleep_duration: 1, wake_at: 1, sleep_at: 0)
      end
    end

    context "when called a second time" do
      it "should raise RuntimeError" do
        sleeper = QuackConcurrency::SafeSleeper.new
        sleeper.wake
        expect{ sleeper.wake }.to raise_error(RuntimeError)
      end
    end

  end

  describe "#sleep" do

    context "when called" do
      it "should return sleep duration as a Float" do
        sleeper = QuackConcurrency::SafeSleeper.new
        return_value = sleeper.sleep(1)
        expect(return_value).to be_a(Float)
        expect_time(return_value, 1)
      end
    end

    context "when called after #wake" do
      it "should return immediately" do
        sleep_test(sleep_duration: 0, wake_at: 0, sleep_at: 1)
      end
    end

    context "when called before #wake" do
      it "should return after #wake is called" do
        sleep_test(sleep_duration: 1, wake_at: 1, sleep_at: 0)
      end
      context "and #wake gets called before timeout is reached" do
        it "should return when #wake is called" do
          sleep_test(sleep_duration: 1, timeout: 2, wake_at: 1, sleep_at: 0)
        end
      end
      context "and #wake gets called after timeout is reached" do
        it "should return when timeout is reached" do
          sleep_test(sleep_duration: 1, timeout: 1, wake_at: 2, sleep_at: 0)
        end
      end
    end

    context "when called with timeout" do
      context "of nil" do
        it "should return only after #wake is called" do
          sleep_test(sleep_duration: 1, timeout: nil, wake_at: 1, sleep_at: 0)
        end
      end
      context "of Float::INFINITY" do
        it "should return only after #wake is called" do
          sleep_test(sleep_duration: 1, timeout: Float::INFINITY, wake_at: 1, sleep_at: 0)
        end
      end
      context "of non Numeric value" do
        it "should raise TypeError" do
          sleeper = QuackConcurrency::SafeSleeper.new
          expect{ sleeper.sleep('1') }.to raise_error(TypeError)
        end
      end
      context "of negative Numeric value" do
        it "should raise ArgumentError" do
          sleeper = QuackConcurrency::SafeSleeper.new
          expect{ sleeper.sleep(-1) }.to raise_error(ArgumentError)
        end
      end
      context "of Numeric value" do
        it "should return after given timeout" do
          sleep_test(sleep_duration: 1, timeout: 1, sleep_at: 0)
        end
      end
      context "and Thread#run is called before timeout is reached" do
        it "should return only after timeout is reached" do
          sleeper = QuackConcurrency::SafeSleeper.new
          elapsed_time = nil
          sleep_thread = Thread.new do
            elapsed_time = timer { sleeper.sleep(2) }
          end
          run_thread = Thread.new do
            delay 1
            sleep_thread.run
          end
          sleep_thread.join
          run_thread.join
          expect_time(elapsed_time, 2)
        end
      end
    end

    context "when called before Thread#run" do
      it "should return only after #wake is called" do
        sleeper = QuackConcurrency::SafeSleeper.new
        elapsed_time = nil
        sleep_thread = Thread.new do
          elapsed_time = timer { sleeper.sleep }
        end
        wake_thread = Thread.new do
          delay 2
          sleeper.wake
        end
        run_thread = Thread.new do
          delay 1
          sleep_thread.run
        end
        sleep_thread.join
        wake_thread.join
        run_thread.join
        expect_time(elapsed_time, 2)
      end
    end

    context "when called a second time" do
      it "should raise RuntimeError" do
        sleeper = QuackConcurrency::SafeSleeper.new
        sleeper.wake
        sleeper.sleep
        expect{ sleeper.sleep }.to raise_error(RuntimeError)
      end
    end

    context "when called with no way to wake up" do
      it "should raise fatal" do
        sleeper = QuackConcurrency::SafeSleeper.new
        FatalError = ObjectSpace.each_object(Class).find { |klass| klass < Exception && klass.inspect == 'fatal' }
        expect{ sleeper.sleep }.to raise_error(FatalError)
      end
    end

  end

end

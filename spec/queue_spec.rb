require 'quack_concurrency'

describe QuackConcurrency::Queue do

  describe "::new" do

    context "called with no arguments" do
      it "should return a Queue" do
        queue = QuackConcurrency::Queue.new
        expect(queue).to be_a(QuackConcurrency::Queue)
      end
    end

  end

  describe "#clear" do

    context "when called with some items in the Queue" do
      it "should remove all the items" do
        queue = QuackConcurrency::Queue.new
        queue.push(1)
        queue.push(2)
        queue.clear
        expect(queue.empty?).to be true
      end
    end

  end

  describe "#close" do

    context "when called" do
      it "should close the Queue" do
        queue = QuackConcurrency::Queue.new
        queue.close
        expect(queue.closed?).to be true
      end
      it "should resume all threads waiting on the Queue" do
        queue = QuackConcurrency::Queue.new
        thread1 = Thread.new { queue.pop }
        thread2 = Thread.new { queue.pop }
        sleep 1
        queue.close
        sleep 1
        expect(thread1.alive?).to be false
        expect(thread2.alive?).to be false
      end
    end

  end

  describe "#closed?" do

    context "when called on non closed Queue" do
      it "should return false" do
        queue = QuackConcurrency::Queue.new
        expect(queue.closed?).to be false
      end
    end

    context "when called on a closed Queue" do
      it "should return true" do
        queue = QuackConcurrency::Queue.new
        queue.close
        expect(queue.closed?).to be true
      end
    end

  end

  describe "#empty?" do

    context "when called on a empty Queue" do
      it "should return false" do
        queue = QuackConcurrency::Queue.new
        expect(queue.empty?).to be true
      end
    end

    context "when called on a non empty Queue" do
      it "should return false" do
        queue = QuackConcurrency::Queue.new
        queue.push(1)
        expect(queue.empty?).to be false
      end
    end

  end

  describe "#length" do

    context "when called on a empty Queue" do
      it "should return 1" do
        queue = QuackConcurrency::Queue.new
        expect(queue.length).to be 0
      end
    end

    context "when called on a Queue with one item" do
      it "should return 1" do
        queue = QuackConcurrency::Queue.new
        queue.push(1)
        expect(queue.length).to be 1
      end
    end

    context "when called on a Queue with two items" do
      it "should return 2" do
        queue = QuackConcurrency::Queue.new
        queue.push(1)
        queue.push(3)
        expect(queue.length).to be 2
      end
    end

  end

  describe "#num_waiting" do

    context "when called on a Queue with no thread waiting on it" do
      it "should return 0" do
        queue = QuackConcurrency::Queue.new
        expect(queue.num_waiting).to be 0
      end
    end

    context "when called on a Queue with a thread waiting on it" do
      it "should return 1" do
        queue = QuackConcurrency::Queue.new
        thread = Thread.new { queue.pop }
        sleep 1
        expect(queue.num_waiting).to be 1
        queue.close
        thread.join
      end
    end

    context "when called on a Queue with two threads waiting on it" do
      it "should return 2" do
        queue = QuackConcurrency::Queue.new
        thread1 = Thread.new { queue.pop }
        thread2 = Thread.new { queue.pop }
        sleep 1
        expect(queue.num_waiting).to be 2
        queue.close
        thread1.join
        thread2.join
      end
    end

  end

  describe "#pop" do

    context "when called on queue with one item" do
      it "should reutrn item" do
        queue = QuackConcurrency::Queue.new
        queue.push(1)
        expect(queue.pop).to eql 1
      end
    end

    context "when called before #close on empty queue" do
      it "should wait for #close then reutrn nil" do
        queue = QuackConcurrency::Queue.new
        value = :not_set
        thread = Thread.new { value = queue.pop }
        sleep 1
        expect(thread.alive?).to be true
        queue.close
        sleep 1
        expect(value).to be nil
      end
    end

    context "when called after #close on queue with one item" do
      it "should reutrn item immediately" do
        queue = QuackConcurrency::Queue.new
        queue.push(1)
        queue.close
        expect(queue.pop).to eql 1
      end
    end

    context "when called on empty Queue with non_block set to true" do
      it "should raise Error" do
        queue = QuackConcurrency::Queue.new
        expect{ queue.pop(true) }.to raise_error(ThreadError)
      end
    end

    context "when called after #close on empty queue" do
      it "should reutrn nil immediately" do
        queue = QuackConcurrency::Queue.new
        queue.close
        expect(queue.pop).to eql nil
      end
    end

    context "when called Queue with some items" do
      it "should reutrn oldest item in the Queue" do
        queue = QuackConcurrency::Queue.new
        queue.push(1)
        queue.push(3)
        queue.push(2)
        expect(queue.pop).to be 1
        expect(queue.pop).to be 3
        expect(queue.pop).to be 2
      end
    end

    context "when called with other threads waiting on Queue" do
      it "should reutrn items in the chronological order of calls to #pop" do
        queue = QuackConcurrency::Queue.new
        values = []
        Thread.new { sleep 1; values << queue.pop }
        Thread.new { sleep 2; values << queue.pop }
        Thread.new { sleep 3; values << queue.pop }
        sleep 4
        queue.push(1)
        queue.push(2)
        queue.push(3)
        sleep 1
        expect(values).to eql [1, 2, 3]
      end
    end

    context "when called before #push" do
      it "should wait until #push is called" do
        values = []
        queue = QuackConcurrency::Queue.new
        thread = Thread.new do
          queue.pop
          values << 1
          sleep 1
          queue.push
        end
        sleep 1
        queue.push
        queue.pop
        values << 2
        thread.join
        expect(values).to eql [1, 2]
      end
    end

  end

  describe "#push" do

    context "when called on non closed Queue" do
      it "should add items to Queue" do
        queue = QuackConcurrency::Queue.new
        queue.push(1)
        queue.push(3)
        expect(queue.length).to be 2
      end
    end

    context "when called on closed Queue" do
      it "should raise ClosedQueueError" do
        queue = QuackConcurrency::Queue.new
        queue.close
        expect{ queue.push(1) }.to raise_error(ClosedQueueError)
      end
    end

  end

end

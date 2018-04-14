require 'quack_concurrency'

RSpec.describe QuackConcurrency::Semaphore do
  
  describe "acquire" do
  
    context "when no permits are available" do
      it "should wait" do
        $test = []
        semaphore = QuackConcurrency::Semaphore.new(2)
        thread = Thread.new do
          sleep 1
          semaphore.acquire
          $test << 2
        end
        semaphore.acquire
        semaphore.acquire
        sleep 2
        $test << 1
        semaphore.release
        thread.join
        expect($test).to eql [1, 2]
      end
    end
    
  end
end

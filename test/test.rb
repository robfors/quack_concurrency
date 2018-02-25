require 'pry'

require_relative "../lib/quack_concurrency.rb"

Thread.abort_on_exception = true



puts 'test ConditionVariable'
m = Mutex.new
c = QuackConcurrency::ConditionVariable.new

t = []
3.times do
  t << Thread.new do
    m.synchronize do
      c.wait(m)
      print '.'
    end
  end
end

4.times do
  sleep 1
  c.signal
end

t.each(&:join)
puts


puts 'test ConditionVariable'
w = QuackConcurrency::Waiter.new

t = []
3.times do
  t << Thread.new do
    w.wait
    print '.'
  end
end

4.times do
  sleep 1
  w.resume
end

t.each(&:join)
puts


puts 'test ReentrantMutex'
r = QuackConcurrency::ReentrantMutex.new

t = []
3.times do
  t << Thread.new do
    r.lock
    r.lock
    r.lock
      sleep 1
    r.unlock
    r.unlock
    r.unlock
    begin
      r.unlock
    rescue
    else
      raise
    end
    print '.'
  end
end

t.each(&:join)
puts


puts 'test Semaphore'
s = QuackConcurrency::Semaphore.new(2)

t = []
4.times do
  t << Thread.new do
    s.acquire
    print '.'
    sleep 1
    s.release
  end
end

t.each(&:join)
puts

exit
binding.pry
binding.pry

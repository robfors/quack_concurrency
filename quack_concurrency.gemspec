Gem::Specification.new do |s|
  s.name        = 'quack_concurrency'
  s.version     = '0.0.0'
  s.date        = '2018-02-25'
  s.summary     = "Concurrency tools that accept duck types of core classes."
  s.description = "Offers concurrency tools that could also be found in the Concurrent Ruby project. However, all these tools will also accept duck types to allow core classes to behave as desired."
  s.authors     = ["Rob Fors"]
  s.email       = 'mail@robfors.com'  
  s.files       = [
    "lib/quack_concurrency.rb",
    "lib/quack_concurrency/condition_variable.rb",
    "lib/quack_concurrency/future.rb",
    "lib/quack_concurrency/reentrant_mutex.rb",
    "lib/quack_concurrency/semaphore.rb",
    "lib/quack_concurrency/waiter.rb"
  ]
  s.homepage    = 'https://github.com/robfors/quack_concurrency'
  s.license       = 'MIT'
end

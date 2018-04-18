Gem::Specification.new do |s|
  s.name        = 'quack_concurrency'
  s.version     = '0.3.0'
  s.date        = '2018-04-18'
  s.summary     = 'Concurrency tools that accept duck types of core classes.'
  s.description = "Offers concurrency tools that could also be found in the 'Concurrent Ruby'. However, all these tools will also accept core class ducktypes to build off of."
  s.authors     = 'Rob Fors'
  s.email       = 'mail@robfors.com'  
  s.files       = Dir.glob("{lib,spec}/**/*") + %w(LICENSE README.md)
  s.homepage    = 'https://github.com/robfors/quack_concurrency'
  s.license     = 'MIT'
end

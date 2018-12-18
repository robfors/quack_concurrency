Gem::Specification.new do |s|
  s.name        = 'quack_concurrency'
  s.version     = '0.5.4'
  s.date        = '2018-12-18'
  s.summary     = 'Concurrency tools that accept duck types of core classes.'
  s.description = "Offers concurrency tools that could also be found in the 'Concurrent Ruby'. However, all these tools will also accept core class duck types to build off of."
  s.authors     = 'Rob Fors'
  s.email       = 'mail@robfors.com'  
  s.files       = Dir.glob("{lib,spec}/**/*") + %w(LICENSE README.md Rakefile)
  s.homepage    = 'https://github.com/robfors/quack_concurrency'
  s.license     = 'MIT'
  s.add_runtime_dependency 'reentrant_mutex', '~>1.1'
end

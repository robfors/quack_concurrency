# Quack Concurrency
This Ruby Gem offers a few concurrency tools that could also be found in [*Concurrent Ruby*](https://github.com/ruby-concurrency/concurrent-ruby). However, all of *Quack Concurrency's* tools will accept duck types of Ruby's core classes to adjust the blocking behaviour of the tools. The tools include: `Future`, `Queue`, `ReentrantMutex`, `Semaphore` and `Waiter`. Each tool will accept a duck type for `ConditionVariable` and `Mutex`. If none are given `::ConditionVariable` and `::Mutex` are used by default. *TODO: list some projects useing it*.

# Install
`gem install quack_concurrency`

Then simply `require 'quack_concurrency'` in your project.

# Documentation
[![Yard Docs](https://img.shields.io/badge/yard-docs-blue.svg?style=for-the-badge)](http://www.rubydoc.info/gems/quack_concurrency)

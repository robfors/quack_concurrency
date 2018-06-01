require 'thread'
require 'reentrant_mutex'

require 'quack_concurrency/condition_variable'
require 'quack_concurrency/error'
require 'quack_concurrency/future'
require 'quack_concurrency/future/canceled'
require 'quack_concurrency/future/complete'
require 'quack_concurrency/mutex'
require 'quack_concurrency/queue'
require 'quack_concurrency/queue/error'
require 'quack_concurrency/reentrant_mutex'
require 'quack_concurrency/reentrant_mutex/error'
require 'quack_concurrency/uninterruptible_condition_variable'
require 'quack_concurrency/uninterruptible_sleeper'
require 'quack_concurrency/waiter'


# if you pass a duck type Hash to any of the concurrency tools it will force you to
#  supply all the required ducktypes, all or nothing, as it were
# this is to protect against forgetting to pass one of the duck types as this
#   would be a hard bug to solve otherwise


module QuackConcurrency
  
  ClosedQueueError = ::ClosedQueueError
  
end

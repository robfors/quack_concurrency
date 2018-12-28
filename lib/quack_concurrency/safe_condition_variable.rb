module QuackConcurrency

  # {SafeConditionVariable} is similar to {ConditionVariable}.
  #
  # The key distinction is that every call to {#wait} can only be resumed via
  # the {SafeConditionVariable} (not with +Thread#run+, +Thread#wakeup+, etc.)
  class SafeConditionVariable < ConditionVariable

    # #@!method wait
    # Puts this thread to sleep until another thread resumes it via this {SafeConditionVariable}.
    # @see ConditionVariable#wait

    private

    # Returns a waitable object for current thread.
    # @api private
    # @return [Waitable]
    def waitable_for_current_thread
      Waitable.new(self)
    end

  end
end

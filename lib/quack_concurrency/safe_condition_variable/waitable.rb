module QuackConcurrency
  class SafeConditionVariable

    # @see ConditionVariable::Waitable
    # Uses {SafeSleeper}s to ensure the thread can only be woken by this {SafeConditionVariable}.
    class Waitable < ConditionVariable::Waitable

      # Creates a new {Waitable}.
      # @return [Waitable]
      def initialize(condition_variable)
        super(condition_variable)
        @sleeper = SafeSleeper.new
      end

      # @!method wait
      # Can only be resumed via {#resume}.
      # @see ConditionVariable#wait

    end
  end
end

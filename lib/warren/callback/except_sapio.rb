# frozen_string_literal: true

module Warren
  module Callback
    # Provides Warren broadcasting helpers that exclude records mastered in Sapio.
    #
    # Including this module adds:
    #
    # - {ClassMethods#broadcast_with_warren_except_sapio} for configuring
    #   automatic broadcasts after commit.
    # - #broadcast_except_sapio for manually broadcasting records while applying
    #   the Sapio filter.
    #
    # Records are considered mastered in Sapio when they respond to
    # `mastered_in_sapio?` and the predicate returns `true`.
    module ExceptSapio
      # Class methods added to models including {ExceptSapio}.
      module ClassMethods
        # Configures the model to broadcast Warren messages after commit,
        # excluding records mastered in Sapio.
        #
        # @param handler [Warren::Handler] The Warren handler that receives
        #   broadcast messages.
        #
        # @return [void]
        def broadcast_with_warren_except_sapio(handler: Warren.handler)
          after_commit BroadcastWithWarrenExceptSapio.new(handler:)
        end
      end

      # Extends the including class with the class methods.
      #
      # @param base [Class] The class including this module.
      #
      # @return [void]
      def self.included(base)
        base.extend(ClassMethods)
      end

      # Broadcasts the record as a Warren full message unless it is mastered
      # in Sapio.
      #
      # Records that implement `mastered_in_sapio?` and return `true` are
      # ignored.
      #
      # @return [void]
      def broadcast_except_sapio
        return if respond_to?(:mastered_in_sapio?) && mastered_in_sapio?

        broadcast
      end
    end
  end
end

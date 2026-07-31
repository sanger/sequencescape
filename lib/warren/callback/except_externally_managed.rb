# frozen_string_literal: true

module Warren
  module Callback
    # Provides Warren broadcasting helpers that exclude records that are externally managed.
    #
    # Including this module adds:
    #
    # - {ClassMethods#broadcast_with_warren_except_externally_managed} for configuring
    #   automatic broadcasts after commit.
    # - #broadcast_except_externally_managed for manually broadcasting records while applying
    #   the externally managed filter.
    #
    # Records are considered externally managed when they respond to
    # `externally_managed?` and the predicate returns `true`.
    module ExceptExternallyManaged
      # Class methods added to models including {ExceptExternallyManaged}.
      module ClassMethods
        # Configures the model to broadcast Warren messages after commit,
        # excluding records that are externally managed.
        #
        # @param handler [Warren::Handler] The Warren handler that receives
        #   broadcast messages.
        #
        # @return [void]
        def broadcast_with_warren_except_externally_managed(handler: Warren.handler)
          after_commit BroadcastWithWarrenExceptExternallyManaged.new(handler:)
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

      # Broadcasts the record as a Warren full message unless it is externally managed.
      #
      # Records that implement `externally_managed?` and return `true` are
      # ignored.
      #
      # @return [void]
      def broadcast_except_externally_managed
        return if respond_to?(:externally_managed?) && externally_managed?

        broadcast
      end
    end
  end
end

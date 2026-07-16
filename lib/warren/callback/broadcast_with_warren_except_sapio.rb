# frozen_string_literal: true

module Warren
  module Callback
    # ActiveRecord callback which broadcasts Warren messages after a successful
    # transaction commit, except for records that are mastered in Sapio.
    #
    # Records that implement `mastered_in_sapio?` and return `true` are ignored.
    # All other records are broadcast using the behaviour inherited from
    # {Warren::Callback::BroadcastWithWarren}.
    #
    # @see Warren::Callback::BroadcastWithWarren
    class BroadcastWithWarrenExceptSapio < Warren::Callback::BroadcastWithWarren
      # Broadcasts a record unless it is mastered in Sapio.
      #
      # Records that implement `mastered_in_sapio?` and return `true` are
      # dropped. All other records are handled by the parent callback.
      #
      # @param record [ActiveRecord::Base] The committed record.
      #
      # @return [void]
      def after_commit(record)
        return if record.respond_to?(:mastered_in_sapio?) && record.mastered_in_sapio?

        super
      end
    end
  end
end

# frozen_string_literal: true

# AASM is a state machine provided by the gem aasm
module AASM
  # Provides extensions to allow for the transtion_to method.
  # This allows RESTful updates of state while still restricting permitted
  # transitions
  module Extensions
    # Attempts to transition the object to target_state by
    # detecting any valid state_machine transitions
    #
    # @param target_state [String] A string matching the state name to transition to
    def transition_to(target_state)
      aasm.fire!(suggested_transition_to(target_state))
    end

    private

    # Determines the most likely event that should be fired when transitioning between the two states.  If there is
    # only one option then that is what is returned, otherwise an exception is raised.
    def suggested_transition_to(target)
      valid_events =
        aasm
          .events(permitted: true)
          .select { |event| permit_automatic_transition?(event) && event.transitions_to_state?(target.to_sym) }

      return valid_events.first.name if valid_events.one?

      raise StandardError, "#{valid_events.length} permitted transitions from '#{state}' to '#{target}'"
    end

    def permit_automatic_transition?(event)
      !event.options[:manual_only?]
    end
  end
end

module StateMachineExtensions
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def states_for_select
      self.state_machine.states.map {|s| [s.human_name.titleize, s.name]}
    end
  end

  # Return an array suitable for HTML select elements with the states that are valid destinations
  # from the current state of this object.
  def states_for_select_from_current_state
    self.state_transitions.map {|t| [t.human_to_name.titleize, t.human_to_name]}
  end
end

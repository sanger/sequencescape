module AasmExtensions
 # Return an array suitable for HTML select elements with the states that are valid destinations
 # from the current state of this object.
 def aasm_states_for_select_from_current_state
   self.aasm_events_for_current_state.map do |event|
     self.class.aasm_events[event].transitions_from_state(self.state.to_sym).map(&:to)
   end.flatten.uniq.map do |state|
     self.class.aasm_states.select { |s| s.name == state }
   end.flatten.map(&:for_select)
 end
end

# frozen_string_literal: true

require_dependency 'request'
class Request
  # LongRead request
  class LongRead < CustomerRequest
    self.sequencing = true

    has_metadata as: Request do
      custom_attribute(:library_type, required: true, validator: true, selection: true)
    end

    validates :state, presence: true

    destroy_aasm

    def passed?
      state == 'passed'
    end

    # We've destroyed the stat_machine, but its validation remains.
    # Here we override it to allow custom states.
    def aasm_validate_states
      true
    end
  end
end

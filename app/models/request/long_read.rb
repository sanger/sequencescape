require_dependency 'request'
class Request
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

  end
end

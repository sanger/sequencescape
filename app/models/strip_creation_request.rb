# frozen_string_literal: true
# Used for customer requests to create strip tubes.
class StripCreationRequest < CustomerRequest
  def on_started
    super
    transfer_aliquots
  end
end

# frozen_string_literal: true

# Helpers for linking receptacles with transfer requests in specs.
module TransferRequestHelper
  # Creates a transfer request without keeping the aliquots it copies into the target,
  # so only the request linkage is added to the fixtures.
  def link_transfer(source, target)
    existing_ids = target.aliquots.pluck(:id)
    create(:transfer_request, asset: source, target_asset: target)
    target.aliquots.where.not(id: existing_ids).destroy_all
    target.aliquots.reset
  end
end

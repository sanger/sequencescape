# frozen_string_literal: true
module PipelinesHelper # rubocop:todo Style/Documentation
  def target_purpose_for(request)
    nrs = request.next_requests
    return nrs.first.request_type.acceptable_purposes.pluck(:name).join('|') unless nrs.empty?

    request.target_purpose.try(:name) || 'Not specified'
  end

  def fluidigm_target?(batch)
    batch.requests.where_is_a(CherrypickForFluidigmRequest).present?
  end
end

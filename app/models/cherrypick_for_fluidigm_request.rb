# frozen_string_literal: true
# Closely related to {CherrypickRequest} is additionally able to track which
# {PlatePurpose plate purpose} is going to be picked on to.
# Fluidigm is a genotyping process, which is represented in Sequencescape as
# a series of Cherrypicks.
class CherrypickForFluidigmRequest < CherrypickRequest
  has_metadata as: Request do
    belongs_to :target_purpose, class_name: 'Purpose'
    association(:target_purpose, :name)
  end

  delegate :target_purpose, to: :request_metadata
end

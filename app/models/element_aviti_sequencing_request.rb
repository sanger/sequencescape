# frozen_string_literal: true

class ElementAvitiSequencingRequest < SequencingRequest
  YES_OR_NO = %w[Yes No].freeze

  has_metadata as: Request do
    custom_attribute(:percent_element_phix_needed, integer: true, required: true, minimum: 0, maximum: 100)
    custom_attribute(:low_diversity, required: true, in: YES_OR_NO)
  end
end

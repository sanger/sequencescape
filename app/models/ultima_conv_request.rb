# frozen_string_literal: true

# Used for Illumina to Ultima library conversion.
class UltimaConvRequest < CustomerRequest
  has_metadata as: Request do
    custom_attribute(:application_type, validator: true, selection: true)
  end

  # Returns the default application type for Ultima conversion requests.
  # This is the first application type in the list of available application types.
  # @return [String] the default application type
  def self.default_application_type
    application_types.first
  end

  # Returns the list of available application types for Ultima conversion requests.
  # @return [Array<String>] the list of available application types
  def self.application_types
    UltimaApplication.pluck(:application_type).freeze
  end
end

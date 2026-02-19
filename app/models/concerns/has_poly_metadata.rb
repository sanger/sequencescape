# frozen_string_literal: true

module HasPolyMetadata
  extend ActiveSupport::Concern

  included do
    has_many :poly_metadata, as: :metadatable, dependent: :destroy, inverse_of: :metadatable
  end

  # Sets a PolyMetaDatum for the given key and value.
  # If value is present, it will create or update the PolyMetaDatum with the
  # given key and value, otherwise it will destroy the PolyMetaDatum with the
  # given key if that exists.
  # @param key [String] The key of the PolyMetaDatum to set.
  # @param value [String] The value of the PolyMetaDatum to set. If nil or empty, the PolyMetaDatum will be destroyed.
  # @return [void]
  def set_poly_metadata(key, value)
    record = poly_metadata.find_by(key:)
    if value.present?
      if record
        record.update!(value:)
      else
        poly_metadata.create!(key:, value:)
      end
    else
      record&.destroy!
    end
  end
end

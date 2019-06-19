# frozen_string_literal: true

# Associations related to {Labware} also included in {Asset} when not refactoring
module LabwareAssociations
  extend ActiveSupport::Concern

  included do
    has_many :barcodes, foreign_key: :asset_id, inverse_of: :asset, dependent: :destroy
  end
end

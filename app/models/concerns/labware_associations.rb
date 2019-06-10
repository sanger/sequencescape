# frozen_string_literal: true

# Associations related to {Labware} also included in {Asset} when not refactoring
module LabwareAssociations
  extend ActiveSupport::Concern

  included do
    has_many :barcodes, foreign_key: :asset_id, inverse_of: :asset, dependent: :destroy

    # We accept not only an individual barcode but also an array of them.
    scope :with_barcode, lambda { |*barcodes|
      db_barcodes = Barcode.extract_barcodes(barcodes)
      joins(:barcodes).where(barcodes: { barcode: db_barcodes }).distinct
    }

    # In contrast to with_barocde, filter_by_barcode only filters in the event
    # a parameter is supplied. eg. an empty string does not filter the data
    scope :filter_by_barcode, lambda { |*barcodes|
      db_barcodes = Barcode.extract_barcodes(barcodes)
      db_barcodes.blank? ? includes(:barcodes) : includes(:barcodes).where(barcodes: { barcode: db_barcodes }).distinct
    }

    scope :source_assets_from_machine_barcode, lambda { |destination_barcode|
      destination_asset = find_from_barcode(destination_barcode)
      if destination_asset
        source_asset_ids = destination_asset.parents.map(&:id)
        if source_asset_ids.empty?
          none
        else
          where(id: source_asset_ids)
        end
      else
        none
      end
    }
  end

  class_methods do
    def find_from_any_barcode(source_barcode)
      if source_barcode.blank?
        nil
      elsif /\A[0-9]{1,7}\z/.match?(source_barcode) # Just a number
        joins(:barcodes).where('barcodes.barcode LIKE "__?_"', source_barcode).first # rubocop:disable Rails/FindBy
      else
        find_by_barcode(source_barcode)
      end
    end

    def find_by_barcode(source_barcode)
      with_barcode(source_barcode).first
    end
    alias_method :find_from_barcode, :find_by_barcode
  end
end

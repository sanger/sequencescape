# frozen_string_literal: true

# Anything that has a barcode is considered barcodeable.
module Barcode::Barcodeable
  def self.included(base)
    base.class_eval do
      # Default prefix is the fallback prefix if no purpose is available.
      class_attribute :default_prefix
      before_create :set_default_prefix
      after_save :broadcast_barcode, if: :saved_change_to_barcode?
      delegate :prefix, to: :barcode_prefix
    end
  end

  def generate_barcode
    self.barcode = AssetBarcode.new_barcode
  end

  def broadcast_barcode
    Messenger.new(template: 'BarcodeIO', root: 'barcode', target: self).broadcast
  end

  def barcode_format
    'SangerEan13'
  end

  def set_default_prefix
    self.barcode_prefix ||= purpose&.barcode_prefix || BarcodePrefix.find_or_create_by(prefix: default_prefix)
  end
  private :set_default_prefix

  def sanger_human_barcode
    return nil if barcode.nil?
    prefix + barcode.to_s + Barcode.calculate_checksum(prefix, barcode)
  end

  def ean13_barcode
    return nil unless barcode.present? and prefix.present?
    Barcode.calculate_barcode(prefix, barcode.to_i).to_s
  end
  alias_method :machine_barcode, :ean13_barcode

  def role
    return nil if no_role?
    stock_plate.wells.first.requests.first.role
  end

  def no_role?
    case
    when stock_plate.nil?
      true
    when stock_plate.wells.first.nil?
      true
    when stock_plate.wells.first.requests.first.nil?
      true
    else
      false
    end
  end

  def external_identifier
    sanger_human_barcode
  end

  def printable_target
    self
  end

  def barcode!
    barcode
  end
end

# frozen_string_literal: true

# Anything that has a barcode is considered barcodeable.
module Barcode::Barcodeable
  def self.included(base)
    base.class_eval do
      # Default prefix is the fallback prefix if no purpose is available.
      class_attribute :default_prefix
      delegate :ean13_barcode, :machine_barcode, :human_barcode, to: :primary_barcode, allow_nil: true
    end
  end

  # Assumes presence of a method called `sanger_barcode=` on the class this is included within.
  # It's not implemented on TubeRack!
  def generate_barcode
    self.sanger_barcode = { prefix: default_prefix, number: AssetBarcode.new_barcode } unless primary_barcode
  end

  # ***** Read-only utility methods *****
  def any_barcode_matching?(other_barcode)
    barcodes.any? { |barcode| barcode =~ other_barcode }
  end

  def barcode_number
    primary_barcode&.number&.to_s
  end

  def barcode_format
    primary_barcode.format
  end

  def prefix
    primary_barcode&.barcode_prefix
  end

  def external_identifier
    human_barcode
  end

  def printable_target
    self
  end

  def sanger_barcode
    barcodes.detect(&:sanger_barcode?)
  end

  def primary_barcode
    # If we've already loaded the barcodes, then their order is indeterminate
    # rather than re-fetching them, we sort in Ruby.
    barcodes.loaded? ? barcodes.max_by(&:id) : barcodes.last
  end

  # ***** End read-only utility methods *****

  # ***** Getter and setter methods for foreign barcodes *****
  def infinium_barcode
    barcodes.detect(&:infinium?)&.machine_barcode
  end

  def infinium_barcode=(barcode)
    barcodes.infinium.first_or_initialize.barcode = barcode
  end

  def fluidigm_barcode
    barcodes.detect(&:fluidigm?)&.machine_barcode
  end

  def fluidigm_barcode=(barcode)
    barcodes.fluidigm.first_or_initialize.barcode = barcode
  end

  def cgap_barcode
    barcodes.detect(&:cgap?)&.machine_barcode
  end

  def cgap_barcode=(barcode)
    barcodes.cgap.first_or_initialize.barcode = barcode
  end

  def external_barcode
    barcodes.detect(&:external?)&.machine_barcode
  end

  def external_barcode=(barcode)
    barcodes.external.first_or_initialize.barcode = barcode
  end

  # Detects the format of the foreign barcode string passed in
  # Adds it to the list of barcodes, making it the primary (most recent) barcode
  # Throws exceptions if there are validation issues
  def foreign_barcode=(barcode)
    barcode_format = Barcode.matching_barcode_format(barcode)

    raise "Cannot determine format for foreign barcode #{barcode}" if barcode_format.blank?

    raise "Foreign Barcode: #{barcode} is already in use!" if Barcode.exists_for_format?(barcode_format, barcode)

    barcodes << Barcode.new(format: barcode_format, barcode: barcode)
  end

  # ***** End getter and setter methods for foreign barcodes *****

  # ***** Deprecated methods *****
  deprecate def barcode!
              barcode
            end,
            deprecator: ActiveSupport::Deprecation.new('14.53.0', 'Sequencescape')

  deprecate def barcode=(barcode)
              @barcode_number ||= barcode
              build_barcode_when_complete
            end,
            deprecator: ActiveSupport::Deprecation.new('14.53.0', 'Sequencescape')

  deprecate def barcode_prefix=(barcode_prefix)
              @barcode_prefix ||= barcode_prefix.prefix
              build_barcode_when_complete
            end,
            deprecator: ActiveSupport::Deprecation.new('14.53.0', 'Sequencescape')

  # ***** End deprecated methods *****

  private

  def build_barcode_when_complete
    return unless @barcode_number && @barcode_prefix

    self.primary_barcode = Barcode.build_sanger_ean13(prefix: @barcode_prefix, number: @barcode_number)

    # We've effectively modified the barcodes relationship, so lets reset it.
    # This probably indicates we should handle primary barcode ourself, and load
    # all barcodes whenever.
    barcodes.reset
  end

  def sanger_barcode_object
    @sanger_barcode_object ||= barcodes.find_or_initialize_by(format: :sanger_barcode).handler
  end
end

# frozen_string_literal: true

# Tube::AttributeUpdater provides a collection
# of small objects to convert a range of qc_results to legacy concentration and volume
module Tube::AttributeUpdater
  #
  # Updates the volume and concentration attributes of the provided tube according to the
  # information in the qc result. It automatically:
  # - Identifies the attribute to update
  # - Scales based on the units provided
  # - Generates any required events
  # @param tube [Tube] The tube to update
  # @param qc_result [QcResult] The QCResult to extract the information from
  #
  # @return [void]
  def self.update(tube, qc_result)
    HANDLER.fetch(qc_result.key.downcase, Base).new(tube, qc_result).update
  end

  # Base class for AttributeUpdaters, does not perform any action itself
  # but impliments the interface, allowing it to act as a Null Handler
  # in the event we don't recognize the QC type
  class Base
    attr_reader :tube, :qc_result

    class_attribute :target_units
    delegate :value, :units, :assay_type, :assay_version, to: :qc_result

    #
    # Create an attribute updater
    # @param tube [Well] The tube to update
    # @param qc_result [QcResult] The QCResult to extract the information from
    #
    def initialize(tube, qc_result)
      @tube = tube
      @qc_result = qc_result
    end

    #
    # The original value, complete with units
    #
    # @return [Unit] A combination of the the value and its units.
    def original_value
      @original_value ||= Unit.new(value, units)
    end

    # The value which will get recorded in the database
    def target_value
      original_value.convert_to(target_units).scalar
    end

    # Used in subclasses to perform the relevant update actions on Wells
    def update
      # The Base class performs no actions
    end
  end

  # Updated the tube volume in ul
  class Volume < Base
    self.target_units = 'ul'

    def update
      tube.update!(volume: target_value)
      tube.save
    end
  end

  # Updates concentration or molarity
  class Molarity < Base
    def molarity?
      original_value.compatible?('nmol/l')
    end

    def molarity
      original_value.convert_to('nmol/l').scalar
    end

    def update
      tube.update!(concentration: molarity) if molarity?
    end
  end

  # Hash mapping potential QCResult#key to handlers
  HANDLER = {
    'volume' => Volume,
    'concentration' => Molarity,
    'molarity' => Molarity
  }.freeze
end

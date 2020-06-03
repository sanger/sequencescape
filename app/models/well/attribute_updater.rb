# frozen_string_literal: true

# Well::AttributeUpdater provides a collection
# of small objects to convert a range of qc_results to legacy well_attributes
module Well::AttributeUpdater
  #
  # Updates the well attributes of the provided well according to the
  # information in the qc result. It automatically:
  # - Identifies the attribute to update
  # - Scales based on the units provided
  # - Generates any required events
  # @param well [Well] The well to update
  # @param qc_result [QcResult] The QCResult to extract the information from
  #
  # @return [void]
  def self.update(well, qc_result)
    HANDLER.fetch(qc_result.key.downcase, Base).new(well, qc_result).update
  end

  # Base class for AttributeUpdaters, does not perform any action itself
  # but impliments the interface, allowing it to act as a Null Handler
  # in the event we don't recognize the QC type
  class Base
    attr_reader :well, :qc_result

    class_attribute :target_units
    delegate :value, :units, :assay_type, :assay_version, to: :qc_result

    #
    # Create an attribute updater
    # @param well [Well] The well to update
    # @param qc_result [QcResult] The QCResult to extract the information from
    #
    def initialize(well, qc_result)
      @well = well
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

    # Identifier of the assay for logging
    def resource
      "#{assay_type} #{assay_version}"
    end
  end

  # Updated the well volume in ul
  class Volume < Base
    self.target_units = 'ul'

    def update
      well.measured_volume = target_value
      well.save
    end
  end

  # Update the RIN. Note: Rin is actually unitless, the specified units here
  # maintains compatibility with other QC systems.
  class Rin < Base
    self.target_units = 'RIN'

    def update
      well.well_attribute.update!(rin: target_value)
    end
  end

  # Updated the snp count (sequenom count) volume in ul
  class SnpCount < Base
    # We don't adjust snp count as its just a raw value
    def target_value
      value
    end

    def update
      well.update_sequenom_count!(target_value, resource)
    end
  end

  # Update the gender markers and generate events
  class GenderMarkers < Base
    def target_value
      value.each_char.map { |c| c == 'U' ? 'Unknown' : c }
    end

    def update
      well.update_gender_markers!(target_value, resource)
    end
  end

  # Updates concentration or molarity
  class Concentration < Base
    def concentration?
      original_value.compatible?('ng/ul')
    end

    def molarity?
      original_value.compatible?('nmol/l')
    end

    def concentration
      original_value.convert_to('ng/ul').scalar
    end

    def molarity
      original_value.convert_to('nmol/l').scalar
    end

    def update
      well.set_concentration(concentration) if concentration?
      well.set_molarity(molarity) if molarity?
    end
  end

  # Hash mapping potential QCResult#key to handlers
  HANDLER = {
    'volume' => Volume,
    'snp_count' => SnpCount,
    'loci_passed' => SnpCount,
    'gender_markers' => GenderMarkers,
    'concentration' => Concentration,
    'molarity' => Concentration,
    'rin' => Rin
  }.freeze
end

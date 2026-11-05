# frozen_string_literal: true

# Records a sample's volume and concentration as customer-supplied QC results
# on its new well or tube. The volume's QC result is the one the sample
# manifest's volume field makes (SequencescapeExcel::SpecialisedField::Volume);
# a manifest keeps concentration in the sample's metadata only, but the lab
# uses both, and pipelines read them from QC results. A QC result sets its
# receptacle's value: a well's measured volume and concentration, a tube's
# volume. A tube's own concentration is molar, so a tube keeps ours in the QC
# result only.
#
# A volume or concentration describes what is in the receptacle, so only a
# receptacle that holds that one sample gets them; in a pool or an MX tube,
# each sample's values stay in its metadata only. Sample manifests do the
# same: their kinds that put several samples in a receptacle have no volume
# or concentration column.
#
# The QC results of one reception share a QC assay named after its
# operation, as a manifest's share one named after the manifest.
class ApiOperation::Reception::Creation::QcFactory
  # The units of each sample field recorded as a QC result of the same key
  UNITS = { 'volume' => 'ul', 'concentration' => 'ng/ul' }.freeze

  # @param labware [Hash{ApiOperation::Reception::Payload::PayloadLabware =>
  #   Labware}] the new labware, by its payload labware
  # @param api_operation [ApiOperation] the operation being received
  def initialize(labware, api_operation)
    @labware = labware
    @api_operation = api_operation
  end

  # Creates the QC results.
  #
  # @return [void]
  def call
    @labware.each do |payload_labware, labware|
      payload_labware.receptacles.each do |payload_receptacle|
        values = sole_sample_values(payload_receptacle)
        next if values.empty?

        well_or_tube = receptacle(labware, payload_receptacle)
        values.each { |key, value| create_qc_result(well_or_tube, key, value) }
      end
    end
  end

  private

  # The volume and concentration of the receptacle's sample, by key, when it
  # holds only that sample
  def sole_sample_values(payload_receptacle)
    samples = payload_receptacle.samples
    return {} unless samples.one?

    samples.first.fields.slice(*UNITS.keys).compact
  end

  def create_qc_result(receptacle, key, value)
    receptacle.qc_results.create!(
      qc_assay: qc_assay, key: key, value: value.to_f, units: UNITS[key],
      assay_type: 'customer_supplied', assay_version: 'v0.0'
    )
  end

  def qc_assay
    @qc_assay ||= QcAssay.find_or_create_by!(
      lot_number: "api_operation_id:#{@api_operation.id}"
    )
  end

  # The well at the payload's position, or the tube's receptacle, as
  # AliquotFactory finds it
  def receptacle(labware, payload_receptacle)
    return labware.receptacle if payload_receptacle.position.nil?

    @wells ||= {}
    @wells[labware] ||= labware.wells.includes(:map).index_by(&:map_description)
    @wells[labware].fetch(payload_receptacle.position)
  end
end

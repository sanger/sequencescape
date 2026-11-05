# frozen_string_literal: true

# Records a sample's volume as a customer-supplied QC result on its new well
# or tube, as the sample manifest's volume field does
# (SequencescapeExcel::SpecialisedField::Volume). The QC result sets the
# receptacle's volume (a well's measured volume, a tube's volume), which
# pipelines read.
#
# A volume describes what is in the receptacle, so only a receptacle that
# holds that one sample gets one; in a pool or an MX tube, each sample's
# volume stays in its metadata only. Sample manifests do the same: their
# kinds that put several samples in a receptacle have no volume column.
#
# The QC results of one reception share a QC assay named after its
# operation, as a manifest's share one named after the manifest.
class ApiOperation::Reception::Creation::VolumeQcFactory
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
        volume = sole_sample_volume(payload_receptacle)
        next if volume.nil?

        create_qc_result(receptacle(labware, payload_receptacle), volume)
      end
    end
  end

  private

  # The volume of the receptacle's sample, when it holds only that one
  def sole_sample_volume(payload_receptacle)
    samples = payload_receptacle.samples
    samples.first.fields['volume'] if samples.one?
  end

  def create_qc_result(receptacle, volume)
    receptacle.qc_results.create!(
      qc_assay: qc_assay, key: 'volume', value: volume.to_f, units: 'ul',
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

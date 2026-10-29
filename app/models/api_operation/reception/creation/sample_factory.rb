# frozen_string_literal: true

# Creates the payload's new samples, once for each UUID, so a sample in more
# than one receptacle is one sample. Each keeps the payload's UUID and is
# externally managed, so it isn't sent to the MLWH.
class ApiOperation::Reception::Creation::SampleFactory
  # @param new_labware [Array<ApiOperation::Reception::Payload::
  #   PayloadLabware>] the payload labware Sequencescape doesn't have
  def initialize(new_labware)
    @new_labware = new_labware
  end

  # Creates the samples in the labware.
  #
  # @return [Hash{String => Sample}] the new samples, by UUID
  def call
    payload_samples.to_h { [it.uuid, create_sample(it)] }
  end

  private

  # The samples to create: one for each UUID
  def payload_samples
    @payload_samples ||=
      @new_labware.flat_map(&:receptacles).flat_map(&:samples).uniq(&:uuid)
  end

  # One save writes the sample, its metadata, its UUID and its study link.
  # The sample keeps the payload's UUID: without lazy_uuid_generation, a new
  # one would replace it after the sample is created.
  def create_sample(payload_sample)
    sample = Sample.new(sample_attributes(payload_sample))
    sample.lazy_uuid_generation = true
    sample.uuid_object = Uuid.new(external_id: payload_sample.uuid)
    sample.studies << studies.fetch(payload_sample.study_uuid)
    sample.save!
    sample
  end

  # As the sample manifest's specialised fields set them; fields not given
  # keep their defaults (no priority, not a control)
  def sample_attributes(payload_sample)
    fields = payload_sample.fields
    control_type = fields['control_type'] || fields['bioscan_control_type']
    {
      name: payload_sample.sanger_sample_id,
      sanger_sample_id: payload_sample.sanger_sample_id,
      externally_managed: true,
      priority: fields['priority'],
      control: control_type.present?,
      control_type: control_type,
      sample_metadata_attributes: metadata_attributes(payload_sample)
    }.compact
  end

  # bioscan_supplier_name replaces supplier_sample_name, as in the manifest;
  # without a reference genome the sample gets the blank one
  def metadata_attributes(payload_sample)
    fields = payload_sample.fields
    {
      supplier_name: fields['bioscan_supplier_name'] ||
        payload_sample.supplier_sample_name,
      donor_id: fields['donor_id'],
      reference_genome: reference_genomes[fields['reference_genome']&.downcase]
    }.compact
  end

  # The samples' studies by UUID (both in lower case), looked up once
  def studies
    @studies ||=
      Study.with_uuid(payload_samples.map(&:study_uuid).uniq)
        .includes(:uuid_object).index_by(&:uuid)
  end

  # The reference genomes the samples name, by name in lower case, looked up
  # once
  def reference_genomes
    @reference_genomes ||= begin
      names = payload_samples.filter_map { it.fields['reference_genome'] }
      ReferenceGenome.where(name: names).index_by { it.name.downcase }
    end
  end
end

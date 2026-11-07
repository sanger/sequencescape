# frozen_string_literal: true

# Creates the payload's new samples, once for each UUID, so a sample in more
# than one receptacle is one sample. Each keeps the payload's UUID and is
# externally managed, so it isn't sent to the MLWH.
class ApiOperation::Reception::Creation::SampleFactory
  # @param new_labware [Array<ApiOperation::Reception::Payload::
  #   PayloadLabware>] the payload labware Sequencescape doesn't have
  # @param studies [Hash{String => Study}] the samples' studies, by UUID
  def initialize(new_labware, studies)
    @new_labware = new_labware
    @studies = studies
  end

  # Creates the samples in the labware. Accessioning is paused while they
  # are saved, as sample manifest uploads pause it, so saving a sample
  # doesn't accession it: Sequencescape doesn't accession Sapio's samples.
  #
  # @return [Hash{String => Sample}] the new samples, by UUID
  def call
    Sample::Current.set(temporary_accessioning_pause: true) do
      payload_samples.to_h { [it.uuid, create_sample(it)] }
    end
  end

  private

  # The samples to create: one for each UUID
  def payload_samples
    @payload_samples ||=
      @new_labware.flat_map(&:receptacles).flat_map(&:samples).uniq(&:uuid)
  end

  # Saves the sample, with its metadata and its UUID, then links it to its
  # study. Linking the saved sample saves only the link; linked before the
  # save, the study would be validated again with each sample. The sample
  # keeps the payload's UUID: without lazy_uuid_generation, a new one would
  # replace it after the sample is created.
  def create_sample(payload_sample)
    sample = Sample.new(sample_attributes(payload_sample))
    sample.lazy_uuid_generation = true
    sample.uuid_object = Uuid.new(external_id: payload_sample.uuid)
    sample.save!
    sample.studies << @studies.fetch(payload_sample.study_uuid)
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
  # without a reference genome the sample gets the blank one. Volume and
  # concentration only for a sample with one entry (one_entry?); they are
  # text columns, so a number is kept as Ruby writes it (12.5, 10, or 10.0
  # for 10.0); genome size is a whole number.
  def metadata_attributes(payload_sample)
    fields = payload_sample.fields
    measured = one_entry?(payload_sample) ? fields : {}
    {
      supplier_name: fields['bioscan_supplier_name'] ||
        payload_sample.supplier_sample_name,
      donor_id: fields['donor_id'],
      reference_genome: reference_genomes[fields['reference_genome']&.downcase],
      volume: measured['volume'],
      concentration: measured['concentration'],
      genome_size: fields['genome_size']
    }.compact
  end

  # Whether the sample has only one entry in the request. A sample in more
  # than one receptacle gets no volume or concentration: its entries may give
  # different values, and which is the sample's isn't known. Each receptacle
  # that holds only that sample gets its own as QC results (QcFactory).
  def one_entry?(payload_sample)
    @entry_counts ||= @new_labware.flat_map(&:receptacles)
      .flat_map(&:samples).map(&:uuid).tally
    @entry_counts[payload_sample.uuid] == 1
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

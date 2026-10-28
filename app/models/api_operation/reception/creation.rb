# frozen_string_literal: true

# Creates the payload's new labware, with its samples, once reconciliation
# and validation have found nothing wrong. ApiOperation::Reception runs it
# inside the coordinator's transaction, so what it creates commits with the
# operation's status, or not at all. Records are saved with save!, so their
# models' validations and callbacks run; a record its model rejects raises,
# which rolls everything back.
#
# Labware gets a stock purpose (Y26-283 acceptance criteria), chosen by
# whether its samples have tags, which mark a library:
# - a plate: Stock Plate, or Library Stock Plate when its samples have tags
# - a tube: Standard sample, Standard library when one of its samples has
#   tags, or Standard MX when more than one has
# Its only barcode is the one it arrived with, in the external format.
#
# Samples are created once for each UUID, so a sample in more than one
# receptacle is one sample. Each keeps the payload's UUID and is externally
# managed, so it isn't sent to the MLWH.
class ApiOperation::Reception::Creation
  # The payload fields of the tag schemes; a sample with any of them has tags
  TAG_FIELDS = ApiOperation::Reception::Validation::SampleCheck::TAG_FIELDS

  # The purpose of a new plate whose samples have tags
  LIBRARY_PLATE_PURPOSE = 'Library Stock Plate'

  # @param new_labware [Array<ApiOperation::Reception::Payload::
  #   PayloadLabware>] the payload labware Sequencescape doesn't have
  def initialize(new_labware)
    @new_labware = new_labware
  end

  # Creates the new labware and its samples.
  #
  # @return [void]
  def call
    @new_labware.each { create_labware(it) }
    payload_samples.each { create_sample(it) }
  end

  private

  def create_labware(payload_labware)
    if payload_labware.type == 'tube'
      create_tube(payload_labware)
    else
      create_plate(payload_labware)
    end
  end

  # As PlatePurpose#create! does, without its Sanger barcode from Baracoda
  def create_plate(payload_labware)
    purpose = plate_purpose(payload_labware)
    plate = purpose.target_class.new(purpose: purpose, size: purpose.size)
    build_barcode(plate, payload_labware)
    plate.save!
    plate.wells.construct!
    plate
  end

  def create_tube(payload_labware)
    purpose = tube_purpose(payload_labware)
    tube = purpose.target_class.new(purpose:)
    build_barcode(tube, payload_labware)
    tube.save!
    tube
  end

  # Gives the labware the barcode it arrived with before it is saved, so that
  # is its only barcode: a plate is named after it, and a sample tube doesn't
  # make itself a Sanger barcode
  def build_barcode(labware, payload_labware)
    labware.barcodes.build(format: :external, barcode: payload_labware.barcode)
  end

  def plate_purpose(payload_labware)
    if tagged_count(payload_labware).zero?
      purpose(:stock_plate) { PlatePurpose.stock_plate_purpose }
    else
      purpose(:library_plate) do
        PlatePurpose.find_by!(name: LIBRARY_PLATE_PURPOSE)
      end
    end
  end

  def tube_purpose(payload_labware)
    case tagged_count(payload_labware)
    when 0 then purpose(:sample_tube) { Tube::Purpose.standard_sample_tube }
    when 1 then purpose(:library_tube) { Tube::Purpose.standard_library_tube }
    else purpose(:mx_tube) { Tube::Purpose.standard_mx_tube }
    end
  end

  # Looks each purpose up once
  def purpose(key)
    @purposes ||= {}
    @purposes[key] ||= yield
  end

  # How many of the labware's samples have tags
  def tagged_count(payload_labware)
    payload_labware.receptacles.flat_map(&:samples).count do |payload_sample|
      payload_sample.fields.keys.intersect?(TAG_FIELDS)
    end
  end

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
    sample.studies << studies.fetch(payload_sample.study_uuid.downcase)
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

  # The samples' studies by UUID, looked up once
  def studies
    @studies ||=
      Study.with_uuid(payload_samples.map(&:study_uuid).uniq)
        .includes(:uuid_object).index_by { it.uuid.downcase }
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

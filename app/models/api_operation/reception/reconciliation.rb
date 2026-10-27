# frozen_string_literal: true

# Sorts the payload's labware into labware Sequencescape already has, which
# is matched and left unchanged (ADR 074), and new labware, which reception
# creates. A payload labware is known if its barcode is any of a
# Sequencescape labware's barcodes, even if nothing else about it matches.
#
# A known labware must also be the same: the same type (plate or tube), the
# same number of wells, and in each well (or the tube) the same number of
# samples with the same supplier sample names. A well the payload doesn't
# list counts as empty. If anything differs, the labware is a conflict, and
# the operation fails.
class ApiOperation::Reception::Reconciliation
  # The Sequencescape class and plate size for each payload labware type
  TYPES = {
    'plate96' => [Plate, 96],
    'plate384' => [Plate, 384],
    'tube' => [Tube, nil]
  }.freeze

  # Loaded with the known labware, to compare its contents
  CONTENTS = { receptacles: [:map, { aliquots: { sample: :sample_metadata } }] }
    .freeze

  # @param payload_labware [Array<ApiOperation::Reception::Payload::
  #   PayloadLabware>] the payload's labware
  def initialize(payload_labware)
    @payload_labware = payload_labware
  end

  # @return [Hash{PayloadLabware => Labware}] the payload labware that
  #   Sequencescape already has, with its Sequencescape labware
  def matched
    @matched ||=
      @payload_labware.each_with_object({}) do |payload_labware, matched|
        labware = find_labware(payload_labware)
        matched[payload_labware] = labware if labware
      end
  end

  # @return [Array<PayloadLabware>] the payload labware that Sequencescape
  #   doesn't have, in payload order
  def new_labware
    @payload_labware - matched.keys
  end

  # @return [Array<Hash>] the conflicts: known labware that isn't the same,
  #   each with a :pointer and a :detail
  def errors
    @errors ||=
      begin
        preload_contents
        matched.flat_map do |payload_labware, labware|
          conflicts(payload_labware, labware)
        end
      end
  end

  private

  # The Sequencescape labware with the payload labware's barcode, in any of
  # the forms it may be stored in, if there is one.
  def find_labware(payload_labware)
    Barcode.extract_barcode(payload_labware.barcode)
      .lazy.filter_map { |barcode| labware_by_barcode[barcode] }.first
  end

  # The Sequencescape labware with any of the payload's barcodes, found in
  # one query, by each of its barcodes.
  def labware_by_barcode
    @labware_by_barcode ||=
      ::Labware.with_barcode(*@payload_labware.map(&:barcode))
        .preload(:barcodes)
        .each_with_object({}) do |labware, index|
          labware.barcodes.each { |barcode| index[barcode.barcode] = labware }
        end
  end

  def preload_contents
    ActiveRecord::Associations::Preloader
      .new(records: matched.values.uniq, associations: CONTENTS).call
  end

  def conflicts(payload_labware, labware)
    type_conflicts(payload_labware, labware).presence ||
      content_conflicts(payload_labware, labware)
  end

  def type_conflicts(payload_labware, labware)
    type, size = TYPES.fetch(payload_labware.type)
    return [] if labware.is_a?(type) && (size.nil? || labware.size == size)

    [{ pointer: "#{payload_labware.pointer}/type",
       detail: "#{payload_labware.barcode} is #{describe(labware)} in " \
               "Sequencescape, not #{describe_type(payload_labware.type)}" }]
  end

  # Compares the supplier sample names in each position that either the
  # payload or Sequencescape has
  def content_conflicts(payload_labware, labware)
    names = names_by_position(labware)
    receptacles = payload_labware.receptacles.index_by(&:position)
    (names.keys | receptacles.keys).filter_map do |position|
      receptacle_conflict(payload_labware, position, receptacles[position],
                          names.fetch(position, []))
    end
  end

  # The supplier sample names in each of the labware's receptacles that hold
  # samples: by well for a plate, under nil for a tube
  def names_by_position(labware)
    labware.receptacles.each_with_object({}) do |receptacle, names|
      next if receptacle.aliquots.empty?

      position = labware.is_a?(Plate) ? receptacle.map.description : nil
      names[position] =
        receptacle.aliquots.map { it.sample.sample_metadata.supplier_name }
    end
  end

  # A receptacle the payload doesn't list has no samples, and its problem is
  # reported against the labware
  def receptacle_conflict(payload_labware, position, receptacle, names)
    payload_names = supplier_sample_names(receptacle)
    return if payload_names.tally == names.tally

    { pointer: receptacle ? receptacle.pointer : payload_labware.pointer,
      detail: "#{place(position)} of #{payload_labware.barcode} " \
              "#{difference(payload_names, names)}" }
  end

  def supplier_sample_names(receptacle)
    return [] unless receptacle

    receptacle.samples.map(&:supplier_sample_name)
  end

  def place(position)
    position ? "well #{position}" : 'the tube'
  end

  def difference(payload_names, names)
    if payload_names.size == names.size
      'has different supplier sample names in Sequencescape'
    else
      "has #{samples(names.size)} in Sequencescape, " \
        "not #{samples(payload_names.size)}"
    end
  end

  def samples(count)
    "#{count} #{'sample'.pluralize(count)}"
  end

  def describe(labware)
    return "a #{labware.size}-well plate" if labware.is_a?(Plate)
    return 'a tube' if labware.is_a?(Tube)

    "a #{labware.class.name.underscore.humanize(capitalize: false)}"
  end

  def describe_type(type)
    plate_size = TYPES.fetch(type).last
    plate_size ? "a #{plate_size}-well plate" : 'a tube'
  end
end

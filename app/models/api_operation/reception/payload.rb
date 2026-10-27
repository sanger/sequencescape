# frozen_string_literal: true

# The labware section of an operation's payload, as labware, receptacles and
# samples. Each carries its JSON pointer into the payload, so an error can say
# where its problem is. The payload matched the schema before it was stored,
# so its structure isn't checked again here; a missing required key raises.
# The work_order section is not read.
class ApiOperation::Reception::Payload
  # The keys every sample has; its other keys are optional fields
  SAMPLE_KEYS = %w[uuid study_uuid sanger_sample_id supplier_sample_name].freeze

  # A plate or tube
  Labware = Data.define(:uuid, :barcode, :type, :receptacles, :pointer)

  # A well of a plate, or the inside of a tube (position nil)
  Receptacle = Data.define(:position, :uuid, :samples, :pointer)

  # A sample in a receptacle. fields holds its optional keys, such as tags,
  # by their payload names.
  Sample =
    Data.define(:uuid, :study_uuid, :sanger_sample_id, :supplier_sample_name,
                :fields, :pointer)

  # @param payload [String] the operation's payload, as received
  def initialize(payload)
    @payload = JSON.parse(payload)
  end

  # @return [Array<Labware>] the labware, in payload order
  def labware
    @labware ||=
      map_with_pointer(@payload.fetch('labware'), '/labware') do |item, pointer|
        build_labware(item, pointer)
      end
  end

  private

  # Maps each item, with its JSON pointer: the base, then its index.
  def map_with_pointer(items, base)
    items.each_with_index.map { |item, index| yield item, "#{base}/#{index}" }
  end

  def build_labware(labware, pointer)
    receptacles =
      map_with_pointer(labware.fetch('receptacles'),
                       "#{pointer}/receptacles") do |item, item_pointer|
        build_receptacle(item, item_pointer)
      end
    Labware.new(uuid: labware.fetch('uuid'), barcode: labware.fetch('barcode'),
                type: labware.fetch('type'), receptacles: receptacles,
                pointer: pointer)
  end

  def build_receptacle(receptacle, pointer)
    samples =
      map_with_pointer(receptacle.fetch('samples'),
                       "#{pointer}/samples") do |item, item_pointer|
        build_sample(item, item_pointer)
      end
    Receptacle.new(position: receptacle.fetch('position'),
                   uuid: receptacle.fetch('uuid'), samples: samples,
                   pointer: pointer)
  end

  def build_sample(sample, pointer)
    Sample.new(**SAMPLE_KEYS.to_h { |key| [key.to_sym, sample.fetch(key)] },
               fields: sample.except(*SAMPLE_KEYS), pointer: pointer)
  end
end

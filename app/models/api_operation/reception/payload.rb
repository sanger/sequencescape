# frozen_string_literal: true

# The labware section of an operation's payload, as labware, receptacles and
# samples. Each carries its JSON pointer into the payload, so an error can say
# where its problem is. The payload matched the schema before it was stored,
# so its structure isn't checked again here; a missing required key raises.
# The work_order section is not read.
#
# The classes are named Payload... so they can't be mistaken for the
# Labware, Receptacle and Sample models.
class ApiOperation::Reception::Payload
  # The keys every sample has; its other keys are optional fields
  SAMPLE_KEYS = %w[uuid study_uuid sanger_sample_id supplier_sample_name].freeze

  # A plate or tube in the payload
  PayloadLabware =
    Data.define(:uuid, :barcode, :type, :receptacles, :pointer)

  # A well of a plate, or the inside of a tube (position nil), in the payload
  PayloadReceptacle = Data.define(:position, :uuid, :samples, :pointer)

  # A sample in the payload. fields holds its optional keys, such as tags,
  # by their payload names. Its uuid is in lower case (see #build_sample).
  PayloadSample =
    Data.define(:uuid, :study_uuid, :sanger_sample_id, :supplier_sample_name,
                :fields, :pointer)

  # @param payload [String] the operation's payload, as received
  def initialize(payload)
    @payload = JSON.parse(payload)
  end

  # @return [Array<PayloadLabware>] the labware, in payload order
  def labware
    @labware ||=
      map_with_pointer(@payload.fetch('labware'), '/labware') do |json, pointer|
        build_labware(json, pointer)
      end
  end

  private

  # Maps each item, with its JSON pointer: the base, then its index.
  def map_with_pointer(items, base)
    items.each_with_index.map { |item, index| yield item, "#{base}/#{index}" }
  end

  def build_labware(json, pointer)
    receptacles =
      map_with_pointer(json.fetch('receptacles'),
                       "#{pointer}/receptacles") do |item, item_pointer|
        build_receptacle(item, item_pointer)
      end
    PayloadLabware.new(uuid: json.fetch('uuid'), barcode: json.fetch('barcode'),
                       type: json.fetch('type'), receptacles: receptacles,
                       pointer: pointer)
  end

  def build_receptacle(json, pointer)
    samples =
      map_with_pointer(json.fetch('samples'),
                       "#{pointer}/samples") do |item, item_pointer|
        build_sample(item, item_pointer)
      end
    PayloadReceptacle.new(position: json.fetch('position'),
                          uuid: json.fetch('uuid'), samples: samples,
                          pointer: pointer)
  end

  # The sample's UUID is lowercased: Sequencescape stores UUIDs in lower case
  # (Uuid accepts no other), and RFC 4122 says they are case insensitive on
  # input. The checks and creation then see one form of each UUID.
  def build_sample(json, pointer)
    keys = SAMPLE_KEYS.to_h { |key| [key.to_sym, json.fetch(key)] }
    keys[:uuid] = keys[:uuid].downcase
    PayloadSample.new(**keys, fields: json.except(*SAMPLE_KEYS),
                              pointer: pointer)
  end
end

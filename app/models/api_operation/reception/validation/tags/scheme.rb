# frozen_string_literal: true

# A way a payload sample can give its tags, by a set of fields (FIELDS),
# named NAME in messages. A scheme is given the samples that give their tags
# its way, and the Input, and checks them. Schemes without rules of their own
# find no problems.
class ApiOperation::Reception::Validation::Tags::Scheme
  # @param samples [Array<ApiOperation::Reception::Payload::PayloadSample>]
  #   the samples that give their tags this way
  # @param input [ApiOperation::Reception::Validation::Input] what the
  #   validation looks at, for rules about a sample's receptacle
  def initialize(samples, input)
    @samples = samples
    @input = input
  end

  # @return [Array<Hash>] the problems, each with a :pointer and a :detail
  def errors
    []
  end

  private

  attr_reader :samples, :input

  # The samples that give both fields of a pair, and an error for each
  # sample that gives only one of them
  #
  # @return [Array(Array<PayloadSample>, Array<Hash>)] the samples and the
  #   errors
  def split_pair(first_field, second_field)
    pair = [first_field, second_field]
    giving = samples.select { pair.intersect?(it.fields.keys) }
    complete, partial = giving.partition { (pair - it.fields.keys).empty? }
    [complete, partial.map { partial_pair_error(it, pair) }]
  end

  # The error for a sample that gives only one field of the pair
  def partial_pair_error(sample, pair)
    given, missing = sample.fields.key?(pair.first) ? pair : pair.reverse
    error("#{sample.pointer}/#{given}", "#{given} needs a #{missing}")
  end

  # An error for each new receptacle that holds a sample of this scheme and
  # other samples too, for schemes that give a sample tags of its own
  # receptacle
  #
  # @param tags [String] the scheme's tags, as named in the message
  def shared_receptacle_errors(tags)
    pointers = samples.to_set(&:pointer)
    input.new_labware.flat_map(&:receptacles).filter_map do |receptacle|
      in_it = receptacle.samples
      next unless in_it.many? && in_it.any? { pointers.include?(it.pointer) }

      error(receptacle.pointer,
            "A receptacle with #{tags} holds one sample, not #{in_it.size}")
    end
  end

  # @return [Integer, nil] the well's position by column on a plate of the
  #   size, from 1 (A1 is 1, B1 is 2), or nil if it isn't one of its wells.
  #   A zero-padded well (A01) is read as A1.
  def well_index(well, plate_size)
    @well_indexes ||= Hash.new do |indexes, size|
      indexes[size] =
        Map.where_plate_size(size).where_plate_shape(AssetShape.default_id)
          .pluck(:description, :column_order)
          .to_h { |description, column_order| [description, column_order + 1] }
    end
    @well_indexes[plate_size][Map.strip_description(well)]
  end

  def used_by(users)
    "used by #{users.size} #{'sample'.pluralize(users.size)}"
  end

  def error(pointer, detail)
    { pointer:, detail: }
  end
end

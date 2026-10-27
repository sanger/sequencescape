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

  def used_by(users)
    "used by #{users.size} #{'sample'.pluralize(users.size)}"
  end

  def error(pointer, detail)
    { pointer:, detail: }
  end
end

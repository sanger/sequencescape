# frozen_string_literal: true

# A way a payload sample can give its tags, by a set of fields (FIELDS),
# named NAME in messages. A scheme is given the samples that give their tags
# its way, and checks them. Schemes without rules of their own find no
# problems.
class ApiOperation::Reception::Validation::Tags::Scheme
  # @param samples [Array<ApiOperation::Reception::Payload::PayloadSample>]
  #   the samples that give their tags this way
  def initialize(samples)
    @samples = samples
  end

  # @return [Array<Hash>] the problems, each with a :pointer and a :detail
  def errors
    []
  end

  private

  attr_reader :samples

  def error(pointer, detail)
    { pointer:, detail: }
  end
end

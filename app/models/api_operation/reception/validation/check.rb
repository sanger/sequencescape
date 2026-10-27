# frozen_string_literal: true

# A group of rules the payload must meet before reception creates anything.
# A check is given an ApiOperation::Reception::Validation::Input and returns
# the problems it finds, each with a pointer into the payload and a detail.
class ApiOperation::Reception::Validation::Check
  # @param input [ApiOperation::Reception::Validation::Input] what the check
  #   looks at
  def initialize(input)
    @input = input
  end

  # @return [Array<Hash>] the problems, each with a :pointer and a :detail
  def errors
    raise NotImplementedError, "#{self.class} must define errors"
  end

  private

  attr_reader :input

  def used_by(users)
    "used by #{users.size} #{'sample'.pluralize(users.size)}"
  end

  def error(pointer, detail)
    { pointer:, detail: }
  end
end

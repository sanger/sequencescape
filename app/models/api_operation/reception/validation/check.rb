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

  def used_by(samples)
    "used by #{samples.size} #{'sample'.pluralize(samples.size)}"
  end

  # The samples that give the field, by the name they give
  def samples_by_name(field)
    input.new_samples.select { it.fields.key?(field) }
      .group_by { it.fields[field] }
  end

  # The field of the supplier name the sample gets, and that name:
  # bioscan_supplier_name, which replaces supplier_sample_name, if given
  def supplier_name_of(sample)
    if sample.fields.key?('bioscan_supplier_name')
      ['bioscan_supplier_name', sample.fields['bioscan_supplier_name']]
    else
      ['supplier_sample_name', sample.supplier_sample_name]
    end
  end

  def error(pointer, detail)
    { pointer:, detail: }
  end
end

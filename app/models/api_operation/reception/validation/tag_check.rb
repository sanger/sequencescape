# frozen_string_literal: true

# Checks the tags of the samples in the new labware. A sample gives its tags
# in one of several ways (schemes, in SCHEMES), each by its own fields, or
# gives none. A sample that gives fields of more than one scheme is a
# problem, and its tags aren't checked further. Each scheme then checks the
# samples that give their tags its way.
class ApiOperation::Reception::Validation::TagCheck <
      ApiOperation::Reception::Validation::Check
  # The ways a sample can give its tags
  SCHEMES = [
    ApiOperation::Reception::Validation::Tags::Oligos,
    ApiOperation::Reception::Validation::Tags::TagGroups,
    ApiOperation::Reception::Validation::Tags::Chromium,
    ApiOperation::Reception::Validation::Tags::DualIndex
  ].freeze

  # (see ApiOperation::Reception::Validation::Check#errors)
  def errors
    @errors ||=
      mixed_scheme_errors +
      SCHEMES.flat_map do |scheme|
        scheme.new(samples_using(scheme), input).errors
      end
  end

  private

  # An error for each sample that gives fields of more than one scheme
  def mixed_scheme_errors
    input.new_samples.filter_map do |sample|
      schemes = schemes_of(sample)
      next unless schemes.many?

      error(sample.pointer,
            "Sample #{sample.sanger_sample_id} gives its tags in more than " \
            "one way: #{schemes.map { it::NAME }.to_sentence}")
    end
  end

  # The samples that give their tags the scheme's way, and no other
  def samples_using(scheme)
    input.new_samples.select { |sample| schemes_of(sample) == [scheme] }
  end

  # @return [Array<Class>] the schemes whose fields the sample gives
  def schemes_of(sample)
    SCHEMES.select { |scheme| sample.fields.keys.intersect?(scheme::FIELDS) }
  end
end

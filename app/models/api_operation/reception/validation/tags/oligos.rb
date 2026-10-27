# frozen_string_literal: true

# Tags given as oligo sequences: i7 for the tag, i5 for tag 2. Mirrors the
# sample manifest's i7 and i5 fields (SampleManifestExcel::Tags::Validator::
# Formatting).
class ApiOperation::Reception::Validation::Tags::Oligos <
      ApiOperation::Reception::Validation::Tags::Scheme
  # The payload fields of this scheme
  FIELDS = %w[i7 i5].freeze

  # How this scheme is named in messages
  NAME = 'i7/i5'

  # Only the letters A, C, G, T and N, in either case
  OLIGO = /\A[acgtn]+\z/i

  # The longest oligo the sample manifest accepts
  MAX_LENGTH = 30

  # (see ApiOperation::Reception::Validation::Tags::Scheme#errors)
  def errors
    @errors ||=
      samples.flat_map do |sample|
        FIELDS.filter_map do |field|
          problem = oligo_problem(sample.fields[field])
          error("#{sample.pointer}/#{field}", "#{field} #{problem}") if problem
        end
      end
  end

  private

  def oligo_problem(oligo)
    if oligo.nil?
      nil
    elsif !OLIGO.match?(oligo)
      'must be a combination of A, C, G, T or N'
    elsif oligo.length > MAX_LENGTH
      "must not be longer than #{MAX_LENGTH} characters"
    end
  end
end

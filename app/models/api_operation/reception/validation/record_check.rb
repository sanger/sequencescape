# frozen_string_literal: true

# Checks the values of the new samples that their records' model validations
# would reject, so they are reported with a pointer instead of failing when
# the records are created:
# - The Sanger sample ID becomes the sample's name, so it can only contain
#   letters, numbers, _ or - (Sample's name format on create).
# - The supplier sample name, from supplier_sample_name or
#   bioscan_supplier_name (which replaces it), only allows ASCII characters
#   (Sample::Metadata#supplier_name).
# - donor_id has no characters of more than 3 bytes, such as emoji
#   (Sample::Metadata, Utf8mb3Validator).
# A sample in more than one receptacle is checked once. Existing names and
# Sanger sample IDs are checked by SampleCheck. The records are still
# created with create!, so their models apply every rule.
class ApiOperation::Reception::Validation::RecordCheck <
      ApiOperation::Reception::Validation::Check
  # Only letters, digits, _ and -, in either case, as Sample's name format
  NAME_FORMAT = /\A[\w_-]+\z/i

  # Only ASCII characters, as Sample::Metadata's supplier name
  ASCII = /\A[[:ascii:]]+\z/

  # The most bytes a character of a utf8mb3 field may have
  MAX_CHARACTER_BYTES = 3

  # (see ApiOperation::Reception::Validation::Check#errors)
  def errors
    @errors ||=
      input.new_samples.uniq(&:uuid).flat_map do |sample|
        [name_error(sample), *supplier_name_errors(sample),
         donor_id_error(sample)].compact
      end
  end

  private

  def name_error(sample)
    name = sample.sanger_sample_id
    return if NAME_FORMAT.match?(name)

    error("#{sample.pointer}/sanger_sample_id",
          "Sanger sample ID #{name} #{I18n.t('samples.name_format')}, " \
          'as it becomes the sample name')
  end

  def supplier_name_errors(sample)
    { 'supplier_sample_name' => sample.supplier_sample_name,
      'bioscan_supplier_name' => sample.fields['bioscan_supplier_name'] }
      .filter_map do |field, name|
        next if name.nil? || ASCII.match?(name)

        others = name.chars.grep_v(ASCII).uniq
        error("#{sample.pointer}/#{field}",
              "#{field} only allows ASCII characters, not " \
              "#{others.to_sentence}")
      end
  end

  def donor_id_error(sample)
    donor_id = sample.fields['donor_id']
    return if donor_id.nil?

    wide = donor_id.chars.select { it.bytesize > MAX_CHARACTER_BYTES }
    return if wide.empty?

    error("#{sample.pointer}/donor_id",
          'donor_id contains supplementary characters (eg. emoji), remove ' \
          "or replace them: #{wide.to_sentence}")
  end
end

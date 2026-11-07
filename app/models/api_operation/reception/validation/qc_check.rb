# frozen_string_literal: true

# Checks that every volume and concentration the new labware's samples give
# can be stored, so that none is dropped. Reception stores the fields that
# Creation::QcFactory records in two places:
# - as QC results on a receptacle that holds only that sample
#   (Creation::QcFactory);
# - in the sample's metadata, when the sample has only one entry
#   (Creation::SampleFactory).
# An entry in a receptacle with other samples, of a sample with more than one
# entry, has neither, so a volume or concentration there is an error. Their
# ranges are the schema's.
class ApiOperation::Reception::Validation::QcCheck <
      ApiOperation::Reception::Validation::Check
  # (see ApiOperation::Reception::Validation::Check#errors)
  def errors
    @errors ||= pooled_entries.filter_map do |sample|
      given = qc_fields(sample)
      next if given.empty? || entry_counts[sample.uuid] == 1

      error(sample.pointer,
            "Sample #{sample.uuid} gives a #{given.to_sentence} that can't " \
            'be stored: it is in more than one receptacle, and this one ' \
            'holds other samples')
    end
  end

  private

  # The entries in receptacles that hold more than one
  def pooled_entries
    input.new_labware.flat_map(&:receptacles)
      .reject { it.samples.one? }.flat_map(&:samples)
  end

  # How many entries each sample has, by UUID
  def entry_counts
    @entry_counts ||= input.new_samples.map(&:uuid).tally
  end

  # The fields recorded as QC results that the entry gives
  def qc_fields(sample)
    ApiOperation::Reception::Creation::QcFactory::UNITS.keys
      .select { sample.fields[it] }
  end
end

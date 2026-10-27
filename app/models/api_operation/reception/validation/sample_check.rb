# frozen_string_literal: true

# Checks the samples in the payload's new labware:
# - Each sample has an existing study. An unknown study is reported once, at
#   the first sample that uses it, with how many do.
# - A sample in more than one receptacle (the same UUID) has the same Sanger
#   sample ID, supplier sample name and study in each.
# - Each sample's UUID and Sanger sample ID are new to Sequencescape, and no
#   two samples share a Sanger sample ID. Sanger sample IDs are compared
#   ignoring case, as sample names are.
# Each check looks up all the samples in one query.
class ApiOperation::Reception::Validation::SampleCheck <
      ApiOperation::Reception::Validation::Check
  # The fields every entry of a sample in more than one receptacle must share
  SAMPLE_FIELDS = %i[sanger_sample_id supplier_sample_name study_uuid].freeze

  # (see ApiOperation::Reception::Validation::Check#errors)
  def errors
    return [] if input.new_samples.empty?

    @errors ||=
      study_errors + repeated_sample_errors + shared_sanger_sample_id_errors +
      used_uuid_errors + used_sanger_sample_id_errors
  end

  private

  # The entries by UUID; a sample in more than one receptacle has an entry in
  # each
  def samples_by_uuid
    @samples_by_uuid ||= input.new_samples.group_by(&:uuid)
  end

  # The first entry of each sample
  def distinct_samples
    samples_by_uuid.values.map(&:first)
  end

  # An error for each study UUID that isn't a Sequencescape study
  def study_errors
    samples_by_study = input.new_samples.group_by(&:study_uuid)
    known = Study.with_uuid(samples_by_study.keys).pluck('uuids.external_id')
    samples_by_study.except(*known).map do |uuid, samples|
      error("#{samples.first.pointer}/study_uuid",
            "No study with UUID #{uuid} (#{used_by(samples)})")
    end
  end

  # An error for each entry of a sample that differs from its first entry
  def repeated_sample_errors
    samples_by_uuid.values.flat_map do |first, *others|
      others.filter_map do |sample|
        fields = SAMPLE_FIELDS.reject { first.send(it) == sample.send(it) }
        next if fields.empty?

        error(sample.pointer,
              "Sample #{sample.uuid} has a different " \
              "#{fields.to_sentence} from #{first.pointer}")
      end
    end
  end

  # An error for each sample whose Sanger sample ID is another's
  def shared_sanger_sample_id_errors
    distinct_samples.group_by { it.sanger_sample_id.downcase }.values
      .flat_map do |first, *others|
        others.map do |sample|
          error("#{sample.pointer}/sanger_sample_id",
                "Sanger sample ID #{sample.sanger_sample_id} is also used " \
                "by another sample, at #{first.pointer}")
        end
      end
  end

  # An error for each sample whose UUID Sequencescape already uses, for a
  # record of any kind
  def used_uuid_errors
    used = Uuid.where(external_id: samples_by_uuid.keys).pluck(:external_id)
      .to_set(&:downcase)
    distinct_samples.filter_map do |sample|
      next unless used.include?(sample.uuid.downcase)

      error("#{sample.pointer}/uuid",
            "UUID #{sample.uuid} is already used in Sequencescape")
    end
  end

  # An error for each sample whose Sanger sample ID is already a sample's
  # Sanger sample ID or name in Sequencescape
  def used_sanger_sample_id_errors
    used = used_sanger_sample_ids
    distinct_samples.filter_map do |sample|
      next unless used.include?(sample.sanger_sample_id.downcase)

      error("#{sample.pointer}/sanger_sample_id",
            "Sanger sample ID #{sample.sanger_sample_id} is already used " \
            'by a sample in Sequencescape')
    end
  end

  # @return [Set<String>] the Sanger sample IDs that are a Sequencescape
  #   sample's Sanger sample ID or name, in lower case
  def used_sanger_sample_ids
    ids = distinct_samples.map(&:sanger_sample_id)
    Sample.where(sanger_sample_id: ids).or(Sample.where(name: ids))
      .pluck(:sanger_sample_id, :name).flatten.compact.to_set(&:downcase)
  end
end

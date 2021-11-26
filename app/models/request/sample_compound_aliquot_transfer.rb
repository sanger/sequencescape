# frozen_string_literal: true

# Module to provide support to handle creation of a compound sample
# from the list of samples at the source.
#
# Assumptions:
#  - This module will be included in a Request class
module Request::SampleCompoundAliquotTransfer
  # Indicates if a compound sample creation is needed, if any of the aliquots
  # at the source has a different tag_depth defined
  def compound_samples_needed?
    return false if asset.aliquots.count == 1

    _tag_clash?
  end

  # Creates a sample in a single aliquot at destination as a compound sample
  # where the component samples are all samples at source
  def transfer_aliquots_into_compound_sample_aliquots
    _aliquots_by_tags_combination.each do |_tags_combo, aliquot_list|
      transfer_into_compound_sample_aliquot(aliquot_list)
    end
  end

  private

  def transfer_into_compound_sample_aliquot(source_aliquots)
    samples = source_aliquots.map(&:sample)

    if source_aliquots.pluck(:tag_depth).uniq.count != source_aliquots.size
      raise "Cannot create compound sample from following samples due to duplicate 'tag depth': #{samples.map(&:name)}"
    end

    compound_sample = _create_compound_sample(_default_compound_study, samples)

    add_aliquot(compound_sample, source_aliquots.first.tag_id, source_aliquots.first.tag2_id)
  end

  def add_aliquot(sample, tag_id, tag2_id)
    target_asset
      .aliquots
      .create(sample: sample)
      .tap do |aliquot|
        aliquot.tag_id = tag_id
        aliquot.tag2_id = tag2_id
        aliquot.library_type = _default_library_type
        aliquot.study_id = _default_compound_study.id
        aliquot.project_id = _default_compound_project_id
        aliquot.save
      end
  end

  def _tag_clash?
    _aliquots_by_tags_combination.any? { |_tags_combo, aliquot_list| aliquot_list.size > 1 }
  end

  def _aliquots_by_tags_combination
    asset.aliquots.group_by(&:tags_combination)
  end

  # Private method to generate a compound sample in a study from a list of
  # component samples
  def _create_compound_sample(study, component_samples)
    study.samples.create!(
      name: SangerSampleId.generate_sanger_sample_id!(study.abbreviation),
      component_samples: component_samples
    )
  end

  # Default study that the new compound sample will use
  def _default_compound_study
    asset.samples.first.studies.first
  end

  # Default project that the new compound sample will use
  def _default_compound_project_id
    asset.aliquots.first.project_id
  end

  # Default library type value
  def _default_library_type
    asset.aliquots.first.library_type
  end
end

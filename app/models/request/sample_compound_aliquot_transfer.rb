# frozen_string_literal: true

# Module to provide support to handle creation of compound samples
# from the list of samples at the source. A compound sample is a
# sample that represents a combination of other samples.
#
# The reason for this is to ensure that when the data gets to the MLWH,
# each row has a unique combination of tag1 and tag2 -
# this is a requirement for the Illumina de-plexing that NPG does.
#
# tag_depth on aliquot is used to indicate that,
# even though certain aliquots might share the same tags, they can in fact
# be separated out by other means
# (e.g. by genotype, because they have been sequenced before).
#
# In the case where multiple aliquots share the same tag1 tag2 combo,
# we represent them as a single aliquot with a single sample
# in the target Lane, but link the sample back to its component sample
# using the SampleCompoundComponent join object.
#
# Assumptions:
#  - This module will be included in a Request class
module Request::SampleCompoundAliquotTransfer
  DUPLICATE_TAG_DEPTH_ERROR_MSG = "Cannot create compound sample from following samples due to duplicate 'tag depth'"
  MULTIPLE_STUDIES_ERROR_MSG =
    'Cannot create compound sample due to the component samples being under different studies.'

  # Indicates if a compound sample creation is needed, by checking
  # if any of the source aliquots share the same tag1 and tag2
  def compound_samples_needed?
    return false if asset.aliquots.count == 1

    _any_aliquots_share_tag_combination?
  end

  # Groups the source aliquots by their tag1 and tag2 combination
  # For each of these groups, create a compound sample.
  def transfer_aliquots_into_compound_sample_aliquots
    _aliquots_by_tags_combination.each do |_tags_combo, aliquot_list|
      _transfer_into_compound_sample_aliquot(aliquot_list)
    end
  end

  private

  def _transfer_into_compound_sample_aliquot(source_aliquots)
    samples = source_aliquots.map(&:sample)

    # Check that the component samples in the compound sample will be able to be distinguished -
    # this is represented by them all having a unique 'tag_depth'
    if source_aliquots.pluck(:tag_depth).uniq.count != source_aliquots.size
      raise "#{DUPLICATE_TAG_DEPTH_ERROR_MSG}: #{samples.map(&:name)}"
    end

    compound_sample = _create_compound_sample(_default_compound_study, samples)

    _add_aliquot(compound_sample, source_aliquots)
  end

  def _add_aliquot(sample, source_aliquots)
    target_asset
      .aliquots
      .create(sample: sample)
      .tap do |aliquot|
        _set_aliquot_attributes(aliquot, source_aliquots)
        aliquot.save
      end
  end

  def _set_aliquot_attributes(aliquot, source_aliquots)
    aliquot.tag_id = source_aliquots.first.tag_id
    aliquot.tag2_id = source_aliquots.first.tag2_id
    aliquot.library_type = _default_library_type
    aliquot.study_id = _default_compound_study.id
    aliquot.project_id = _default_compound_project_id
    aliquot.library_id = _copy_library_id(source_aliquots)
  end

  # If the library_id is the same on all source aliquots, we can confidently transfer it to the target aliquot
  # How the library_id should be set if the source aliquots have different library_ids is not defined
  # Therefore, set it to nil for now, until we have a real requirement
  def _copy_library_id(source_aliquots)
    library_ids = source_aliquots.map(&:library_id).uniq
    library_ids.size == 1 ? library_ids.first : nil
  end

  def _any_aliquots_share_tag_combination?
    _aliquots_by_tags_combination.any? { |_tags_combo, aliquot_list| aliquot_list.size > 1 }
  end

  def _aliquots_by_tags_combination
    asset.aliquots.group_by(&:tags_combination)
  end

  def _studies
    @studies ||= asset.aliquots.map(&:study).uniq
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
  # Uses the one from the request if it's present,
  # otherwise, the one from the source aliquots if it's consistent.
  def _default_compound_study
    _initial_study ||
      begin
        raise MULTIPLE_STUDIES_ERROR_MSG if _studies.count > 1

        _studies.first
      end
  end

  def _initial_study
    return nil unless initial_study_id

    Study.find(initial_study_id)
  end

  # Default project that the new compound sample will use
  # Uses the one from the request if it's present,
  # otherwise, one grabbed from a source aliquot.
  def _default_compound_project_id
    initial_project_id || asset.aliquots.first.project_id
  end

  # Default library type value
  def _default_library_type
    asset.aliquots.first.library_type
  end
end

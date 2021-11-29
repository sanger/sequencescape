# frozen_string_literal: true

# Module to provide support to handle creation of compound samples
# from the list of samples at the source.
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
      transfer_into_compound_sample_aliquot(aliquot_list)
    end
  end

  private

  def transfer_into_compound_sample_aliquot(source_aliquots)
    samples = source_aliquots.map(&:sample)

    # Check that the component samples in the compound sample will be able to be distinguished -
    # this is represented by them all having a unique 'tag_depth'
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

  def _any_aliquots_share_tag_combination?
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

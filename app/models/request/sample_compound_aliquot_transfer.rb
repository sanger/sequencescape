# frozen_string_literal: true

# Module to provide support to handle creation of a compound sample
# from the list of samples at the source.
#
# Assumptions:
#  - This module will be included in a Request class
module Request::SampleCompoundAliquotTransfer
  # Indicates if a compound sample creation is needed, if any of the aliquots
  # at the source has a tag_depth defined
  def compound_samples_needed?
    asset.aliquots.any? {|al| !al.tag_depth.nil? }
  end

  # Creates a sample in a single aliquot at destination as a compound sample
  # where the component samples are all samples at source
  def transfer_aliquots_into_compound_sample_aliquot
    compound_sample = _create_compound_sample(_default_compound_study, asset.samples)
    target_asset.aliquots.create(sample: compound_sample).tap do |aliquot|
      aliquot.study_id = _default_compound_study.id
      aliquot.project_id = _default_compound_project_id
      aliquot.save
    end
  end

  private

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

end
